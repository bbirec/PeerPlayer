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



- (void)launchPeerflix:(NSString*)torrentFile {
    NSString* execPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"go-peerflix"];
    NSLog(@"%@", execPath);
    
    task = [[NSTask alloc] init];
    NSPipe* outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setLaunchPath:execPath];
    [task setArguments:	[NSArray arrayWithObjects:torrentFile, nil]];
    
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
        // JSON data is malformed.
        return NO;
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *results = object;
        
        // Start player if it's ready to play.
        if([results objectForKey:@"Ready"] && self->mpv == nil) {
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
            
            int port = [[results objectForKey:@"Port"] intValue];
            
            if(targetHash != nil) {
                NSString* url = [NSString stringWithFormat:@"http://localhost:%d/?hash=%@", port, targetHash];
                NSLog(@"url: %@", url);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self startPlayerWithUrl:url];
                });
                return YES;

                
            }
            else {
                // TODO:
                NSLog(@"Not found any file to play");
                return NO;
            }
            
        }
        else {
            return NO;
        }
    }
    else
    {
        // JSON data is malformed.
        return NO;
    }
    
}


- (void)readCompleted:(NSNotification *)notification {
    NSLog(@"Read data: %@", [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem]);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
}

-(void) startPlayerWithUrl:(NSString*) url {
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
        
        // Load the indicated file
        const char *cmd[] = {"loadfile", url.UTF8String, NULL};
        check_error(mpv_command(mpv, cmd));
    });
}

-(void) initSubscription {
    // Subscribe the publish from peerflix
    ctx = [[ZMQContext alloc] initWithIOThreads:1];
    
    NSString *endpoint = @"tcp://localhost:5556";
    ZMQSocket *subscriber = [ctx socketWithType:ZMQ_SUB];
    BOOL didConnect = [subscriber connectToEndpoint:endpoint];
    if (!didConnect) {
        NSLog(@"*** Failed to connect to endpoint [%@].", endpoint);
        return;
    }
    
    [subscriber subscribeAll];
    
    for(;;) {
        NSData* data = [subscriber receiveDataWithFlags:0];
        NSLog(@"Read data from peerflix");
        [self performWithPeerData:data];
        sleep(1);
    }
    
}

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
    
    // Subscribe the message from peerflix
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(initSubscription) object:nil];
    [thread start];
    
    // Launch the peerflix
    [self launchPeerflix:@"/Users/bbirec/tmp/es.torrent"];

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


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if(mpv){
        const char *args[] = {"quit", NULL};
        mpv_command(mpv, args);
    }
    
    if(ctx) {
        [ctx closeSockets];
        [ctx terminate];
    }

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end


static void wakeup(void *context) {
    AppDelegate *a = (__bridge AppDelegate *) context;
    [a readEvents];
}

