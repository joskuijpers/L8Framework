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
#import "NSString+L8.h"
#import "ObjCRuntime+L8.h"
#import "L8WrapperMap.h"

#include <objc/runtime.h>
#include "v8.h"

const char *createStringFromV8Value(v8::Handle<v8::Value> value)
{
	char *buffer;
	v8::Handle<v8::String> v8String;

	if(!value->IsString())
		return NULL;
	v8String = value->ToString();

	buffer = (char *)malloc(v8String->Length()+1);
	v8String->WriteUtf8(buffer);

	return buffer;
}

SEL selectorFromV8Value(v8::Handle<v8::Value> value)
{
	const char *selName;
	SEL selector;

	selName = createStringFromV8Value(value);
	selector = sel_registerName(selName);
	free((void *)selName);

	return selector;
}

void objCSetInvocationArgument(NSInvocation *invocation, int index, L8Value *val)
{
	// Discard too many arguments
	// TODO: what to do with vararg!
	if(index >= invocation.methodSignature.numberOfArguments)
		return;

	const char *type = [invocation.methodSignature getArgumentTypeAtIndex:index];

	// TODO add range checks
	switch(*type) {
		case 'c': { // char (8)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			int8_t value = [[val toNumber] charValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'i': { // int
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			int32_t value = [[val toNumber] intValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 's': { // short (16)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			int16_t value = [[val toNumber] shortValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'l': { // long (32)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			long value = [[val toNumber] longValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'q': { // long long (64)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			int64_t value = [[val toNumber] longLongValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'C': { // unsigned char (8)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			uint8_t value = [[val toNumber] unsignedCharValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'I': { // unsigned int
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			uint32_t value = [[val toNumber] unsignedIntValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'S': { // unsigned short (16)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			uint16_t value = [[val toNumber] unsignedShortValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'L': { // unsigned long (32)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			unsigned long value = [[val toNumber] unsignedLongValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'Q': { // unsigned long long (64)
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			uint64_t value = [[val toNumber] unsignedLongLongValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}

		case 'f': { // float
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			float value = [[val toNumber] floatValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'd': { // double
			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			double value = [[val toNumber] doubleValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}

		case 'B': { // bool or _Bool
			if(![val isBoolean])
				v8::Exception::TypeError(v8::String::New("The implementation requests a boolean"));

			bool value = [[val toNumber] boolValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'v': // void
			break;
		case '*': { // char *
			if(![val isString])
				v8::Exception::TypeError(v8::String::New("The implementation requests a string"));

			const char *value = [[val toString] UTF8String];
			[invocation setArgument:&value
							atIndex:index];
		}
		case '@': { // object
			id value = [val toObject];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case '#': // Class
		case ':': // SEL
		case '^': // pointer
		case '?': // Unknown (also function pointers)
		default:
			assert(0 && "Type not implemented");
			break;
	}
}

v8::Handle<v8::Value> objCInvocation(NSInvocation *invocation, const char *neededReturnType = NULL)
{
	@autoreleasepool {
		[invocation invoke];
	}

	unsigned long retLength = invocation.methodSignature.methodReturnLength;
	const char *returnType = invocation.methodSignature.methodReturnType;
	L8Value *result;

	if(neededReturnType) {
		assert(*returnType == *neededReturnType);

		// TODO: are there any other types with more info?
		assert(strlen(neededReturnType) == 1 || *neededReturnType == '@');
	}

	switch(*returnType) {
		case 'c': // char (8)
		case 'i': // int
		case 's': // short (16)
		case 'l': { // long (32)
			int32_t value;
			assert(retLength <= 4);

			[invocation getReturnValue:&value];
			result = [L8Value valueWithInt32:value];
			break;
		}
		case 'q': // long long (64)
			@throw [NSException exceptionWithName:NSRangeException reason:@"JavaScript does not support long long" userInfo:nil];

		case 'C': // unsigned char (8)
		case 'I': // unsigned int
		case 'S': // unsigned short (16)
		case 'L': { // unsigned long (32)
			uint32_t value;
			assert(retLength <= 4);

			[invocation getReturnValue:&value];
			result = [L8Value valueWithUInt32:value];
			break;
		}
		case 'Q': // unsigned long long (64)
			@throw [NSException exceptionWithName:NSRangeException reason:@"JavaScript does not support long long" userInfo:nil];

		case 'f': { // float
			float value;
			[invocation getReturnValue:&value];
			result = [L8Value valueWithDouble:value];
			break;
		}
		case 'd': { // double
			double value;
			[invocation getReturnValue:&value];
			result = [L8Value valueWithDouble:value];
			break;
		}

		case 'B': { // bool or _Bool
			bool value;
			[invocation getReturnValue:&value];
			result = [L8Value valueWithBool:value];
			break;
		}
		case 'v': // void
			return v8::Undefined();
		case '*': { // char *
			char *string;
			[invocation getReturnValue:&string];
			result = [L8Value valueWithObject:@(string)];
			break;
		}
		case '@': { // object
			id __unsafe_unretained object;
			assert(retLength == sizeof(id));

			[invocation getReturnValue:&object];

			// has needed return type, which must not be a block
			if(neededReturnType && strlen(neededReturnType) > 1) {
				if(*(returnType+1) == '?' && [object isKindOfClass:BlockClass()]) {
					v8::Handle<v8::Function> function = wrapBlock(object);
					return function;
				} else {
					size_t length = strlen(neededReturnType);
					char *className = (char *)malloc(length-3+1); // minus @"", plus \0
					memcpy(className, neededReturnType+2, length-3);
					className[length-3] = 0;

//					Class cls = objc_getClass(className);
					free(className);

					result = [L8Value valueWithObject:object];
				}
			} else
				result = [L8Value valueWithObject:object];

			break;
		}
		case '#': // Class
		case ':': // SEL
			NSLog(@"Class and SEL not implemented");
			return v8::Undefined();
		case '^': // pointer
			NSLog(@"Pointer to %s",returnType+1);
		case '?': // Unknown (also function pointers)
		default:
			assert(0 && "A return type is not implemented");
	}

	return [result V8Value];
}

void ObjCConstructor(const v8::FunctionCallbackInfo<v8::Value>& info)
{
	const char *className;
	Class cls;
	SEL selector;
	id object;
	id __unsafe_unretained resultObject;
	v8::HandleScope localScope(info.GetIsolate());

	NSMethodSignature *methodSignature;
	NSInvocation *invocation;

	className = createStringFromV8Value(info.Data().As<v8::String>());
	cls = objc_getClass(className);

	selector = @selector(init);
	Method m = class_getInstanceMethod(cls, selector);
	const char *enc = method_getTypeEncoding(m);
	NSLog(@"encoding %s",enc);

	methodSignature = [NSMethodSignature methodSignatureForSelector:selector];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = selector;

	// TODO handle multiple init methods and arguments
	for(int i = 0; i < info.Length(); i++) {
		L8Value *argument = [L8Value valueWithV8Value:info[i]];

		id obj = [argument toObject];
		NSLog(@"Argument %d: %@",i,argument);

		objCSetInvocationArgument(invocation, i+2, argument);
	}

	// Allocate...
	object = [cls alloc];
	invocation.target = object;

	// and initialize
	@autoreleasepool {
		[invocation invoke];
		[invocation getReturnValue:&resultObject];
		info.This()->SetInternalField(0, makeWrapper([[L8Runtime currentRuntime] V8Context], resultObject));
	}

	info.GetReturnValue().Set(info.This());
}

void ObjCMethodCall(const v8::FunctionCallbackInfo<v8::Value>& info)
{
	SEL selector;
	id object;
	const char *types;
	bool isClassMethod = false;
	NSMethodSignature *methodSignature;
	NSInvocation *invocation;
	v8::Handle<v8::Array> extraData;
	v8::Handle<v8::Value> retVal;

	extraData = info.Data().As<v8::Array>();
	selector = selectorFromV8Value(extraData->Get(0));
	types = createStringFromV8Value(extraData->Get(1));
	isClassMethod = extraData->Get(2)->ToBoolean()->Value();

	methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	free((void *)types);

	// Class methods must use the function (This) name to find the class meta object
	if(isClassMethod) {
		v8::Handle<v8::Function> function = info.This().As<v8::Function>();
		object = objc_getClass(createStringFromV8Value(function->GetName()));
	} else
		object = objectFromWrapper(info.This()->GetInternalField(0));

	invocation.selector = selector;
	if(!info.IsConstructCall())
		invocation.target = object;

	for(int i = 0; i < info.Length(); i++) {
		L8Value *val = [L8Value valueWithV8Value:info[i]];
		objCSetInvocationArgument(invocation,i+2,val);
	}

	[invocation retainArguments];

	retVal = objCInvocation(invocation);
	info.GetReturnValue().Set(retVal);
}

void ObjCBlockCall(const v8::FunctionCallbackInfo<v8::Value>& info)
{
	id block = (__bridge id)info.Data().As<v8::External>()->Value();

	NSMethodSignature *methodSignature;
	NSInvocation *invocation;

	methodSignature = [NSMethodSignature signatureWithObjCTypes:_Block_signature((__bridge void *)block)];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.target = block;

	// Set arguments (+1)
	for(int i = 0; i < info.Length(); i++) {
		L8Value *val = [L8Value valueWithV8Value:info[i]];
		objCSetInvocationArgument(invocation, i+1, val);
	}

	@autoreleasepool {
		[invocation invoke];
	}

	// TODO blocks can also have return values
}

void ObjCNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	[object setObject:[L8Value valueWithV8Value:value] forKeyedSubscript:[NSString stringWithV8String:property]];
}

void ObjCNamedPropertyGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	id value = [object objectForKeyedSubscript:[NSString stringWithV8String:property]];

	if(value)
		info.GetReturnValue().Set(objectToValue([L8Runtime currentRuntime], value));
}

void ObjCNamedPropertyQuery(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
	NSLog(@"property query");
}

void ObjCIndexedPropertySetter(uint32_t index, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	[object setObject:[L8Value valueWithV8Value:value] atIndexedSubscript:index];
}

void ObjCIndexedPropertyGetter(uint32_t index, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	id value = [object objectAtIndexedSubscript:index];

	if(value)
		info.GetReturnValue().Set(objectToValue([L8Runtime currentRuntime], value));
}

void ObjCIndexedPropertyQuery(uint32_t index, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
	NSLog(@"index %d query",index);
}

void ObjCAccessorSetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void> &info)
{
	SEL selector;
	id object;
	NSMethodSignature *methodSignature;
	NSInvocation *invocation;
	const char *types, *valueType;
	v8::Handle<v8::Array> extraData;
	v8::Handle<v8::Value> retVal;

	object = objectFromWrapper(info.This()->GetInternalField(0));
	extraData = info.Data().As<v8::Array>();

	// 0 = name, 1 = value type, 2 = getter SEL, 3 = getter types, 4 = setter SEL, 5 = setter types
	// TODO use valuetype to verify argument
	valueType = createStringFromV8Value(extraData->Get(1));
	free((void *)valueType);

	selector = selectorFromV8Value(extraData->Get(4));
	types = createStringFromV8Value(extraData->Get(5));

	methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
	free((void *)types);

	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = selector;
	invocation.target = object;

	if(invocation.methodSignature.numberOfArguments != 3) {
		// make JS exception
		assert(0 && "More parameters than arguments: not a setter called?");
	}

	L8Value *val = [L8Value valueWithV8Value:value];
	// TODO verify or transform class
	objCSetInvocationArgument(invocation,2,val);

	retVal = objCInvocation(invocation);

	info.GetReturnValue().Set(retVal);
}

void ObjCAccessorGetter(v8::Local<v8::String> property, const v8::PropertyCallbackInfo<v8::Value> &info)
{
	SEL selector;
	id object;
	NSMethodSignature *methodSignature;
	NSInvocation *invocation;
	const char *types, *returnType;
	v8::Handle<v8::Array> extraData;
	v8::Handle<v8::Value> retVal;

	object = objectFromWrapper(info.This()->GetInternalField(0));
	extraData = info.Data().As<v8::Array>();

	// 0 = name, 1 = value type, 2 = getter SEL, 3 = getter types, 4 = setter SEL, 5 = setter types
	returnType = createStringFromV8Value(extraData->Get(1));
	selector = selectorFromV8Value(extraData->Get(2));
	types = createStringFromV8Value(extraData->Get(3));

	methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
	free((void *)types);

	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = selector;
	invocation.target = object;

	if(invocation.methodSignature.numberOfArguments != 2) {
		// make JS exception
		assert(0 && "More parameters than arguments: not a getter called?");
	}

	retVal = objCInvocation(invocation,returnType);

	info.GetReturnValue().Set(retVal);
}

/*!
 * Called when an ObjC object stored in v8 will be released by v8.
 * This function causes an ObjC release on the object.
 */
void ObjCWeakReferenceCallback(v8::Isolate *isolate, v8::Persistent<v8::External> *persistent, void *parameter)
{
	v8::Local<v8::External> ext = v8::Local<v8::External>::New(isolate, *persistent);

#if 1 // Debug
	id wrappedObject = 	CFBridgingRelease(ext->Value());
	NSLog(@"Weakreferencecallback for object %@",wrappedObject);
#else
	CFRelease(ext->Value());
#endif
}