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

#include "v8.h"

/**
 * @brief Converting between NSStrings and v8::Values.
 */
@interface NSString (L8)

/**
 * Get an NSString from a v8::String.
 *
 * @param v8string The v8::String.
 * @return An NSString with the same string as v8string.
 */
+ (NSString *)stringWithV8String:(v8::Local<v8::String>)v8string;

/**
 * Get an NSString from a v8::Value.
 *
 * @param v8string The v8::Value.
 * @param isolate Isolate to work in.
 * @return An NSString with the same string as v8string.
 */
+ (NSString *)stringWithV8Value:(v8::Local<v8::Value>)v8value
					  inIsolate:(v8::Isolate *)isolate;

/**
 * Get an NSString from a v8::Value.
 *
 * @param v8string The v8::Value.
 * @return An NSString with the same string as v8string.
 */
+ (NSString *)stringWithV8Value:(v8::Local<v8::Value>)v8value;

/**
 * Get a v8::String from an NSString.
 *
 * @param isolate The isolate to store the object into.
 * @return A v8::String with the same string as the receiver.
 */
- (v8::Local<v8::String>)V8StringInIsolate:(v8::Isolate *)isolate;

@end