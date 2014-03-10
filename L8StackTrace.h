//
//  L8StackTrace.h
//  Sphere
//
//  Created by Jos Kuijpers on 9/26/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

@class L8StackFrame;

/**
 * @brief Stacktrace container
 */
@interface L8StackTrace : NSObject

/**
 * Gets a stackframe at given index.
 *
 * @param index frame number. Maximum value is <code>numberOfFrames-1</code>
 * @return a stackframe or nil if not available
 */
- (L8StackFrame *)stackFrameAtIndex:(unsigned int)index;

/**
 * Gets the number of frames in the stacktrace.
 *
 * @return integer with number of frames
 */
- (unsigned int)numberOfFrames;

/**
 * Get a stack trace for current point of execution.
 *
 * @return An L8StackTrace
 */
+ (L8StackTrace *)currentStackTrace;

@end

/**
 * @brief Subscription methods
 */
@interface L8StackTrace (Subscription)

/**
 * Gets a stackframe at given index.
 *
 * This method is the same as stackFrameAtIndex:
 *
 * @param index frame number. Maximum value is <code>numberOfFrames-1</code>
 * @return a stackframe or nil if not available
 */
- (L8StackFrame *)objectAtIndexedSubscript:(NSUInteger)index;

@end

/**
 * @brief Enumeration methods
 */
@interface L8StackTrace (Enumeration) <NSFastEnumeration>
@end

/**
 * @brief A single frame in the stack
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
