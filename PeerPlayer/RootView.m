//
//  RootView.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 13..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "RootView.h"
#import "MpvController.h"
#import "AppDelegate.h"

@implementation RootView

-(BOOL) acceptsFirstMouse:(NSEvent *)event { return YES; }
-(BOOL) acceptsFirstResponder { return YES; }

-(void) awakeFromNib {
    [self setWantsLayer:YES];
    
    self.autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:3.f
                                                 target:self
                                               selector:@selector(autoHideHUD)
                                               userInfo:nil
                                                repeats:YES];

}

-(void) keyDown:(NSEvent *)event
{
    NSLog(@"keydown: %@", event);
    AppDelegate* delegate = [[NSApplication sharedApplication] delegate];
    
    switch(event.keyCode) {
        // Space
        case 49:
            [[MpvController getInstance] togglePause];
            break;
        // Left arrow
        case 123:
            if([event modifierFlags] & NSShiftKeyMask) {
                [[MpvController getInstance] seek:-10];
            }
            else if([event modifierFlags] & NSCommandKeyMask) {
                [delegate playPrev];
            }
            else {
                [[MpvController getInstance] seek:-1];
            }
            break;
        // Right arrow
        case 124:
            if([event modifierFlags] & NSShiftKeyMask) {
                [[MpvController getInstance] seek:10];
            }
            else if([event modifierFlags] & NSCommandKeyMask) {
                [delegate playNext];
            }
            else {
                [[MpvController getInstance] seek:1];
            }
            
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
        // z
        case 6:
            [[MpvController getInstance] subDelay:-0.1f];
            break;
        // x
        case 7:
            [[MpvController getInstance] subDelay:0.1f];
            break;
        // Esc
        case 53:
            if([self isFullscreen]) {
                [self.window toggleFullScreen:self];
            }
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

-(void)mouseMoved:(NSEvent *)theEvent
{
    if(NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], self.bounds)) {
        // Prevent auto hide
        self.shouldHide = NO;
        [self showHUD];

    }
}

-(BOOL) isFullscreen {
    return (([self.window styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask);
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


#pragma mark -
#pragma mark Auto Hide

-(void) autoHideHUD {
    // Hide
    if(![self isFullscreen]) {
        return;
    }
    
    if(self.shouldHide) {
        [self hideHUD];
    }

    self.shouldHide = YES;
}

-(void) hideHUD {
    if(!self.cursorHidden) {
        [NSCursor hide];
        self.cursorHidden = YES;
    }
}

-(void) showHUD {
    self.shouldHide = NO;
    
    if(self.cursorHidden) {
        [NSCursor unhide];
        self.cursorHidden = NO;
        
    }
}


@end
