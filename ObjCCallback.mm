//
//  ObjCCallback.m
//  L8Framework
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "ObjCCallback.h"

#include <string.h>
#include <objc/runtime.h>

#import "L8Runtime_Private.h"
#import "L8Value_Private.h"
#import "NSString+L8.h"
#import "ObjCRuntime+L8.h"
#import "L8WrapperMap.h"
#import "L8Exception_Private.h"

#include "v8.h"

/**
 * Creates a C string from given v8 value
 *
 * @param value The V8 value
 * @return A string. Must be freed!
 */
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

/**
 * Finds first position of given needle in haystack
 *
 * @param haystack String to search in
 * @param needle String to find
 * @param count Maximum length string to search in haystack
 * @return position or -1 if not found
 */
long strnpos(const char *haystack, const char *needle, long count)
{
	const char *p = strnstr(haystack, needle, count);
	if(p)
		return p - haystack;
	return -1;
}

void objCSetInvocationArgument(NSInvocation *invocation, int index, L8Value *val)
{
	// Discard too many arguments. These can be accessed through +[L8Runtime currentArguments]
	if(index >= invocation.methodSignature.numberOfArguments)
		return;

	const char *type = [invocation.methodSignature getArgumentTypeAtIndex:index];

	switch(*type) {
		case 'c': { // char (8)
			long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT8_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (int8)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'i': { // int
			long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (int)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 's': { // short (16)
			long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT16_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (int16)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'l': { // long (32)
			long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT32_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (int32)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'q': { // long long (64)
			long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT64_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (int64)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'C': { // unsigned char (8)
			unsigned long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT8_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (uint8)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'I': { // unsigned int
			unsigned long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (uint)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'S': { // unsigned short (16)
			unsigned long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT16_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (uint16)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'L': { // unsigned long (32)
			unsigned long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT32_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (uint32)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'Q': { // unsigned long long (64)
			unsigned long long value;

			if(![val isNumber])
				v8::Exception::TypeError(v8::String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT64_MAX)
				v8::Exception::RangeError(v8::String::New("Value exceeds native argument size (uint64)"));

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
			bool value = [val toBool];
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
			id value;
			Class objectClass = Nil;

			// Try to find the classname of the object
			if(*(type+1) == '"') {
				long length;
				char *className;

				// Retrieve a Class object from the information
				length = strnpos(type+2, "\"", strlen(type));
				className = strndup(type+2, length);
				objectClass = objc_getClass(className);
				free((void *)className);
			}

			if(objectClass == [L8Value class])
				value = val;
			else if(objectClass == [NSString class])
				value = valueToString([L8Runtime currentRuntime], [val V8Value]);
			else if(objectClass == [NSNumber class])
				value = valueToNumber([L8Runtime currentRuntime], [val V8Value]);
			else if(objectClass == [NSDate class])
				value = valueToDate([L8Runtime currentRuntime], [val V8Value]);
			else if(objectClass == [NSArray class])
				value = valueToArray([L8Runtime currentRuntime], [val V8Value]);
			else if(objectClass == [NSDictionary class])
				value = valueToObject([L8Runtime currentRuntime], [val V8Value]);
			else
				value = [val toObject];

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case '#': // Class
		case ':': // SEL
		case '^': // pointer
		case '?': // Unknown (also function pointers, eg blocks)
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
		case 'q': { // long long (64)
			int64_t value;

			[invocation getReturnValue:&value];
			if(value <= INT32_MAX)
				result = [L8Value valueWithInt32:(int32_t)value];
			else
				result = [L8Value valueWithDouble:value];

			break;
		}
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
		case 'Q': { // unsigned long long (64)
			uint64_t value;

			[invocation getReturnValue:&value];
			if(value <= UINT32_MAX)
				result = [L8Value valueWithUInt32:(uint32_t)value];
			else
				result = [L8Value valueWithDouble:value];

			break;
		}
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

			NSLog(@"Needed return type is '%s'",neededReturnType);

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
	__block SEL selector = nil;
	id object;
	id __unsafe_unretained resultObject;
	v8::HandleScope localScope(info.GetIsolate());

	NSMethodSignature *methodSignature;
	NSInvocation *invocation;

	className = createStringFromV8Value(info.Data().As<v8::String>());
	cls = objc_getClass(className);
	free((void *)className); className = NULL;

	// TODO find correct selector!
	// Implementation below sucks ballz. Make some algorithm to find
	// the best selector for given arguments for init

	// Look at all selectors, finding the correct init*
	forEachMethodInClass(cls, ^(Method method, BOOL *stop) {
		const char *selName, *enc;
		char *simpleEnc;

		// Find only selectors starting with 'init'
		selName = sel_getName(method_getName(method));
		if(strnpos(selName,"init",MAX(4, strlen(selName))) != 0)
		   return;

		// Get encoding
		enc = method_getTypeEncoding(method);

		// Remove all numbers
		simpleEnc = (char *)calloc(strlen(enc)+1,sizeof(char));
		int j = 0, k = 0;
		for(const char *p = enc; *p != '\0'; p++) {
			if(*p < '0' || *p > '9') {
				if(k < 3) // skip first three: @@: (return, self, _cmd)
					k++;
				else
					simpleEnc[j++] = *p;
			}
		}

		// Check number of arguments
		if(j/*strlen of simpleEnc*/ != info.Length()) {
			free(simpleEnc);
			return;
		}


		// Now we have the argument types for the method
		// Go over all input arguments and see if they fit
		// If they do, stop searching (so first hit counts)
		for(int i = 0; i < info.Length() && i < j; i++) {
			L8Value *argument = [L8Value valueWithV8Value:info[i]];
			BOOL valid = NO;

			switch(simpleEnc[i]) {
				case '@': // We can always convert to an object
					valid = YES;
					break;
				case 'i':
					valid = [argument isNumber];
					break;
				default:
					NSLog(@"NO HANDLE OF %c",simpleEnc[i]);
					break;
			}

			// Not valid? Next method!
			if(!valid)
				return;

//			NSLog(@"Argument %d: %@, %c",i,argument,simpleEnc[i]);
		}

		selector = method_getName(method);
		free(simpleEnc);
		*stop = YES;

		// TODO cache this: Class + Req Argument Types + SEL
	});

	if(selector == nil)
		selector = @selector(init);

	// Allocate...
	object = [cls alloc];

	methodSignature = [object methodSignatureForSelector:selector];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = selector;

//	NSLog(@"SEL %@",NSStringFromSelector(selector));

	for(int i = 0; i < info.Length(); i++) {
		L8Value *argument = [L8Value valueWithV8Value:info[i]];
		objCSetInvocationArgument(invocation, i+2, argument);
	}

	// Set target
	invocation.target = object;

	v8::Local<v8::Context> context = [[L8Runtime currentRuntime] V8Context];
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_THIS, info.This());
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_CALLEE, info.Callee());
	v8::Local<v8::Array> argList = v8::Array::New(info.Length());
	for(int i = 0; i < info.Length(); ++i)
		argList->Set(i, info[i]);
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_ARGS, argList);

	// and initialize
	@autoreleasepool {
		@try {
			[invocation invoke];
			[invocation getReturnValue:&resultObject];
			info.This()->SetInternalField(0, makeWrapper(context, resultObject));
		} @catch(L8Exception *l8e) {
			info.GetReturnValue().Set(v8::ThrowException([l8e v8exception]));
			return;
		} @catch (NSException *nse) {
			NSLog(@"Caught NSException");
		} @catch (id e) {
			info.GetReturnValue().Set(v8::ThrowException([[L8Value valueWithObject:e] V8Value]));
			return;
		} @finally {
			context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_THIS, v8::Null());
			context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_CALLEE, v8::Null());
			context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_ARGS, v8::Null());
		}
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
		const char *classStr = createStringFromV8Value(function->GetName());
		object = objc_getClass(classStr);
		free((void *)classStr);
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

	v8::Local<v8::Context> context = [[L8Runtime currentRuntime] V8Context];
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_THIS, info.This());
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_CALLEE, info.Callee());
	v8::Local<v8::Array> argList = v8::Array::New(info.Length());
	for(int i = 0; i < info.Length(); ++i)
		argList->Set(i, info[i]);
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_ARGS, argList);

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
		@try {
			[invocation invoke];
		} @catch(L8Exception *l8e) {
			info.GetReturnValue().Set(v8::ThrowException([l8e v8exception]));
			return;
		} @catch (NSException *nse) {
			NSLog(@"Caught NSException");
		} @catch (id e) {
			info.GetReturnValue().Set(v8::ThrowException([[L8Value valueWithObject:e] V8Value]));
			return;
		}
	}

	// TODO blocks can also have return values
}

void ObjCNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	L8Value *setValue = [L8Value valueWithV8Value:value];
	[object setObject:setValue forKeyedSubscript:[NSString stringWithV8String:property]];

	info.GetReturnValue().Set([setValue V8Value]);
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
//	TODO NSLog(@"property query");
}

void ObjCIndexedPropertySetter(uint32_t index, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	L8Value *setValue = [L8Value valueWithV8Value:value];
	[object setObject:setValue atIndexedSubscript:index];

	info.GetReturnValue().Set([setValue V8Value]);
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
//	TODO NSLog(@"index %d query",index);
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
//	valueType = createStringFromV8Value(extraData->Get(1));
//	free((void *)valueType);

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
	free((void *)returnType);

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