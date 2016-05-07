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
                    @"mpeg", @"mpg", @"m4v", @"3gp", @"mp3", @"ts",
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

-(File*) getFirstMedia {
    return [self.mediaFiles firstObject];
}

-(File*) getPrevMedia:(File*) currentFile {
    if(currentFile == nil) {
        return [self.mediaFiles firstObject];
    }
    else {
        NSUInteger idx = [self.mediaFiles indexOfObject:currentFile];
        if(idx == NSNotFound) {
            return nil;
        }
        else if(idx == 0) {
            return nil;
        }
        else {
            return [self.mediaFiles objectAtIndex:idx-1];
        }
    }
}

-(File*) getNextMedia:(File*) currentFile {
    // Return the first file
    if(currentFile == nil) {
        return [self.mediaFiles firstObject];
    }
    
    NSUInteger idx = [self.mediaFiles indexOfObject:currentFile];
    if(idx == NSNotFound) {
        return nil;
    }
    else if(idx + 1 == [self.mediaFiles count]) {
        return nil;
        
    }
    else {
        return [self.mediaFiles objectAtIndex:idx+1];
    }
}

-(File*) getSubtitleForMedia:(File*) mediaFile {
    NSString* name = [[mediaFile.fileName stringByDeletingPathExtension] lowercaseString];
    
    for(File* f in self.subFiles) {
        if([[[f.fileName stringByDeletingPathExtension] lowercaseString] isEqualToString:name]) {
            return f;
        }
    }
    
    return nil;
}

@end
