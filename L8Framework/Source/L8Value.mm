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

#include "v8.h"
#import <objc/runtime.h>

#include <vector>
#include <map>

using namespace v8;

@implementation L8Value {
	Local<Value> _v8value;
}

#pragma mark Value creations

+ (instancetype)valueWithObject:(id)value inContext:(L8Context *)context
{
	return [self valueWithV8Value:objectToValue(context, value) inContext:context];
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

#pragma mark Object conversions

- (id)toObject
{
	return valueToObject(_context, _v8value);
}

- (id)toObjectOfClass:(Class)expectedClass
{
	id result = [self toObject];
	return [result isKindOfClass:expectedClass]?result:nil;
}

- (id)toBlockFunction
{
	Local<Function> function;
	Local<Value> isBlock;

	if(!_v8value->IsFunction())
		return nil;

	function = _v8value.As<Function>();

	isBlock = function->GetHiddenValue(String::NewFromUtf8(_context.virtualMachine.V8Isolate, "isBlock"));
	if(!isBlock.IsEmpty() && isBlock->IsTrue()) {
		id block;

		block = l8_unwrap_block(_context.virtualMachine.V8Isolate,function);

		return block;
	}

	return nil;
}

- (BOOL)toBool
{
	return (BOOL)_v8value->ToBoolean()->IsTrue();
}

- (double)toDouble
{
	return _v8value->NumberValue();
}

- (int32_t)toInt32
{
	return _v8value->Int32Value();
}

- (uint32_t)toUInt32
{
	return _v8value->Uint32Value();
}

- (NSNumber *)toNumber
{
	return valueToNumber(_context, _v8value);
}

- (NSString *)toString
{
	return valueToString(_context, _v8value);
}

- (NSDate *)toDate
{
	return valueToDate(_context, _v8value);
}

- (NSArray *)toArray
{
	return valueToArray(_context, _v8value);
}

- (NSDictionary *)toDictionary
{
	return valueToDictionary(_context, _v8value);
}

#pragma mark Setting and getting properties

- (L8Value *)valueForProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	Local<Object> object;
	Local<Value> value;

	object = _v8value->ToObject();
	value = object->Get([property V8StringInIsolate:isolate]);

	return [L8Value valueWithV8Value:localScope.Escape(value) inContext:_context];
}

- (void)setValue:(id)value forProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object = _v8value->ToObject();
	object->Set([property V8StringInIsolate:isolate],objectToValue(_context,value));
}

- (BOOL)deleteProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object = _v8value->ToObject();
	return object->Delete([property V8StringInIsolate:isolate]);
}

- (BOOL)hasProperty:(NSString *)property
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<Object> object = _v8value->ToObject();
	return object->Has([property V8StringInIsolate:isolate]);
}

- (L8Value *)valueAtIndex:(NSUInteger)index
{
	Local<Object> object;

	if(index != (uint32_t)index) {
		NSString *propertyName;

		propertyName = [[L8Value valueWithDouble:index inContext:_context] toString];
		return [self valueForProperty:propertyName];
	}

	object = _v8value->ToObject();

	return [L8Value valueWithV8Value:object->Get((uint32_t)index) inContext:_context];
}

- (void)setValue:(id)value atIndex:(NSUInteger)index
{
	Local<Object> object;

	if(index != (uint32_t)index) {
		NSString *propertyName;

		propertyName = [[L8Value valueWithDouble:index inContext:_context] toString];
		return [self setValue:value forProperty:propertyName];
	}

	object = _v8value->ToObject();
	object->Set((uint32_t)index, objectToValue(_context,value));
}

- (void)defineProperty:(NSString *)property descriptor:(id)descriptor
{
	[_context.globalObject[@"Object"] invokeMethod:@"defineProperty"
									 withArguments:@[self, property, descriptor]];
}

#pragma mark Type discovery

- (BOOL)isUndefined
{
	return _v8value->IsUndefined();
}

- (BOOL)isNull
{
	return _v8value->IsNull();
}

- (BOOL)isBoolean
{
	return _v8value->IsBoolean() || (_v8value->IsNumber() && _v8value->Uint32Value() <= 1);
}

- (BOOL)isNumber
{
	return _v8value->IsNumber();
}

- (BOOL)isString
{
	return _v8value->IsString();
}

- (BOOL)isObject
{
	return _v8value->IsObject() && !_v8value->IsFunction();
}

- (BOOL)isFunction
{
	return _v8value->IsFunction();
}

- (BOOL)isRegularExpression
{
	return _v8value->IsRegExp();
}

- (BOOL)isNativeError
{
	return _v8value->IsNativeError();
}

- (BOOL)isEqualToObject:(id)value
{
	return 	_v8value->StrictEquals(objectToValue(_context,value));
}

- (BOOL)isEqualWithTypeCoercionToObject:(id)value
{
	return 	_v8value->Equals(objectToValue(_context,value));
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

	return funcTemplate->HasInstance(_v8value);
}

#pragma mark Throwing exceptions

- (void)throwValue
{
	_context.virtualMachine.V8Isolate->ThrowException(_v8value);
}

#pragma mark Invoking methods and constructors

- (L8Value *)callWithArguments:(NSArray *)arguments
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	Local<Value> *argv, result;
	Local<Object> function;

	if(!_v8value->IsFunction())
		return [L8Value valueWithUndefinedInContext:_context];

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_context, obj);
	}];

	function = _v8value->ToObject();

	{
		TryCatch tryCatch;

		result = function->CallAsFunction(_v8value->ToObject(), (int)[arguments count], argv);
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
	Local<Value> *argv, result;

	// Just like ObjC, we want no need to check the validity of
	// self when invoking this method.
	if(!_v8value->IsFunction())
		return [L8Value valueWithUndefinedInContext:_context];

	function = _v8value.As<Function>();

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_context, obj);
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
	Local<Value> v8value, result, *argv;
	Local<Function> v8function;

	// Just like ObjC, we want no need to check the validity of
	// self when invoking this method.
	if(_v8value->IsUndefined() || _v8value->IsNull())
		return [L8Value valueWithUndefinedInContext:_context];

	function = self[method];
	if(!function || function->_v8value->IsUndefined())
		return [L8Value valueWithUndefinedInContext:_context];

	v8value = function->_v8value;
	v8function = v8value.As<Function>();

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_context, obj);
	}];

	{
		TryCatch tryCatch;

		result = v8function->CallAsFunction(_v8value->ToObject(), (int)[arguments count], argv);
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

	if(id wrapped = l8_unwrap_objc_object(_context.virtualMachine.V8Isolate, _v8value))
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
		_v8value = value;
		_context = context;
	}
	return self;
}

- (Local<Value>)V8Value
{
	return _v8value;
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

	JavaScriptContainerConverter(Local<Context> context)
	: _context(context)
	{}

	id convert(Local<Value> value);
	void add(Job job);
	Job take();
	bool isJobListEmpty() { return _jobList.size() == 0; }

private:
	Local<Context> _context;
	std::map<Local<Value>, id, ValueCompare> _objectMap;
	std::vector<Job> _jobList;
};

id JavaScriptContainerConverter::convert(Local<Value> value)
{
	std::map<Local<Value>, id>::iterator i = _objectMap.find(value);
	if(i != _objectMap.end())
		return i->second;

	Job job = valueToObjectWithoutCopy(_context, value);
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

static JavaScriptContainerConverter::Job valueToObjectWithoutCopy(Local<Context> v8context, Local<Value> value)
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
		else {
			assert(value->IsUndefined());
			primitive = nil;
		}
		return (JavaScriptContainerConverter::Job){ value, primitive, COLLECTION_NONE };
	}

	object = value->ToObject();
	if(id wrapped = l8_unwrap_objc_object(v8context->GetIsolate(), value))
		return (JavaScriptContainerConverter::Job){ object, wrapped, COLLECTION_NONE };

	if(object->IsDate())
		return (JavaScriptContainerConverter::Job){ object, [NSDate dateWithTimeIntervalSince1970:object->ToNumber()->Value()], COLLECTION_NONE };

	if(object->IsArray())
		return (JavaScriptContainerConverter::Job){ object, [NSMutableArray array], COLLECTION_ARRAY };

	return (JavaScriptContainerConverter::Job){ object, [NSMutableDictionary dictionary], COLLECTION_DICTIONARY };
}

static id containerValueToObject(Local<Context> v8context, JavaScriptContainerConverter::Job job)
{
	Isolate *isolate = v8context->GetIsolate();

	assert(job.type != COLLECTION_NONE);
	JavaScriptContainerConverter converter(v8context);
	converter.add(job);

	do {
		JavaScriptContainerConverter::Job currentJob = converter.take();
		assert(currentJob.value->IsObject());
		Local<Object> value = currentJob.value->ToObject();

		if(currentJob.type == COLLECTION_ARRAY) {
			NSMutableArray *array = currentJob.object;

			uint32_t length = value->Get([@"length" V8StringInIsolate:isolate])->Uint32Value();

			for(uint32_t i = 0; i < length; i++) {
				id object = converter.convert(value->Get(i));
				[array addObject:object?object:[NSNull null]];
			}

		} else {
			NSMutableDictionary *dictionary = currentJob.object;

			Local<Array> propertyNames = value->GetPropertyNames();
			uint32_t length = propertyNames->Length();

			for(uint32_t i = 0; i < length; i++) {
				Local<Value> key = propertyNames->Get(i);
				id object = converter.convert(value->Get(key));
				if(object)
					dictionary[[NSString stringWithV8Value:key inIsolate:isolate]] = object;
			}
		}

	} while(!converter.isJobListEmpty());

	return job.object;
}

id valueToObject(L8Context *context, Local<Value> value)
{
	JavaScriptContainerConverter::Job job = valueToObjectWithoutCopy(context.V8Context, value);
	if(job.type == COLLECTION_NONE)
		return job.object;
	return containerValueToObject(context.V8Context, job);
}

NSNumber *valueToNumber(L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(context.virtualMachine.V8Isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSNumber class]]) {
		return wrapped;
	}

	if(value->IsInt32())
		return [NSNumber numberWithInteger:value->Int32Value()];
	else if(value->IsUint32())
		return [NSNumber numberWithUnsignedInteger:value->Uint32Value()];
	return [NSNumber numberWithDouble:value->NumberValue()];
}

NSString *valueToString(L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(context.virtualMachine.V8Isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSString class]]) {
		return wrapped;
	}

	if(value.IsEmpty())
		return nil;

	return [NSString stringWithV8String:value->ToString()];
}

NSDate *valueToDate(L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(context.virtualMachine.V8Isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSDate class]]) {
		return wrapped;
	}

	return [NSDate dateWithTimeIntervalSince1970:value->NumberValue()];
}

NSArray *valueToArray(L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(context.virtualMachine.V8Isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSArray class]]) {
		return wrapped;
	}

	if(value->IsArray())
		return containerValueToObject(context.V8Context, (JavaScriptContainerConverter::Job){value, [NSMutableArray array], COLLECTION_ARRAY});

	if(!value->IsNull() && value->IsUndefined())
		@throw [NSException exceptionWithName:@"TypeErrror"
									   reason:@"Cannot convert to Array" userInfo:nil];

	return nil;
}

NSDictionary *valueToDictionary(L8Context *context, Local<Value> value)
{
	id wrapped = l8_unwrap_objc_object(context.virtualMachine.V8Isolate, value);
	if(wrapped && [wrapped isKindOfClass:[NSDictionary class]]) {
		return wrapped;
	}

	if(value->IsObject())
		return containerValueToObject(context.V8Context, (JavaScriptContainerConverter::Job){ value, [NSMutableDictionary dictionary], COLLECTION_DICTIONARY} );

	if(!value->IsNull() && value->IsUndefined())
		@throw [NSException exceptionWithName:@"TypeErrror"
									   reason:@"Cannot convert to Dictionary" userInfo:nil];

	return nil;
}

class ObjCContainerConverter
{
public:
	struct Job {
		id object;
		Local<Value> value;
		COLLECTION_TYPE type;
	};

	ObjCContainerConverter(L8Context *context)
	: _context(context)
	{}

	Local<Value> convert(id object);
	void add(Job job);
	Job take();
	bool isJobListEmpty() { return _jobList.size() == 0; }

private:
	L8Context *_context;
	std::map<id, Local<Value>> _objectMap;
	std::vector<Job> _jobList;
};

Local<Value> ObjCContainerConverter::convert(id object)
{
	auto i = _objectMap.find(object);
	if(i != _objectMap.end())
		return i->second;

	Job job = objectToValueWithoutCopy(_context, object);
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

static ObjCContainerConverter::Job objectToValueWithoutCopy(L8Context *context, id object)
{
	Isolate *isolate = context.virtualMachine.V8Isolate;
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
			return (ObjCContainerConverter::Job){object, ((L8Value *)object)->_v8value, COLLECTION_NONE};

		if([object isKindOfClass:[NSString class]]) {
			return (ObjCContainerConverter::Job) {
				object,
				[(NSString *)object V8StringInIsolate:isolate],
				COLLECTION_NONE
			};
		}

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
			return (ObjCContainerConverter::Job){object, [context wrapperForObjCObject:object]->_v8value, COLLECTION_NONE};

		if([object isKindOfClass:[L8ManagedValue class]]) {
			L8Value *value;

			value = [(L8ManagedValue *)object value];
			if(!value) // collected
				return (ObjCContainerConverter::Job){object, Undefined(isolate), COLLECTION_NONE};
			return (ObjCContainerConverter::Job){object, value.V8Value, COLLECTION_NONE};
		}
	}

	return (ObjCContainerConverter::Job){ object, [context wrapperForObjCObject:object]->_v8value, COLLECTION_NONE };
}

Local<Value> objectToValue(L8Context *context, id object)
{
	Isolate *isolate = context.virtualMachine.V8Isolate;
	EscapableHandleScope handleScope(isolate);

	if(object == nil)
		return handleScope.Escape((Local<Value>)Undefined(isolate));

	ObjCContainerConverter::Job job = objectToValueWithoutCopy(context, object);
	if(job.type == COLLECTION_NONE)
		return handleScope.Escape(job.value);

	__block ObjCContainerConverter converter(context);
	converter.add(job);

	do {
		ObjCContainerConverter::Job currentJob = converter.take();
		assert(currentJob.value->IsObject());
		Local<Object> value = currentJob.value->ToObject();

		if(currentJob.type == COLLECTION_ARRAY) {
			NSArray *array = currentJob.object;

			for(NSUInteger i = 0; i < [array count]; i++)
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
