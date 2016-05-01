//
//  MpvClientOGLView.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 3. 25..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mpv/opengl_cb.h>

@interface MpvClientOGLView : NSOpenGLView<NSDraggingDestination>
@property mpv_opengl_cb_context *mpvGL;
- (instancetype)initWithFrame:(NSRect)frame;
- (void) drawRect;
@end
