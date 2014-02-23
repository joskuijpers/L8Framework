//
//  L8Exception.h
//  Sphere
//
//  Created by Jos Kuijpers on 23/02/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L8StackTrace;

@interface L8Exception : NSObject

@property (readonly,assign) int startColumn;
@property (readonly,assign) int endColumn;
@property (readonly,copy) NSString *sourceLine;
@property (readonly,assign) int lineNumber;
@property (readonly,copy) NSString *resourceName;
@property (readonly,copy) NSString *message;

+ (instancetype)exception;
+ (instancetype)exceptionWithMessage:(NSString *)message;

- (NSString *)description;
- (L8StackTrace *)backtrace;

@end
