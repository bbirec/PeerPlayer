//
//  MpvController.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "MpvController.h"

static inline void check_error(int status)
{
    if (status < 0) {
        printf("mpv API error: %s\n", mpv_error_string(status));
        exit(1);
    }
}

@interface MpvController(private)
- (void) readEvents;
@end

@implementation MpvController

static void wakeup(void *context) {
    MpvController *a = (__bridge MpvController *) context;
    [a readEvents];
}

-(id) initWithView:(NSView*) wrapper {
    if (self = [super init]) {
        self.wrapper = wrapper;
        
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
            
        case MPV_EVENT_VIDEO_RECONFIG: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *subviews = [self.wrapper subviews];
                if ([subviews count] > 0) {
                    // mpv's events view
                    NSView *eview = [self.wrapper subviews][0];
                    NSWindow* window = [[NSApplication sharedApplication] mainWindow];
                    [window makeFirstResponder:eview];
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

@end
