//
//  OverlayTextView.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 3. 1..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "OverlayTextView.h"

@implementation OverlayTextView

@synthesize msg = _msg;


-(void) awakeFromNib {
    self.font = [NSFont boldSystemFontOfSize:30.f];
    
    self.strokeShadow = [[NSShadow alloc] init];
    [self.strokeShadow setShadowOffset:NSMakeSize(1.0, -1.0)];
    [self.strokeShadow setShadowColor:[NSColor blackColor]];
    [self.strokeShadow setShadowBlurRadius:8];
    
    
    // Stroke text & shadow
    self.strokeAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                       self.font, NSFontAttributeName,
                       [NSNumber numberWithFloat:-15.f], NSStrokeWidthAttributeName,
                       [NSColor blackColor], NSStrokeColorAttributeName,
                       self.strokeShadow, NSShadowAttributeName,
                       nil];
    
    // Foreground text
    self.foregroundAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                           self.font, NSFontAttributeName,
                           [NSColor whiteColor], NSForegroundColorAttributeName, nil];
}

-(NSString*) getMsg {
    return _msg;
}

-(void) setMsg:(NSString *)msg {
    // Skip if the msg is same
    if([msg isEqualToString:self.msg]) {
        return;
    }
    
    _msg = msg;
    self.strokeStr = [[NSMutableAttributedString alloc]
                                         initWithString:self.msg attributes:self.strokeAttr];
    
    self.foregroundStr = [[NSMutableAttributedString alloc]
                                             initWithString:self.msg attributes:self.foregroundAttr];
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [self.strokeStr drawInRect:self.bounds];
    [self.foregroundStr drawInRect:self.bounds];
}

@end
