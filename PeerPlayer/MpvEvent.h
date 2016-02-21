//
//  MpvEvent.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 21..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mpv/client.h>

@interface MpvEvent : NSObject

+(id) convertProperty:(mpv_event_property*) prop;

@end
