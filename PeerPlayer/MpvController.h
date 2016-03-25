//
//  MpvController.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <mpv/client.h>
#import <mpv/opengl_cb.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

@interface PlayInfo : NSObject

@property BOOL startFile;
@property BOOL loadFile;

@property double duration; // in seconds
@property double timePos; // in seconds
@property double cacheDuration; // in seconds
@property BOOL paused;
@property double volume;

@end

@interface MpvClientOGLView : NSOpenGLView<NSDraggingDestination>
@property mpv_opengl_cb_context *mpvGL;
- (instancetype)initWithFrame:(NSRect)frame;
- (void)drawRect;
- (void)fillBlack;
@end


@interface MpvWindow : NSWindow
@property(strong) MpvClientOGLView *glView;
- (void)initOGLView;
@end

typedef NS_ENUM(NSUInteger, PlayEndReason) {
    kPlayEndUnknown = 0,
    kPlayEndEOF,
    kPlayEndStop,
    kPlayEndQuit,
    kPlayEndError,
};

@protocol PlayerDelegate <NSObject>
-(void) playInfoChanged:(PlayInfo*) info;
-(void) playStarted;
-(void) playEnded:(PlayEndReason)reason;
@end



@interface MpvController : NSObject {
    mpv_handle *mpv;
    dispatch_queue_t queue;
    IOPMAssertionID nonSleepHandler;
}

@property (strong) MpvWindow* window;
@property (strong) PlayInfo* info;
@property (strong) id<PlayerDelegate> delegate;

+(MpvController*) getInstance;

-(id) initWithWindow:(MpvWindow*) window;

-(void) playWithUrl:(NSString*) url;
-(void) stop;
-(void) quit;
-(void) togglePause;
-(void) seek:(int)seconds;
-(void) volume:(double)vol;
-(void) loadSubtitle:(NSString*)filepath;

@end
