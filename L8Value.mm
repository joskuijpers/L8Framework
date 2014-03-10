//
//  V8Value.m
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8Value_Private.h"
#import "NSString+L8.h"
#import "L8Runtime_Private.h"
#import "L8Reporter_Private.h"
#import "L8Export.h"
#import "L8WrapperMap.h"

#include "v8.h"
#import <objc/runtime.h>

#include <vector>
#include <map>

@implementation L8Value {
	v8::Handle<v8::Value> _v8value;
}

+ (L8Value *)valueWithObject:(id)value
{
	return [self valueWithV8Value:objectToValue([L8Runtime currentRuntime], value)];
}

+ (L8Value *)valueWithBool:(BOOL)value
{
	return [self valueWithV8Value:v8::Boolean::New(value)];
}

+ (L8Value *)valueWithDouble:(double)value
{
	return [self valueWithV8Value:v8::Number::New(value)];
}

+ (L8Value *)valueWithInt32:(int32_t)value
{
	return [self valueWithV8Value:v8::Int32::New(value)];
}

+ (L8Value *)valueWithUInt32:(uint32_t)value
{
	return [self valueWithV8Value:v8::Uint32::New(value)];
}

+ (L8Value *)valueWithNewObject
{
	return [self valueWithV8Value:v8::Object::New()];
}

+ (L8Value *)valueWithNewArray
{
	return [self valueWithV8Value:v8::Array::New()];
}

+ (L8Value *)valueWithNewRegularExpressionFromPattern:(NSString *)pattern flags:(NSString *)flags
{
	int iFlags = v8::RegExp::Flags::kNone;

	if([flags rangeOfString:@"g"].location != NSNotFound)
		iFlags |= v8::RegExp::Flags::kGlobal;
	if([flags rangeOfString:@"i"].location != NSNotFound)
		iFlags |= v8::RegExp::Flags::kIgnoreCase;
	if([flags rangeOfString:@"m"].location != NSNotFound)
		iFlags |= v8::RegExp::Flags::kMultiline;

	return [self valueWithV8Value:v8::RegExp::New([pattern V8String], (v8::RegExp::Flags)iFlags)];
}

+ (L8Value *)valueWithNewErrorFromMessage:(NSString *)message
{
	v8::Handle<v8::Value> error = v8::Exception::Error([message V8String]);
	return [self valueWithV8Value:error];
}

+ (L8Value *)valueWithNull
{
	return [self valueWithV8Value:v8::Null()];
}

+ (L8Value *)valueWithUndefined
{
	return [self valueWithV8Value:v8::Undefined()];
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

- (id)toFunction
{
	@throw [NSException exceptionWithName:@"NotImplemented" reason:@"Not Implemented" userInfo:nil];

	v8::Handle<v8::Function> function = _v8value.As<v8::Function>();
	v8::Handle<v8::Value> isBlock = function->GetHiddenValue(v8::String::New("isBlock"));
	if(!isBlock.IsEmpty() && isBlock->IsTrue()) {
		NSLog(@"BLOCK %@",[self toString]);
	} else {
		NSLog(@"New Function %@",[self toString]);
	}

	return nil;
}

- (BOOL)toBool
{
	return (BOOL)_v8value->IsTrue();
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
	v8::HandleScope localScope(v8::Isolate::GetCurrent());

	v8::Local<v8::Object> object = _v8value->ToObject();
	v8::Local<v8::Value> v = object->Get([property V8String]);
	return [L8Value valueWithV8Value:localScope.Close(v)];
}

- (void)setValue:(id)value forProperty:(NSString *)property
{
	v8::Local<v8::Object> object = _v8value->ToObject();
	object->Set([property V8String],objectToValue(_runtime,value));
}

- (BOOL)deleteProperty:(NSString *)property
{
	v8::Local<v8::Object> object = _v8value->ToObject();
	return object->Delete([property V8String]);
}

- (BOOL)hasProperty:(NSString *)property
{
	v8::Local<v8::Object> object = _v8value->ToObject();
	return object->Has([property V8String]);
}

- (L8Value *)valueAtIndex:(NSUInteger)index
{
	if(index != (uint32_t)index)
		return [self valueForProperty:[[L8Value valueWithDouble:index] toString]];

	v8::Local<v8::Object> object = _v8value->ToObject();

	return [L8Value valueWithV8Value:object->Get((uint32_t)index)];
}

- (void)setValue:(id)value atIndex:(NSUInteger)index
{
	if(index != (uint32_t)index)
		return [self setValue:value forProperty:[[L8Value valueWithDouble:index] toString]];

	v8::Local<v8::Object> object = _v8value->ToObject();
	object->Set((uint32_t)index, objectToValue(_runtime,value));
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
	return _v8value->IsBoolean();
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
	return 	_v8value->Equals(objectToValue(_runtime,value));
}

/*
 * This method is equal to -[isStringEqualToObject:] which is nicer
 * to write. However, to keep resemblance with JavaScriptCore we keep
 * this method.
 */
- (BOOL)isEqualWithTypeCoercionToObject:(id)value
{
	return 	_v8value->StrictEquals(objectToValue(_runtime,value));
}

- (BOOL)isStrictEqualToObject:(id)value
{
	return 	_v8value->StrictEquals(objectToValue(_runtime,value));
}

- (BOOL)isInstanceOf:(id)value
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);

//	v8::Local<v8::Object> constructor = objectToValue(_runtime, value)->ToObject();
	BOOL result = NO;

	@throw [NSException exceptionWithName:@"NotImplemented" reason:@"Not Implemented" userInfo:nil];
	return result;
}

- (void)throwValue
{
	v8::ThrowException(_v8value);
}

- (L8Value *)callWithArguments:(NSArray *)arguments
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);

	v8::Handle<v8::Value> *argv = (v8::Handle<v8::Value> *)calloc(arguments.count,sizeof(v8::Handle<v8::Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_runtime, obj);
	}];

	v8::Handle<v8::Object> function = _v8value->ToObject();

	v8::Handle<v8::Value> result;
	{
		v8::TryCatch tryCatch;

		// TODO: the receiving object should be zero (is that Global?)
		result = function->CallAsFunction(_v8value->ToObject(), (int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Close(result)];
}

- (L8Value *)constructWithArguments:(NSArray *)arguments
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);

	v8::Handle<v8::Function> function = _v8value.As<v8::Function>();

	v8::Handle<v8::Value> *argv = (v8::Handle<v8::Value> *)calloc(arguments.count,sizeof(v8::Handle<v8::Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_runtime, obj);
	}];

	v8::Handle<v8::Value> result;
	{
		v8::TryCatch tryCatch;

		result = function->CallAsConstructor((int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch inIsolate:isolate];
			return nil;
		}
	}

	return [L8Value valueWithV8Value:localScope.Close(result)];
}

- (L8Value *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments
{
	v8::Isolate *isolate = v8::Isolate::GetCurrent();
	v8::HandleScope localScope(isolate);

	v8::Handle<v8::Value> v8value = self[method]->_v8value;
	v8::Handle<v8::Function> function = v8value.As<v8::Function>();

	v8::Handle<v8::Value> *argv = (v8::Handle<v8::Value> *)calloc(arguments.count,sizeof(v8::Handle<v8::Value>));
	[arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		argv[idx] = objectToValue(_runtime, obj);
	}];

	v8::Handle<v8::Value> result;
	{
		v8::TryCatch tryCatch;

		result = function->CallAsFunction(_v8value->ToObject(), (int)[arguments count], argv);
		free((void *)argv);

		if(tryCatch.HasCaught()) {
			[L8Reporter reportTryCatch:&tryCatch
							 inIsolate:isolate];
		}
	}

	return [L8Value valueWithV8Value:localScope.Close(result)];
}

- (NSString *)description
{
	if(id wrapped = unwrapObjcObject([_runtime V8Context], _v8value))
			return [wrapped description];
	return [self toString];
}

#pragma mark - Private

+ (L8Value *)valueWithV8Value:(v8::Handle<v8::Value>)value
{
	return [[L8Runtime currentRuntime] wrapperForJSObject:value];
}

- (L8Value *)init
{
	return nil;
}

- (L8Value *)initWithV8Value:(v8::Handle<v8::Value>)value
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

- (v8::Handle<v8::Value>)V8Value
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
	bool operator()(v8::Handle<v8::Value> left, v8::Handle<v8::Value> right)
	const {
		return *left < *right;
	}
};

class JavaScriptContainerConverter
{
public:
	struct Job {
		v8::Handle<v8::Value> value;
		id object;
		COLLECTION_TYPE type;
	};

	JavaScriptContainerConverter(v8::Handle<v8::Context> context)
	: _context(context)
	{}

	id convert(v8::Handle<v8::Value> value);
	void add(Job job);
	Job take();
	bool isJobListEmpty() { return _jobList.size() == 0; }

private:
	v8::Handle<v8::Context> _context;
	std::map<v8::Handle<v8::Value>, id, ValueCompare> _objectMap;
	std::vector<Job> _jobList;
};

id JavaScriptContainerConverter::convert(v8::Handle<v8::Value> value)
{
	std::map<v8::Handle<v8::Value>, id>::iterator i = _objectMap.find(value);
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

static JavaScriptContainerConverter::Job valueToObjectWithoutCopy(v8::Handle<v8::Context> context, v8::Handle<v8::Value> value)
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

	v8::Handle<v8::Object> object = value->ToObject();
	if(id wrapped = unwrapObjcObject(context, value))
		return (JavaScriptContainerConverter::Job){ object, wrapped, COLLECTION_NONE };

	if(object->IsDate())
		return (JavaScriptContainerConverter::Job){ object, [NSDate dateWithTimeIntervalSince1970:object->ToNumber()->Value()], COLLECTION_NONE };

	if(object->IsArray())
		return (JavaScriptContainerConverter::Job){ object, [NSMutableArray array], COLLECTION_ARRAY };

	return (JavaScriptContainerConverter::Job){ object, [NSMutableDictionary dictionary], COLLECTION_DICTIONARY };
}

static id containerValueToObject(v8::Handle<v8::Context> context, JavaScriptContainerConverter::Job job)
{
	assert(job.type != COLLECTION_NONE);
	JavaScriptContainerConverter converter(context);
	converter.add(job);

	do {
		JavaScriptContainerConverter::Job currentJob = converter.take();
		assert(currentJob.value->IsObject());
		v8::Handle<v8::Object> value = currentJob.value->ToObject();

		if(currentJob.type == COLLECTION_ARRAY) {
			NSMutableArray *array = currentJob.object;

			uint32_t length = value->Get([@"length" V8String])->Uint32Value();

			for(uint32_t i = 0; i < length; i++) {
				id object = converter.convert(value->Get(i));
				[array addObject:object?object:[NSNull null]];
			}

		} else {
			NSMutableDictionary *dictionary = currentJob.object;

			v8::Handle<v8::Array> propertyNames = value->GetPropertyNames();
			uint32_t length = propertyNames->Length();

			for(uint32_t i = 0; i < length; i++) {
				v8::Handle<v8::Value> key = propertyNames->Get(i);
				id object = converter.convert(value->Get(key));
				if(object)
					dictionary[[NSString stringWithV8Value:key]] = object;
			}
		}

	} while(!converter.isJobListEmpty());

	return job.object;
}

id valueToObject(L8Runtime *runtime, v8::Handle<v8::Value> value)
{
	JavaScriptContainerConverter::Job job = valueToObjectWithoutCopy([runtime V8Context], value);
	if(job.type == COLLECTION_NONE)
		return job.object;
	return containerValueToObject([runtime V8Context], job);
}

NSNumber *valueToNumber(L8Runtime *runtime, v8::Handle<v8::Value> value)
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

NSString *valueToString(L8Runtime *runtime, v8::Handle<v8::Value> value)
{
	id wrapped = unwrapObjcObject([runtime V8Context], value);
	if(wrapped && [wrapped isKindOfClass:[NSString class]]) {
		return wrapped;
	}

	if(value.IsEmpty())
		return nil;

	return [NSString stringWithV8String:value->ToString()];
}

NSDate *valueToDate(L8Runtime *runtime, v8::Handle<v8::Value> value)
{
	id wrapped = unwrapObjcObject([runtime V8Context], value);
	if(wrapped && [wrapped isKindOfClass:[NSDate class]]) {
		return wrapped;
	}

	return [NSDate dateWithTimeIntervalSince1970:value->NumberValue()];
}

NSArray *valueToArray(L8Runtime *runtime, v8::Handle<v8::Value> value)
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

NSDictionary *valueToDictionary(L8Runtime *runtime, v8::Handle<v8::Value> value)
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
		v8::Handle<v8::Value> value;
		COLLECTION_TYPE type;
	};

	ObjCContainerConverter(L8Runtime *runtime)
	: _runtime(runtime)
	{}

	v8::Handle<v8::Value> convert(id object);
	void add(Job job);
	Job take();
	bool isJobListEmpty() { return _jobList.size() == 0; }

private:
	L8Runtime *_runtime;
	std::map<id, v8::Handle<v8::Value>> _objectMap;
	std::vector<Job> _jobList;
};

v8::Handle<v8::Value> ObjCContainerConverter::convert(id object)
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
	if(!object)
		return (ObjCContainerConverter::Job){ object, v8::Undefined(), COLLECTION_NONE };

	if(![object conformsToProtocol:@protocol(L8Export)]) {

		if([object isKindOfClass:[NSArray class]])
			return (ObjCContainerConverter::Job){ object, v8::Array::New(), COLLECTION_ARRAY };

		if([object isKindOfClass:[NSDictionary class]])
			return (ObjCContainerConverter::Job){ object, v8::Object::New(), COLLECTION_DICTIONARY };

		if([object isKindOfClass:[NSNull class]])
			return (ObjCContainerConverter::Job){ object, v8::Null(), COLLECTION_NONE };

		if([object isKindOfClass:[L8Value class]])
			return (ObjCContainerConverter::Job){ object, ((L8Value *)object)->_v8value, COLLECTION_NONE };

		if([object isKindOfClass:[NSString class]])
			return (ObjCContainerConverter::Job){ object, [(NSString *)object V8String], COLLECTION_NONE };

		if([object isKindOfClass:[NSNumber class]]) {
			assert([@YES class] == [@NO class]);
			assert([@YES class] != [NSNumber class]);
			assert([[@YES class] isSubclassOfClass:[NSNumber class]]);
			if([object isKindOfClass:[@YES class]]) // Pretty much a hack: assumes Boolean class cluster
				return (ObjCContainerConverter::Job){ object, v8::Boolean::New([object boolValue]), COLLECTION_NONE };
			return (ObjCContainerConverter::Job){ object, v8::Number::New([object doubleValue]), COLLECTION_NONE };
		}

		if([object isKindOfClass:[NSDate class]])
			return (ObjCContainerConverter::Job){ object, v8::Date::New([object timeIntervalSince1970]), COLLECTION_NONE };

		if([object isKindOfClass:BlockClass()]) {
			//return (ObjCContainerConverter::Job){ object, makeWrapper([runtime V8Context], [object copy]), COLLECTION_NONE };
			return (ObjCContainerConverter::Job){ object, [runtime wrapperForObjCObject:object]->_v8value, COLLECTION_NONE };
		}

		assert(0 && "Code must not be reached, or implementation is missing");

		// managed value
		// https://github.com/WebKit/webkit/blob/master/Source/JavaScriptCore/API/L8Value.mm#L901
	}

	return (ObjCContainerConverter::Job){ object, [runtime wrapperForObjCObject:object]->_v8value, COLLECTION_NONE };
}

v8::Local<v8::Value> objectToValue(L8Runtime *runtime, id object)
{
	v8::Handle<v8::Context> context = [runtime V8Context];
	v8::HandleScope handleScope(context->GetIsolate());

	if(object == nil)
		handleScope.Close(v8::Null());

	ObjCContainerConverter::Job job = objectToValueWithoutCopy(runtime, object);
	if(job.type == COLLECTION_NONE)
		return handleScope.Close(job.value);

	__block ObjCContainerConverter converter(runtime);
	converter.add(job);

	do {
		ObjCContainerConverter::Job currentJob = converter.take();
		assert(currentJob.value->IsObject());
		v8::Handle<v8::Object> value = currentJob.value->ToObject();

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

	return handleScope.Close(job.value);
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
