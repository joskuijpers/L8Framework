//
//  ObjCCallback.h
//  V8Test
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#include "v8.h"

@class L8Runtime;

v8::Handle<v8::Object> ObjCCallbackFunctionForMethod(L8Runtime *runtime,
													Class cls,
													Protocol *protocol,
													BOOL isInstanceMethod,
													SEL sel,
													const char *types);
v8::Handle<v8::Object> ObjCCallbackFunctionForBlock(L8Runtime *runtime, id block);

