//
//  L8Reporter.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

@class L8Exception;

/**
 * @brief Error and exception reporter
 */
@interface L8Reporter : NSObject

/// Default exception handling block
@property (copy) void (^exceptionHandler)(L8Exception *);

/**
 * Gets the default instance of the reporter
 *
 * @return default L8Reporter instance
 */
+ (L8Reporter *)sharedReporter;

/**
 * Prints an exception with nice formatting.
 *
 * This includes a copy of the faulty line, and a line
 * pointing to the faulty characters.
 *
 * @param exception the exception to print
 */
+ (void)printException:(L8Exception *)exception;

@end
