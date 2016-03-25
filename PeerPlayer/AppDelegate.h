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
#import "Playlist.h"

// Player
#define kPPPlayInfoKey @"info"
#define kPPPlayInfoChanged @"PPPlayInfoChanged"

// Torrent
#define kPPTorrentStatusChanged @"PPTorrentStatusChanged"

@interface AppDelegate : NSObject <NSApplicationDelegate, PeerflixDelegate, PlayerDelegate>

@property BOOL initialized;

@property (weak) IBOutlet MpvWindow *window;
@property (weak) IBOutlet NSMenu* mediaMenu;
@property (weak) IBOutlet NSMenu* subtitleMenu;

@property (strong) Peerflix* peerflix;
@property (strong) MpvController* mpv;

// Hold the files of current torrent.
@property (strong) Playlist* playlist;
@property (strong) File* selectedMedia;
@property (strong) File* selectedSubtitle;

-(void) playTorrent:(NSString*)url;
-(IBAction) openTorrentFile:(id)sender;
-(IBAction) stopCurrentVideo:(id)sender;
@end

