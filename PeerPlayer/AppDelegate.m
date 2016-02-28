//
//  AppDelegate.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 7..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

-(void) playTorrent:(NSString*) url {
    [self.mpv stop];
    self.currentFiles = nil;
    [self.peerflix downloadTorrent:url];
}

-(void) updateTorrentMenu {
    [self.torrentMenu removeAllItems];
    NSArray* files = [self.currentFiles objectForKey:@"Files"];
    for(NSDictionary* dict in files) {
        NSString* filename = [dict objectForKey:@"Filename"];
        
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:filename
                                                      action:@selector(torrentMenuItemAction:)
                                               keyEquivalent:@""];
        item.representedObject = dict;
        [self.torrentMenu addItem:item];
    }
}

#pragma mark Peerflix Delegate


-(void) torrentReady:(NSDictionary*)data {
    self.currentFiles = data;
    [self updateTorrentMenu];
    
    // Default action is playing the largest file.
    NSInteger maxSize = 0;
    NSString* targetHash;
    NSString* filename;
    NSArray* files = [data objectForKey:@"Files"];
    for(NSDictionary* dict in files) {
        NSInteger s = [[dict objectForKey:@"Size"] longValue];
        if(maxSize < s) {
            maxSize = s;
            targetHash = [dict objectForKey:@"Hash"];
            filename = [dict objectForKey:@"Filename"];
        }
    }
    
    NSLog(@"Largest Filename: %@", filename);
    
    if(targetHash != nil) {
        NSString* url = [self.peerflix streamUrlFromHash:targetHash];
        NSLog(@"URL: %@", url);
        [self.mpv playWithUrl:url];
    }
    else {
        NSLog(@"Nothing to play");
    }
}


-(void) torrentStatusChanged:(NSDictionary*) info {
    [[NSNotificationCenter defaultCenter] postNotificationName:kPPTorrentStatusChanged
                                                        object:self
                                                      userInfo:info];
}


#pragma mark Player Delegate

-(void) playInfoChanged:(PlayInfo *)info {
    [[NSNotificationCenter defaultCenter] postNotificationName:kPPPlayInfoChanged
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:info forKey:kPPPlayInfoKey]];

}

#pragma mark App Delegate

-(void) createWindow {
    // Style the window and prepare for mpv player.
    int mask = NSTitledWindowMask|NSClosableWindowMask|
    NSMiniaturizableWindowMask|NSResizableWindowMask|
    NSFullSizeContentViewWindowMask|NSUnifiedTitleAndToolbarWindowMask;
    
    [self.window setStyleMask:mask];
    [self.window setMinSize:NSMakeSize(200, 200)];
    [self.window initOGLView];
    [self.window setStyleMask:mask];
    [self.window setBackgroundColor:
     [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1.f]];
    [self.window makeMainWindow];
    [self.window makeKeyAndOrderFront:nil];
    [self.window setMovableByWindowBackground:YES];
    [self.window setTitlebarAppearsTransparent:YES];
    [self.window setTitleVisibility:NSWindowTitleHidden];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    
    [NSApp activateIgnoringOtherApps:YES];
}

-(void) initApp {
    if(self.initialized) {
        return;
    }
    self.initialized = YES;
    
    NSLog(@"Init PeerPlayer");
    
    // Init main window
    [self createWindow];
    
    // Initialize Mpv Controller.
    self.mpv = [[MpvController alloc] initWithWindow:self.window];
    self.mpv.delegate = self;
    
    // Initialize Peerflix
    self.peerflix = [[Peerflix alloc] init];
    self.peerflix.delegate = self;
    [self.peerflix initialize];
    
    [self updateTorrentMenu];
    
    // Register magnet link
    if(![self registerMagnet]){
        NSLog(@"Failed to associate the magnet url scheme as default.");
    }
    
}

-(BOOL) registerMagnet {
    // Register magnet scheme as default
    CFStringRef bundleID = (__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier];
    OSStatus ret = LSSetDefaultHandlerForURLScheme(CFSTR("magnet"), bundleID);
    return ret == noErr;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(handleURLEvent:withReplyEvent:)
     forEventClass:kInternetEventClass
     andEventID:kAEGetURL];
    
    [self initApp];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject]
                     stringValue];
    NSLog(@"handle URL: %@", url);
    [self initApp];
    [self playTorrent:url];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSLog(@"new file load: %@", filename);
    [self initApp];
    [self playTorrent:filename];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.mpv quit];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


#pragma mark IBActions


-(void) torrentMenuItemAction:(id) sender {
    NSDictionary* dict = [sender representedObject];
    NSString* hash = [dict objectForKey:@"Hash"];
    NSString* filename = [dict objectForKey:@"Filename"];
    NSLog(@"Selected hash: %@", hash);
    
    NSString* ext = [filename pathExtension];
    if(self.mpv.info.loadFile && ([ext isEqualToString:@"smi"] || [ext isEqualToString:@"srt"])) {
        // Load subtitle
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self.peerflix streamUrlFromHash:hash]]];
        
        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:filename]];
        [data writeToURL:fileURL atomically:YES];
        
        [self.mpv loadSubtitle:fileURL.path];

    }
    else {
        // Play file
        [self.mpv playWithUrl:[self.peerflix streamUrlFromHash:hash]];
    }
    
}


-(IBAction) openTorrentFile:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setResolvesAliases:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setTitle:@"Open Torrent File"];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        NSString *fileUrl = [[[openPanel URLs] objectAtIndex:0] path];
        NSLog(@"file selected: %@", fileUrl);
        [self playTorrent:fileUrl];
    }

}

-(IBAction) stopCurrentVideo:(id)sender {
    [self.mpv stop];
}

@end
