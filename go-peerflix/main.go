package main

/*
#include <stdlib.h>
typedef void (*callback_ready)(int);
static inline void CallbackReady(void* ptr, int ready) {
	if(ptr != 0) {
		((void (*)(int))ptr)(ready);
	}
}
typedef void (*callback_status)(char*);
static inline void CallbackStatus(void* ptr, char* status) {
	if(ptr != 0) {
		((void (*)(char*))ptr)(status);
	}
}
*/
import "C"

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
	"unsafe"

	"os/signal"
	"syscall"
)

// Exit statuses.
const (
	_ = iota
	exitNoTorrentProvided
	exitErrorInClient
)

var client *Client

//export Init
func Init(statusCallback unsafe.Pointer) {
	var err error
	folder := os.TempDir()
	port := 8000
	// Start up the torrent client.
	client, err = NewClient(folder)
	if err != nil {
		log.Fatalf(err.Error())
		os.Exit(exitErrorInClient)
	}
	log.Printf("Downloading on %s\n", folder)

	go func() {
		for {
			// Send status every seconds
			err, status := client.GetStatusJson()
			if err != nil {
				continue
			}

			statusC := C.CString(status)
			C.CallbackStatus(statusCallback, statusC)
			C.free(unsafe.Pointer(statusC))

			time.Sleep(time.Second)
		}
	}()

	go func() {
		log.Printf("Listening on port %d\n", port)
		http.HandleFunc("/", client.GetFile)
		log.Fatal(http.ListenAndServe(":"+strconv.Itoa(port), nil))
	}()
}

//export NewTorrent
func NewTorrent(torrentPath string, readyCallback unsafe.Pointer) {
	log.Printf("New torrent: %s\n", torrentPath)

	// Copy torrentPath string due to abnormal behaviour
	err, readyChan := client.NewTorrent(fmt.Sprint(torrentPath))
	if err != nil {
		log.Println(err)
	}

	go func() {
		ready := <-readyChan
		log.Printf("Ready: %t\n", ready)
		var v int
		if ready {
			v = 1
		} else {
			v = 0
		}

		C.CallbackReady(readyCallback, C.int(v))

	}()

}

//export GetStatus
func GetStatus() string {
	err, status := client.GetStatusJson()
	if err != nil {
		return ""
	}

	log.Printf("Status: %s\n", status)

	return status
}

func main() {
	// Empty
	Init(nil)
	NewTorrent("/Users/bbirec/tmp/es.torrent", nil)
	GetStatus()

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGPIPE)

	go func() {
		sig := <-sigs
		log.Println()
		log.Println(sig)
	}()

	for {
		time.Sleep(time.Second * 1)
	}
}