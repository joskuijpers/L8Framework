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

/**
 * Callback for 'new <class>()'
 */
void ObjCConstructor(const v8::FunctionCallbackInfo<v8::Value>& info);

/**
 * Callback for <class>() and <object>()
 */
void ObjCMethodCall(const v8::FunctionCallbackInfo<v8::Value>& info);

/**
 * Callback for <function>()
 */
void ObjCBlockCall(const v8::FunctionCallbackInfo<v8::Value>& info);

/**
 * Callback for setters of properties: obj[prop] = xx;
 */
void ObjCNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info);

/**
 * Callback for getters of properties: obj[prop]
 */
void ObjCNamedPropertyGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value>& info);
void ObjCNamedPropertyQuery(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Integer>& info);

/**
 * Callback for indexed property setters: obj[1] = xx;
 */
void ObjCIndexedPropertySetter(uint32_t index, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info);

/**
 * Callback for indexed property getters: obj[1]
 */
void ObjCIndexedPropertyGetter(uint32_t index, const v8::PropertyCallbackInfo<v8::Value>& info);
void ObjCIndexedPropertyQuery(uint32_t index, const v8::PropertyCallbackInfo<v8::Integer>& info);

/**
 * Callback for any setter: obj.prop = xx;
 */
void ObjCAccessorSetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void> &info);

/**
 * Callback for getters: obj.prop
 */
void ObjCAccessorGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value> &info);

/**
 * Callback for stored objective-c values in Persisent<> that need freeing.
 */
void ObjCWeakReferenceCallback(v8::Isolate *isolate, v8::Persistent<v8::External> *object, void *parameter);