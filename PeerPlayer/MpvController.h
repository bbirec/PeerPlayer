//
//  MpvController.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <mpv/client.h>

@interface MpvController : NSObject {
    mpv_handle *mpv;
    dispatch_queue_t queue;
}

@property (strong) NSView* wrapper;

-(id) initWithView:(NSView*) wrapper;

-(void) playWithUrl:(NSString*) url;
-(void) stop;
-(void) quit;

@end
