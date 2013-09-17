//
//  L8WrapperMap.m
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <objc/runtime.h>

#import "L8WrapperMap.h"

#import "L8Runtime_Private.h"
#import "L8Value_Private.h"
#import "L8Export.h"

#import "NSString+L8.h"
#import "ObjCRuntime+L8.h"
#import "ObjCCallback.h"

#include "v8.h"
#include <map>
#import <vector>

@class L8ClassInfo;

@interface L8WrapperMap ()
- (L8ClassInfo *)classInfoForClass:(Class)cls;
@end

static NSString *selectorToPropertyName(const char *start)
{
	// Find the first semicolon
	const char *firstColon = index(start, ':');
	if(!firstColon)
		return [NSString stringWithUTF8String:start];

	size_t header = firstColon - start;
	char *buffer = (char *)malloc(header + strlen(firstColon + 1) + 1);
	memcpy(buffer, start, header);

	char *output = buffer + header;
	const char *input = start + header + 1;

	while(true) {
		char c;

		// Skip over semicolons, as they shall not be included
		while((c = *(input++)) == ':');

		// The first character after a semicolon should be uppercase
		// copy it, unless it is zero
		if(!(*(output++) = toupper(c)))
			goto done;

		while((c = *(input++)) != ':') {
			// Copy the character until the character equals zero
			if(!(*(output++) = c))
				goto done;
		}
	}

done:
	NSString *result = [NSString stringWithUTF8String:buffer];
	free(buffer);

	return result;
}

static v8::Handle<v8::Object> makeWrapper(v8::Handle<v8::Context> context, void *jsClass, id wrappedObject)
{
	NSLog(@"makeWrapper %@",wrappedObject);

	v8::Handle<v8::ObjectTemplate> wrapperTemplate = v8::ObjectTemplate::New();
	wrapperTemplate->SetInternalFieldCount(1);

	v8::Handle<v8::Object> wrapper = wrapperTemplate->NewInstance();
	wrapper->SetInternalField(0, v8::External::New((__bridge void *)wrappedObject));

	return wrapper;
}

static L8Value *objectWithCustomBrand(L8Runtime *runtime, NSString *brand, Class cls = Nil)
{
	return [L8Value valueWithNewObject];
}

static NSMutableDictionary *createRenameMap(Protocol *protocol, BOOL isInstanceMethod)
{
	NSMutableDictionary *renameMap = [NSMutableDictionary dictionary];

	forEachMethodInProtocol(protocol, NO, isInstanceMethod, ^(SEL sel, const char *types)
	{
		NSString *rename = @(sel_getName(sel));
		NSRange range = [rename rangeOfString:@"__L8_EXPORT_AS__"];
		if(range.location == NSNotFound)
			return;

		NSString *selector = [rename substringToIndex:range.location];
		NSUInteger begin = range.location + range.length;
		NSUInteger length = [rename length] - begin - 1;
		NSString *name = [rename substringWithRange:(NSRange){ begin, length }];
		renameMap[selector] = name;
	});

	return renameMap;
}

inline void putNonEnumerable(L8Value *base, NSString *property, L8Value *value)
{
	[base defineProperty:property
				   value:value
				writable:YES
			  enumerable:NO
			configurable:YES
				  getter:nil
				  setter:nil]; // nil is ObjC for undefined
}

static void copyMethodsToObject(L8Runtime *runtime, Class objectClass, Protocol *protocol,
								BOOL isInstanceMethod, L8Value *object,
								NSMutableDictionary *accessorMethods = nil)
{
	NSMutableDictionary *renameMap = createRenameMap(protocol, isInstanceMethod);

	forEachMethodInProtocol(protocol, YES, isInstanceMethod, ^(SEL sel, const char *types) {
		const char *cname = sel_getName(sel);
		NSString *name = @(cname);
		v8::Handle<v8::Object> method;
		NSLog(@"Copy selector %@ for types %s",NSStringFromSelector(sel),types);
		if(accessorMethods && accessorMethods[name]) {
			method = ObjCCallbackFunctionForMethod(runtime, objectClass, protocol, isInstanceMethod, sel, types);
			if(method.IsEmpty())
				return;

			accessorMethods[name] = [L8Value valueWithV8Value:method];
		} else {
			name = renameMap[name];
			if(!name)
				name = selectorToPropertyName(cname);

			if([object hasProperty:name])
				return;

			method = ObjCCallbackFunctionForMethod(runtime, objectClass, protocol, isInstanceMethod, sel, types);
			if(!method.IsEmpty())
				putNonEnumerable(object, name, [L8Value valueWithV8Value:method]);
		}
	});
}

static bool parsePropertyAttributes(objc_property_t property, char *& getterName, char *& setterName)
{
	bool readonly = false;
	unsigned int attributeCount;

	objc_property_attribute_t *attributes = property_copyAttributeList(property, &attributeCount);

	for(unsigned int i = 0; i < attributeCount; i++) {
		switch(*(attributes[i].name)) {
			case 'G': // Gettername
				getterName = strdup(attributes[i].value);
				break;
			case 'S': // Settername
				setterName = strdup(attributes[i].value);
				break;
			case 'R': // Readonly
				readonly = true;
				break;
			default:
				NSLog(@"Found unkown attribute %c",*(attributes[i].name));
				break;
		}
	}

	free(attributes);
	return readonly;
}

static char *makeSetterName(const char *name)
{
	size_t length = strlen(name);
	char *setterName = (char *)malloc(length + 5); // 'set' Name ':' 0

	setterName[0] = 's';
	setterName[1] = 'e';
	setterName[2] = 't';
	setterName[3] = toupper(*name);

	memcpy(setterName + 4, name + 1, length - 1);

	setterName[length + 3] = ':';
	setterName[length + 4] = 0;

	return setterName;
}

static void copyPrototypeProperties(L8Runtime *runtime, Class objectClass, Protocol *protocol, L8Value *prototypeValue)
{
	struct Property {
		const char *name;
		char *getterName;
		char *setterName;
	};
	__block std::vector<Property> propertyList;

	NSMutableDictionary *accessorMethods = [NSMutableDictionary dictionary];
	L8Value *undefined = [L8Value valueWithUndefined];

	forEachPropertyInProtocol(protocol, ^(objc_property_t property) {
		char *getterName = 0, *setterName = 0;
		bool readOnly = parsePropertyAttributes(property, getterName, setterName);

		const char *name = property_getName(property);

		if(!getterName)
			getterName = strdup(name);
		accessorMethods[@(getterName)] = undefined;

		if(!readOnly) {
			if(!setterName)
				setterName = makeSetterName(name);
			accessorMethods[@(setterName)] = undefined;
		}

		NSLog(@"property with name %s, setter %s, getter %s",name,setterName,getterName);

		propertyList.push_back((Property){ name, getterName, setterName });
	});

	copyMethodsToObject(runtime, objectClass, protocol, YES, prototypeValue, accessorMethods);

	for(size_t i = 0; i < propertyList.size(); i++) {
		Property& property = propertyList[i];
		L8Value *getter, *setter = undefined;

		getter = accessorMethods[@(property.getterName)];
		free(property.getterName);
		assert(![getter isUndefined]);

		if(property.setterName) {
			setter = accessorMethods[@(property.setterName)];
			free(property.setterName);
			assert(![setter isUndefined]);
		}

		[prototypeValue defineProperty:@(property.name)
								 value:nil
							  writable:NO
							enumerable:NO
						  configurable:YES
								getter:getter
								setter:setter];
	}
}

@interface L8ClassInfo : NSObject {
	L8Runtime *_runtime;
	Class _class;
	bool _block;
	void *_classRef;
	// weak objects: prototype and constructor
	// persistent + makeWeak ?
	v8::Handle<v8::Object> _prototype;
	v8::Handle<v8::Object> _constructor;
}

- (instancetype)initWithRuntime:(L8Runtime *)runtime
					   forClass:(Class)cls
				 superClassInfo:(L8ClassInfo *)superClassInfo;
- (L8Value *)wrapperForObject:(id)object;
- (L8Value *)constructor;

@end

@implementation L8ClassInfo

- (id)initWithRuntime:(L8Runtime *)runtime
					   forClass:(Class)cls
				 superClassInfo:(L8ClassInfo *)superClassInfo
{
	self = [super init];
	if(self) {
		_runtime = runtime;
		_class = cls;
		_block = [cls isSubclassOfClass:objc_getClass("NSBlock")];

		NSLog(@"New class info :D");
		// JS CLASS DEF
		// def = kJSClassDefEmpty
		// def.classname = classname
		// _classref = jsclasscreate(&def)

		[self allocateConstructorAndOrPrototypeWithSuperClassInfo:superClassInfo];
	}
	return self;
}

- (void)allocateConstructorAndOrPrototypeWithSuperClassInfo:(L8ClassInfo *)superClass
{
	assert(_constructor.IsEmpty() || _prototype.IsEmpty());
	assert((_class == [NSObject class]) == !superClass);

	if(!superClass) {
		L8Value *constructor = _runtime[@"Object"];
		if(_constructor.IsEmpty())
			_constructor = [constructor V8Value]->ToObject();

		if(_prototype.IsEmpty())
			_prototype = [constructor[@"prototype"] V8Value]->ToObject();
	} else {
		const char *className = class_getName(_class);
		L8Value *prototype, *constructor;

		if(!_prototype.IsEmpty())
			prototype = [L8Value valueWithV8Value:_prototype];
		else
			prototype = objectWithCustomBrand(_runtime, [NSString stringWithFormat:@"%sPrototype",className]);

		if(!_constructor.IsEmpty())
			constructor = [L8Value valueWithV8Value:_constructor];
		else
			constructor = objectWithCustomBrand(_runtime, [NSString stringWithFormat:@"%sConstructor",className], _class);

		_prototype = [prototype V8Value]->ToObject();
		_constructor = [constructor V8Value]->ToObject();

		putNonEnumerable(prototype, @"constructor", constructor);
		putNonEnumerable(constructor, @"prototype", prototype);

		Protocol *exportProtocol = @protocol(L8Export);
		forEachProtocolImplementingProtocol(_class, exportProtocol, ^(Protocol *protocol) {
			copyPrototypeProperties(_runtime, _class, protocol, prototype);
			copyMethodsToObject(_runtime, _class, protocol, NO, constructor);
		});

		_prototype->SetPrototype(superClass->_prototype->ToObject());
	}
}

- (void)reallocateConstructorAndOrPrototype
{
	L8ClassInfo *info = [_runtime.wrapperMap classInfoForClass:class_getSuperclass(_class)];
	[self allocateConstructorAndOrPrototypeWithSuperClassInfo:info];
}

- (L8Value *)wrapperForObject:(id)object
{
	NSLog(@"%@",NSStringFromSelector(_cmd));
	if(_block) {
		v8::Handle<v8::Object> method;
		method = ObjCCallbackFunctionForBlock(_runtime, object);
		if(!method.IsEmpty())
			return [L8Value valueWithV8Value:method];
	}

	if(_prototype.IsEmpty())
		[self reallocateConstructorAndOrPrototype];
	assert(!_prototype.IsEmpty());

	v8::Handle<v8::Object> wrapper = makeWrapper([_runtime V8Context], _classRef, object);
	wrapper->SetPrototype(_prototype);

	return [L8Value valueWithV8Value:wrapper];
}

- (L8Value *)constructor
{
	if(_constructor.IsEmpty())
		[self reallocateConstructorAndOrPrototype];
	assert(!_constructor.IsEmpty());

	return [L8Value valueWithV8Value:_constructor];
}

@end

@implementation L8WrapperMap {
	L8Runtime * _runtime;
	NSMutableDictionary *_classMap;
	std::map<id, v8::Handle<v8::Object>> _cachedJSWrappers; // Should be weak
	NSMapTable *_cachedObjCWrappers;
}

- (id)initWithRuntime:(L8Runtime *)runtime
{
	self = [super init];
	if(self) {
		_cachedObjCWrappers = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaqueMemory
														valueOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality
															capacity:0];
		_runtime = runtime;
		_classMap = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (L8Value *)JSWrapperForObject:(id)object
{
	NSLog(@"%@%@",NSStringFromSelector(_cmd),object);

	v8::Handle<v8::Object> jsWrapper = _cachedJSWrappers[object];
	if(!jsWrapper.IsEmpty())
		return [L8Value valueWithV8Value:jsWrapper];

	L8Value *wrapper;
	if(class_isMetaClass(object_getClass(object)))
		wrapper = [[self classInfoForClass:(Class)object] constructor];
	else {
		L8ClassInfo *classInfo = [self classInfoForClass:[object class]];
		NSLog(@"Class Info %@",classInfo);
		wrapper = [classInfo wrapperForObject:object];
		NSLog(@"wrapper %@",wrapper);
	}

	// Todo: Cache

	return wrapper;
}

- (L8Value *)ObjCWrapperForValue:(v8::Handle<v8::Value>)value
{
//	NSLog(@"%@%@",NSStringFromSelector(_cmd),[NSString stringWithV8Value:value]);

	L8Value *wrapper;// = static_cast<L8Value *>(NSMapGet(_cachedObjCWrappers, value));
//	if(!wrapper) {
		wrapper = [[L8Value alloc] initWithV8Value:value];
//		NSMapInsert(_cachedObjCWrappers, value, wrapper);
//	}
	return wrapper;
}

- (L8ClassInfo *)classInfoForClass:(Class)cls
{
	L8ClassInfo *classInfo;

	if(!cls)
		return nil;

	if((classInfo = _classMap[cls]))
		return classInfo;

	classInfo = [self classInfoForClass:class_getSuperclass(cls)];
	if(*class_getName(cls) == '_')
		return _classMap[cls] = classInfo;

	return _classMap[cls] = [[L8ClassInfo alloc] initWithRuntime:_runtime
														forClass:cls
												  superClassInfo:classInfo];
}

@end

id unwrapObjcObject(v8::Handle<v8::Context> context, v8::Handle<v8::Value> value) {
	if(!value->IsObject())
		return nil;

	v8::Handle<v8::Object> object = value->ToObject();

	if(object->InternalFieldCount() > 0) {
		v8::Handle<v8::Value> field = object->GetInternalField(0);
		if(!field.IsEmpty() && field->IsExternal())
			return (__bridge id)v8::External::Cast(*field)->Value();
	}

	if(id target = unwrapBlock(object))
		return target;

	return nil;
}

id unwrapBlock(v8::Handle<v8::Object> object)
{
	NSLog(@"Unwrap block");
	return nil;
}