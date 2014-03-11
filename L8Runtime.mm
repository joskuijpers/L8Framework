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

#import <objc/runtime.h>

#import "L8Runtime_Private.h"
#import "L8Runtime_Debugging.h"
#import "L8Value_Private.h"
#import "L8Reporter_Private.h"
#import "L8WrapperMap.h"
#import "L8ManagedValue_Private.h"

#import "NSString+L8.h"

#include "v8.h"
#include "v8-debug.h"

@interface L8Runtime ()
- (id)init;
@end

@implementation L8Runtime {
	v8::Persistent<v8::Context> _v8context;
	NSMapTable *_managedObjectGraph;
}

+ (void)initialize
{
	v8::V8::SetCaptureStackTraceForUncaughtExceptions(true);
}

+ (L8Runtime *)contextWithV8Context:(v8::Local<v8::Context>)v8context;
{
	if(v8context.IsEmpty())
		return nil;

	v8::Local<v8::External> data = v8context->GetEmbedderData(0).As<v8::External>();
	L8Runtime *context = (__bridge L8Runtime *)data->Value();

	return context;
}

- (id)init
{
	self = [super init];
	if(self) {
		v8::Isolate *isolate = v8::Isolate::GetCurrent();
		v8::HandleScope mainScope(isolate);

		// Create the context
		v8::Local<v8::Context> context = v8::Context::New(isolate);
		context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_SELF, v8::External::New((void *)CFBridgingRetain(self)));
		_v8context.Reset(isolate, context);

		// Start the context scope
		v8::Context::Scope contextScope(isolate,_v8context);

		// Create the wrappermap for the context
		_wrapperMap = [[L8WrapperMap alloc] initWithRuntime:self];

		_managedObjectGraph = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality
														valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
															capacity:0];
	}
	return self;
}

- (void)dealloc
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope mainScope(isolate);
	v8::Context::Scope contextScope(isolate,_v8context);
	v8::Local<v8::Context> context = v8::Local<v8::Context>::New(isolate, _v8context);

	v8::Local<v8::External> selfStored = context->GetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_SELF).As<v8::External>();
	if(!selfStored.IsEmpty()) {
		CFRelease(selfStored->Value());
	}

	_v8context.Clear();
}

- (void)executeBlockInRuntime:(void(^)(L8Runtime *runtime))block
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);
	v8::Context::Scope contextScope(isolate,_v8context);

	v8::TryCatch tryCatch;

	block(self);

	if(tryCatch.HasCaught()) {
		[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
	}
}

- (BOOL)loadScriptAtPath:(NSString *)filePath
{
	NSError *error;
	NSString *data = [NSString stringWithContentsOfFile:filePath
											   encoding:NSUTF8StringEncoding
												  error:&error];
	if(error != NULL)
		return NO;

	return [self loadScript:data withName:filePath];
}

- (BOOL)loadScript:(NSString *)scriptData withName:(NSString *)name
{
	if(scriptData == nil)
		return NO;

	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);
	v8::ScriptOrigin scriptOrigin = v8::ScriptOrigin([name V8String]);

	v8::Local<v8::Script> script;
	{
		v8::TryCatch tryCatch;

		script = v8::Script::Compile([scriptData V8String], &scriptOrigin);
		if(script.IsEmpty()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return NO;
		}
	}

	{
		v8::TryCatch tryCatch;
		script->Run();

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return NO;
		}
	}

	return YES;
}

- (L8Value *)evaluateScript:(NSString *)scriptData
{
	return [self evaluateScript:scriptData withName:@""];
}

- (L8Value *)evaluateScript:(NSString *)scriptData withName:(NSString *)name
{
	if(scriptData == nil)
		return nil;

	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);
	v8::ScriptOrigin scriptOrigin = v8::ScriptOrigin([name V8String]);

	v8::Local<v8::Script> script;
	{
		v8::TryCatch tryCatch;

		script = v8::Script::Compile([scriptData V8String], &scriptOrigin);
		if(script.IsEmpty()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return nil;
		}
	}

	{
		v8::TryCatch tryCatch;
		v8::Local<v8::Value> retVal = script->Run();

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return nil;
		}

		return [L8Value valueWithV8Value:localScope.Close(retVal)];
	}

	return nil;
}

- (L8Value *)globalObject
{
	v8::Local<v8::Context> localContext = v8::Local<v8::Context>::New(v8::Isolate::GetCurrent(),_v8context);
	return [L8Value valueWithV8Value:localContext->Global()];
}

+ (L8Runtime *)currentRuntime
{
	v8::Local<v8::Context> context = v8::Isolate::GetCurrent()->GetCurrentContext();
	return [self contextWithV8Context:context];
}

+ (L8Value *)currentThis
{
	v8::Local<v8::Value> thisObject;
	v8::Local<v8::Context> context;

	context = v8::Isolate::GetCurrent()->GetCurrentContext();
	if(context.IsEmpty())
		return nil;

	// Retrieve the object from the store
	thisObject = context->GetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_THIS);
	if(thisObject.IsEmpty() || thisObject->IsNull())
		return nil;

	assert(thisObject->IsObject());

	return [L8Value valueWithV8Value:thisObject];
}

+ (L8Value *)currentCallee
{
	v8::Local<v8::Value> thisObject;
	v8::Local<v8::Context> context;

	context = v8::Isolate::GetCurrent()->GetCurrentContext();
	if(context.IsEmpty())
		return nil;

	// Retrieve the function from the store
	thisObject = context->GetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_CALLEE);
	if(thisObject.IsEmpty() || thisObject->IsNull())
		return nil;

	// Callee should be a function
	assert(thisObject->IsFunction());

	return [L8Value valueWithV8Value:thisObject];
}

+ (NSArray *)currentArguments
{
	v8::Local<v8::Value> thisObject;
	v8::Local<v8::Context> context;
	v8::Local<v8::Array> argArray;
	NSMutableArray *arguments;

	context = v8::Isolate::GetCurrent()->GetCurrentContext();
	if(context.IsEmpty())
		return nil;

	// Retrieve the function from the store
	thisObject = context->GetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_ARGS);
	if(thisObject.IsEmpty() || thisObject->IsNull())
		return nil;

	// Callee should be an array
	assert(thisObject->IsArray());

	argArray = v8::Local<v8::Array>::Cast(thisObject);
	arguments = [[NSMutableArray alloc] init];

	for(int i = 0; i < argArray->Length(); ++i)
		arguments[i] = [L8Value valueWithV8Value:argArray->Get(i)];

	return arguments;
}

- (v8::Local<v8::Context>)V8Context
{
	return v8::Local<v8::Context>::New(v8::Isolate::GetCurrent(), _v8context);
}

- (L8Value *)wrapperForObjCObject:(id)object
{
	@synchronized(_wrapperMap) {
		return [_wrapperMap JSWrapperForObject:object];
	}
}

- (L8Value *)wrapperForJSObject:(v8::Local<v8::Value>)value
{
	@synchronized(_wrapperMap) {
		return [_wrapperMap ObjCWrapperForValue:value];
	}
}

void L8RuntimeDebugMessageDispatchHandler()
{
	dispatch_async(dispatch_get_main_queue(), ^{
		v8::Isolate *isolate = v8::Isolate::GetCurrent();
		v8::HandleScope localScope(isolate);

		v8::Local<v8::Context> debugContext = v8::Debug::GetDebugContext();
		L8Runtime *runtime = (__bridge L8Runtime *)debugContext->GetEmbedderData(1).As<v8::External>()->Value();

		v8::Local<v8::Context> context = v8::Local<v8::Context>::New(isolate, [runtime V8Context]);
		v8::Context::Scope contextScope(context);

		v8::Debug::ProcessDebugMessages();
	});
}

- (void)enableDebugging
{
	if(_debuggerPort == 0) {
		_debuggerPort = 12228; // L=12 V=22 8, LFV8
	}

	v8::Debug::EnableAgent("sphere_runtime", _debuggerPort, _waitForDebugger);
	v8::Debug::SetDebugMessageDispatchHandler(L8RuntimeDebugMessageDispatchHandler);

	v8::HandleScope localScope(v8::Isolate::GetCurrent());
	v8::Debug::GetDebugContext()->SetEmbedderData(1, v8::External::New((__bridge void *)self));
}

- (void)disableDebugging
{
	v8::Debug::DisableAgent();
}

- (id)getInternalObjCObject:(id)object
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);
	v8::Local<v8::Context> localContext;

	localContext = v8::Local<v8::Context>::New(isolate, _v8context);

	if([object isKindOfClass:[L8ManagedValue class]]) {
		id temp;
		L8Value *value;

		value = [(L8ManagedValue *)object value];
		temp = unwrapObjcObject(localContext, [value V8Value]);

		if(temp)
			return temp;
		return object;
	}

	if([object isKindOfClass:[L8Value class]]) {
		L8Value *value;

		value = (L8Value *)object;
		object = unwrapObjcObject(localContext, [value V8Value]);
	}

	return object;
}

- (void)addManagedReference:(id)object withOwner:(id)owner
{
	NSMapTable *objectsOwned;
	const void *key;
	size_t count;

	if([object isKindOfClass:[L8ManagedValue class]])
		[object didAddOwner:owner];

	object = [self getInternalObjCObject:object];
	owner = [self getInternalObjCObject:owner];

	if(object == nil || owner == nil)
		return;

	objectsOwned = [_managedObjectGraph objectForKey:object];
	if(!objectsOwned) {
		objectsOwned = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality
												 valueOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality
													 capacity:1];

		[_managedObjectGraph setObject:objectsOwned forKey:owner];
	}

	key = (__bridge void *)object;
	count = reinterpret_cast<size_t>(NSMapGet(objectsOwned, key));
	NSMapInsert(objectsOwned, key, reinterpret_cast<void *>(count + 1));
}

- (void)removeManagedReference:(id)object withOwner:(id)owner
{
	NSMapTable *objectsOwned;
	const void *key;
	size_t count;

	if([object isKindOfClass:[L8ManagedValue class]])
		[object didRemoveOwner:owner];

	object = [self getInternalObjCObject:object];
	owner = [self getInternalObjCObject:owner];

	if(object == nil || owner == nil)
		return;

	objectsOwned = [_managedObjectGraph objectForKey:object];
	if(!objectsOwned)
		return;

	key = (__bridge void *)object;
	count = reinterpret_cast<size_t>(NSMapGet(objectsOwned, key));
	if(count > 1) {
		NSMapInsert(objectsOwned, key, reinterpret_cast<void *>(count - 1));
		return;
	}

	if(count == 1)
		NSMapRemove(objectsOwned, key);

	if(![objectsOwned count])
		[_managedObjectGraph removeObjectForKey:owner];
}

- (void)runGarbageCollector
{
	while(!v8::V8::IdleNotification()) {};
}

@end

@implementation L8Runtime (Subscripting)

- (L8Value *)objectForKeyedSubscript:(id)key
{
	return [self globalObject][key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key
{
	[self globalObject][key] = object;
}

@end
