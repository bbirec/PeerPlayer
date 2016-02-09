//
//  Peerflix.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "Peerflix.h"


@implementation Peerflix

-(id) init {
    if(self = [super init]) {
        [self connectWs];
        
        // Launch
        NSString* execPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"go-peerflix"];
        NSLog(@"%@", execPath);
        
        NSTask* task = [[NSTask alloc] init];
        NSPipe* outputPipe = [NSPipe pipe];
        [task setStandardOutput:outputPipe];
        [task setLaunchPath:execPath];
        [task setArguments:	[NSArray arrayWithObjects:@"-port", @"8000", nil]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(readCompleted:)
                                                     name:NSFileHandleReadToEndOfFileCompletionNotification object:[outputPipe fileHandleForReading]];
        [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
        
        [task launch];
    }
    return self;
}


- (void)readCompleted:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
}



+(void) kill {
    NSTask *controlTask = [[NSTask alloc] init];
    controlTask.launchPath = @"/usr/bin/pkill";
    controlTask.arguments = @[@"go-peerflix"];
    [controlTask launch];
}

#pragma mark WebSocket

-(void) connectWs {
    // Connect Web socket
    NSURL* wsUrl = [NSURL URLWithString:@"http://localhost:8000/ws"];
    self.socket = [[SRWebSocket alloc] initWithURL:wsUrl];
    self.socket.delegate = self;
    [self.socket open];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString*)message {
    NSLog(@"Got ws message:%@", message);
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    
    if(error) {
        NSLog(@"JSON data is malformed.");
        return;
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = object;
        if(self.delegate) {
            [self.delegate torrentReady:dict];
        }
    }
    else
    {
        // JSON data is malformed.
        NSLog(@"JSON data is malformed.");
        return;
    }
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
    //TODO : When web socket server could not start. Exponential back off?
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(connectWs)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark Torrent

-(void) downloadTorrent:(NSString*)pathOrMagnet {
    [self.socket send:pathOrMagnet];
}

@end
