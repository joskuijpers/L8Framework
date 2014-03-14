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
#import "NSString+L8.h"
#import "L8Runtime_Private.h"
#import "L8Reporter_Private.h"
#import "L8Export.h"
#import "L8WrapperMap.h"
#import "L8ManagedValue_Private.h"

#include "v8.h"
#import <objc/runtime.h>

#include <vector>
#include <map>

using namespace v8;

@implementation L8Value {
	Local<Value> _v8value;
}

+ (L8Value *)valueWithObject:(id)value
{
	return [self valueWithV8Value:objectToValue([L8Runtime currentRuntime], value)];
}

+ (L8Value *)valueWithBool:(BOOL)value
{
	return [self valueWithV8Value:v8::Boolean::New(Isolate::GetCurrent(),value)];
}

+ (L8Value *)valueWithDouble:(double)value
{
	return [self valueWithV8Value:Number::New(Isolate::GetCurrent(),value)];
}

+ (L8Value *)valueWithInt32:(int32_t)value
{
	return [self valueWithV8Value:Int32::New(Isolate::GetCurrent(),value)];
}

+ (L8Value *)valueWithUInt32:(uint32_t)value
{
	return [self valueWithV8Value:Uint32::New(Isolate::GetCurrent(),value)];
}

+ (L8Value *)valueWithNewObject
{
	return [self valueWithV8Value:Object::New(Isolate::GetCurrent())];
}

+ (L8Value *)valueWithNewArray
{
	return [self valueWithV8Value:Array::New(Isolate::GetCurrent())];
}

+ (L8Value *)valueWithNewRegularExpressionFromPattern:(NSString *)pattern flags:(NSString *)flags
{
	int iFlags = RegExp::Flags::kNone;

	if([flags rangeOfString:@"g"].location != NSNotFound)
		iFlags |= RegExp::Flags::kGlobal;
	if([flags rangeOfString:@"i"].location != NSNotFound)
		iFlags |= RegExp::Flags::kIgnoreCase;
	if([flags rangeOfString:@"m"].location != NSNotFound)
		iFlags |= RegExp::Flags::kMultiline;

	return [self valueWithV8Value:RegExp::New([pattern V8String], (RegExp::Flags)iFlags)];
}

+ (L8Value *)valueWithNewErrorFromMessage:(NSString *)message
{
	Local<Value> error = Exception::Error([message V8String]);
	return [self valueWithV8Value:error];
}

+ (L8Value *)valueWithNull
{
	return [self valueWithV8Value:Null(Isolate::GetCurrent())];
}

+ (L8Value *)valueWithUndefined
{
	return [self valueWithV8Value:Undefined(Isolate::GetCurrent())];
}

- (id)toObject
{
	return valueToObject(_runtime, _v8value);
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

	isBlock = function->GetHiddenValue(String::NewFromUtf8(Isolate::GetCurrent(), "isBlock"));
	if(!isBlock.IsEmpty() && isBlock->IsTrue()) {
		id block;

		block = unwrapBlock(function);

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
	return valueToNumber(_runtime, _v8value);
}

- (NSString *)toString
{
	return valueToString(_runtime, _v8value);
}

- (NSDate *)toDate
{
	return valueToDate(_runtime, _v8value);
}

- (NSArray *)toArray
{
	return valueToArray(_runtime, _v8value);
}

- (NSDictionary *)toDictionary
{
	return valueToDictionary(_runtime, _v8value);
}

- (L8Value *)valueForProperty:(NSString *)property
{
	EscapableHandleScope localScope(Isolate::GetCurrent());

	Local<Object> object = _v8value->ToObject();
	Local<Value> v = object->Get([property V8String]);
	return [L8Value valueWithV8Value:localScope.Escape(v)];
}

- (void)setValue:(id)value forProperty:(NSString *)property
{
	Local<Object> object = _v8value->ToObject();
	object->Set([property V8String],objectToValue(_runtime,value));
}

- (BOOL)deleteProperty:(NSString *)property
{
	Local<Object> object = _v8value->ToObject();
	return object->Delete([property V8String]);
}

- (BOOL)hasProperty:(NSString *)property
{
	Local<Object> object = _v8value->ToObject();
	return object->Has([property V8String]);
}

- (L8Value *)valueAtIndex:(NSUInteger)index
{
	if(index != (uint32_t)index)
		return [self valueForProperty:[[L8Value valueWithDouble:index] toString]];

	Local<Object> object = _v8value->ToObject();

	return [L8Value valueWithV8Value:object->Get((uint32_t)index)];
}

- (void)setValue:(id)value atIndex:(NSUInteger)index
{
	if(index != (uint32_t)index)
		return [self setValue:value forProperty:[[L8Value valueWithDouble:index] toString]];

	Local<Object> object = _v8value->ToObject();
	object->Set((uint32_t)index, objectToValue(_runtime,value));
}

- (void)defineProperty:(NSString *)property descriptor:(id)descriptor
{
	[_runtime.globalObject[@"Object"] invokeMethod:@"defineProperty"
									 withArguments:@[self, property, descriptor]];
}

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
	return 	_v8value->StrictEquals(objectToValue(_runtime,value));
}

- (BOOL)isEqualWithTypeCoercionToObject:(id)value
{
	return 	_v8value->Equals(objectToValue(_runtime,value));
}

- (BOOL)isInstanceOf:(id)value
{
	Class cls = Nil;
	L8WrapperMap *map;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope localScope(isolate);
	Local<FunctionTemplate> funcTemplate;

	if(class_isMetaClass(cls))
		cls = value;
	else
		cls = [value class];

	map = [[L8Runtime currentRuntime] wrapperMap];
	funcTemplate = [map getCachedFunctionTemplateForClass:cls];
	if(funcTemplate.IsEmpty())
		return NO;

	return funcTemplate->HasInstance(_v8value);
}

- (void)throwValue
{
	Isolate::GetCurrent()->ThrowException(_v8value);
}

- (L8Value *)callWithArguments:(NSArray *)arguments
{
	Isolate *isolate = Isolate::GetCurrent();
	EscapableHandleScope localScope(isolate);
	Local<Value> *argv, result;
	Local<Object> function;

	if(!_v8value->IsFunction())
		return [L8Value valueWithUndefined];

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_runtime, obj);
	}];

	function = _v8value->ToObject();

	{
		TryCatch tryCatch;

		result = function->CallAsFunction(_v8value->ToObject(), (int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Escape(result)];
}

- (L8Value *)constructWithArguments:(NSArray *)arguments
{
	Isolate *isolate = Isolate::GetCurrent();
	EscapableHandleScope localScope(isolate);
	Local<Function> function;
	Local<Value> *argv, result;

	// Just like ObjC, we want no need to check the validity of
	// self when invoking this method.
	if(!_v8value->IsFunction())
		return [L8Value valueWithUndefined];

	function = _v8value.As<Function>();

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_runtime, obj);
	}];

	{
		TryCatch tryCatch;

		result = function->CallAsConstructor((int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Escape(result)];
}

- (L8Value *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments
{
	Isolate *isolate = Isolate::GetCurrent();
	EscapableHandleScope localScope(isolate);
	L8Value *function;
	Local<Value> v8value, result, *argv;
	Local<Function> v8function;

	// Just like ObjC, we want no need to check the validity of
	// self when invoking this method.
	if(_v8value->IsUndefined() || _v8value->IsNull())
		return [L8Value valueWithUndefined];

	function = self[method];
	if(!function || function->_v8value->IsUndefined())
		return [L8Value valueWithUndefined];

	v8value = function->_v8value;
	v8function = v8value.As<Function>();

	argv = (Local<Value> *)calloc(arguments.count,sizeof(Local<Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_runtime, obj);
	}];

	{
		TryCatch tryCatch;

		result = v8function->CallAsFunction(_v8value->ToObject(), (int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch
							 inIsolate:isolate];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Escape(result)];
}

- (NSString *)description
{
	if(id wrapped = unwrapObjcObject([_runtime V8Context], _v8value))
			return [wrapped description];
	return [self toString];
}

#pragma mark - Private

+ (L8Value *)valueWithV8Value:(Local<Value>)value
{
	return [[L8Runtime currentRuntime] wrapperForJSObject:value];
}

- (L8Value *)init
{
	return nil;
}

- (L8Value *)initWithV8Value:(Local<Value>)value
{
	if(value.IsEmpty())
		return nil;

	self = [super init];
	if(self) {
		_v8value = value;
		_runtime = [L8Runtime currentRuntime];
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

static JavaScriptContainerConverter::Job valueToObjectWithoutCopy(Local<Context> context, Local<Value> value)
{
	if(!value->IsObject()) {
		id primitive;

		if(value->IsBoolean())
			primitive = [NSNumber numberWithBool:value->BooleanValue()];
		else if(value->IsNumber())
			primitive = [NSNumber numberWithDouble:value->ToNumber()->Value()];
		else if(value->IsString())
			primitive = [NSString stringWithV8Value:value];
		else if(value->IsNull())
			primitive = [NSNull null];
		else {
			assert(value->IsUndefined());
			primitive = nil;
		}
		return (JavaScriptContainerConverter::Job){ value, primitive, COLLECTION_NONE };
	}

	Local<Object> object = value->ToObject();
	if(id wrapped = unwrapObjcObject(context, value))
		return (JavaScriptContainerConverter::Job){ object, wrapped, COLLECTION_NONE };

	if(object->IsDate())
		return (JavaScriptContainerConverter::Job){ object, [NSDate dateWithTimeIntervalSince1970:object->ToNumber()->Value()], COLLECTION_NONE };

	if(object->IsArray())
		return (JavaScriptContainerConverter::Job){ object, [NSMutableArray array], COLLECTION_ARRAY };

	return (JavaScriptContainerConverter::Job){ object, [NSMutableDictionary dictionary], COLLECTION_DICTIONARY };
}

static id containerValueToObject(Local<Context> context, JavaScriptContainerConverter::Job job)
{
	assert(job.type != COLLECTION_NONE);
	JavaScriptContainerConverter converter(context);
	converter.add(job);

	do {
		JavaScriptContainerConverter::Job currentJob = converter.take();
		assert(currentJob.value->IsObject());
		Local<Object> value = currentJob.value->ToObject();

		if(currentJob.type == COLLECTION_ARRAY) {
			NSMutableArray *array = currentJob.object;

			uint32_t length = value->Get([@"length" V8String])->Uint32Value();

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
					dictionary[[NSString stringWithV8Value:key]] = object;
			}
		}

	} while(!converter.isJobListEmpty());

	return job.object;
}

id valueToObject(L8Runtime *runtime, Local<Value> value)
{
	JavaScriptContainerConverter::Job job = valueToObjectWithoutCopy([runtime V8Context], value);
	if(job.type == COLLECTION_NONE)
		return job.object;
	return containerValueToObject([runtime V8Context], job);
}

NSNumber *valueToNumber(L8Runtime *runtime, Local<Value> value)
{
	id wrapped = unwrapObjcObject([runtime V8Context], value);
	if(wrapped && [wrapped isKindOfClass:[NSNumber class]]) {
		return wrapped;
	}

	if(value->IsInt32())
		return [NSNumber numberWithInteger:value->Int32Value()];
	else if(value->IsUint32())
		return [NSNumber numberWithUnsignedInteger:value->Uint32Value()];
	return [NSNumber numberWithDouble:value->NumberValue()];
}

NSString *valueToString(L8Runtime *runtime, Local<Value> value)
{
	id wrapped = unwrapObjcObject([runtime V8Context], value);
	if(wrapped && [wrapped isKindOfClass:[NSString class]]) {
		return wrapped;
	}

	if(value.IsEmpty())
		return nil;

	return [NSString stringWithV8String:value->ToString()];
}

NSDate *valueToDate(L8Runtime *runtime, Local<Value> value)
{
	id wrapped = unwrapObjcObject([runtime V8Context], value);
	if(wrapped && [wrapped isKindOfClass:[NSDate class]]) {
		return wrapped;
	}

	return [NSDate dateWithTimeIntervalSince1970:value->NumberValue()];
}

NSArray *valueToArray(L8Runtime *runtime, Local<Value> value)
{
	id wrapped = unwrapObjcObject([runtime V8Context], value);
	if(wrapped && [wrapped isKindOfClass:[NSArray class]]) {
		return wrapped;
	}

	if(value->IsArray())
		return containerValueToObject([runtime V8Context], (JavaScriptContainerConverter::Job){value, [NSMutableArray array], COLLECTION_ARRAY});

	if(!value->IsNull() && value->IsUndefined())
		@throw [NSException exceptionWithName:@"TypeErrror"
									   reason:@"Cannot convert to Array" userInfo:nil];

	return nil;
}

NSDictionary *valueToDictionary(L8Runtime *runtime, Local<Value> value)
{
	id wrapped = unwrapObjcObject([runtime V8Context], value);
	if(wrapped && [wrapped isKindOfClass:[NSDictionary class]]) {
		return wrapped;
	}

	if(value->IsObject())
		return containerValueToObject([runtime V8Context], (JavaScriptContainerConverter::Job){ value, [NSMutableDictionary dictionary], COLLECTION_DICTIONARY} );

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

	ObjCContainerConverter(L8Runtime *runtime)
	: _runtime(runtime)
	{}

	Local<Value> convert(id object);
	void add(Job job);
	Job take();
	bool isJobListEmpty() { return _jobList.size() == 0; }

private:
	L8Runtime *_runtime;
	std::map<id, Local<Value>> _objectMap;
	std::vector<Job> _jobList;
};

Local<Value> ObjCContainerConverter::convert(id object)
{
	auto i = _objectMap.find(object);
	if(i != _objectMap.end())
		return i->second;

	Job job = objectToValueWithoutCopy(_runtime, object);
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

static ObjCContainerConverter::Job objectToValueWithoutCopy(L8Runtime *runtime, id object)
{
	Isolate *isolate = Isolate::GetCurrent();
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

		if([object isKindOfClass:[NSString class]])
			return (ObjCContainerConverter::Job){object, [(NSString *)object V8String], COLLECTION_NONE};

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
			return (ObjCContainerConverter::Job){object, [runtime wrapperForObjCObject:object]->_v8value, COLLECTION_NONE};

		if([object isKindOfClass:[L8ManagedValue class]]) {
			L8Value *value;

			value = [(L8ManagedValue *)object value];
			if(!value) // collected
				return (ObjCContainerConverter::Job){object, Undefined(isolate), COLLECTION_NONE};
			return (ObjCContainerConverter::Job){object, [value V8Value], COLLECTION_NONE};
		}
	}

	return (ObjCContainerConverter::Job){ object, [runtime wrapperForObjCObject:object]->_v8value, COLLECTION_NONE };
}

Local<Value> objectToValue(L8Runtime *runtime, id object)
{
	Local<Context> context = [runtime V8Context];
	Isolate *isolate = context->GetIsolate();
	EscapableHandleScope handleScope(isolate);

	if(object == nil)
		return handleScope.Escape((Local<Value>)Undefined(isolate));

	ObjCContainerConverter::Job job = objectToValueWithoutCopy(runtime, object);
	if(job.type == COLLECTION_NONE)
		return handleScope.Escape(job.value);

	__block ObjCContainerConverter converter(runtime);
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
					value->Set([key V8String],
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
		key = [[L8Value valueWithObject:key] toString];

	return [self valueForProperty:(NSString *)key];
}

- (L8Value *)objectAtIndexedSubscript:(NSUInteger)index
{
	return [self valueAtIndex:index];
}

- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key
{
	if(![key isKindOfClass:[NSString class]])
		key = [[L8Value valueWithObject:key] toString];
	[self setValue:object forProperty:(NSString *)key];
}

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index
{
	[self setValue:object atIndex:index];
}

@end