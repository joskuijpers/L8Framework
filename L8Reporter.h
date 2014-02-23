//
//  L8Reporter.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L8Exception;

@interface L8Reporter : NSObject

@property (copy) void (^exceptionHandler)(L8Exception *);

+ (L8Reporter *)sharedReporter;
+ (void)printException:(L8Exception *)exception;

@end
