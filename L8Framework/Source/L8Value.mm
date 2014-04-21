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

#import "L8Value_Private.h"
#import "L8Context_Private.h"
#import "L8Reporter_Private.h"
#import "L8ManagedValue_Private.h"
#import "L8VirtualMachine_Private.h"
#import "L8Export.h"
#import "L8WrapperMap.h"
#import "NSString+L8.h"
#import "L8Symbol_Private.h"
#import "L8TypedArray_Private.h"

#include "v8.h"
#import <objc/runtime.h>

#include <vector>
#include <map>

using namespace v8;

@implementation L8Value {
	Persistent<Value> _v8value;
}

#pragma mark Value creations

+ (instancetype)valueWithObject:(id)value inContext:(L8Context *)context
{
	return [self valueWithV8Value:objectToValue(context.virtualMachine.V8Isolate, context, value) inContext:context];
}

+ (instancetype)valueWithBool:(BOOL)value inContext:(L8Context *)context
{
	return [self valueWithV8Value:v8::Boolean::New(context.virtualMachine.V8Isolate,value) inContext:context];
}

+ (instancetype)valueWithDouble:(double)value inContext:(L8Context *)context
{
	return [self valueWithV8Value:Number::New(context.virtualMachine.V8Isolate,value) inContext:context];
}

+ (instancetype)valueWithInt32:(int32_t)value inContext:(L8Context *)context
{
	return [self valueWithV8Value:Int32::New(context.virtualMachine.V8Isolate,value) inContext:context];
}

+ (instancetype)valueWithUInt32:(uint32_t)value inContext:(L8Context *)context
{
	return [self valueWithV8Value:Uint32::New(context.virtualMachine.V8Isolate,value) inContext:context];
}

+ (instancetype)valueWithNewObjectInContext:(L8Context *)context
{
	return [self valueWithV8Value:Object::New(context.virtualMachine.V8Isolate) inContext:context];
}

+ (instancetype)valueWithNewArrayInContext:(L8Context *)context
{
	return [self valueWithV8Value:Array::New(context.virtualMachine.V8Isolate) inContext:context];
}

+ (instancetype)valueWithNewRegularExpressionFromPattern:(NSString *)pattern
												   flags:(NSString *)flags
											   inContext:(L8Context *)context
{
	int iFlags = RegExp::Flags::kNone;
	Isolate *isolate = context.virtualMachine.V8Isolate;

	if([flags rangeOfString:@"g"].location != NSNotFound)
		iFlags |= RegExp::Flags::kGlobal;
	if([flags rangeOfString:@"i"].location != NSNotFound)
		iFlags |= RegExp::Flags::kIgnoreCase;
	if([flags rangeOfString:@"m"].location != NSNotFound)
		iFlags |= RegExp::Flags::kMultiline;

	return [self valueWithV8Value:RegExp::New([pattern V8StringInIsolate:isolate],
											  (RegExp::Flags)iFlags)
						inContext:context];
}

+ (instancetype)valueWithNewErrorFromMessage:(NSString *)message
								   inContext:(L8Context *)context
{
	Local<String> msg = [message V8StringInIsolate:context.virtualMachine.V8Isolate];
	Local<Value> error = Exception::Error(msg);
	return [self valueWithV8Value:error inContext:context];
}

+ (instancetype)valueWithNullInContext:(L8Context *)context
{
	return [self valueWithV8Value:Null(context.virtualMachine.V8Isolate) inContext:context];
}

+ (instancetype)valueWithUndefinedInContext:(L8Context *)context
{
	return [self valueWithV8Value:Undefined(context.virtualMachine.V8Isolate) inContext:context];
}

#ifdef L8_ENABLE_SYMBOLS
+ (instancetype)valueWithSymbol:(NSString *)symbol inContext:(L8Context *)context
{
	return [self valueWithV8Value:Symbol::New(context.virtualMachine.V8Isolate,
											  [symbol UTF8String],
											  (int)symbol.length)
						inContext:context];
}
#endif

#ifdef L8_ENABLE_TYPED_ARRAYS
+ (instancetype)valueWithArrayBufferOfLength:(size_t)length inContext:(L8Context *)context
{
	return [self valueWithV8Value:ArrayBuffer::New(context.virtualMachine.V8Isolate,
												   length)
						inContext:context];
}
#endif

#pragma mark Object conversions

- (id)toObject
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return valueToObject(isolate, _context, Local<Value>::New(isolate,_v8value));
}

- (id)toObjectOfClass:(Class)expectedClass
{
	id result = [self toObject];
	return [result isKindOfClass:expectedClass]?result:nil;
}

- (id)toBlockFunction
{
	Local<Function> function;
	Local<Value> isBlock, v8value;
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);

	v8value = Local<Value>::New(isolate,_v8value);

	if(!v8value->IsFunction())
		return nil;

	function = v8value.As<Function>();

	isBlock = function->GetHiddenValue(String::NewFromUtf8(isolate, "isBlock"));
	if(!isBlock.IsEmpty() && isBlock->IsTrue()) {
		id block;

		block = l8_unwrap_block(isolate,function);

		return block;
	}

	return nil;
}

- (BOOL)toBool
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	return (BOOL)Local<Value>::New(isolate,_v8value)->ToBoolean()->IsTrue();
}

- (double)toDouble
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	return Local<Value>::New(isolate,_v8value)->NumberValue();
}

- (int32_t)toInt32
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->Int32Value();
}

- (uint32_t)toUInt32
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->Uint32Value();
}

- (NSNumber *)toNumber
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return valueToNumber(isolate, _context, Local<Value>::New(isolate,_v8value));
}

- (NSString *)toString
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return valueToString(isolate, _context, Local<Value>::New(isolate,_v8value));
}

- (NSDate *)toDate
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return valueToDate(isolate, _context, Local<Value>::New(isolate,_v8value));
}

- (NSArray *)toArray
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return valueToArray(isolate, _context, Local<Value>::New(isolate,_v8value));
}

- (NSDictionary *)toDictionary
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return valueToDictionary(isolate, _context, Local<Value>::New(isolate,_v8value));
}

- (NSData *)toData
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return valueToData(isolate, _context, Local<Value>::New(isolate,_v8value));
}

#pragma mark Setting and getting properties

- (L8Value *)valueForProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	Local<Object> object;
	Local<Value> value;

	object = Local<Value>::New(isolate,_v8value)->ToObject();
	value = object->Get([property V8StringInIsolate:isolate]);

	return [L8Value valueWithV8Value:localScope.Escape(value) inContext:_context];
}

- (void)setValue:(id)value forProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object = Local<Value>::New(isolate,_v8value)->ToObject();
	object->Set([property V8StringInIsolate:isolate],objectToValue(isolate,_context,value));
}

- (BOOL)deleteProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object = Local<Value>::New(isolate,_v8value)->ToObject();
	return object->Delete([property V8StringInIsolate:isolate]);
}

- (BOOL)hasProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object = Local<Value>::New(isolate,_v8value)->ToObject();
	return object->Has([property V8StringInIsolate:isolate]);
}

- (L8Value *)valueAtIndex:(NSUInteger)index
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object;

	if(index != (uint32_t)index) {
		NSString *propertyName;

		propertyName = [[L8Value valueWithDouble:index inContext:_context] toString];
		return [self valueForProperty:propertyName];
	}

	object = Local<Value>::New(isolate,_v8value)->ToObject();

	return [L8Value valueWithV8Value:object->Get((uint32_t)index) inContext:_context];
}

- (void)setValue:(id)value atIndex:(NSUInteger)index
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object;

	if(index != (uint32_t)index) {
		NSString *propertyName;

		propertyName = [[L8Value valueWithDouble:index inContext:_context] toString];
		return [self setValue:value forProperty:propertyName];
	}

	object = Local<Value>::New(isolate,_v8value)->ToObject();
	object->Set((uint32_t)index, objectToValue(isolate,_context,value));
}

- (void)defineProperty:(NSString *)property descriptor:(id)descriptor
{
	[_context.globalObject[@"Object"] invokeMethod:@"defineProperty"
									 withArguments:@[self, property, descriptor]];
}

#pragma mark Type discovery

- (BOOL)isUndefined
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsUndefined();
}

- (BOOL)isNull
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsNull();
}

- (BOOL)isBoolean
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	Local<Value> v8value = Local<Value>::New(isolate,_v8value);
	return v8value->IsBoolean() || (v8value->IsNumber() && v8value->Uint32Value() <= 1);
}

- (BOOL)isNumber
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsNumber();
}

- (BOOL)isString
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsString();
}

- (BOOL)isObject
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	Local<Value> v8value = Local<Value>::New(isolate,_v8value);
	return v8value->IsObject() && !v8value->IsFunction();
}

- (BOOL)isFunction
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsFunction();
}

- (BOOL)isRegularExpression
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsRegExp();
}

- (BOOL)isNativeError
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsNativeError();
}

#ifdef L8_ENABLE_SYMBOLS
- (BOOL)isSymbol
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsSymbol();
}
#endif

#ifdef L8_ENABLE_TYPED_ARRAYS
- (BOOL)isArrayBuffer
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsArrayBuffer();
}

- (BOOL)isArrayBufferView
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return Local<Value>::New(isolate,_v8value)->IsArrayBufferView();
}
#endif

- (BOOL)isEqualToObject:(id)value
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return 	Local<Value>::New(isolate,_v8value)->StrictEquals(objectToValue(isolate,_context,value));
}

- (BOOL)isEqualWithTypeCoercionToObject:(id)value
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	return 	Local<Value>::New(isolate,_v8value)->Equals(objectToValue(isolate,_context,value));
}

- (BOOL)isInstanceOf:(id)value
{
	Class cls = Nil;
	L8WrapperMap *map;
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	Local<FunctionTemplate> funcTemplate;

	if(class_isMetaClass(cls))
		cls = value;
	else
		cls = [value class];

	map = [_context wrapperMap];
	funcTemplate = [map getCachedFunctionTemplateForClass:cls];
	if(funcTemplate.IsEmpty())
		return NO;

	return funcTemplate->HasInstance(Local<Value>::New(isolate,_v8value));
}

#pragma mark Throwing exceptions

- (void)throwValue
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	HandleScope localScope(isolate);
	isolate->ThrowException(Local<Value>::New(isolate,_v8value));
}

#pragma mark Invoking methods and constructors

- (L8Value *)callWithArguments:(NSArray *)arguments
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	Local<Value> *argv, result, v8value;
	Local<Object> function;

	if(!Local<Value>::New(isolate,_v8value)->IsFunction())
		return [L8Value valueWithUndefinedInContext:_context];

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(isolate,_context, obj);
	}];

	v8value = Local<Value>::New(isolate,_v8value);
	function = v8value->ToObject();

	{
		TryCatch tryCatch;

		result = function->CallAsFunction(v8value->ToObject(), (int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inContext:_context];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Escape(result) inContext:_context];
}

- (L8Value *)constructWithArguments:(NSArray *)arguments
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	Local<Function> function;
	Local<Value> *argv, result, v8value;

	// Just like ObjC, we want no need to check the validity of
	// self when invoking this method.
	v8value = Local<Value>::New(isolate,_v8value);
	if(!v8value->IsFunction())
		return [L8Value valueWithUndefinedInContext:_context];

	function = v8value.As<Function>();

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(isolate, _context, obj);
	}];

	{
		TryCatch tryCatch;

		result = function->CallAsConstructor((int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inContext:_context];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Escape(result) inContext:_context];
}

- (L8Value *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	L8Value *function;
	Local<Value> v8value, result, *argv, selfV8value;
	Local<Function> v8function;

	// Just like ObjC, we want no need to check the validity of
	// self when invoking this method.
	selfV8value = Local<Value>::New(isolate,_v8value);
	if(selfV8value->IsUndefined() || selfV8value->IsNull())
		return [L8Value valueWithUndefinedInContext:_context];

	function = self[method];
	if(!function || Local<Value>::New(isolate,_v8value)->IsUndefined())
		return [L8Value valueWithUndefinedInContext:_context];

	v8value = Local<Value>::New(isolate,function->_v8value);
	v8function = v8value.As<Function>();

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(isolate, _context, obj);
	}];

	{
		TryCatch tryCatch;

		result = v8function->CallAsFunction(selfV8value->ToObject(), (int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inContext:_context];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Escape(result) inContext:_context];
}

- (NSString *)description
{
	NSString *value;
	Isolate *isolate = _context.virtualMachine.V8Isolate;

	if(id wrapped = l8_unwrap_objc_object(isolate, Local<Value>::New(isolate,_v8value)))
		value = [wrapped description];
	else
		value = [self toString];

	return [NSString stringWithFormat:@"<L8Value>(%@)",value];
}

#pragma mark - Private

+ (instancetype)valueWithV8Value:(Local<Value>)value inContext:(L8Context *)context
{
	return [context wrapperForJSObject:value];
}

- (instancetype)initWithV8Value:(Local<Value>)value inContext:(L8Context *)context
{
	if(value.IsEmpty())
		return nil;

	self = [super init];
	if(self) {
		_context = context;
		_v8value.Reset(_context.virtualMachine.V8Isolate,value);
	}
	return self;
}

- (Local<Value>)V8Value
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	return Local<Value>::New(isolate,_v8value);
}

- (void)dealloc
{
	_v8value.ClearAndLeak();
}

enum COLLECTION_TYPE {
	COLLECTION_ARRAY,
	COLLECTION_DICTIONARY,
	COLLECTION_NONE
};

class ValueCompare
{
public:
	bool operator()(Local<Value> left, Local<Value> right)
	const {
		return *left < *right;
	}
};

class JavaScriptContainerConverter
{
public:
	struct Job {
		Local<Value> value;
		id object;
		COLLECTION_TYPE type;
	};

	JavaScriptContainerConverter(Isolate *isolate, Local<Context> context)
	: _isolate(isolate), _context(context)
	{}

	id convert(Local<Value> value);
	void add(Job job);
	Job take();
	bool isJobListEmpty() { return _jobList.size() == 0; }

private:
	Local<Context> _context;
	Isolate *_isolate;
	std::map<Local<Value>, id, ValueCompare> _objectMap;
	std::vector<Job> _jobList;
};

id JavaScriptContainerConverter::convert(Local<Value> value)
{
	std::map<Local<Value>, id>::iterator i = _objectMap.find(value);
	if(i != _objectMap.end())
		return i->second;

	Job job = valueToObjectWithoutCopy(_isolate, _context, value);
	if(!job.value.IsEmpty())
		add(job);

	return job.object;
}

void JavaScriptContainerConverter::add(JavaScriptContainerConverter::Job job)
{
	_objectMap[job.value] = job.object;
	if(job.type != COLLECTION_NONE)
		_jobList.push_back(job);
}

JavaScriptContainerConverter::Job JavaScriptContainerConverter::take()
{
	assert(!isJobListEmpty());
	Job last = _jobList.front();
	_jobList.erase(_jobList.begin());
	return last;
}

static JavaScriptContainerConverter::Job valueToObjectWithoutCopy(Isolate *isolate,
																  Local<Context> v8context,
																  Local<Value> value)
{
	Local<Object> object;

	if(!value->IsObject()) {
		id primitive;

		if(value->IsBoolean())
			primitive = [NSNumber numberWithBool:value->BooleanValue()];
		else if(value->IsNumber())
			primitive = [NSNumber numberWithDouble:value->ToNumber()->Value()];
		else if(value->IsString())
			primitive = [NSString stringWithV8Value:value inIsolate:v8context->GetIsolate()];
		else if(value->IsNull())
			primitive = [NSNull null];
#ifdef L8_ENABLE_SYMBOLS
		else if(value->IsSymbol())
			primitive = [[L8Symbol alloc] initWithV8Value:value];
#endif
#ifdef L8_ENABLE_TYPED_ARRAYS
		else if(value->IsArrayBuffer())
			primitive = valueToData(isolate, [L8Context contextWithV8Context:v8context], value);
		else if(value->IsArrayBufferView())
			primitive = [[L8TypedArray alloc] initWithV8Value:value];
#endif
		else {
			assert(value->IsUndefined());
			primitive = nil;
		}
		return (JavaScriptContainerConverter::Job){ value, primitive, COLLECTION_NONE };
	}

	object = value->ToObject();
	if(id wrapped = l8_unwrap_objc_object(isolate, value))
		return (JavaScriptContainerConverter::Job){ object, wrapped, COLLECTION_NONE };

	if(object->IsDate())
		return (JavaScriptContainerConverter::Job) { object, [NSDate dateWithTimeIntervalSince1970:object->ToNumber()->Value()], COLLECTION_NONE };

	if(object->IsArray())
		return (JavaScriptContainerConverter::Job){ object, [NSMutableArray array], COLLECTION_ARRAY };

	return (JavaScriptContainerConverter::Job){ object, [NSMutableDictionary dictionary], COLLECTION_DICTIONARY };
}

static id containerValueToObject(Isolate *isolate, Local<Context> v8context, JavaScriptContainerConverter::Job job)
{
	assert(job.type != COLLECTION_NONE);
	JavaScriptContainerConverter converter(isolate, v8context);
	converter.add(job);

	do {
		JavaScriptContainerConverter::Job currentJob = converter.take();
		assert(currentJob.value->IsObject());
		Local<Object> value = currentJob.value->ToObject();

		if(currentJob.type == COLLECTION_ARRAY) {
			NSMutableArray *array = currentJob.object;

			uint32_t length = value->Get([@"length" V8StringInIsolate:isolate])->Uint32Value();

			for(uint32_t i = 0; i < length; ++i) {
				id object = converter.convert(value->Get(i));
				[array addObject:object?object:[NSNull null]];
			}

		} else {
			NSMutableDictionary *dictionary = currentJob.object;

			Local<Array> propertyNames = value->GetPropertyNames();
			uint32_t length = propertyNames->Length();

			for(uint32_t i = 0; i < length; ++i) {
				Local<Value> key = propertyNames->Get(i);
				id object = converter.convert(value->Get(key));
				if(object)
					dictionary[[NSString stringWithV8Value:key inIsolate:isolate]] = object;
			}
		}

	} while(!converter.isJobListEmpty());

	return job.object;
}

id valueToObject(Isolate *isolate, L8Context *context, Local<Value> value)
{
	JavaScriptContainerConverter::Job job = valueToObjectWithoutCopy(isolate, context.V8Context, value);
	if(job.type == COLLECTION_NONE)
		return job.object;
	return containerValueToObject(isolate, context.V8Context, job);
}

NSNumber *valueToNumber(Isolate *isolate, L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSNumber class]]) {
		return wrapped;
	}

	if(value->IsInt32())
		return [NSNumber numberWithInteger:value->Int32Value()];
	else if(value->IsUint32())
		return [NSNumber numberWithUnsignedInteger:value->Uint32Value()];
	return [NSNumber numberWithDouble:value->NumberValue()];
}

NSString *valueToString(Isolate *isolate, L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSString class]])
		return wrapped;

	if(value.IsEmpty())
		return nil;

#ifdef L8_ENABLE_SYMBOLS
	if(value->IsSymbol())
		return [NSString stringWithV8Value:value.As<Symbol>()->Name() inIsolate:isolate];
#endif

	return [NSString stringWithV8String:value->ToString()];
}

NSDate *valueToDate(Isolate *isolate, L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSDate class]]) {
		return wrapped;
	}

	return [NSDate dateWithTimeIntervalSince1970:value->NumberValue()];
}

NSArray *valueToArray(Isolate *isolate, L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSArray class]]) {
		return wrapped;
	}

	if(value->IsArray())
		return containerValueToObject(isolate, context.V8Context, (JavaScriptContainerConverter::Job) { value, [NSMutableArray array], COLLECTION_ARRAY });

	if(!value->IsNull() && value->IsUndefined())
		@throw [NSException exceptionWithName:@"TypeErrror"
									   reason:@"Cannot convert to Array" userInfo:nil];

	return nil;
}

NSDictionary *valueToDictionary(Isolate *isolate, L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSDictionary class]]) {
		return wrapped;
	}

	if(value->IsObject())
		return containerValueToObject(isolate, context.V8Context, (JavaScriptContainerConverter::Job){ value, [NSMutableDictionary dictionary], COLLECTION_DICTIONARY} );

	if(!value->IsNull() && value->IsUndefined())
		@throw [NSException exceptionWithName:@"TypeErrror"
									   reason:@"Cannot convert to Dictionary" userInfo:nil];

	return nil;
}

/**
 TODO; Create a wrapper class for ArrayBuffer
 It contains Length and pointer to the Buffer
 Make it have a strong handle to itself
 Plust a Persistent handle to the arraybuffer
 In weak callback, reset persistent handle and self_strong
 
 when destructed, call free() on the buffer
 */

NSData *valueToData(Isolate *isolate, L8Context *context, Local<Value> value)
{
	Local<ArrayBuffer> arrayBuffer;
	NSData *data;
	ArrayBuffer::Contents contents;

	id wrapped = l8_unwrap_objc_object(isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSDictionary class]]) {
		return wrapped;
	}

	if(value->IsNull() || value->IsUndefined())
		return nil;
	if(!value->IsArrayBuffer())
		return nil;

	arrayBuffer = value.As<ArrayBuffer>();
	if(arrayBuffer->IsExternal()) {
		data = (__bridge NSData *)arrayBuffer->GetAlignedPointerFromInternalField(0);
		return data;
	}

	contents = arrayBuffer->Externalize();
	data = [NSData dataWithBytes:contents.Data() length:contents.ByteLength()];
	// OR NOCOPY (+ FREE)

	arrayBuffer->SetAlignedPointerInInternalField(0, (__bridge_retained void *)data);

	return data;
}

Local<Value> dataToValue(Isolate *isolate, NSData *data)
{
	Local<ArrayBuffer> ret;
#warning TODO

	ret = ArrayBuffer::New(isolate, (void *)data.bytes, data.length);
	ret->SetAlignedPointerInInternalField(0, (__bridge_retained void *)data);

	return ret;
}

class ObjCContainerConverter
{
public:
	struct Job {
		id object;
		Local<Value> value;
		COLLECTION_TYPE type;
	};

	ObjCContainerConverter(Isolate *isolate, L8Context *context)
	: _isolate(isolate), _context(context)
	{}

	Local<Value> convert(id object);
	void add(Job job);
	Job take();
	bool isJobListEmpty() { return _jobList.size() == 0; }

private:
	L8Context *_context;
	Isolate *_isolate;
	std::map<id, Local<Value>> _objectMap;
	std::vector<Job> _jobList;
};

Local<Value> ObjCContainerConverter::convert(id object)
{
	auto i = _objectMap.find(object);
	if(i != _objectMap.end())
		return i->second;

	Job job = objectToValueWithoutCopy(_isolate, _context, object);
	add(job);

	return job.value;
}

void ObjCContainerConverter::add(ObjCContainerConverter::Job job)
{
	_objectMap[job.object] = job.value;
	if(job.type != COLLECTION_NONE)
		_jobList.push_back(job);
}

ObjCContainerConverter::Job ObjCContainerConverter::take()
{
	assert(!isJobListEmpty());
	Job last = _jobList.front();
	_jobList.erase(_jobList.begin());
	return last;
}

static ObjCContainerConverter::Job objectToValueWithoutCopy(Isolate *isolate, L8Context *context, id object)
{
	if(!object)
		return (ObjCContainerConverter::Job){object, Undefined(isolate), COLLECTION_NONE};

	if(![object conformsToProtocol:@protocol(L8Export)]) {

		if([object isKindOfClass:[NSArray class]])
			return (ObjCContainerConverter::Job){object, Array::New(isolate), COLLECTION_ARRAY};

		if([object isKindOfClass:[NSDictionary class]])
			return (ObjCContainerConverter::Job){object, Object::New(isolate), COLLECTION_DICTIONARY};

		if([object isKindOfClass:[NSNull class]])
			return (ObjCContainerConverter::Job){object, Null(isolate), COLLECTION_NONE};

		if([object isKindOfClass:[L8Value class]])
			return (ObjCContainerConverter::Job){object, [((L8Value *)object) V8Value], COLLECTION_NONE};

		if([object isKindOfClass:[NSString class]])
			return (ObjCContainerConverter::Job) {object, [(NSString *)object V8StringInIsolate:isolate], COLLECTION_NONE};

		if([object isKindOfClass:[NSNumber class]]) {
			assert([@YES class] == [@NO class]);
			assert([@YES class] != [NSNumber class]);
			assert([[@YES class] isSubclassOfClass:[NSNumber class]]);
			if([object isKindOfClass:[@YES class]]) // Pretty much a hack: assumes Boolean class cluster
				return (ObjCContainerConverter::Job){object, v8::Boolean::New(isolate,[object boolValue]), COLLECTION_NONE};
			return (ObjCContainerConverter::Job){object, Number::New(isolate,[object doubleValue]), COLLECTION_NONE};
		}

		if([object isKindOfClass:[NSDate class]])
			return (ObjCContainerConverter::Job){object, Date::New(isolate,[object timeIntervalSince1970]), COLLECTION_NONE};

		if([object isKindOfClass:BlockClass()])
			return (ObjCContainerConverter::Job){object, [[context wrapperForObjCObject:object] V8Value], COLLECTION_NONE};

#ifdef L8_ENABLE_SYMBOLS
		if([object isKindOfClass:[L8Symbol class]]) {
			NSString *name = [(L8Symbol *)object name];
			return (ObjCContainerConverter::Job){object, Symbol::New(isolate,[name UTF8String],(int)name.length), COLLECTION_NONE};
		}
#endif

#ifdef L8_ENABLE_TYPED_ARRAYS
		if([object isKindOfClass:[NSData class]])
			return (ObjCContainerConverter::Job){object, dataToValue(isolate, (NSData *)object), COLLECTION_NONE};

		if([object isKindOfClass:[L8TypedArray class]])
			return (ObjCContainerConverter::Job){object, [(L8TypedArray *)object createV8ValueInIsolate:isolate], COLLECTION_NONE};
#endif

		if([object isKindOfClass:[L8ManagedValue class]]) {
			L8Value *value;

			value = [(L8ManagedValue *)object value];
			if(!value) // collected
				return (ObjCContainerConverter::Job){object, Undefined(isolate), COLLECTION_NONE};
			return (ObjCContainerConverter::Job){object, value.V8Value, COLLECTION_NONE};
		}
	}

	return (ObjCContainerConverter::Job){ object, [[context wrapperForObjCObject:object] V8Value], COLLECTION_NONE };
}

Local<Value> objectToValue(Isolate *isolate, L8Context *context, id object)
{
	EscapableHandleScope handleScope(isolate);

	if(object == nil)
		return handleScope.Escape((Local<Value>)Undefined(isolate));

	ObjCContainerConverter::Job job = objectToValueWithoutCopy(isolate, context, object);
	if(job.type == COLLECTION_NONE)
		return handleScope.Escape(job.value);

	__block ObjCContainerConverter converter(isolate, context);
	converter.add(job);

	do {
		ObjCContainerConverter::Job currentJob = converter.take();
		assert(currentJob.value->IsObject());
		Local<Object> value = currentJob.value->ToObject();

		if(currentJob.type == COLLECTION_ARRAY) {
			NSArray *array = currentJob.object;

			for(NSUInteger i = 0; i < [array count]; ++i)
				value->Set((uint32_t)i, converter.convert(array[i]));
		} else {
			NSDictionary *dictionary = currentJob.object;

			[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
				if([key isKindOfClass:[NSString class]]) { // Only string key are allowed in JS
					value->Set([key V8StringInIsolate:isolate],
							   converter.convert(obj));
				}
			}];
		}

	} while(!converter.isJobListEmpty());

	return handleScope.Escape(job.value);
}

@end

@implementation L8Value (Subscripting)

- (L8Value *)objectForKeyedSubscript:(id)key
{
	if(![key isKindOfClass:[NSString class]])
		key = [[L8Value valueWithObject:key inContext:_context] toString];

	return [self valueForProperty:(NSString *)key];
}

- (L8Value *)objectAtIndexedSubscript:(NSUInteger)index
{
	return [self valueAtIndex:index];
}

- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key
{
	if(![key isKindOfClass:[NSString class]])
		key = [[L8Value valueWithObject:key inContext:_context] toString];
	[self setValue:object forProperty:(NSString *)key];
}

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index
{
	[self setValue:object atIndex:index];
}

@end
