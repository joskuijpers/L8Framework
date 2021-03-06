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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

@class LDFBreakPoint, LDFProcess, LDFMessage;

/**
 * @brief Delegate used for process notifications.
 */
@protocol LDFProcessDelegate <NSObject>
@optional

/**
 * Sent when an error occurred when trying to connect to
 * the remote process.
 *
 * @param process The process representation.
 * @param error Information about the problem.
 */
- (void)process:(LDFProcess *)process failedToConnect:(NSError *)error;

/**
 * Sent when successfully a connection is made to the remote process.
 * @param process The process representation.
 */
- (void)processDidConnect:(LDFProcess *)process;

/**
 * Sent when the process is about to handle a specific message.
 *
 * Return NO if the message should not be handled. For example, if
 * you want to handle it yourself.
 *
 * @param process The process representation.
 * @param message Message that will be processed.
 * @return NO if the message should be skipped, YES otherwise.
 */
- (BOOL)process:(LDFProcess *)process shouldHandleMessage:(LDFMessage *)message;

/**
 * Sent by the remote process when it hits a breakpoint.
 *
 * @param process The process hitting a breakpoint.
 * @param breakpoint The breakpoint that is hit.
 */
- (void)process:(LDFProcess *)process hitBreakpoint:(LDFBreakPoint *)breakpoint;

@end

/**
 * @brief A remote process.
 */
@interface LDFProcess : NSObject

/// Object where async messages will be sent to
@property (weak) id<LDFProcessDelegate> delegate;

/// Port on which the L8 process is running
@property (readonly) uint16_t port;

@property (readonly) NSString *v8Version;
@property (readonly) NSString *protocolVersion;
@property (readonly) NSString *embeddingHost;

/**
 * Initialize a connection to a remote L8 process.
 *
 * @param port Port used by the remote L8 process.
 * @return An initialized LDFProcess.
 */
- (instancetype)initWithPort:(uint16_t)port;

/**
 * Start the connection to the remote process.
 */
- (void)connect;

/**
 * Close the connection to the remote process.
 *
 * @todo How does this affect the remote process?
 */
- (void)close;

@end
