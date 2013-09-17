//
//  L8Runtime_Private.h
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8Runtime.h"
#include "v8.h"

@class L8WrapperMap;

@interface L8Runtime ()

@property (strong,readonly) L8WrapperMap *wrapperMap;

+ (L8Runtime *)contextWithV8Context:(v8::Handle<v8::Context>)v8context;
- (v8::Local<v8::Context>)V8Context;

- (L8Value *)wrapperForObjCObject:(id)object;
- (L8Value *)wrapperForJSObject:(v8::Handle<v8::Value>)value;

@end
