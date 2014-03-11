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

#import "L8Exception_Private.h"
#import "NSString+L8.h"
#import "L8StackTrace_Private.h"
#include "v8.h"

@implementation L8Exception {
	L8StackTrace *_backtrace;
}

+ (instancetype)exception
{
	return [[self alloc] initWithMessage:nil];
}

+ (instancetype)exceptionWithMessage:(NSString *)message
{
	return [[self alloc] initWithMessage:message];
}

+ (instancetype)exceptionWithV8Message:(v8::Local<v8::Message>)message
						  thrownObject:(__weak id)object
{
	return [[self alloc] initWithV8Message:message
							  thrownObject:object];
}

- (instancetype)initWithMessage:(NSString *)message
{
	self = [super init];
	if(self) {
		_message = message;
	}
	return self;
}

- (instancetype)initWithV8Message:(v8::Local<v8::Message>)message
					 thrownObject:(__weak id)object
{
	self = [super init];
	if(self) {
		_backtrace = [[L8StackTrace alloc] initWithV8StackTrace:message->GetStackTrace()];

		_startColumn = message->GetStartColumn();
		_endColumn = message->GetEndColumn();
		_lineNumber = message->GetLineNumber();
		// start pos, end pos

		_sourceLine = [NSString stringWithV8String:message->GetSourceLine()];
		_resourceName = [NSString stringWithV8Value:message->GetScriptResourceName()];

		_thrownObject = object;
		_message = [_thrownObject description];
	}
	return self;
}

- (v8::Local<v8::Value>)v8exception
{
	return v8::Exception::Error([(_message == nil?@"":_message) V8String]);
}

+ (v8::Local<v8::Value>)v8exceptionWithMessage:(NSString *)message
{
	return v8::Exception::Error([(message == nil?@"":message) V8String]);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"An exception of type %@ occurred at %@:%d:%d-%d: '%@'",
			self.className,_resourceName,_lineNumber,
			_startColumn,_endColumn,_message];
}

- (L8StackTrace *)backtrace
{
	return _backtrace;
}

@end
