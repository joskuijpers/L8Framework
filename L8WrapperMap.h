//
//  L8WrapperMap.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#include "v8.h"

@class L8Runtime, L8Value;

@interface L8WrapperMap : NSObject

- (instancetype)initWithRuntime:(L8Runtime *)runtime;

- (L8Value *)JSWrapperForObject:(id)object;
- (L8Value *)ObjCWrapperForValue:(v8::Handle<v8::Value>)value;

@end

v8::Handle<v8::External> makeWrapper(v8::Handle<v8::Context> context, id wrappedObject);
id objectFromWrapper(v8::Handle<v8::Value> wrapper);

id unwrapObjcObject(v8::Handle<v8::Context> context, v8::Handle<v8::Value> value);
v8::Handle<v8::Function> wrapBlock(id object);
id unwrapBlock(v8::Handle<v8::Object> object);

Class BlockClass();