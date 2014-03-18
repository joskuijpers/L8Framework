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

#import "L8Exception_Private.h"
#import "NSString+L8.h"
#import "L8StackTrace_Private.h"
#include "v8.h"

using namespace v8;

@implementation L8Exception {
	L8StackTrace *_backtrace;
	Isolate *_v8isolate;
}

+ (instancetype)exception
{
	return [[self alloc] initWithMessage:nil];
}

+ (instancetype)exceptionWithMessage:(L8_STRING_CLASS *)message
{
	return [[self alloc] initWithMessage:message];
}

+ (instancetype)exceptionWithV8Message:(Local<Message>)message
						  thrownObject:(__weak id)object
							   isolate:(Isolate *)isolate
{
	return [[self alloc] initWithV8Message:message
							  thrownObject:object
								   isolate:isolate];
}

- (instancetype)initWithMessage:(L8_STRING_CLASS *)message
{
	self = [super init];
	if(self) {
		_message = message;
	}
	return self;
}

- (instancetype)initWithV8Message:(Local<Message>)message
					 thrownObject:(__weak id)object
						  isolate:(Isolate *)isolate
{
	self = [super init];
	if(self) {
		_v8isolate = isolate;

		_backtrace = [[L8StackTrace alloc] initWithV8StackTrace:message->GetStackTrace()];

		_startColumn = message->GetStartColumn();
		_endColumn = message->GetEndColumn();
		_lineNumber = message->GetLineNumber();
		// start pos, end pos

		_sourceLine = [L8_STRING_CLASS stringWithV8String:message->GetSourceLine()];
		_resourceName = [L8_STRING_CLASS stringWithV8Value:message->GetScriptResourceName()
											inIsolate:isolate];

		_thrownObject = object;
		_message = [_thrownObject description];
	}
	return self;
}

- (Local<Value>)v8exception
{
	return Exception::Error([(_message == nil?@"":_message) V8StringInIsolate:_v8isolate]);
}

+ (Local<Value>)v8exceptionWithMessage:(L8_STRING_CLASS *)message inIsolate:(Isolate *)isolate
{
	return Exception::Error([(message == nil?@"":message) V8StringInIsolate:isolate]);
}

- (L8_STRING_CLASS *)description
{
	return [L8_STRING_CLASS stringWithFormat:@"An exception of type %@ occurred at %@:%d:%d-%d: '%@'",
			self.className,_resourceName,_lineNumber,
			_startColumn,_endColumn,_message];
}

- (L8StackTrace *)backtrace
{
	return _backtrace;
}

@end
