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

#import "L8Value.h"
#include "v8.h"

/**
 * @brief Value extension with private methods
 */
@interface L8Value ()

/// v8::Value wrapped by this L8Value.
@property (nonatomic,readonly) v8::Local<v8::Value> V8Value;

+ (instancetype)valueWithV8Value:(v8::Local<v8::Value>)value L8_UNAVAILABLE("Use valueWithV8Value:inContext: instead.");
+ (instancetype)valueWithV8Value:(v8::Local<v8::Value>)value inContext:(L8Context *)context;

- (instancetype)init L8_UNAVAILABLE("Use initWithV8Value:inContext: instead.");
- (instancetype)initWithV8Value:(v8::Local<v8::Value>)value L8_UNAVAILABLE("Use initWithV8Value:inContext: instead.");
- (instancetype)initWithV8Value:(v8::Local<v8::Value>)value inContext:(L8Context *)context;

@end

v8::Local<v8::Value> objectToValue(v8::Isolate *isolate, L8Context *context, id object);

id valueToObject(v8::Isolate *isolate, L8Context *context, v8::Local<v8::Value> value);
NSNumber *valueToNumber(v8::Isolate *isolate, L8Context *context, v8::Local<v8::Value> value);
NSString *valueToString(v8::Isolate *isolate, L8Context *context, v8::Local<v8::Value> value);
NSDate *valueToDate(v8::Isolate *isolate, L8Context *context, v8::Local<v8::Value> value);
NSArray *valueToArray(v8::Isolate *isolate, L8Context *context, v8::Local<v8::Value> value);
NSDictionary *valueToDictionary(v8::Isolate *isolate, L8Context *context, v8::Local<v8::Value> value);
NSData *valueToData(v8::Isolate *isolate, L8Context *context, v8::Local<v8::Value> value);
