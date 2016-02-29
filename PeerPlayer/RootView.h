//
//  RootView.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 13..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ControlUI.h"

@interface RootView : NSView

@property (strong) NSTimer* autoHideTimer;

@property BOOL cursorHidden;
@property BOOL shouldHide;


@end
