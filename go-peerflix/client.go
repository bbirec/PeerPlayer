package main

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/anacrolix/torrent"
)

// ClientError formats errors coming from the client.
type ClientError struct {
	Type   string
	Origin error
}

func (clientError ClientError) Error() string {
	return fmt.Sprintf("Error %s: %s\n", clientError.Type, clientError.Origin)
}

// Client manages the torrent downloading.
type Client struct {
	Client         *torrent.Client
	downloadFolder string

	// Maintain one torrent file at a time
	Ready       bool
	TorrentPath string
}

// Return md5 hash of a string
func md5Hash(str string) string {
	hasher := md5.New()
	hasher.Write([]byte(str))
	return hex.EncodeToString(hasher.Sum(nil))
}

func NewClient(downloadFolder string) (*Client, error) {
	client, err := torrent.NewClient(&torrent.Config{
		DataDir:    downloadFolder,
		NoUpload:   false,
		Seed:       true,
		DisableTCP: false,
	})
	if err != nil {
		return nil, ClientError{Type: "creating torrent client", Origin: err}
	}

	return &Client{
		Client:         client,
		downloadFolder: downloadFolder,
	}, nil
}

func (c *Client) NewTorrent(torrentPath string) (error, chan bool) {
	c.DropTorrent()
	c.Ready = false
	c.TorrentPath = torrentPath

	readyChan := make(chan bool)

	var t torrent.Torrent
	client := c.Client

	// Add as magnet url.
	var err error
	if strings.HasPrefix(torrentPath, "magnet:") {
		if t, err = client.AddMagnet(torrentPath); err != nil {
			return ClientError{Type: "adding torrent", Origin: err}, nil
		}
	} else {
		// Otherwise add as a torrent file.

		// Check if the file exists.
		if _, err = os.Stat(torrentPath); err != nil {
			return ClientError{Type: "file not found", Origin: err}, nil
		}

		if t, err = client.AddTorrentFromFile(torrentPath); err != nil {
			return ClientError{Type: "adding torrent to the client", Origin: err}, nil
		}
	}

	go func() {
		// Wait for the torrent info and start to download immediately
		<-t.GotInfo()
		t.DownloadAll()

		c.Ready = true

		// Publish torrent info
		readyChan <- true
	}()

	return nil, readyChan
}

func (c *Client) DropTorrent() {
	// Drop existing torrents
	for _, t := range c.Client.Torrents() {
		t.Drop()
	}
}

func (c *Client) GetTorrent() (*torrent.Torrent, error) {
	ts := c.Client.Torrents()
	if len(ts) == 0 {
		return nil, errors.New("There is no torrent")
	}
	return &ts[0], nil
}

// Close cleans up the connections.
func (c *Client) Close() {
	c.DropTorrent()
	c.Client.Close()
}

// Find a file if md5 hash of file path is matched.
func (c Client) getFileFromHash(hash string) (*torrent.File, error) {
	t, err := c.GetTorrent()

	if err != nil {
		return nil, err
	}

	for _, file := range t.Files() {
		if md5Hash(file.Path()) == hash {
			return &file, nil
		}
	}
	return nil, errors.New("Not found file from hash")
}

// GetFile is an http handler to serve file indentified by md5 hash of file path.
func (c Client) GetFile(w http.ResponseWriter, r *http.Request) {
	if r.Method == "HEAD" {
		return
	}

	hash := r.FormValue("hash")

	target, err := c.getFileFromHash(hash)
	if err != nil {
		http.NotFound(w, r)
		return
	}

	entry, err := NewFileReader(target)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer func() {
		if err := entry.Close(); err != nil {
			log.Printf("Error closing file reader: %s\n", err)
		}
	}()

	filename := filepath.Base(target.Path())
	w.Header().Set("Content-Disposition", "attachment; filename=\""+filename+"\"")
	http.ServeContent(w, r, target.DisplayPath(), time.Now(), entry)
}

func (c *Client) GetStatusJson() (error, string) {
	// Assume that there is only one torrent.
	t, err := c.GetTorrent()
	if err != nil {
		return err, ""
	}

	// Compose the status payload
	var status ClientStatus
	status.Files = make([]*FileStatus, len(t.Files()))
	for i, file := range t.Files() {
		completed := true
		for _, state := range file.State() {
			if !state.Complete {
				completed = false
				break
			}
		}

		status.Files[i] = &FileStatus{
			Filename:  file.Path(),
			Size:      file.Length(),
			Completed: completed,
			Hash:      md5Hash(file.Path()),
		}
	}

	status.BytesCompleted = t.BytesCompleted()
	status.BytesTotal = t.Length()
	status.Ready = c.Ready
	status.TorrentPath = c.TorrentPath

	data, err := json.Marshal(status)
	if err != nil {
		fmt.Println("Error to serialize status")
		return err, ""
	}

	return nil, string(data)
}
