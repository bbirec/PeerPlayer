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

// Player
#define kPPPlayInfoKey @"info"
#define kPPPlayInfoChanged @"PPPlayInfoChanged"

// Torrent
#define kPPTorrentStatusChanged @"PPTorrentStatusChanged"

@interface AppDelegate : NSObject <NSApplicationDelegate, PeerflixDelegate, PlayerDelegate>

@property (weak) IBOutlet CocoaWindow *window;
@property (weak) IBOutlet NSMenu* torrentMenu;

@property (strong) Peerflix* peerflix;
@property (strong) MpvController* mpv;

// Hold the files of current torrent.
@property (strong) NSDictionary* currentFiles;

-(void) playTorrent:(NSString*)url;
-(IBAction) openTorrentFile:(id)sender;
-(IBAction) stopCurrentVideo:(id)sender;
@end

