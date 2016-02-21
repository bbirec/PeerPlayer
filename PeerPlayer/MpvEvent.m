//
//  MpvEvent.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 21..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "MpvEvent.h"

@implementation MpvEvent

+(id) nodeToObject:(mpv_node*)node {
    switch (node->format) {
        case MPV_FORMAT_STRING:
            return [NSString stringWithUTF8String:node->u.string];
        case MPV_FORMAT_FLAG:
            return [NSNumber numberWithInt:node->u.flag];
        case MPV_FORMAT_INT64:
            return [NSNumber numberWithLong:node->u.int64];
        case MPV_FORMAT_DOUBLE:
            return [NSNumber numberWithDouble:node->u.double_];
        case MPV_FORMAT_NODE_ARRAY: {
            mpv_node_list *list = node->u.list;
            NSMutableArray* arr = [NSMutableArray arrayWithCapacity:list->num];
            
            for (int n = 0; n < list->num; n++) {
                [arr addObject:[self nodeToObject:&list->values[n]]];
            }
            return arr;
        }
        case MPV_FORMAT_NODE_MAP: {
            mpv_node_list *list = node->u.list;
            NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:list->num];
            
            for (int n = 0; n < list->num; n++) {
                [dict setObject:[self nodeToObject:&list->values[n]]
                         forKey:[NSString stringWithUTF8String:list->keys[n]]];
            }
            return dict;
        }
        default: // MPV_FORMAT_NONE, unknown values (e.g. future extensions)
            NSAssert(true, @"Not supported mpv format");
            return nil;
    }
}

+(id) convertProperty:(mpv_event_property*) prop {
    if (prop->format == MPV_FORMAT_DOUBLE) {
        return [NSNumber numberWithDouble:*(double *)prop->data];
    }
    else if(prop->format == MPV_FORMAT_FLAG) {
        return [NSNumber numberWithInteger:*(int *)prop->data];
    }
    else if (prop->format == MPV_FORMAT_NODE) {
        return [self nodeToObject:(mpv_node *)prop->data];
    }
    else {
        NSAssert(true, @"Not supported conversion");
        return nil;
    }
}
@end
