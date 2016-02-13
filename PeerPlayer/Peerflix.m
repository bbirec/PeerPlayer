//
//  Peerflix.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "Peerflix.h"
#import "go-peerflix.h"

static Peerflix* _instance;

@implementation Peerflix

-(void) initialize {
    _instance = self;
    
    // Initilize peerflix
    Init();
}

-(NSDictionary*) getStatus {
    GoString str = GetStatus();
    NSString* statusJson = [NSString stringWithUTF8String:str.p];
    
    NSLog(@"Get status:%@", statusJson);
    NSData* data = [statusJson dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    
    if(error) {
        NSLog(@"JSON data is malformed.");
        return nil;
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = object;

        return dict;
    }
    else
    {
        // JSON data is malformed.
        NSLog(@"JSON data is malformed.");
        return nil;
    }
}

-(void) torrentReady {
    if(self.delegate) {
        NSDictionary* status = [self getStatus];
        NSLog(@"%@", status);
        [self.delegate torrentReady:status];
    }
}

#pragma mark Torrent

void readyCb(int ready) {
    NSLog(@"Ready cb: %d", ready);
    
    [_instance performSelectorOnMainThread:@selector(torrentReady)
                                withObject:nil
                             waitUntilDone:NO];
}

-(void) downloadTorrent:(NSString*)pathOrMagnet {
    GoString path;
    path.p = (char*)[pathOrMagnet UTF8String];
    path.n = strlen(path.p);
    
    NewTorrent(path, &readyCb);
}

-(NSString*) streamUrlFromHash:(NSString*) hash {
    return [NSString stringWithFormat:@"http://localhost:8000/?hash=%@", hash];
}

@end
