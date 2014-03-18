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
@property (readonly) v8::Local<v8::Value> V8Value;

+ (instancetype)valueWithV8Value:(v8::Local<v8::Value>)value __attribute__((unavailable("Use valueWithV8Value:inContext: instead.")));;
+ (instancetype)valueWithV8Value:(v8::Local<v8::Value>)value inContext:(L8Runtime *)context;

- (instancetype)init __attribute__((unavailable));
- (instancetype)initWithV8Value:(v8::Local<v8::Value>)value __attribute__((unavailable("Use initWithV8Value:inContext: instead.")));
- (instancetype)initWithV8Value:(v8::Local<v8::Value>)value inContext:(L8Runtime *)context;

@end

v8::Local<v8::Value> objectToValue(L8Runtime *runtime, id object);

id valueToObject(L8Runtime *runtime, v8::Local<v8::Value> value);
NSNumber *valueToNumber(L8Runtime *runtime, v8::Local<v8::Value> value);
NSString *valueToString(L8Runtime *runtime, v8::Local<v8::Value> value);
NSDate *valueToDate(L8Runtime *runtime, v8::Local<v8::Value> value);
NSArray *valueToArray(L8Runtime *runtime, v8::Local<v8::Value> value);
NSDictionary *valueToDictionary(L8Runtime *runtime, v8::Local<v8::Value> value);
