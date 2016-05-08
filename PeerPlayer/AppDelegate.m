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
    // Make sure that downloading the torrent after intializing
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mpv stop];
        self.playlist = nil;
        [self.peerflix downloadTorrent:url];
    });
    
}

-(void) playFile:(File*) file {
    NSString* url = [self.peerflix streamUrlFromHash:file.fileHash];
    NSLog(@"URL: %@", url);
    [self.mpv playWithUrl:url];
    self.selectedMedia = file;
    self.selectedSubtitle = nil;
    [self updateMenuState];
}

-(void) loadSubtitle:(File*) file {
    if(!self.mpv.info.loadFile) {
        NSLog(@"Skip this subtitle. No playback is playing.");
        return;
    }
    
    // Load subtitle asynchronously
    NSURLSession * session = [NSURLSession sharedSession];
    
    NSURL* url = [NSURL URLWithString:[self.peerflix streamUrlFromHash:file.fileHash]];
    NSLog(@"Subtitle url: %@", url);
    
    NSURLSessionDataTask * dataTask =
    [session dataTaskWithURL:url
           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         if(error != nil) {
             NSLog(@"Failed to load subtitle: %@", error);
         }
         else {
             NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
             NSLog(@"Temporary subtitle path: %@", path);
             if([data writeToFile:path atomically:YES]) {
                 [self.mpv loadSubtitle:path];
                 self.selectedSubtitle = file;
                 [self updateMenuState];
             }
             else {
                 NSLog(@"Failed to save subtitle: %@", error);
             }
         }
     }];
    
    [dataTask resume];
}

-(BOOL) hasPrev {
    return [self.playlist getPrevMedia:self.selectedMedia] != nil;
}

-(BOOL) hasNext {
    return [self.playlist getNextMedia:self.selectedMedia] != nil;
}


-(void) playPrev {
    File* next = [self.playlist getPrevMedia:self.selectedMedia];
    if(next != nil) {
        [self playFile:next];
    }
}

-(void) playNext {
    File* next = [self.playlist getNextMedia:self.selectedMedia];
    if(next != nil) {
        [self playFile:next];
    }
}

#pragma Menu

-(void) updateMenu {
    [self.mediaMenu removeAllItems];
    
    for(File* f in self.playlist.mediaFiles) {
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:f.fileName
                                                      action:@selector(mediaMenuItemAction:)
                                               keyEquivalent:@""];
        item.representedObject = f;
        [self.mediaMenu addItem:item];
    }

    for(File* f in self.playlist.subFiles) {
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:f.fileName
                                                      action:@selector(subtitleMenuItemAction:)
                                               keyEquivalent:@""];
        item.representedObject = f;
        [self.subtitleMenu addItem:item];
    }
}

-(void) updateMenuState {
    for(NSMenuItem* item in self.mediaMenu.itemArray) {
        File* f = item.representedObject;
        if([f.fileHash isEqualToString:self.selectedMedia.fileHash]) {
            [item setState:NSOnState];
        }
        else {
            [item setState:NSOffState];
        }
    }
    
    
    for(NSMenuItem* item in self.subtitleMenu.itemArray) {
        File* f = item.representedObject;
        if([f.fileHash isEqualToString:self.selectedSubtitle.fileHash]) {
            [item setState:NSOnState];
        }
        else {
            [item setState:NSOffState];
        }
    }
}

-(void) mediaMenuItemAction:(id) sender {
    File* f = [sender representedObject];
    [self playFile:f];
}

-(void) subtitleMenuItemAction:(id) sender {
    File* f = [sender representedObject];
    [self loadSubtitle:f];
}

#pragma mark Peerflix Delegate


-(void) torrentReady:(NSDictionary*)data {
    NSArray* files = [data objectForKey:@"Files"];
    
    NSMutableArray<File*>* fileArr = [NSMutableArray array];
    for(NSDictionary* dict in files) {
        File* f = [[File alloc] init];
        f.fileName = [dict objectForKey:@"Filename"];
        f.fileHash = [dict objectForKey:@"Hash"];
        f.fileSize = [[dict objectForKey:@"Size"] longValue];
        
        [fileArr addObject:f];
    }
    
    
    self.playlist = [Playlist playListFromFiles:fileArr];
    [self updateMenu];
    
    // Start the first media in the playlist.
    File* f = [self.playlist getFirstMedia];
    if(f != nil) {
        [self playFile:f];
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

-(void) playStarted {
    NSLog(@"Play started");
    
    File* f = [self.playlist getSubtitleForMedia:self.selectedMedia];
    if(f != nil) {
        [self loadSubtitle:f];
    }
}

-(void) playEnded:(PlayEndReason)reason {
    NSLog(@"Play ended : %ld", reason);
    if(reason == kPlayEndEOF) {
        // Play the next media automatically.
        [self playNext];
    }
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
    [self updateMenu];
    
    // Register magnet link if possible
    if(![self registerMagnet]){
        NSLog(@"Failed to associate the magnet url scheme as default.");
    }
    
    // Initialize Mpv Controller.
    self.mpv = [[MpvController alloc] initWithWindow:self.window];
    self.mpv.delegate = self;
    
    // Avoid main thread blocking
    dispatch_async(dispatch_get_main_queue(), ^{
        // Initialize Peerflix
        self.peerflix = [[Peerflix alloc] init];
        self.peerflix.delegate = self;
        [self.peerflix initialize];
    });
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
    self.selectedMedia = nil;
    self.selectedSubtitle = nil;
    [self updateMenuState];
}

-(IBAction) stepForward:(id)sender {
    [self.mpv seek:10];
}

-(IBAction) stepBackward:(id)sender {
    [self.mpv seek:-10];
}

-(IBAction) jumpForward:(id)sender {
    [[MpvController getInstance] seek:60];
}

-(IBAction) jumpBackward:(id)sender {
    [[MpvController getInstance] seek:-60];
}

-(IBAction) prevMedia:(id)sender {
    [self playPrev];
}

-(IBAction) nextMedia:(id)sender {
    [self playNext];
}

-(IBAction) subDelayUp:(id)sender {
    [self.mpv subDelay:0.1f];
}

-(IBAction) subDelayDown:(id)sender {
    [self.mpv subDelay:-0.1f];
}

-(IBAction) volumeUp:(id)sender {
    [self.mpv volume:10.f];
}

-(IBAction) volumeDown:(id)sender {
    [self.mpv volume:-10.f];
}

@end
