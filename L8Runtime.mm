//
//  V8Context.m
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <objc/runtime.h>

#import "L8Runtime_Private.h"
#import "L8RuntimeDelegate.h"
#import "L8Value_Private.h"
#import "L8Reporter_Private.h"
#import "L8WrapperMap.h"

#import "NSString+L8.h"

#include "v8.h"

static L8Runtime *g_sharedRuntimeInstance = nil;


@interface MyConsole : NSObject

@property (strong) NSString *name;

- (void)log:(NSString *)text;

@end
@implementation MyConsole

- (void)log:(NSString *)text
{
	NSLog(@"Console [%@]: %@",_name,text);
}

@end

@implementation L8Runtime {
	v8::Persistent<v8::Context> _v8context;
}

+ (void)initialize
{
	v8::V8::SetCaptureStackTraceForUncaughtExceptions(true);
}

- (id)init
{
    self = [super init];
    if(self) {
		_wrapperMap = [[L8WrapperMap alloc] initWithRuntime:self];
	}
    return self;
}

+ (L8Runtime *)contextWithV8Context:(v8::Handle<v8::Context>)v8context;
{
	if(v8context.IsEmpty())
		return nil;

	v8::Local<v8::Value> data = v8context->GetEmbedderData(0);
	v8::External *ext = v8::External::Cast(*data);
	L8Runtime *context = (__bridge L8Runtime *)ext->Value();

	return context;
}

void ObjCConstructor(const v8::FunctionCallbackInfo<v8::Value>& info)
{
	if(!info.This()->GetInternalField(0).IsEmpty())
		return;

	NSLog(@"ConsoleConstruct, Holder %@",[NSString stringWithV8Value:info.Holder()]);
	NSLog(@"This: %@",[NSString stringWithV8Value:info.This()]);
	for(int i = 0; i < info.Length(); i++)
		NSLog(@"Argument %d: %@",i,[NSString stringWithV8Value:info[i]]);

	id object = [[MyConsole alloc] init];
	info.This()->SetInternalField(0, v8::External::New((__bridge_retained void *)object));

	info.GetReturnValue().Set(true);
}

void ObjCMethodCall(const v8::FunctionCallbackInfo<v8::Value>& info)
{
	NSLog(@"ObjCMethodCall, Holder %@, name '%@'",
		  [NSString stringWithV8Value:info.Holder()],
		  [NSString stringWithV8Value:info.Callee()->GetName()]);

	NSLog(@"This: %@",[NSString stringWithV8Value:info.This()]);
	for(int i = 0; i < info.Length(); i++)
		NSLog(@"Argument %d: %@",i,[NSString stringWithV8Value:info[i]]);
	NSLog(@"Is Cons: %d",info.IsConstructCall());

	id object = (__bridge id)  v8::External::Cast(*(info.This()->GetInternalField(0)))->Value();
	NSLog(@"Wrapped object: %@",object);

	info.GetReturnValue().Set(true);
}

void ObjCNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	NSLog(@"Named prop setter callback for %@, val %@, data %@",
		  [NSString stringWithV8Value:property],
		  [NSString stringWithV8Value:value],
		  [NSString stringWithV8Value:info.Data()]);

	id object = (__bridge id)  v8::External::Cast(*(info.This()->GetInternalField(0)))->Value();
	NSLog(@"Wrapped object: %@",object);
}

void ObjCNamedPropertyGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	NSLog(@"Named prop getter callback for %@, data %@",
		  [NSString stringWithV8Value:property],
		  [NSString stringWithV8Value:info.Data()]);

	id object = (__bridge id)  v8::External::Cast(*(info.This()->GetInternalField(0)))->Value();
	NSLog(@"Wrapped object: %@",object);
}

void ObjCIndexedPropertySetter(uint32_t index, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	NSLog(@"indexed property setter on index %u",index);
}

void ObjCIndexedPropertyGetter(uint32_t index, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	NSLog(@"indexed property getter on index %u",index);
}

void ObjCAccessorSetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void> &info)
{
	NSLog(@"setter");
}

void ObjCAccessorGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value> &info)
{
	NSLog(@"getter for %@, data %@, this %@",[NSString stringWithV8Value:property],[NSString stringWithV8Value:info.Data()],[NSString stringWithV8Value:info.This()]);
}


- (void)start
{
	if(!_delegate)
		@throw [NSException exceptionWithName:@"InvalidArgumentException"
									   reason:@"delegate is not set"
									 userInfo:nil];

	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope mainHandleScope(isolate);

	// Create the context
	v8::Local<v8::Context> context = v8::Context::New(isolate);
	context->SetEmbedderData(0, v8::External::New((__bridge void *)self));
	_v8context.Reset(isolate, context);

	// Start the context scope
	v8::Context::Scope contextScope(isolate,_v8context);
/*
////////////////////////////////

	v8::Handle<v8::FunctionTemplate> objcClassTemplate = v8::FunctionTemplate::New();
	objcClassTemplate->SetCallHandler(ObjCConstructor); // can be with data

	v8::Handle<v8::ObjectTemplate> instanceTemplate = objcClassTemplate->InstanceTemplate();
	instanceTemplate->SetInternalFieldCount(1);
	instanceTemplate->SetNamedPropertyHandler(ObjCNamedPropertyGetter, ObjCNamedPropertySetter); // query (attribs), deleter (true/false), enumerator (indices), data
	instanceTemplate->SetIndexedPropertyHandler(ObjCIndexedPropertyGetter, ObjCIndexedPropertySetter); // query (attribs), deleter (true/false), enumerator (indices), data

	v8::Handle<v8::FunctionTemplate> objcMethodTemplate = v8::FunctionTemplate::New();
	//objcMethodTemplate->InstanceTemplate()->SetInternalFieldCount(1);
	objcMethodTemplate->SetCallHandler(ObjCMethodCall); // can be with data

////////////////////////////////

	MyConsole *console = [[MyConsole alloc] init];
	console.name = @"Hello";

	v8::Handle<v8::FunctionTemplate> consoleTemplate = v8::FunctionTemplate::New();
	consoleTemplate->Inherit(objcClassTemplate);
	consoleTemplate->SetClassName([[console className] V8String]);

	v8::Handle<v8::ObjectTemplate> prototypeTemplate = consoleTemplate->PrototypeTemplate();
	// Every method
	v8::Handle<v8::Function> logFunc = objcMethodTemplate->GetFunction();
	logFunc->SetName([@"log" V8String]);
//	logFunc->SetInternalField(0, [@"log2" V8String]);
	prototypeTemplate->Set([@"log" V8String], logFunc);

	// Must do this again
	v8::Handle<v8::ObjectTemplate> iTemplate = consoleTemplate->InstanceTemplate();
	iTemplate->SetInternalFieldCount(1);
	iTemplate->SetAccessor([@"name" V8String], ObjCAccessorGetter, ObjCAccessorSetter, [@"SomeData" V8String]);
	// SetAccessor(name, ObjCAccessorGetter, ObjCAccessorSetter, data, accesscontrol, propertyattrib, signature)

	// The class (constructor)
	v8::Handle<v8::Function> function = consoleTemplate->GetFunction();

	// An instance
	v8::Handle<v8::Object> instance = function->NewInstance(); // can haz argc+argv

	// Always set the representing object
	instance->SetInternalField(0, v8::External::New((__bridge void *)console));

	// Set an instance, for an instance (obv). (Instance wrapper)
	self[@"console"] = [L8Value valueWithV8Value:instance];

	// Set function to make available as class (Class wrapper)
	self[@"Console"] = [L8Value valueWithV8Value:function];

//	NSLog(@"Return from new in objc: %@",[self evaluateScript:@"console.log('Hello','World');" withName:@"test.js"]);
	NSLog(@"Return from new in js: %@",[self evaluateScript:@"(new Console()).log('Hello');" withName:@"test2.js"]);

////////////////////////////////
*/
	// Begin communicating with the delegate
	if([_delegate respondsToSelector:@selector(runtimeDidFinishCreatingContext:)])
		[_delegate runtimeDidFinishCreatingContext:self];

	if([_delegate respondsToSelector:@selector(runtimeWillRunMain:)])
		[_delegate runtimeWillRunMain:self];

	// Call javascript main()
	//[[self globalObject] invokeMethod:@"main"
	//					withArguments:@[]];

	if([_delegate respondsToSelector:@selector(runtimeDidRunMain:)])
		[_delegate runtimeDidRunMain:self];
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
	v8::HandleScope handleScope(isolate);
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
	v8::HandleScope handleScope(isolate);
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

		return [L8Value valueWithV8Value:retVal];
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
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::Local<v8::Context> localContext = isolate->GetCurrentContext();

	return [self contextWithV8Context:localContext];
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

- (L8Value *)objectForKeyedSubscript:(id)key
{
	return [self globalObject][key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key
{
	[self globalObject][key] = object;
}

- (v8::Local<v8::Context>)V8Context
{
	return v8::Handle<v8::Context>::New(v8::Isolate::GetCurrent(), _v8context);
//	return v8::Isolate::GetCurrent()->GetCurrentContext();
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

@end