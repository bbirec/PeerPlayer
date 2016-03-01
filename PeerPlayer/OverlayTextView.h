//
//  OverlayTextView.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 3. 1..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OverlayTextView : NSView

@property (strong,setter=setMsg:,getter=getMsg) NSString* msg;

@property (strong) NSMutableAttributedString* strokeStr;
@property (strong) NSMutableAttributedString* foregroundStr;
@property (strong) NSShadow* strokeShadow;
@property (strong) NSFont* font;
@property (strong) NSDictionary* strokeAttr;
@property (strong) NSDictionary* foregroundAttr;


@end
