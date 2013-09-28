//
//  L8StackTrace.h
//  Sphere
//
//  Created by Jos Kuijpers on 9/26/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L8StackFrame;

@interface L8StackTrace : NSObject

- (L8StackFrame *)stackFrameAtIndex:(unsigned int)index;
- (unsigned int)numberOfFrames;

+ (L8StackTrace *)currentStackTrace;

@end

@interface L8StackTrace (Subscription)

- (L8StackFrame *)objectAtIndexedSubscript:(NSUInteger)index;

@end

@interface L8StackTrace (Enumeration) <NSFastEnumeration>

@end

@interface L8StackFrame : NSObject

@property (strong,readonly) NSNumber *lineNumber;
@property (strong,readonly) NSNumber *column;
@property (strong,readonly) NSString *scriptName;
@property (strong,readonly) NSURL *sourceURL;
@property (strong,readonly) NSString *functionName;
@property (assign,readonly,getter=isConstructor) BOOL constructor;
@property (assign,readonly,getter=isEval) BOOL eval;

@end
