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

#import "L8NativeException.h"
#import "NSString+L8.h"
#include "v8.h"

using v8::Local;
using v8::Value;
using v8::Exception;

@implementation L8SyntaxErrorException

+ (Local<Value>)v8exceptionWithMessage:(NSString *)message
{
	return Exception::SyntaxError([(message == nil?@"":message) V8String]);
}

- (Local<Value>)v8exception
{
	return Exception::SyntaxError([(self.message == nil?@"":self.message) V8String]);
}

@end

@implementation L8TypeErrorException

+ (Local<Value>)v8exceptionWithMessage:(NSString *)message
{
	return Exception::TypeError([(message == nil?@"":message) V8String]);
}

- (Local<Value>)v8exception
{
	return Exception::TypeError([(self.message == nil?@"":self.message) V8String]);
}

@end

@implementation L8ReferenceErrorException

+ (Local<Value>)v8exceptionWithMessage:(NSString *)message
{
	return Exception::ReferenceError([(message == nil?@"":message) V8String]);
}

- (Local<Value>)v8exception
{
	return Exception::ReferenceError([(self.message == nil?@"":self.message) V8String]);
}

@end

@implementation L8RangeErrorException

+ (Local<Value>)v8exceptionWithMessage:(NSString *)message
{
	return Exception::RangeError([(message == nil?@"":message) V8String]);
}

- (Local<Value>)v8exception
{
	return Exception::RangeError([(self.message == nil?@"":self.message) V8String]);
}

@end
