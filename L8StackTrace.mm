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

#import "L8StackTrace_Private.h"
#import "NSString+L8.h"
#include "v8.h"

#define L8_STACKTRACE_FRAMELIMIT 20

using v8::Local;
using v8::StackTrace;
using v8::StackFrame;

@implementation L8StackTrace {
	NSMutableArray *_frameCache;
	Local<StackTrace> _v8stackTrace;
}

- (id)initWithV8StackTrace:(Local<StackTrace>)v8stackTrace;
{
	self = [super init];
	if(self) {
		if(v8stackTrace.IsEmpty())
			return nil;

		_v8stackTrace = v8stackTrace;

		_frameCache = [NSMutableArray array];
		for(int i = 0; i < _v8stackTrace->GetFrameCount(); i++) {
			[_frameCache addObject:[NSNull null]];
		}
	}
	return self;
}

- (L8StackFrame *)stackFrameAtIndex:(unsigned int)index
{
	L8StackFrame *obj = _frameCache[index];
	if(obj == nil)
		return nil;

	if([obj isEqual:[NSNull null]]) {
		obj = [[L8StackFrame alloc] initWithV8StackFrame:_v8stackTrace->GetFrame(index)];
		_frameCache[index] = obj;
	}
	
	return obj;
}

- (unsigned int)numberOfFrames
{
	return _v8stackTrace->GetFrameCount();
}

+ (L8StackTrace *)currentStackTrace
{
	Local<StackTrace> trace;
	trace = StackTrace::CurrentStackTrace(L8_STACKTRACE_FRAMELIMIT);

	return [[self alloc] initWithV8StackTrace:trace];
}

- (NSString *)description
{
	NSMutableString *desc  = [[NSMutableString alloc] init];

	for(unsigned int i = 0; i < self.numberOfFrames; i++) {
		L8StackFrame *frame = self[i];

		if(i == 0)
			[desc appendFormat:@"%@",frame];
		else
			[desc appendFormat:@"\n%@",frame];
	}

	return desc;
}

@end

@implementation L8StackTrace (Subscription)

- (L8StackFrame *)objectAtIndexedSubscript:(NSUInteger)index
{
	return [self stackFrameAtIndex:(unsigned int)index];
}

@end

@implementation L8StackTrace (Enumeration)

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(__unsafe_unretained id [])buffer
									count:(NSUInteger)len
{
	@throw [NSException exceptionWithName:@"NotImplemented" reason:@"" userInfo:nil];
	return 0;
}

@end

@implementation L8StackFrame {
	Local<StackFrame> _v8stackFrame;
}

- (id)initWithV8StackFrame:(Local<StackFrame>)v8stackFrame
{
	self = [super init];
	if(self) {
		_v8stackFrame = v8stackFrame;
	}
	return self;
}

- (NSNumber *)lineNumber
{
	return @(_v8stackFrame->GetLineNumber());
}

- (NSNumber *)column
{
	return @(_v8stackFrame->GetColumn());
}

- (NSString *)scriptName
{
	return [NSString stringWithV8String:_v8stackFrame->GetScriptName()];
}

- (NSURL *)sourceURL
{
	NSString *str = [NSString stringWithV8String:_v8stackFrame->GetScriptNameOrSourceURL()];
	return [NSURL URLWithString:str];
}

- (NSString *)functionName
{
	return [NSString stringWithV8String:_v8stackFrame->GetFunctionName()];
}

- (BOOL)isConstructor
{
	return _v8stackFrame->IsConstructor();
}

- (BOOL)isEval
{
	return _v8stackFrame->IsEval();
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ at %@:%@:%@",self.functionName,self.scriptName,self.lineNumber,self.column];
}

@end