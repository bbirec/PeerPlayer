//
//  Playlist.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 3. 12..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "Playlist.h"

@implementation File

-(BOOL) isMedia {
    static NSSet* mediaExt;
    if(mediaExt == nil) {
        mediaExt = [NSSet setWithObjects:@"mkv", @"avi", @"mp4", @"ogv", @"webm",
                    @"rmvb", @"flv", @"wmv", @"vob", @"asf",
                    @"mpeg", @"mpg", @"m4v", @"3gp", @"mp3",
                    @"wav", @"ogv", @"flac", @"m4a", @"wma", nil];
    }
    
    NSString* ext = [[self.fileName pathExtension] lowercaseString];
    return [mediaExt containsObject:ext];
}

-(BOOL) isSubtitle {
    static NSSet* subExt;
    if(subExt == nil) {
        subExt = [NSSet setWithObjects:@"smi", @"srt", nil];
    }
    
    NSString* ext = [[self.fileName pathExtension] lowercaseString];
    return [subExt containsObject:ext];
}

- (NSComparisonResult)alphabeticallyCompare:(File *)file {
    return [self.fileName localizedCaseInsensitiveCompare:file.fileName];
}

@end

@implementation Playlist

+(Playlist*) playListFromFiles:(NSArray<File*>*) files {
    Playlist* instance = [[Playlist alloc] init];
    
    NSMutableArray<File*> * mediaFiles = [[NSMutableArray alloc] init];
    NSMutableArray<File*> * subFiles = [[NSMutableArray alloc] init];
    for(File* f in files) {
        if([f isMedia]) {
            [mediaFiles addObject:f];
        }
        else if([f isSubtitle]) {
            [subFiles addObject:f];
        }
    }
    
    instance.mediaFiles = [mediaFiles sortedArrayUsingSelector:@selector(alphabeticallyCompare:)];;
    instance.subFiles = [subFiles sortedArrayUsingSelector:@selector(alphabeticallyCompare:)];
    
    return instance;
}

-(File*) getNextMedia:(File*) currentFile {
    // Return the first file
    if(currentFile == nil) {
        return [self.mediaFiles firstObject];
    }
    
    NSUInteger idx = [self.mediaFiles indexOfObject:currentFile];
    if(idx + 1 < [self.mediaFiles count]) {
        return [self.mediaFiles objectAtIndex:idx+1];
    }
    return nil;
}

@end