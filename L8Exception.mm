//
//  L8Exception.m
//  Sphere
//
//  Created by Jos Kuijpers on 23/02/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

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

- (v8::Handle<v8::Value>)v8exception
{
	return v8::Exception::Error([(_message == nil?@"":_message) V8String]);
}

+ (v8::Handle<v8::Value>)v8exceptionWithMessage:(NSString *)message
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
