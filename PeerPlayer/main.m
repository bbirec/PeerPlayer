//
//  main.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 7..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    // Ignore SIGPIPE signal globally.
    // In order to ignore SIGPIPE on debug, add ~/.lldbinit file with following:
    // process handle SIGPIPE -n true -p true -s false
    signal(SIGPIPE, SIG_IGN);
    
    return NSApplicationMain(argc, argv);
}
