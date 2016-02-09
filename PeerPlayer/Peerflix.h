//
//  Peerflix.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"

@protocol PeerflixDelegate <NSObject>

-(void) torrentReady:(NSDictionary*)data;

@end




@interface Peerflix : NSObject<SRWebSocketDelegate>

@property (strong) id<PeerflixDelegate> delegate;
@property (strong) SRWebSocket* socket;

// Kill the existing peerflix process
+(void) kill;

// Download torrent file
-(void) downloadTorrent:(NSString*)pathOrMagnet;

@end
