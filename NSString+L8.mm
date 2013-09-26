//
//  NSString+V8.m
//  V8Test
//
//  Created by Jos Kuijpers on 9/10/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "NSString+L8.h"
#include "v8.h"

@implementation NSString (L8)

+ (NSString *)stringWithV8String:(v8::Local<v8::String>)v8string
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

+ (NSString *)stringWithV8Value:(v8::Handle<v8::Value>)v8value
{
	return [NSString stringWithV8Value:v8value
						   withIsolate:v8::Isolate::GetCurrent()];
}

+ (NSString *)stringWithV8Value:(v8::Handle<v8::Value>)v8value
					withIsolate:(v8::Isolate *)isolate
{
	if(v8value.IsEmpty())
		return nil;

	v8::HandleScope handleScope(isolate);
	v8::Local<v8::String> string = v8value->ToString();

	return [NSString stringWithV8String:string];
}

- (v8::Local<v8::String>)V8String
{
	return [self V8StringWithIsolate:v8::Isolate::GetCurrent()];
}

- (v8::Local<v8::String>)V8StringWithIsolate:(v8::Isolate *)isolate
{
	v8::HandleScope scope(isolate);

	v8::Local<v8::String> ret = v8::String::NewFromUtf8(isolate, [self UTF8String]);

	return scope.Close(ret);
}

@end