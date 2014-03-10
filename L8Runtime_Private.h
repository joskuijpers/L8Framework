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

#import "L8Runtime.h"
#include "v8.h"

@class L8WrapperMap;

#define L8_RUNTIME_EMBEDDER_DATA_SELF 0
//#define L8_RUNTIME_EMBEDDER_DATA_SELF_2 1 // TODO: This seems wrong
#define L8_RUNTIME_EMBEDDER_DATA_CB_THIS 2
#define L8_RUNTIME_EMBEDDER_DATA_CB_CALLEE 3
#define L8_RUNTIME_EMBEDDER_DATA_CB_ARGS 4
#define L8_RUNTIME_EMBEDDER_DATA_SKIP_CONSTRUCTING 5

@interface L8Runtime ()

@property (readonly) L8WrapperMap *wrapperMap;

+ (L8Runtime *)contextWithV8Context:(v8::Handle<v8::Context>)v8context;
- (v8::Local<v8::Context>)V8Context;

- (L8Value *)wrapperForObjCObject:(id)object;
- (L8Value *)wrapperForJSObject:(v8::Handle<v8::Value>)value;

@end
