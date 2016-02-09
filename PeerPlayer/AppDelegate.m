//
//  AppDelegate.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 7..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "AppDelegate.h"


static inline void check_error(int status)
{
    if (status < 0) {
        printf("mpv API error: %s\n", mpv_error_string(status));
        exit(1);
    }
}


static void wakeup(void *);

@interface CocoaWindow : NSWindow
@end

@implementation CocoaWindow
- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
@end


@implementation AppDelegate

#pragma mark Peerflix

- (void)launchPeerflix {
    if(task) {
        [task terminate];
        task = nil;
    }

    
    NSString* execPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"go-peerflix"];
    NSLog(@"%@", execPath);
    
    task = [[NSTask alloc] init];
    NSPipe* outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setLaunchPath:execPath];
    [task setArguments:	[NSArray arrayWithObjects:@"-port", @"8000", nil]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(readCompleted:)
                                                 name:NSFileHandleReadToEndOfFileCompletionNotification object:[outputPipe fileHandleForReading]];
    [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    
    [task launch];
}


-(BOOL) performWithPeerData:(NSData*) returnedData {
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:returnedData
                 options:0
                 error:&error];
    
    if(error) {
        NSLog(@"JSON data is malformed.");
        return NO;
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *results = object;
        
        // Start player
        NSLog(@"Start player");
        
        // Select the largest file
        NSInteger maxSize = 0;
        NSString* targetHash;
        NSString* filename;
        NSArray* files = [results objectForKey:@"Files"];
        for(NSDictionary* dict in files) {
            NSInteger s = [[dict objectForKey:@"Size"] longValue];
            NSLog(@"size: %ld", s);
            if(maxSize < s) {
                maxSize = s;
                targetHash = [dict objectForKey:@"Hash"];
                filename = [dict objectForKey:@"Filename"];
            }
        }
        
        if(targetHash != nil) {
            NSString* url = [NSString stringWithFormat:@"http://localhost:8000/?hash=%@", targetHash];
            [self startPlayerWithUrl:url];
            return YES;
        }
        else {
            // TODO:
            NSLog(@"Not found any file to play");
            return NO;
        }
    }
    else
    {
        // JSON data is malformed.
        NSLog(@"JSON data is malformed.");
        return NO;
    }
    
}


#pragma mark WebSocket

-(void) connectWs {
    // Web socket
    NSURL* wsUrl = [NSURL URLWithString:@"http://localhost:8000/ws"];
    self.socket = [[SRWebSocket alloc] initWithURL:wsUrl];
    self.socket.delegate = self;
    [self.socket open];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [webSocket send:@"/Users/bbirec/tmp/es.torrent"];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"Got ws message:%@", message);
    [self performWithPeerData:[message dataUsingEncoding:NSUTF8StringEncoding]];
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
    //TODO : When web socket server could not start. Exponential back off?
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(connectWs)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma -
#pragma mark MPV

-(void) initPlayer {
    // Deal with MPV in the background.
    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        mpv = mpv_create();
        if (!mpv) {
            printf("failed creating context\n");
            exit(1);
        }
        
        int64_t wid = (intptr_t) self.wrapper;
        check_error(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &wid));
        
        // Maybe set some options here, like default key bindings.
        // NOTE: Interaction with the window seems to be broken for now.
        check_error(mpv_set_option_string(mpv, "input-default-bindings", "yes"));
        
        // for testing!
        check_error(mpv_set_option_string(mpv, "osc", "yes"));
        check_error(mpv_set_option_string(mpv, "input-media-keys", "yes"));
        check_error(mpv_set_option_string(mpv, "input-cursor", "yes"));
        check_error(mpv_set_option_string(mpv, "input-vo-keyboard", "yes"));
        
        // request important errors
        check_error(mpv_request_log_messages(mpv, "warn"));
        
        check_error(mpv_initialize(mpv));
        
        // Register to be woken up whenever mpv generates new events.
        mpv_set_wakeup_callback(mpv, wakeup, (__bridge void *) self);
    });
}

-(void) startPlayerWithUrl:(NSString*) url {
    NSLog(@"play url: %@", url);
    
    // Deal with MPV in the background.
    dispatch_async(queue, ^{
        // Load the indicated file
        const char *cmd[] = {"loadfile", url.UTF8String, NULL};
        check_error(mpv_command(mpv, cmd));
        
    });
}

- (void)readCompleted:(NSNotification *)notification {
    /*
     NSLog(@"Read data: %@", [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem]);*/
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
}



- (void) handleEvent:(mpv_event *)event
{
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            mpv_detach_destroy(mpv);
            mpv = NULL;
            printf("event: shutdown\n");
            break;
        }
            
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            printf("[%s] %s: %s", msg->prefix, msg->level, msg->text);
        }
            
        case MPV_EVENT_VIDEO_RECONFIG: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *subviews = [self.wrapper subviews];
                if ([subviews count] > 0) {
                    // mpv's events view
                    NSView *eview = [self.wrapper subviews][0];
                    [self.window makeFirstResponder:eview];
                }
            });
        }
            
        default:
            printf("event: %s\n", mpv_event_name(event->event_id));
    }
}


- (void) readEvents
{
    dispatch_async(queue, ^{
        while (mpv) {
            mpv_event *event = mpv_wait_event(mpv, 0);
            if (event->event_id == MPV_EVENT_NONE)
                break;
            [self handleEvent:event];
        }
    });
}

#pragma -

#pragma mark App delegate

-(void) initWindow {
    // Style the window and prepare for mpv player.
    int mask = NSTitledWindowMask|NSClosableWindowMask|
    NSMiniaturizableWindowMask|NSResizableWindowMask|
    NSFullSizeContentViewWindowMask|NSUnifiedTitleAndToolbarWindowMask;
    
    self.window = [[CocoaWindow alloc] initWithContentRect:NSMakeRect(0,0, 640, 480)
                                                 styleMask:mask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    
    [self.window setStyleMask:mask];
    [self.window setBackgroundColor:
     [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1.f]];
    [self.window makeMainWindow];
    [self.window makeKeyAndOrderFront:nil];
    [self.window setMovableByWindowBackground:YES];
    [self.window setTitlebarAppearsTransparent:YES];
    [self.window setTitleVisibility:NSWindowTitleHidden];
    
    NSRect frame = [[self.window contentView] bounds];
    self.wrapper = [[NSView alloc] initWithFrame:frame];
    [self.wrapper setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [[self.window contentView] addSubview:self.wrapper];
    
    [NSApp activateIgnoringOtherApps:YES];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Init main window
    [self initWindow];
    [self initPlayer];
    [self launchPeerflix];
    [self connectWs];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSLog(@"new file load: %@", filename);
    [self.socket send:filename];
    return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if(mpv){
        const char *args[] = {"quit", NULL};
        mpv_command(mpv, args);
    }
    
    if(thread) {
        [thread cancel];
    }
    
    if(task) {
        [task terminate];
    }
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


static void wakeup(void *context) {
    AppDelegate *a = (__bridge AppDelegate *) context;
    [a readEvents];
}

@end
