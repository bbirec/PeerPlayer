//
//  MpvController.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "MpvController.h"

#import "AppDelegate.h"

static inline void check_error(int status)
{
    if (status < 0) {
        printf("mpv API error: %s\n", mpv_error_string(status));
        exit(1);
    }
}

#pragma mark OGLView

static void *get_proc_address(void *ctx, const char *name)
{
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
    void *addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengl")), symbolName);
    CFRelease(symbolName);
    return addr;
}

static void glupdate(void *ctx);

@implementation MpvClientOGLView
- (instancetype)initWithFrame:(NSRect)frame
{
    // make sure the pixel format is double buffered so we can use
    // [[self openGLContext] flushBuffer].
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADoubleBuffer,
        0
    };
    self = [super initWithFrame:frame
                    pixelFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes]];
    
    if (self) {
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        // swap on vsyncs
        GLint swapInt = 1;
        [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
        [[self openGLContext] makeCurrentContext];
        self.mpvGL = nil;
        
        // Drag & drop
        [self registerForDraggedTypes:@[NSFilenamesPboardType,
                                        NSURLPboardType]];
    }
    return self;
}

- (void)fillBlack
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)drawRect
{
    if (self.mpvGL){
        mpv_opengl_cb_draw(self.mpvGL, 0, self.bounds.size.width, -self.bounds.size.height);
    }
    else{
        [self fillBlack];
    }
    [[self openGLContext] flushBuffer];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self drawRect];
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *types = [pboard types];
    if ([types containsObject:NSURLPboardType])
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    AppDelegate* delegate = [[NSApplication sharedApplication] delegate];
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSString* url = [[NSURL URLFromPasteboard:pboard] absoluteString];
        // Local file
        if([url hasPrefix:@"file:///.file/id="]) {
            NSString* filepath = [[NSURL URLFromPasteboard:pboard] path];
            
            // Accept only .torrent file
            if([[filepath pathExtension] isEqualToString:@"torrent"]) {
                NSLog(@"filepath: %@", filepath);
                [delegate playTorrent:filepath];
                return YES;
            }
        }
        // Link
        else if([url hasPrefix:@"magnet://"]){
            NSLog(@"magnet: %@", url);
            [delegate playTorrent:url];
            return YES;
        }
    }
    return NO;
}

-(BOOL) mouseDownCanMoveWindow {
    return YES;
}

@end


static void glupdate(void *ctx)
{
    MpvClientOGLView *glView = (__bridge MpvClientOGLView *)ctx;
    // I'm still not sure what the best way to handle this is, but this
    // works.
    dispatch_async(dispatch_get_main_queue(), ^{
        [glView drawRect];
    });
}

#pragma mark CocoaWindow


@implementation CocoaWindow
- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (void)initOGLView {
    NSRect bounds = [[self contentView] bounds];
    // window coordinate origin is bottom left
    NSRect glFrame = NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    self.glView = [[MpvClientOGLView alloc] initWithFrame:glFrame];
    [self.contentView addSubview:self.glView];
}
@end


#pragma mark MpvController



@interface MpvController(private)
- (void) readEvents;
@end

@implementation MpvController

static void wakeup(void *context) {
    MpvController *a = (__bridge MpvController *) context;
    [a readEvents];
}

-(id) initWithWindow:(CocoaWindow*) window {
    if (self = [super init]) {
        self.window = window;
        
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
        
        // Deal with MPV in the background.
        queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
        
        dispatch_async(queue, ^{
            // Register to be woken up whenever mpv generates new events.
            mpv_set_wakeup_callback(mpv, wakeup, (__bridge void *) self);
        });
    }
    return self;

}

-(void) playWithUrl:(NSString*) url {
    NSLog(@"play url: %@", url);
    
    // Deal with MPV in the background.
    dispatch_async(queue, ^{
        // Load the indicated file
        const char *cmd[] = {"loadfile", url.UTF8String, NULL};
        check_error(mpv_command(mpv, cmd));
    });
}

-(void) stop {
    dispatch_async(queue, ^{
        const char *cmd[] = {"stop", NULL};
        check_error(mpv_command(mpv, cmd));
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

-(void) handleEvent:(mpv_event *)event
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

@end
