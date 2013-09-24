//
//  ObjCCallback.h
//  V8Test
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#include "v8.h"

void ObjCConstructor(const v8::FunctionCallbackInfo<v8::Value>& info);
void ObjCMethodCall(const v8::FunctionCallbackInfo<v8::Value>& info);
void ObjCBlockCall(const v8::FunctionCallbackInfo<v8::Value>& info);

void ObjCNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info);
void ObjCNamedPropertyGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value>& info);
void ObjCNamedPropertyQuery(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Integer>& info);

void ObjCIndexedPropertySetter(uint32_t index, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info);
void ObjCIndexedPropertyGetter(uint32_t index, const v8::PropertyCallbackInfo<v8::Value>& info);
void ObjCIndexedPropertyQuery(uint32_t index, const v8::PropertyCallbackInfo<v8::Integer>& info);

void ObjCAccessorSetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void> &info);
void ObjCAccessorGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value> &info);

void ObjCWeakReferenceCallback(v8::Isolate *isolate, v8::Persistent<v8::External> *object, void *parameter);