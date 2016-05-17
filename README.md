PeerPlayer
----------

*PeerPlayer* is a media player plays various video/audio files from `.torrent` file.

## Features
 - Play any media file without extra codec plugin.
 - Play media file while downloading
 - Load subtitle automatically

## Dependencies
 - [mpv](https://github.com/mpv-player/mpv)
 - [torrent](https://github.com/anacrolix/torrent)

## How to build

 - [Install Go](https://golang.org/dl/)

### Build mpv
Download the mpv source code and build as shared library.

```
$ brew install mpv # This will install mpv dependencies.

$ ./waf configure --enable-libmpv-shared
$ ./waf
$ ./waf install
```

## Install dylibbundler (For Release Build)
`dylibbundler` will bundle the dynamic libraries(libmpv.dylib, libavcodec.dylib, ...) into the App package.
The executable binary will be fixed to link the libraries properly.

```
$ go get github.com/bbirec/dylibbundler
```

## License
GPLv2 or later