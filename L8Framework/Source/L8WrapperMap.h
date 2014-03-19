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

@class L8Context, L8Value;

/**
 * @brief A structure that maps between JS and ObjC objects.
 */
@interface L8WrapperMap : NSObject

/// Context using this wrapper map
@property (nonatomic,readonly) L8Context *context;

/**
 * Create a new Wrapper Map for specified context.
 *
 * @return self.
 */
- (instancetype)initWithContext:(L8Context *)context;

/**
 * Create a JavaScript wrapper for an Objective-C object.
 *
 * @todo Add caching to increase performance and decrease memory usage.
 *
 * @param object The Objective-C object.
 * @return A JavaScript value.
 */
- (L8Value *)JSWrapperForObject:(id)object;

/**
 * Create a JavaScript wrapper for an Objective-C object.
 *
 * @todo This method simply calls the init method of L8Value. It should
 * instead be caching the values.
 *
 * @param object A v8 value.
 * @return L8Value containing the v8 value.
 */
- (L8Value *)ObjCWrapperForValue:(v8::Local<v8::Value>)value;

/**
 * Get the cached function template for given class.
 *
 * Used by -[L8Value isInstanceOf:]
 *
 * @param cls Class to get the template for.
 * @return The function template, or an Empty handle when cache
 * does not contain the class.
 */
- (v8::Local<v8::FunctionTemplate>)getCachedFunctionTemplateForClass:(Class)cls;

@end

/**
 * Wrap an ObjC object in a simple v8 object with weak memory.
 *
 * @param context The v8 context to create the wrapper in.
 * @param wrappedObject The ObjC object to wrap.
 * @return A v8 value.
 */
v8::Local<v8::External> l8_make_wrapper(v8::Local<v8::Context> context, id object);

/**
 * Get an ObjC object from a V8 object with weak memory.
 *
 * @param wrapper The v8 object containing the ObjC object.
 * @return The ObjC object, or nil on failure.
 */
id l8_object_from_wrapper(v8::Local<v8::Value> wrapper);

/**
 * Get the wrapped ObjC object from an V8 object, created using -[JSWrapperForObject:]
 *
 * @param isolate The isolate the value is created in.
 * @param value The v8 value containing the object.
 * @return The ObjC object, or nil on failure.
 */
id l8_unwrap_objc_object(v8::Isolate *isolate, v8::Local<v8::Value> value);

/**
 * Wrap a C block into a V8 function object.
 *
 * @param context The v8 context to create the wrapper in.
 * @param object The C block.
 * @return A v8 Function object.
 */
v8::Local<v8::Function> l8_wrap_block(v8::Local<v8::Context> context, id object);

/**
 * Get the wrapped C block from a V8 object.
 *
 * @param isolate The v8 isolate.
 * @param object The object containing the block.
 * @return A block on success, <code>nil</code> on failure.
 */
id l8_unwrap_block(v8::Isolate *isolate, v8::Local<v8::Object> object);

/**
 * The class of a Block
 *
 * @return Class of a block
 */
Class BlockClass();
