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
        // Space
        case 49:
            [[MpvController getInstance] togglePause];
            break;
        // Left arrow
        case 123:
            [[MpvController getInstance] seek:-10];
            break;
        // Right arrow
        case 124:
            [[MpvController getInstance] seek:10];
            break;
        // Up arrow
        case 126:
            [[MpvController getInstance] volume:10.f];
            break;
        // Down arrow
        case 125:
            [[MpvController getInstance] volume:-10.f];
            break;
        // Enter
        case 36:
            [self.window toggleFullScreen:self];
            break;
        default:
            break;
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if([theEvent clickCount] == 2)
    {
        // Fullscreen
        [self.window toggleFullScreen:self];
    }
}


- (void)scrollWheel:(NSEvent *)theEvent {
    if([theEvent deltaY] < 0.0) {
        // Volume down
        [[MpvController getInstance] volume:-10.f];
    }
    else if(0.0 < [theEvent deltaY]) {
        // Volume up
        [[MpvController getInstance] volume:10.f];
    }
}


@end
