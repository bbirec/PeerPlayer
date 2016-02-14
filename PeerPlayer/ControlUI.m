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
        
        [noti addObserver:self
                 selector:@selector(torrentStatusChanged:)
                     name:kPPTorrentStatusChanged object:nil];
    }
    return self;
}

-(void) awakeFromNib {
    [self initCenterMsg];
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

-(void) updateUI {
    if(self.playInfo.loadFile) {
        self.osd.hidden = NO;
        self.centerMsg.hidden = YES;
        
        [self.osd setStringValue:
         [NSString stringWithFormat:@"%@ %@/%@",
          self.playInfo.paused ? @"Paused":@"Playing",
          [ControlUI formatTime:self.playInfo.timePos],
          [ControlUI formatTime:self.playInfo.duration]]];
    }
    else {
        self.osd.hidden = YES;
        self.centerMsg.hidden = NO;
        
        if(self.torrentStatus && ![[self.torrentStatus objectForKey:@"Ready"] boolValue]) {
            self.centerMsg.stringValue = @"Loading magnet link..";
        }
        else if(self.playInfo.startFile) {
            self.centerMsg.stringValue = @"Starting video..";
        }
    }
    

}

-(void) playInfoChanged:(NSNotification*)notification {
    PlayInfo* info = [notification.userInfo objectForKey:kPPPlayInfoKey];
    NSAssert(info != nil, @"Play info is nil");
    
    self.playInfo = info;
    [self updateUI];
}

-(void) torrentStatusChanged:(NSNotification*) notification {
    self.torrentStatus = notification.userInfo;
    [self updateUI];
}

#pragma mark Center msg

-(void) initCenterMsg {
    self.centerMsg.stringValue = @"Drop .torrent file";
}


@end
