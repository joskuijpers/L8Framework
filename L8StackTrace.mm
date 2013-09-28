//
//  L8StackTrace.m
//  Sphere
//
//  Created by Jos Kuijpers on 9/26/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8StackTrace_Private.h"
#import "NSString+L8.h"
#include "v8.h"

#define L8_STACKTRACE_FRAMELIMIT 20

@implementation L8StackTrace {
	NSMutableArray *_frameCache;
	v8::Handle<v8::StackTrace> _v8stackTrace;
}

- (id)initWithV8StackTrace:(v8::Handle<v8::StackTrace>)v8stackTrace;
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
	v8::Handle<v8::StackTrace> trace;
	trace = v8::StackTrace::CurrentStackTrace(L8_STACKTRACE_FRAMELIMIT);

	return [[self alloc] initWithV8StackTrace:trace];
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
	v8::Handle<v8::StackFrame> _v8stackFrame;
}

- (id)initWithV8StackFrame:(v8::Handle<v8::StackFrame>)v8stackFrame
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

@end