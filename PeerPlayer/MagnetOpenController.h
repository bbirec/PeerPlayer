//
//  MagnetOpenController.h
//  PeerPlayer
//
//  Created by 문희홍 on 2016. 2. 9..
//  Copyright © 2016년 HackersTalk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface MagnetOpenController : NSObject

@property (weak) IBOutlet NSPanel* panel;
@property (weak) IBOutlet NSTextField* textField;

@property (weak) IBOutlet AppDelegate* appDelegate;

-(IBAction) open:(id) sender;
-(IBAction) confirmed:(id) sender;
-(IBAction) canceled:(id) sender;

@end
