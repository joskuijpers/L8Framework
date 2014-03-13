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

#include "v8.h"

@class L8Runtime, L8Value;

@interface L8WrapperMap : NSObject

- (instancetype)initWithRuntime:(L8Runtime *)runtime;

- (L8Value *)JSWrapperForObject:(id)object;
- (L8Value *)ObjCWrapperForValue:(v8::Local<v8::Value>)value;

// Used by -isInstanceOf:
- (v8::Local<v8::FunctionTemplate>)getCachedFunctionTemplateForClass:(Class)cls;

@end

v8::Local<v8::External> makeWrapper(v8::Local<v8::Context> context, id wrappedObject);
id objectFromWrapper(v8::Local<v8::Value> wrapper);

id unwrapObjcObject(v8::Local<v8::Context> context, v8::Local<v8::Value> value);
v8::Local<v8::Function> wrapBlock(id object);
id unwrapBlock(v8::Local<v8::Object> object);

/**
 * The class of a Block
 *
 * @return Class of a block
 */
Class BlockClass();