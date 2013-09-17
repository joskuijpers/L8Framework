//
//  ObjCCallback.m
//  V8Test
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "ObjCCallback.h"

#import "L8Runtime_Private.h"
#import "L8Value_Private.h"
#import "ObjCRuntime+L8.h"

#include <objc/runtime.h>
#include "v8.h"

enum CallbackType {
	CALLBACK_INSTANCE_METHOD,
	CALLBACK_CLASS_METHOD,
	CALLBACK_BLOCK
};

v8::Handle<v8::Object> ObjCCallbackFunctionForInvocation(L8Runtime *runtime,
														NSInvocation *invocation,
														CallbackType type,
													Class instanceClass,
													const char *signatueWithObjCClasses)
{
	NSLog(@"ObjCCallbackFunctionForInvocation with invocation %@, class %s and signatue %s",invocation,class_getName(instanceClass),signatueWithObjCClasses);

	return v8::Object::New();
}

v8::Handle<v8::Object> ObjCCallbackFunctionForMethod(L8Runtime *runtime,
													Class cls,
													Protocol *protocol,
													BOOL isInstanceMethod,
													SEL sel,
													const char *types)
{
	NSInvocation *invocation;
	NSMethodSignature *signature;

	signature = [NSMethodSignature signatureWithObjCTypes:types];
	invocation = [NSInvocation invocationWithMethodSignature:signature];

	invocation.selector = sel;
	if(!isInstanceMethod)
		invocation.target = cls;

	return ObjCCallbackFunctionForInvocation(runtime,
											 invocation,
											 isInstanceMethod ? CALLBACK_INSTANCE_METHOD : CALLBACK_CLASS_METHOD,
											 isInstanceMethod ? cls : nil,
											 _protocol_getMethodTypeEncoding(protocol, sel, YES, isInstanceMethod));
}

v8::Handle<v8::Object> ObjCCallbackFunctionForBlock(L8Runtime *runtime, id target)
{
	if(!_Block_has_signature((__bridge void *)target)) {
		NSLog(@"returning supposed empty");
		return v8::Object::New();
	}

	const char *signature = _Block_signature((__bridge void *)target);

	NSInvocation *invocation;
	NSMethodSignature *methodSignature;

	methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

	id targetCopy = [target copy];
	invocation.target = targetCopy;

	return ObjCCallbackFunctionForInvocation(runtime,
											 invocation,
											 CALLBACK_BLOCK,
											 Nil,
											 signature);
}

