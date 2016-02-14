package main

type FileStatus struct {
	Filename  string
	Hash      string
	Size      int64
	Completed bool
}

type ClientStatus struct {
	Files []*FileStatus

	TorrentPath    string
	Ready          bool
	BytesTotal     int64
	BytesCompleted int64
}
