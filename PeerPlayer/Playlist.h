//
//  Playlist.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 3. 12..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface File : NSObject

@property (strong) NSString* fileName;
@property (strong) NSString* fileHash;
@property long fileSize;

-(BOOL) isMedia;

@end

@interface Playlist : NSObject

+(Playlist*) playListFromFiles:(NSArray<File*>*) files;

@property (strong) NSArray<File*>* mediaFiles;
@property (strong) NSArray<File*>* subFiles;

-(File*) getFirstMedia;
-(File*) getPrevMedia:(File*) currentFile;
-(File*) getNextMedia:(File*) currentFile;
-(File*) getSubtitleForMedia:(File*) mediaFile;

@end
