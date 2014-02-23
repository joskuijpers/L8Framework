//
//  V8Context.m
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <objc/runtime.h>

#import "L8Runtime_Private.h"
#import "L8Runtime_Debugging.h"
#import "L8Value_Private.h"
#import "L8Reporter_Private.h"
#import "L8WrapperMap.h"

#import "NSString+L8.h"

#include "v8.h"
#include "v8-debug.h"

@interface L8Runtime ()
- (id)init;
@end

@implementation L8Runtime {
	v8::Persistent<v8::Context> _v8context;
}

+ (void)initialize
{
	v8::V8::SetCaptureStackTraceForUncaughtExceptions(true);
}

+ (L8Runtime *)contextWithV8Context:(v8::Handle<v8::Context>)v8context;
{
	if(v8context.IsEmpty())
		return nil;

	v8::Handle<v8::External> data = v8context->GetEmbedderData(0).As<v8::External>();
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
		context->SetEmbedderData(0, v8::External::New((void *)CFBridgingRetain(self)));
		_v8context.Reset(isolate, context);

		// Start the context scope
		v8::Context::Scope contextScope(isolate,_v8context);

		// Create the wrappermap for the context
		_wrapperMap = [[L8WrapperMap alloc] initWithRuntime:self];
	}
	return self;
}

- (void)dealloc
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope mainScope(isolate);
	v8::Context::Scope contextScope(isolate,_v8context);
	v8::Handle<v8::Context> context = v8::Handle<v8::Context>::New(isolate, _v8context);

	v8::Handle<v8::External> selfStored = context->GetEmbedderData(0).As<v8::External>();
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
		[[L8Reporter sharedReporter] reportTryCatch:&tryCatch inIsolate:isolate];
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

	v8::Handle<v8::Script> script;
	{
		v8::TryCatch tryCatch;

		script = v8::Script::Compile([scriptData V8String], &scriptOrigin);
		if(script.IsEmpty()) {
			[[L8Reporter sharedReporter] reportTryCatch:&tryCatch inIsolate:isolate];
			return NO;
		}
	}

	{
		v8::TryCatch tryCatch;
		script->Run();

		if(tryCatch.HasCaught()) {
			[[L8Reporter sharedReporter] reportTryCatch:&tryCatch inIsolate:isolate];
			return NO;
		}
	}

	return YES;
}

- (L8Value *)evaluateScript:(NSString *)scriptData withName:(NSString *)name
{
	if(scriptData == nil)
		return nil;

	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);
	v8::ScriptOrigin scriptOrigin = v8::ScriptOrigin([name V8String]);

	v8::Handle<v8::Script> script;
	{
		v8::TryCatch tryCatch;

		script = v8::Script::Compile([scriptData V8String], &scriptOrigin);
		if(script.IsEmpty()) {
			[[L8Reporter sharedReporter] reportTryCatch:&tryCatch inIsolate:isolate];
			return nil;
		}
	}

	{
		v8::TryCatch tryCatch;
		v8::Handle<v8::Value> retVal = script->Run();

		if(tryCatch.HasCaught()) {
			[[L8Reporter sharedReporter] reportTryCatch:&tryCatch inIsolate:isolate];
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
	@throw [NSException exceptionWithName:@"NotImplemented" reason:@"Not Implemented" userInfo:nil];
	return nil;
}

+ (NSArray *)currentArguments
{
	@throw [NSException exceptionWithName:@"NotImplemented" reason:@"Not Implemented" userInfo:nil];
	return nil;
}

- (v8::Local<v8::Context>)V8Context
{
	return v8::Handle<v8::Context>::New(v8::Isolate::GetCurrent(), _v8context);
}

- (L8Value *)wrapperForObjCObject:(id)object
{
	@synchronized(_wrapperMap) {
		return [_wrapperMap JSWrapperForObject:object];
	}
}

- (L8Value *)wrapperForJSObject:(v8::Handle<v8::Value>)value
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

		v8::Handle<v8::Context> debugContext = v8::Debug::GetDebugContext();
		L8Runtime *runtime = (__bridge L8Runtime *)debugContext->GetEmbedderData(1).As<v8::External>()->Value();

		v8::Handle<v8::Context> context = v8::Handle<v8::Context>::New(isolate, [runtime V8Context]);
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
