//
//  ITErrors.h
//  Traktable
//
//  Created by Johan Kuijt on 02-09-13.
//  Copyright (c) 2013 Mustacherious. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITErrors : NSObject

- (NSArray *)fetchErrors;
- (void)clearErrors;

@end

@interface ITErrorGroupHeader : NSObject

@property (nonatomic, strong) NSString *date;

- (id)initWithDateString:(NSString *)date;

@end