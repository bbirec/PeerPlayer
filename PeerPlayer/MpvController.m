//
//  MpvController.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "MpvController.h"

#import "AppDelegate.h"

#import "MpvEvent.h"

static inline void check_error(int status)
{
    if (status < 0) {
        printf("mpv API error: %s\n", mpv_error_string(status));
        exit(1);
    }
}

static void *get_proc_address(void *ctx, const char *name)
{
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
    void *addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengl")), symbolName);
    CFRelease(symbolName);
    return addr;
}

static void glupdate(void *ctx)
{
    MpvClientOGLView *glView = (__bridge MpvClientOGLView *)ctx;
    // I'm still not sure what the best way to handle this is, but this
    // works.
    dispatch_async(dispatch_get_main_queue(), ^{
        [glView drawRect];
    });
}


#pragma mark Info

@implementation PlayInfo

@end


#pragma mark MpvWindow

@implementation MpvWindow
- (BOOL)canBecomeMainWindow { return YES; }

- (BOOL)canBecomeKeyWindow { return YES; }

- (void)initOGLView {
    NSRect bounds = [[self contentView] bounds];
    // window coordinate origin is bottom left
    NSRect glFrame = NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    self.glView = [[MpvClientOGLView alloc] initWithFrame:glFrame];
    [self.contentView addSubview:self.glView positioned:NSWindowBelow relativeTo:nil];
    
    // Accept the ouse move event to hide mouse cursor automatically
    [self setAcceptsMouseMovedEvents:YES];
}

-(void) setVideoSize:(NSSize) size {
    self.contentAspectRatio = size;
    
    // Bound to visible screen frame
    NSRect screenRect = [self.screen visibleFrame];
    NSSize screenSize = screenRect.size;
    
    float scale = MIN(screenSize.width/size.width, screenSize.height/size.height);
    
    size.width *= scale;
    size.height *= scale;
    
    float originX = self.frame.origin.x + (self.frame.size.width - size.width) / 2;
    float originY = self.frame.origin.y + (self.frame.size.height - size.height) / 2;
    
    NSRect windowFrame = CGRectMake(MAX(originX, screenRect.origin.x),
                                    MAX(originY, screenRect.origin.y),
                                    size.width, size.height);
    
    [self setFrame:windowFrame display:YES animate:YES];
}

-(void) clearVideoSize {
    self.resizeIncrements = NSMakeSize(1.0, 1.0);
    
    // Restore to the default window size
    NSSize size = NSMakeSize(640, 480);
    NSRect frame = self.frame;
    
    float originX = frame.origin.x + (frame.size.width - size.width) / 2;
    float originY = frame.origin.y + (frame.size.height - size.height) / 2;
    
    
    [self setFrame:NSMakeRect(originX, originY, size.width, size.height)
           display:YES
           animate:YES];
}

@end


#pragma mark MpvController

static MpvController* _mpv;

@interface MpvController(private)
- (void) readEvents;
@end

@implementation MpvController

static void wakeup(void *context) {
    MpvController *a = (__bridge MpvController *) context;
    [a readEvents];
}

-(id) initWithWindow:(MpvWindow*) window {
    if (self = [super init]) {
        self.window = window;
        self.info = [[PlayInfo alloc] init];
        
        mpv = mpv_create();
        if (!mpv) {
            printf("failed creating context\n");
            exit(1);
        }
        
        check_error(mpv_set_option_string(mpv, "input-media-keys", "yes"));
        // request important errors
        check_error(mpv_request_log_messages(mpv, "warn"));
        
        check_error(mpv_initialize(mpv));
        check_error(mpv_set_option_string(mpv, "vo", "opengl-cb"));
        mpv_opengl_cb_context *mpvGL = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
        if (!mpvGL) {
            puts("libmpv does not have the opengl-cb sub-API.");
            exit(1);
        }
        
        // pass the mpvGL context to our view
        window.glView.mpvGL = mpvGL;
        int r = mpv_opengl_cb_init_gl(mpvGL, NULL, get_proc_address, NULL);
        if (r < 0) {
            puts("gl init has failed.");
            exit(1);
        }
        mpv_opengl_cb_set_update_callback(mpvGL, glupdate, (__bridge void *)window.glView);
        
        // observe events
        mpv_observe_property(mpv, 0, "duration", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "demuxer-cache-duration", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG);
        mpv_observe_property(mpv, 0, "volume", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 0, "track-list", MPV_FORMAT_NODE);
        mpv_observe_property(mpv, 0, "video-params", MPV_FORMAT_NODE);
        mpv_observe_property(mpv, 0, "sub-delay", MPV_FORMAT_DOUBLE);
        
        // Deal with MPV in the background.
        queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
        
        dispatch_async(queue, ^{
            // Register to be woken up whenever mpv generates new events.
            mpv_set_wakeup_callback(mpv, wakeup, (__bridge void *) self);
        });
        
        
        // Set as singleton object
        _mpv = self;
    }
    return self;

}

+(MpvController*) getInstance {
    NSAssert(_mpv != nil, @"Mpv is not initialized.");
    return _mpv;
}

-(void) playWithUrl:(NSString*) url {
    NSLog(@"play url: %@", url);
    // Deal with MPV in the background.
    dispatch_async(queue, ^{
        // Load the indicated file
        const char *cmd[] = {"loadfile", url.UTF8String, NULL};
        check_error(mpv_command(mpv, cmd));
        
        int pause = 0;
        mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, (void*)&pause);
    });
}

-(void) stop {
    dispatch_async(queue, ^{
        const char *cmd[] = {"stop", NULL};
        check_error(mpv_command(mpv, cmd));
    });
}

-(void) togglePause {
    dispatch_async(queue, ^{
        int pause;
        mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &pause);
        pause = !pause;
        mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, (void*)&pause);
    });
}

-(void) seek:(int)seconds {
    if(self.info.startFile && self.info.loadFile) {
        dispatch_async(queue, ^{
            // Load the indicated file
            const char* sec = [[NSString stringWithFormat:@"%d", seconds] UTF8String];
            const char *cmd[] = {"seek", sec, NULL};
            check_error(mpv_command(mpv, cmd));
        });
    }
    
}

-(void) volume:(double) vol {
    dispatch_async(queue, ^{
        double v;
        mpv_get_property(mpv, "volume", MPV_FORMAT_DOUBLE, &v);
        v += vol;
        mpv_set_property(mpv, "volume", MPV_FORMAT_DOUBLE, (void*)&v);
    });
}

-(void) loadSubtitle:(NSString*)filepath {
    dispatch_async(queue, ^{
        // Set subtitle
        const char *cmd[] = {"sub-add", filepath.UTF8String, "select", NULL};
        check_error(mpv_command(mpv, cmd));
    });
}

-(void) subDelay:(double)delay {
    dispatch_async(queue, ^{
        double d;
        mpv_get_property(mpv, "sub-delay", MPV_FORMAT_DOUBLE, &d);
        d += delay;
        mpv_set_property(mpv, "sub-delay", MPV_FORMAT_DOUBLE, (void*)&d);
    });
}

-(void) rotate {
    dispatch_async(queue, ^{
        int a;
        mpv_get_property(mpv, "video-rotate", MPV_FORMAT_INT64, &a);
        a += 90;
        a = a % 360;
        mpv_set_property(mpv, "video-rotate", MPV_FORMAT_INT64, (void*)&a);
    });
}

-(void) quit {
    mpv_opengl_cb_uninit_gl(self.window.glView.mpvGL);
    [self.window.glView clearGLContext];
    
    dispatch_async(queue, ^{
        const char *cmd[] = {"quit", NULL};
        check_error(mpv_command(mpv, cmd));
    });
}

-(void) _playInfoChanged {
    [self.delegate playInfoChanged:self.info];
}

-(void) playInfoChanged {
    [self performSelectorOnMainThread:@selector(_playInfoChanged) withObject:nil waitUntilDone:NO];
}

-(void) gotVideoParam:(NSDictionary*) videoParam {
    NSNumber* w = [videoParam objectForKey:@"w"];
    NSNumber* h = [videoParam objectForKey:@"h"];
    if(w != nil && h != nil) {
        NSLog(@"Video: w=%@, h=%@", w, h);
        [self.window setVideoSize:NSMakeSize([w doubleValue], [h doubleValue])];
    }
    else {
        [self.window clearVideoSize];
    }
}

-(void) gotTrackList:(NSArray*) trackList {
    NSLog(@"Track list: %@", trackList);
}

// Update the play info
// This function may be called from mpv thread, so the functions manipulating UI functions should be performed on the main thread.
-(void) updateInfo:(mpv_event_property*) prop {
    if (strcmp(prop->name, "time-pos") == 0) {
        self.info.timePos = [[MpvEvent convertProperty:prop] doubleValue];
        [self playInfoChanged];
        
    }
    else if (strcmp(prop->name, "duration") == 0) {
        self.info.duration = [[MpvEvent convertProperty:prop] doubleValue];
        [self playInfoChanged];
    }
    else if(strcmp(prop->name, "pause") == 0) {
        self.info.paused = [[MpvEvent convertProperty:prop] intValue];
        [self playInfoChanged];
    }
    else if(strcmp(prop->name, "demuxer-cache-duration") == 0) {
        self.info.cacheDuration = [[MpvEvent convertProperty:prop] doubleValue];
        [self playInfoChanged];
    }
    else if(strcmp(prop->name, "volume") == 0) {
        self.info.volume = [[MpvEvent convertProperty:prop] doubleValue];
        [self playInfoChanged];
    }
    else if(strcmp(prop->name, "track-list") == 0) {
        NSArray* data = [MpvEvent convertProperty:prop];
        [self performSelectorOnMainThread:@selector(gotTrackList:) withObject:data waitUntilDone:NO];
    }
    else if(strcmp(prop->name, "video-params") == 0) {
        NSDictionary* data = [MpvEvent convertProperty:prop];
        [self performSelectorOnMainThread:@selector(gotVideoParam:) withObject:data waitUntilDone:NO];
    }
    else if(strcmp(prop->name, "sub-delay") == 0) {
        self.info.subDelay = [[MpvEvent convertProperty:prop] doubleValue];
        [self playInfoChanged];
    }
    

}

- (void) readEvents
{
    dispatch_async(queue, ^{
        while (mpv) {
            mpv_event *event = mpv_wait_event(mpv, 0);
            if (event->event_id == MPV_EVENT_NONE)
                break;

            switch (event->event_id) {
                case MPV_EVENT_SHUTDOWN: {
                    mpv_detach_destroy(mpv);
                    mpv = NULL;
                    printf("event: shutdown\n");
                    break;
                }
                case MPV_EVENT_PROPERTY_CHANGE: {
                    mpv_event_property *prop = (mpv_event_property *)event->data;
                    [self updateInfo:prop];
                    break;
                }
                case MPV_EVENT_LOG_MESSAGE: {
                    struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
                    printf("[%s] %s: %s", msg->prefix, msg->level, msg->text);
                    break;
                }
                case MPV_EVENT_START_FILE: {
                    printf("event: %s\n", mpv_event_name(event->event_id));
                    self.info.startFile = YES;
                    self.info.loadFile = NO;
                    [self playInfoChanged];
                    
                    
                    // Disable power management
                    [self disablePowerManagement];
                    break;
                }
                case MPV_EVENT_END_FILE: {
                    printf("event: %s\n", mpv_event_name(event->event_id));
                    self.info.startFile = NO;
                    self.info.loadFile = NO;
                    [self playInfoChanged];
                    
                    mpv_event_end_file* ef = (mpv_event_end_file*)event->data;
                    switch(ef->reason){
                        case MPV_END_FILE_REASON_EOF:
                            [self.delegate playEnded:kPlayEndEOF];
                            break;
                        case MPV_END_FILE_REASON_STOP:
                            [self.delegate playEnded:kPlayEndStop];
                            break;
                        case MPV_END_FILE_REASON_QUIT:
                            [self.delegate playEnded:kPlayEndQuit];
                            break;
                        case MPV_END_FILE_REASON_ERROR:
                            [self.delegate playEnded:kPlayEndError];
                            break;
                        default:
                            [self.delegate playEnded:kPlayEndUnknown];
                            break;
                    }
                    
                    // Enable power management
                    [self enablePowerManagement];
                    break;
                }
                case MPV_EVENT_FILE_LOADED: {
                    printf("event: %s\n", mpv_event_name(event->event_id));
                    self.info.loadFile = YES;
                    [self playInfoChanged];
                    
                    [self.delegate playStarted];
                    break;
                }
                    
                default:{
                    //printf("event: %s\n", mpv_event_name(event->event_id));
                }
            }
        }
    });
}

#pragma mark Power Management

-(void) enablePowerManagement {
    if (nonSleepHandler != kIOPMNullAssertionID) {
        IOPMAssertionRelease(nonSleepHandler);
        nonSleepHandler = kIOPMNullAssertionID;
    }	

}

-(void) disablePowerManagement {
    if(nonSleepHandler == kIOPMNullAssertionID) {
        IOReturn err = IOPMAssertionCreateWithName(
                                    kIOPMAssertPreventUserIdleDisplaySleep,
                                    kIOPMAssertionLevelOn,
                                    (__bridge CFStringRef)@"PeerPlayer is playing.",
                                    &nonSleepHandler);
        if(err != kIOReturnSuccess) {
            NSLog(@"Can't disable powersave");
        }
    }
    
}


@end
