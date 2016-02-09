//
//  AppDelegate.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 7..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MpvController.h"

#import "Peerflix.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, PeerflixDelegate>

@property (strong) NSWindow *window;

@property (strong) Peerflix* peerflix;
@property (strong) MpvController* mpv;

-(void) playTorrent:(NSString*)url;
-(IBAction) openTorrentFile:(id)sender;

@end

