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

#import "NSString+L8.h"
#include "v8.h"

using namespace v8;

@implementation NSString (L8)

+ (NSString *)stringWithV8String:(Local<String>)v8string
{
	char *buffer;
	NSString *ret;

	if(v8string.IsEmpty())
		return nil;

	buffer = (char *)malloc(v8string->Length()+1);
	if(buffer == NULL)
		return nil;

	v8string->WriteUtf8(buffer);
	ret = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
	free(buffer);

	return ret;
}

+ (NSString *)stringWithV8Value:(Local<Value>)v8value
{
	return [NSString stringWithV8Value:v8value
						   withIsolate:Isolate::GetCurrent()];
}

+ (NSString *)stringWithV8Value:(Local<Value>)v8value
					withIsolate:(Isolate *)isolate
{
	if(v8value.IsEmpty())
		return nil;

	HandleScope handleScope(isolate);
	Local<String> string = v8value->ToString();

	return [NSString stringWithV8String:string];
}

- (Local<String>)V8String
{
	return [self V8StringWithIsolate:Isolate::GetCurrent()];
}

- (Local<String>)V8StringWithIsolate:(Isolate *)isolate
{
	EscapableHandleScope scope(isolate);

	Local<String> ret = String::NewFromUtf8(isolate, [self UTF8String]);

	return scope.Escape(ret);
}

@end