//
//  ObjCCallback.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

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