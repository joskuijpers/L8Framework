//
//  L8Exception.h
//  Sphere
//
//  Created by Jos Kuijpers on 23/02/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

@class L8StackTrace;

/**
 * @brief An JavaScript exception
 */
@interface L8Exception : NSObject

/// Column where the appointed problem starts
@property (readonly,assign) int startColumn;

/// Column where the appointed problem ends
@property (readonly,assign) int endColumn;

/// Line of code from source code
@property (readonly,copy) NSString *sourceLine;

/// Number of the line in the source
@property (readonly,assign) int lineNumber;

/// Name of the script
@property (readonly,copy) NSString *resourceName;

/// Message of the exception
@property (readonly,copy) NSString *message;

/**
 * Create a new, empty exception.
 *
 * @return A new exception.
 */
+ (instancetype)exception;

/**
 * Create a new exception with specific message.
 *
 * @param message The message of the exception.
 * @return A new exception.
 */
+ (instancetype)exceptionWithMessage:(NSString *)message;

/**
 * Get the backtrace of the exception.
 *
 * @return The L8StackTrace backtrace.
 */
- (L8StackTrace *)backtrace;

@end
