//
//  NSString+V8.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/10/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#include "v8.h"

@interface NSString (L8)

+ (NSString *)stringWithV8String:(v8::Local<v8::String>)v8string;

+ (NSString *)stringWithV8Value:(v8::Handle<v8::Value>)v8value withIsolate:(v8::Isolate *)isolate;
+ (NSString *)stringWithV8Value:(v8::Handle<v8::Value>)v8value;

- (v8::Local<v8::String>)V8StringWithIsolate:(v8::Isolate *)isolate;
- (v8::Local<v8::String>)V8String;

@end