//
//  ControlUI.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 13..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface ControlUI : NSObject

@property (strong) PlayInfo* playInfo;
@property (strong) NSDictionary* torrentStatus;

@property (weak) IBOutlet NSTextField* osd;
@property (weak) IBOutlet NSTextField* centerMsg;

@end
