//
//  L8StackTrace.h
//  Sphere
//
//  Created by Jos Kuijpers on 9/26/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

@class L8StackFrame;

@interface L8StackTrace : NSObject

/**
 * Gets a stackframe at given index.
 *
 * @param index frame number. Maximum value is -[numberOfFrames]-1
 * @return a stackframe or nil if not available
 */
- (L8StackFrame *)stackFrameAtIndex:(unsigned int)index;

/**
 * Gets the number of frames in the stacktrace.
 *
 * @return integer with number of frames
 */
- (unsigned int)numberOfFrames;

+ (L8StackTrace *)currentStackTrace;

@end

@interface L8StackTrace (Subscription)

- (L8StackFrame *)objectAtIndexedSubscript:(NSUInteger)index;

@end

@interface L8StackTrace (Enumeration) <NSFastEnumeration>
@end

/**
 * A single frame in the stack
 */
@interface L8StackFrame : NSObject

/// Number of the line in the script
@property (readonly) NSNumber *lineNumber;

/// Column in the line where the frame resides
@property (readonly) NSNumber *column;

/// Name of the script the frame is in
@property (readonly) NSString *scriptName;

/// URL of the origin of the script
@property (readonly) NSURL *sourceURL;

/// Name of the function around the execution point
@property (readonly) NSString *functionName;

/// Whether the frame is inside a constructor
@property (readonly,getter=isConstructor) BOOL constructor;

/// Whether the frame is inside an eval()
@property (readonly,getter=isEval) BOOL eval;

@end
