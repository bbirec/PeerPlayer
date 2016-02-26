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

void readyCb(int ready);
void statusCb(char* status);


@implementation Peerflix

-(void) initialize {
    _instance = self;
    
    // Initilize peerflix
    Init(&statusCb);
}

-(NSDictionary*) parseStatus:(NSString*) statusJson {
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

-(NSDictionary*) getStatus {
    char* p = GetStatus();
    NSString* statusJson = [NSString stringWithUTF8String:p];
    free(p);
    
    return [self parseStatus:statusJson];
}


void readyCb(int ready) {
    [_instance performSelectorOnMainThread:@selector(torrentReady)
                                withObject:nil
                             waitUntilDone:NO];
}

void statusCb(char* status) {
    NSString* statusJson = [NSString stringWithUTF8String:status];
    [_instance performSelectorOnMainThread:@selector(torrentStatus:)
                                withObject:statusJson
                             waitUntilDone:NO];
}



-(void) torrentReady {
    if(self.delegate) {
        NSDictionary* status = [self getStatus];
        [self.delegate torrentReady:status];
    }
}

-(void) torrentStatus:(NSString*) statusJson {
    [self.delegate torrentStatusChanged:[self parseStatus:statusJson]];
}

#pragma mark Torrent

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


