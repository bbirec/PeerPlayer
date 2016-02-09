//
//  MagnetOpenController.m
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import "MagnetOpenController.h"

@implementation MagnetOpenController


-(IBAction) openMagnetLink:(id) sender
{
    if([NSApp runModalForWindow:self.panel] == NSFileHandlingPanelOKButton) {
        NSString* url = [self.textField stringValue];
        NSLog(@"url: %@", url);
        [self.appDelegate play:url];
    }
}


-(IBAction) confirmed:(id) sender
{
    [NSApp stopModalWithCode:NSFileHandlingPanelOKButton];
    [self.panel orderOut:self];
    NSLog(@"confirmed");
}

-(IBAction) canceled:(id) sender
{
    [NSApp abortModal];
    [self.panel orderOut:self];
    NSLog(@"aborted");
}


@end
