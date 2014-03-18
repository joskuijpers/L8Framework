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

#import <objc/runtime.h>

#import "L8Context_Private.h"
#import "L8Context_Debugging.h"
#import "L8VirtualMachine_Private.h"
#import "L8Value_Private.h"
#import "L8Reporter_Private.h"
#import "L8WrapperMap.h"
#import "L8ManagedValue_Private.h"

#import "NSString+L8.h"

#include "v8.h"
#include "v8-debug.h"

using namespace v8;

@interface L8Context ()
- (id)init;
@end

@implementation L8Context {
	Persistent<Context> _v8context;
}

+ (instancetype)contextWithV8Context:(Local<Context>)v8context;
{
	if(v8context.IsEmpty())
		return nil;

	Local<External> data = v8context->GetEmbedderData(0).As<External>();
	L8Context *context = (__bridge L8Context *)data->Value();

	return context;
}

- (instancetype)init
{
	return [self initWithVirtualMachine:[[L8VirtualMachine alloc] init]];
}

- (instancetype)initWithVirtualMachine:(L8VirtualMachine *)virtualMachine
{
	self = [super init];
	if(self) {
		Isolate *isolate = virtualMachine.V8Isolate;
		HandleScope mainScope(isolate);

		_virtualMachine = virtualMachine;

		// Create the context
		Local<Context> context = Context::New(isolate);
		context->SetEmbedderData(L8_CONTEXT_EMBEDDER_DATA_SELF, External::New(isolate,(__bridge void *)self));
		_v8context.Reset(isolate, context);

		// Start the context scope
		Context::Scope contextScope(context);

		// Create the wrappermap for the context
		_wrapperMap = [[L8WrapperMap alloc] initWithContext:self];
	}
	return self;
}

- (void)dealloc
{
	Isolate *isolate = _virtualMachine.V8Isolate;
	HandleScope mainScope(isolate);
	Local<Context> context = Local<Context>::New(isolate, _v8context);
	Context::Scope contextScope(context);

	_v8context.ClearAndLeak();
}

- (void)executeBlockInContext:(void(^)(L8Context *context))block
{
	Isolate *isolate = _virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	Context::Scope contextScope(Local<Context>::New(isolate,_v8context));

	TryCatch tryCatch;

	block(self);

	if(tryCatch.HasCaught()) {
		[L8Reporter reportTryCatch:&tryCatch inContext:self];
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

	Isolate *isolate = _virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	ScriptOrigin scriptOrigin = ScriptOrigin([name V8String]);

	Local<Script> script;
	{
		TryCatch tryCatch;

		script = Script::Compile([scriptData V8String], &scriptOrigin);
		if(script.IsEmpty()) {
			[L8Reporter reportTryCatch:&tryCatch inContext:self];
			return NO;
		}
	}

	{
		TryCatch tryCatch;
		script->Run();

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inContext:self];
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

	Isolate *isolate = _virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	ScriptOrigin scriptOrigin = ScriptOrigin([name V8String]);

	Local<Script> script;
	{
		TryCatch tryCatch;

		script = Script::Compile([scriptData V8String], &scriptOrigin);
		if(script.IsEmpty()) {
			[L8Reporter reportTryCatch:&tryCatch inContext:self];
			return nil;
		}
	}

	{
		TryCatch tryCatch;
		Local<Value> retVal = script->Run();

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inContext:self];
			return nil;
		}

		return [L8Value valueWithV8Value:localScope.Escape(retVal) inContext:self];
	}

	return nil;
}

- (L8Value *)globalObject
{
	Isolate *isolate = _virtualMachine.V8Isolate;
	Local<Context> localContext = Local<Context>::New(isolate,_v8context);
	return [L8Value valueWithV8Value:localContext->Global() inContext:self];
}

+ (instancetype)currentContext
{
	return [self contextWithV8Context:Isolate::GetCurrent()->GetCurrentContext()];
}

+ (L8Value *)currentThis
{
	Local<Value> thisObject;
	Local<Context> v8context;
	L8Context *context;

	v8context = Isolate::GetCurrent()->GetCurrentContext();
	if(v8context.IsEmpty())
		return nil;

	// Retrieve the object from the store
	thisObject = v8context->GetEmbedderData(L8_CONTEXT_EMBEDDER_DATA_CB_THIS);
	if(thisObject.IsEmpty() || thisObject->IsNull())
		return nil;

	context = [self contextWithV8Context:v8context];

	assert(thisObject->IsObject());

	return [L8Value valueWithV8Value:thisObject inContext:context];
}

+ (L8Value *)currentCallee
{
	Local<Value> thisObject;
	Local<Context> v8context;
	L8Context *context;

	v8context = Isolate::GetCurrent()->GetCurrentContext();
	if(v8context.IsEmpty())
		return nil;

	// Retrieve the function from the store
	thisObject = v8context->GetEmbedderData(L8_CONTEXT_EMBEDDER_DATA_CB_CALLEE);
	if(thisObject.IsEmpty() || thisObject->IsNull())
		return nil;

	context = [self contextWithV8Context:v8context];

	// Callee should be a function
	assert(thisObject->IsFunction());

	return [L8Value valueWithV8Value:thisObject inContext:context];
}

+ (NSArray *)currentArguments
{
	Local<Value> thisObject;
	Local<Context> v8context;
	Local<Array> argArray;
	NSMutableArray *arguments;
	L8Context *context;

	v8context = Isolate::GetCurrent()->GetCurrentContext();
	if(v8context.IsEmpty())
		return nil;

	thisObject = v8context->GetEmbedderData(L8_CONTEXT_EMBEDDER_DATA_CB_ARGS);
	if(thisObject.IsEmpty() || thisObject->IsNull())
		return nil;

	context = [self contextWithV8Context:v8context];

	// Callee should be an array
	assert(thisObject->IsArray());

	argArray = Local<Array>::Cast(thisObject);
	arguments = [[NSMutableArray alloc] init];

	for(int i = 0; i < argArray->Length(); ++i)
		arguments[i] = [L8Value valueWithV8Value:argArray->Get(i) inContext:context];

	return arguments;
}

- (Local<Context>)V8Context
{
	Isolate *isolate = _virtualMachine.V8Isolate;
	return Local<Context>::New(isolate, _v8context);
}

- (L8Value *)wrapperForObjCObject:(id)object
{
	@synchronized(_wrapperMap) {
		return [_wrapperMap JSWrapperForObject:object];
	}
}

- (L8Value *)wrapperForJSObject:(Local<Value>)value
{
	@synchronized(_wrapperMap) {
		return [_wrapperMap ObjCWrapperForValue:value];
	}
}

#pragma mark Debugging

void L8ContextDebugMessageDispatchHandler()
{
	dispatch_async(dispatch_get_main_queue(), ^{
		Isolate *isolate = Isolate::GetCurrent();
		HandleScope localScope(isolate);
		Local<Context> debugContext, v8context;
		L8Context *context;

		debugContext = Debug::GetDebugContext();
		context = (__bridge L8Context *)debugContext->GetEmbedderData(1).As<External>()->Value();

		v8context = context.V8Context; // if fails, use New(isolate,context) instead.
		Context::Scope contextScope(v8context);

		Debug::ProcessDebugMessages();
	});
}

- (void)enableDebugging
{
	Isolate *isolate = _virtualMachine.V8Isolate;
	HandleScope localScope(isolate);

	if(_debuggerPort == 0) {
		_debuggerPort = 12228; // L=12 V=22 8, LFV8
	}

	Debug::EnableAgent("sphere_context", _debuggerPort, _waitForDebugger);
	Debug::SetDebugMessageDispatchHandler(L8ContextDebugMessageDispatchHandler);

	Debug::GetDebugContext()->SetEmbedderData(1, External::New(isolate,(__bridge void *)self));
}

- (void)disableDebugging
{
	Debug::DisableAgent();
}

@end

@implementation L8Context (Subscripting)

- (L8Value *)objectForKeyedSubscript:(id)key
{
	return [self globalObject][key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key
{
	[self globalObject][key] = object;
}

@end
