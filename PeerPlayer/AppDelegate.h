//
//  AppDelegate.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 7..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <mpv/client.h>
#import "ZMQObjC.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    mpv_handle *mpv;
    dispatch_queue_t queue;
    ZMQContext *ctx;
    
    NSTask *task;
}

@property (strong) NSWindow *window;
@property (strong) NSView* wrapper;

@end

