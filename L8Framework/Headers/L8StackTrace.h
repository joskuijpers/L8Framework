/*
 * Copyright (c) 2014 Jos Kuijpers. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
