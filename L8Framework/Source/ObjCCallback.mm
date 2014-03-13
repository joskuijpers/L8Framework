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

using namespace v8;

/**
 * Creates a C string from given v8 value
 *
 * @param value The V8 value
 * @return A string. Must be freed!
 */
const char *createStringFromV8Value(Local<Value> value)
{
	char *buffer;
	Local<String> v8String;

	if(!value->IsString())
		return NULL;
	v8String = value->ToString();

	buffer = (char *)malloc(v8String->Length()+1);
	v8String->WriteUtf8(buffer);

	return buffer;
}

SEL selectorFromV8Value(Local<Value> value)
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
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT8_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (int8)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'i': { // int
			long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (int)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 's': { // short (16)
			long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT16_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (int16)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'l': { // long (32)
			long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT32_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (int32)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'q': { // long long (64)
			long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > INT64_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (int64)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'C': { // unsigned char (8)
			unsigned long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT8_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (uint8)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'I': { // unsigned int
			unsigned long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (uint)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'S': { // unsigned short (16)
			unsigned long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT16_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (uint16)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'L': { // unsigned long (32)
			unsigned long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT32_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (uint32)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'Q': { // unsigned long long (64)
			unsigned long long value;

			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			value = [[val toNumber] longLongValue];
			if(value > UINT64_MAX)
				Exception::RangeError(String::New("Value exceeds native argument size (uint64)"));

			[invocation setArgument:&value
							atIndex:index];
			break;
		}

		case 'f': { // float
			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

			float value = [[val toNumber] floatValue];
			[invocation setArgument:&value
							atIndex:index];
			break;
		}
		case 'd': { // double
			if(![val isNumber])
				Exception::TypeError(String::New("The implementation requests a number"));

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
				Exception::TypeError(String::New("The implementation requests a string"));

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

Local<Value> handleInvocationException(id exception)
{
	Isolate *isolate = Isolate::GetCurrent();
	Local<Value> valueToThrow;

	if([exception isKindOfClass:[L8Exception class]])
		valueToThrow = [exception v8exception];
	else if([exception isKindOfClass:[NSException class]]) {
		NSException *nsException = (NSException *)exception;
		Local<String> message;

		message = [[NSString stringWithFormat:@"%@ exception from native code: %@",
					nsException.name,nsException.reason] V8String];

		if([nsException.name isEqualToString:NSRangeException])
			valueToThrow = Exception::RangeError(message);
		else if([nsException.name isEqualToString:NSInvalidArgumentException])
			valueToThrow = Exception::TypeError(message);
		else
			valueToThrow = Exception::Error(message);
	} else
		valueToThrow = [[L8Value valueWithObject:exception] V8Value];

	return isolate->ThrowException(valueToThrow);
}

Local<Value> objCInvocation(NSInvocation *invocation, const char *neededReturnType = NULL)
{
	unsigned long retLength;
	const char *returnType;
	L8Value *result;

	@autoreleasepool {
		@try {
			[invocation invoke];
		} @catch(id exception) {
			return handleInvocationException(exception);
		}
	}

	retLength = invocation.methodSignature.methodReturnLength;
	returnType = invocation.methodSignature.methodReturnType;

	if(neededReturnType) {
		assert(*returnType == *neededReturnType);
		assert(strlen(neededReturnType) == 1 || *neededReturnType == '@');
	}

	_Static_assert(sizeof(uint8_t) == sizeof(unsigned char), "Sizeof uint32_t and unsigned char");
	_Static_assert(sizeof(uint16_t) == sizeof(unsigned short), "Sizeof uint32_t and unsigned short");
	_Static_assert(sizeof(uint32_t) == sizeof(unsigned int), "Sizeof uint32_t and unsigned int");
	_Static_assert(sizeof(uint64_t) == sizeof(unsigned long), "Sizeof uint64_t and unsigned long");
	_Static_assert(sizeof(uint64_t) == sizeof(unsigned long long), "Sizeof uint64_t and unsigned long long");

	switch(*returnType) {
		case 'c': { // char (8)
			int8_t value;
			assert(retLength == sizeof(int8_t));

			[invocation getReturnValue:&value];
			result = [L8Value valueWithInt32:value];
			break;
		}
		case 's': { // short (16)
			int16_t value;
			assert(retLength == sizeof(int16_t));

			[invocation getReturnValue:&value];
			result = [L8Value valueWithInt32:value];
			break;
		}
		case 'i': { // int (32)
			int32_t value;
			assert(retLength == sizeof(int32_t));

			[invocation getReturnValue:&value];
			result = [L8Value valueWithInt32:value];
			break;
		}
		case 'l': // long (64)
		case 'q': { // long long (64)
			int64_t value;
			assert(retLength == sizeof(int64_t));

			[invocation getReturnValue:&value];
			if(value <= INT32_MAX)
				result = [L8Value valueWithInt32:(int32_t)value];
			else
				result = [L8Value valueWithDouble:value];

			break;
		}
		case 'C': { // unsigned char (8)
			uint8_t value;
			assert(retLength == sizeof(uint8_t));

			[invocation getReturnValue:&value];
			result = [L8Value valueWithUInt32:value];
			break;
		}
		case 'S': { // unsigned short (16)
			uint16_t value;
			assert(retLength == sizeof(uint16_t));

			[invocation getReturnValue:&value];
			result = [L8Value valueWithUInt32:value];
			break;
		}
		case 'I': { // unsigned int (32)
			uint32_t value;
			assert(retLength == sizeof(uint32_t));

			[invocation getReturnValue:&value];
			result = [L8Value valueWithUInt32:value];
			break;
		}
		case 'L': // unsigned long (64)
		case 'Q': { // unsigned long long (64)
			uint64_t value;
			assert(retLength == sizeof(uint64_t));

			[invocation getReturnValue:&value];
			if(value <= UINT32_MAX)
				result = [L8Value valueWithUInt32:(uint32_t)value];
			else
				result = [L8Value valueWithDouble:value];

			break;
		}
		case 'f': { // float
			float value;
			assert(retLength == sizeof(float));
			[invocation getReturnValue:&value];
			result = [L8Value valueWithDouble:value];
			break;
		}
		case 'd': { // double
			double value;
			assert(retLength == sizeof(double));
			[invocation getReturnValue:&value];
			result = [L8Value valueWithDouble:value];
			break;
		}

		case 'B': { // bool or _Bool
			bool value;
			assert(retLength <= sizeof(bool));

			[invocation getReturnValue:&value];
			result = [L8Value valueWithBool:value];
			break;
		}
		case 'v': // void
			return Undefined();
		case '*': { // char *
			char *string;
			assert(retLength == sizeof(char *));

			[invocation getReturnValue:&string];
			return objectToValue([L8Runtime currentRuntime],@(string));
		}
		case '@': { // object
			id __unsafe_unretained object;
			assert(retLength == sizeof(id));

			[invocation getReturnValue:&object];
			return objectToValue([L8Runtime currentRuntime], object);
		}
		case '#': { // Class
			Class __unsafe_unretained classObject;

			[invocation getReturnValue:&classObject];

			// TODO find name of class if available

			result = [L8Value valueWithObject:classObject];

			break;
		}
		case ':': // SEL
			return Undefined();
		case '{': // struct, {name=type}
			// TODO implement
		case '[': // array, [type]
		case '(': // union, (name=type)
		case '^': // pointer, ^type
		case '?': // Unknown
		case 'b': // bitfield, bnum
		default:
			NSLog(@"Returntype: '%s', len %lu",returnType,retLength);
			assert(0 && "A return type is not implemented");
	}

	return [result V8Value];
}

inline void objCSetInvocationArguments(NSInvocation *invocation,
									   const FunctionCallbackInfo<Value>& info, int offset)
{
	for(int i = 0; i < invocation.methodSignature.numberOfArguments; i++) {
		L8Value *argument;

		// Arguments that are requested but not supplied: give Undefined
		if(i < info.Length())
			argument = [L8Value valueWithV8Value:info[i]];
		else
			argument = [L8Value valueWithUndefined];

		objCSetInvocationArgument(invocation, i+offset, argument);
	}
}

inline void objCSetContextEmbedderData(const FunctionCallbackInfo<Value>& info)
{
	Local<Context> context = [[L8Runtime currentRuntime] V8Context];

	// Set embedder data
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_THIS, info.This());
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_CALLEE, info.Callee());
	Local<Array> argList = Array::New(info.Length());
	for(int i = 0; i < info.Length(); ++i)
		argList->Set(i, info[i]);
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_ARGS, argList);
}

inline void objCClearContextEmbedderData() {
	Local<Context> context = [[L8Runtime currentRuntime] V8Context];

	// Clear embedder data
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_THIS, Null());
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_CALLEE, Null());
	context->SetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_CB_ARGS, Null());
}

void ObjCConstructor(const FunctionCallbackInfo<Value>& info)
{
	const char *className, *selName;
	Class cls;
	SEL selector = nil;
	id object;
	id __unsafe_unretained resultObject;
	HandleScope localScope(info.GetIsolate());

	NSMethodSignature *methodSignature;
	NSInvocation *invocation;

	// In one situation we should no nothing:
	// When just created the class for an existing object
	Local<Value> skipConstruct = info.GetIsolate()->GetCurrentContext()->GetEmbedderData(L8_RUNTIME_EMBEDDER_DATA_SKIP_CONSTRUCTING);
	if(!skipConstruct.IsEmpty() && skipConstruct->IsTrue())
		return;

	Local<Array> extraClassData;
	extraClassData = info.Data().As<Array>();

	className = createStringFromV8Value(extraClassData->Get(0));
	cls = objc_getClass(className);
	free((void *)className); className = NULL;

	selName = createStringFromV8Value(extraClassData->Get(1));
	selector = sel_registerName(selName);
	free((void *)selName); selName = NULL;

	object = [cls alloc];

	// The allocated object is now already released by
	// the runtime because the init returned nil. We can't
	// release object anymore: it is a zombie.
	// That is why CFRetain and a conditional CFRelease is used:
	// to circumvent the ARC problem.
	CFRetain((void *)object);

	methodSignature = [object methodSignatureForSelector:selector];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = selector;

	// Set target
	invocation.target = object;

	objCSetInvocationArguments(invocation, info, 2);
	objCSetContextEmbedderData(info);

	// and initialize
	@autoreleasepool {
		@try {
			[invocation invoke];
			[invocation getReturnValue:&resultObject];

			// init returned nil.
			if(resultObject == nil) {
				Local<String> error;
				Local<Value> exception;

				error = String::New("Failed to create native object: initializer returned <nil>.");
				exception = Exception::ReferenceError(error);
				info.GetReturnValue().Set(Isolate::GetCurrent()->ThrowException(exception));

				return;
			} else
				CFRelease((void *)object);

			// Set our self to, ourself
			info.This()->SetInternalField(0, makeWrapper([[L8Runtime currentRuntime] V8Context], resultObject));

		} @catch (id exception) {
			info.GetReturnValue().Set(handleInvocationException(exception));
			return;
		} @finally {
			objCClearContextEmbedderData();
		}
	}

	info.GetReturnValue().Set(info.This());
}

void ObjCMethodCall(const FunctionCallbackInfo<Value>& info)
{
	SEL selector;
	id object;
	const char *types;
	bool isClassMethod = false;
	NSMethodSignature *methodSignature;
	NSInvocation *invocation;
	Local<Array> extraData;
	Local<Value> retVal;

	// A constructor call should be with ObjCConstructor
	assert(info.IsConstructCall() == false);

	extraData = info.Data().As<Array>();
	selector = selectorFromV8Value(extraData->Get(0));
	types = createStringFromV8Value(extraData->Get(1));
	isClassMethod = extraData->Get(2)->ToBoolean()->Value();

	methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	free((void *)types);

	// Class methods must use the function (This) name to find the class meta object
	if(isClassMethod) {
		Local<Function> function = info.This().As<Function>();
		const char *classStr = createStringFromV8Value(function->GetName());
		object = objc_getClass(classStr);
		free((void *)classStr);
	} else
		object = objectFromWrapper(info.This()->GetInternalField(0));

	invocation.selector = selector;
	invocation.target = object;

	// Set the arguments
	objCSetInvocationArguments(invocation, info, 2);
	objCSetContextEmbedderData(info);

	// Retain those
	[invocation retainArguments];

	retVal = objCInvocation(invocation);

	objCClearContextEmbedderData();

	info.GetReturnValue().Set(retVal);
}

void ObjCBlockCall(const FunctionCallbackInfo<Value>& info)
{
	id block = (__bridge id)info.Data().As<External>()->Value();

	NSMethodSignature *methodSignature;
	NSInvocation *invocation;
	const char *signature;

	signature = _Block_signature((__bridge void *)block);
	methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.target = block;

	// Set arguments (+1)
	objCSetInvocationArguments(invocation, info, 1);

	[invocation retainArguments];

	@autoreleasepool {
		@try {
			Local<Value> retVal;

			retVal = objCInvocation(invocation);
			info.GetReturnValue().Set(retVal);
		} @catch (id exception) {
			info.GetReturnValue().Set(handleInvocationException(exception));
		}
	}
}

void ObjCNamedPropertySetter(Local<String> property, Local<Value> value, const PropertyCallbackInfo<Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	L8Value *setValue = [L8Value valueWithV8Value:value];
	[object setObject:setValue forKeyedSubscript:[NSString stringWithV8String:property]];

	info.GetReturnValue().Set([setValue V8Value]);
}

void ObjCNamedPropertyGetter(Local<String> property, const PropertyCallbackInfo<Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	id value = [object objectForKeyedSubscript:[NSString stringWithV8String:property]];

	if(value)
		info.GetReturnValue().Set(objectToValue([L8Runtime currentRuntime], value));
}

void ObjCNamedPropertyQuery(Local<String> property, const PropertyCallbackInfo<Integer>& info)
{
//	TODO NSLog(@"property query");
//	NSLog(@"Not yet implemented: ObjCNamedPropertyQuery");
}

void ObjCIndexedPropertySetter(uint32_t index, Local<Value> value, const PropertyCallbackInfo<Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	L8Value *setValue = [L8Value valueWithV8Value:value];
	[object setObject:setValue atIndexedSubscript:index];

	info.GetReturnValue().Set([setValue V8Value]);
}

void ObjCIndexedPropertyGetter(uint32_t index, const PropertyCallbackInfo<Value>& info)
{
	id object = objectFromWrapper(info.This()->GetInternalField(0));
	id value = [object objectAtIndexedSubscript:index];

	if(value)
		info.GetReturnValue().Set(objectToValue([L8Runtime currentRuntime], value));
}

void ObjCIndexedPropertyQuery(uint32_t index, const PropertyCallbackInfo<Integer>& info)
{
//	TODO NSLog(@"index %d query",index);
//	NSLog(@"Not yet implemented: ObjCIndexedPropertyQuery");
}

void ObjCAccessorSetter(Local<String> property, Local<Value> value, const PropertyCallbackInfo<void> &info)
{
	SEL selector;
	id object;
	NSMethodSignature *methodSignature;
	NSInvocation *invocation;
	const char *types;//, *valueType;
	Local<Array> extraData;
	Local<Value> retVal;
	L8Value *newValue;

	object = objectFromWrapper(info.This()->GetInternalField(0));
	extraData = info.Data().As<Array>();

	// 0 = name, 1 = value type, 2 = getter SEL, 3 = getter types, 4 = setter SEL, 5 = setter types
	selector = selectorFromV8Value(extraData->Get(4));
	types = createStringFromV8Value(extraData->Get(5));

	methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
	free((void *)types);

	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = selector;
	invocation.target = object;

	assert(invocation.methodSignature.numberOfArguments == 3
		   && "More parameters than arguments: not a setter called?");

	newValue = [L8Value valueWithV8Value:value];
	objCSetInvocationArgument(invocation,2,newValue);

	retVal = objCInvocation(invocation);

	info.GetReturnValue().Set(retVal);
}

void ObjCAccessorGetter(Local<String> property, const PropertyCallbackInfo<Value> &info)
{
	SEL selector;
	id object;
	NSMethodSignature *methodSignature;
	NSInvocation *invocation;
	const char *types, *returnType;
	Local<Array> extraData;
	Local<Value> retVal;

	object = objectFromWrapper(info.This()->GetInternalField(0));
	extraData = info.Data().As<Array>();

	// 0 = name, 1 = value type, 2 = getter SEL, 3 = getter types, 4 = setter SEL, 5 = setter types
	returnType = createStringFromV8Value(extraData->Get(1));
	selector = selectorFromV8Value(extraData->Get(2));
	types = createStringFromV8Value(extraData->Get(3));

	methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
	free((void *)types);

	invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = selector;
	invocation.target = object;

	assert(invocation.methodSignature.numberOfArguments == 2
		   && "More parameters than arguments: not a getter called?");

	retVal = objCInvocation(invocation,returnType);
	free((void *)returnType);

	info.GetReturnValue().Set(retVal);
}

/**
 * Called when an ObjC object stored in v8 will be released by v8.
 * This function causes an ObjC release on the object.
 */
void ObjCWeakReferenceCallback(Isolate *isolate, Persistent<External> *persistent, void *parameter)
{
	Local<External> ext;

	ext = Local<External>::New(isolate, *persistent);

	CFRelease(ext->Value());
}