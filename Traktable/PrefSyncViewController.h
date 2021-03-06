//
//  PrefSyncViewController.h
//  Traktable
//
//  Created by Johan Kuijt on 27-02-13.
//  Copyright (c) 2013 Mustacherious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MASPreferencesViewController.h"

@interface PrefSyncViewController : NSViewController <MASPreferencesViewController>

@property(nonatomic, retain) IBOutlet NSButton *collection;

- (IBAction)sync:(id)sender;
- (IBAction)import:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)addToCollection:(id)sender;

@end
