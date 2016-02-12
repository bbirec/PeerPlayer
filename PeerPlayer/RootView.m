//
//  RootView.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 13..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "RootView.h"
#import "MpvController.h"

@implementation RootView

-(BOOL) acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL) acceptsFirstResponder { return YES; }

-(void) awakeFromNib {
    [self setWantsLayer:YES];
}

-(void) keyDown:(NSEvent *)event
{
    NSLog(@"keydown: %@", event);
    
    switch(event.keyCode) {
        case 49:
            // Toggle pause
            [[MpvController getInstance] togglePause];
            break;
        case 123:
            // Seek -10
            [[MpvController getInstance] seek:-10];
            break;
        case 124:
            // Seek 10
            [[MpvController getInstance] seek:10];
            break;
        default:
            break;
    }
}

@end
