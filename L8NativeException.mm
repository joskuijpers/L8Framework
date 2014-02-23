//
//  L8NativeException.m
//  Sphere
//
//  Created by Jos Kuijpers on 23/02/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

#import "L8NativeException.h"
#import "NSString+L8.h"
#include "v8.h"

@implementation L8SyntaxErrorException

+ (v8::Handle<v8::Value>)v8exceptionWithMessage:(NSString *)message
{
	return v8::Exception::SyntaxError([(message == nil?@"":message) V8String]);
}

- (v8::Handle<v8::Value>)v8exception
{
	return v8::Exception::SyntaxError([(self.message == nil?@"":self.message) V8String]);
}

@end

@implementation L8TypeErrorException

+ (v8::Handle<v8::Value>)v8exceptionWithMessage:(NSString *)message
{
	return v8::Exception::TypeError([(message == nil?@"":message) V8String]);
}

- (v8::Handle<v8::Value>)v8exception
{
	return v8::Exception::TypeError([(self.message == nil?@"":self.message) V8String]);
}

@end

@implementation L8ReferenceErrorException

+ (v8::Handle<v8::Value>)v8exceptionWithMessage:(NSString *)message
{
	return v8::Exception::ReferenceError([(message == nil?@"":message) V8String]);
}

- (v8::Handle<v8::Value>)v8exception
{
	return v8::Exception::ReferenceError([(self.message == nil?@"":self.message) V8String]);
}

@end

@implementation L8RangeErrorException

+ (v8::Handle<v8::Value>)v8exceptionWithMessage:(NSString *)message
{
	return v8::Exception::RangeError([(message == nil?@"":message) V8String]);
}

- (v8::Handle<v8::Value>)v8exception
{
	return v8::Exception::RangeError([(self.message == nil?@"":self.message) V8String]);
}

@end
