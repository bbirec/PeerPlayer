all: go-peerflix.a

go-peerflix.a: *.go
	go get -d
	go build -buildmode=c-archive

clean:
	rm go-peerflix.a go-peerflix.h