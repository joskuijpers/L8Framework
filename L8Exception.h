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
