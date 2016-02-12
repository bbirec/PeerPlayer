//
//  ControlUI.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 13..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "ControlUI.h"
#import "MpvController.h"

@implementation ControlUI

-(id) init {
    if(self = [super init]) {
        NSNotificationCenter* noti = [NSNotificationCenter defaultCenter];
        [noti addObserver:self
                 selector:@selector(playInfoChanged:)
                     name:kPPPlayInfoChanged object:nil];
    }
    return self;
}

+(NSString*) formatTime:(NSInteger)time {
    NSInteger hour, minute, sec;
    NSString *formatString;
    
    if (time < 0) {
        time = -time;
        formatString = @"-%02d:%02d:%02d";
    } else {
        formatString = @"%02d:%02d:%02d";
    }
    
    sec = time % 60;
    time = (time - sec) / 60;
    
    minute = time % 60;
    hour = (time - minute) / 60;
    
    return [NSString stringWithFormat:formatString, hour, minute, sec];
}

-(void) playInfoChanged:(NSNotification*)notification {
    PlayInfo* info = [notification.userInfo objectForKey:kPPPlayInfoKey];
    NSAssert(info != nil, @"Play info is nil");
    [self.osd setStringValue:
     [NSString stringWithFormat:@"%@ %@/%@",
      info.paused ? @"정지":@"재생",
      [ControlUI formatTime:info.timePos],
      [ControlUI formatTime:info.duration]]];
}

@end
