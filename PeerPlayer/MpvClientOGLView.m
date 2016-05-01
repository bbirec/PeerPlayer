//
//  MpvClientOGLView.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 3. 25..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "MpvClientOGLView.h"
#import "AppDelegate.h"



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
    if ([types containsObject:NSURLPboardType] || [types containsObject:NSFilenamesPboardType])
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    AppDelegate* delegate = [[NSApplication sharedApplication] delegate];
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSLog(@"drag operation: %@", [pboard types]);
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSURL* u = [NSURL URLFromPasteboard:pboard];
        NSString* url = [u absoluteString];
        
        if([u isFileURL]) {
            NSString* filepath = u.path;
            
            NSString* ext = [filepath pathExtension];
            if([ext isEqualToString:@"torrent"]) {
                [delegate playTorrent:filepath];
                return YES;
            }
            else if([MpvController getInstance].info.loadFile &&
                    ([ext isEqualToString:@"smi"] || [ext isEqualToString:@"srt"])) {
                NSLog(@"Load subtitle: %@", filepath);
                [[MpvController getInstance] loadSubtitle:filepath];
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



