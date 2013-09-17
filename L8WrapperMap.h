//
//  L8WrapperMap.h
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "v8.h"

@class L8Runtime, L8Value;

@interface L8WrapperMap : NSObject

- (instancetype)initWithRuntime:(L8Runtime *)runtime;

- (L8Value *)JSWrapperForObject:(id)object;
- (L8Value *)ObjCWrapperForValue:(v8::Handle<v8::Value>)value;

@end

extern id unwrapObjcObject(v8::Handle<v8::Context> context, v8::Handle<v8::Value> value);
extern id unwrapBlock(v8::Handle<v8::Object> object);