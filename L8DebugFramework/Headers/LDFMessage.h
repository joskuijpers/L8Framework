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

/**
 * @brief A debug protocol message.
 */
@interface LDFMessage : NSObject

@property (copy) NSNumber *seq;

@end

@interface LDFRequestMessage : LDFMessage

@property (copy) NSString *command;
@property (copy) NSDictionary *arguments;

@end

@interface LDFResponseMessage : LDFMessage

@property (readonly) NSNumber *requestSeq;
@property (readonly) LDFMessage *request;
@property (readonly) NSString *command;
@property (readonly) NSDictionary *body;
@property (readonly,getter=isRunning) BOOL running;
@property (readonly) BOOL success;
@property (readonly) NSString *errorMessage;

@end

@interface LDFEventMessage : LDFMessage

@property (readonly) NSString *event;
@property (readonly) NSDictionary *body;

@end