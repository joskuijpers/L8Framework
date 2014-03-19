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

#include <objc/runtime.h>
#include <vector>
#include <string>
#include <map>
#include <iterator>

#import "L8WrapperMap.h"

#import "L8VirtualMachine_Private.h"
#import "L8Context_Private.h"
#import "L8Value_Private.h"
#import "L8Export.h"

#import "NSString+L8.h"
#import "ObjCRuntime+L8.h"
#import "ObjCCallback.h"

#include "v8.h"

using namespace v8;

/**
 * Extract a propertyname from a selectorname.
 *
 * Removes ':' and makes every letter following such colon uppercase. For example,
 * 'initWithName:surname:' becomes 'initWithNameSurname'. Return value is stored in
 * an NSString due to the locally allocated buffer.
 *
 * @return An NSString containing the property name
 */
static NSString *l8_selector_to_property_name(const char *start, bool instanceMethod = true)
{
	const char *firstColon, *input;
	char *buffer, *output;
	size_t header;
	NSString *result;

	// Find the first semicolon
	firstColon = index(start, ':');
	if(!firstColon)
		return [NSString stringWithUTF8String:start];

	header = firstColon - start;
	buffer = (char *)malloc(header + strlen(firstColon + 1) + 1);
	memcpy(buffer, start, header);

	if(!instanceMethod)
		buffer[0] = toupper(buffer[0]);

	output = buffer + header;
	input = start + header + 1;

	while(true) {
		char c;

		while((c = *(input++)) == ':');

		if(!(*(output++) = toupper(c)))
			goto done;

		while((c = *(input++)) != ':') {
			if(!(*(output++) = c))
				goto done;
		}
	}

done:
	result = [NSString stringWithUTF8String:buffer];
	free(buffer);

	return result;
}

/**
 * Creates a v8 handle containing the given ObjC object, with memory management
 * taken care of.
 *
 * @return v8 Handle containing the wrapped object
 */
Local<External> l8_make_wrapper(Local<Context> context, id wrappedObject)
{
	void *voidObject;
	Local<External> ext;

	voidObject = (void *)CFBridgingRetain(wrappedObject);

	ext = External::New(context->GetIsolate(),voidObject);
	Persistent<External> persist(context->GetIsolate(),ext);
	persist.SetWeak((__bridge void *)wrappedObject, ObjCWeakReferenceCallback);

	return ext;
}

/**
 * Obtains the ObjC object withing the wrapper
 *
 * @return Objective-C object withing wrapper, or nil on failure
 */
id l8_object_from_wrapper(Local<Value> wrapper)
{
	id object;

	if(!wrapper->IsExternal())
		return nil;

	object = (__bridge id)External::Cast(*wrapper)->Value();

	return object;
}

static NSMutableDictionary *l8_create_rename_map(Protocol *protocol, BOOL isInstanceMethod)
{
	NSMutableDictionary *renameMap;

	renameMap = [NSMutableDictionary dictionary];

	l8_for_each_method_in_protocol(protocol, NO, isInstanceMethod, ^(SEL sel, const char *types)
	{
		const char *selName;
		NSString *rename, *selector, *name;
		NSUInteger begin, length;
		NSRange range;
		BOOL hasNoArguments = NO;

		selName = sel_getName(sel);
		rename = @(selName);
		range = [rename rangeOfString:@"__L8_EXPORT_AS__"];
		if(range.location == NSNotFound)
			return;

		if(selName[strlen(selName)-1] != ':')
			hasNoArguments = YES;

		selector = [rename substringToIndex:range.location];
		begin = range.location + range.length;
		length = [rename length] - begin - hasNoArguments?0:1;
		name = [rename substringWithRange:(NSRange){ begin, length }];
		renameMap[selector] = name;
	});

	return renameMap;
}

/*
 * Create the default setter name using only the property name.
 * A setter name is built with: 'set'<name with first letter capital>':'
 */
static char *l8_make_setter_name(const char *name)
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

bool l8_is_method_initializer(SEL sel)
{
	char *selStr;

	selStr = (char *)sel_getName(sel);

	while(*selStr == '_')
		selStr++;

	if(*selStr == '\0')
		return false;

	if(strncmp(selStr, "init", 4) != 0)
		return false;
	selStr += 4;

	if(*selStr == '\0' || isupper(*selStr) || *selStr == ':')
		return true;

	return false;
}

/**
 * Get whether the given method should not be copied
 * to the JavaScript object.
 */
bool l8_should_skip_method_when_copying(SEL sel)
{
	return l8_is_method_initializer(sel);
}

/*
 * Install the ObjC methods from the protocol in the JS prototype.
 * If isInstanceMethod is YES, only instance methods will be installed.
 * If non-YES, it will install class-methods.
 * This method also stores type-information of accessor methods in the given
 * dictionary, if given.
 */
void l8_copy_method_to_object(L8WrapperMap *wrapperMap,
						 Protocol *protocol,
						 BOOL isInstanceMethod,
						 Local<Template> theTemplate,
						 NSMutableDictionary *accessorMethods = nil)
{
	Isolate *isolate = wrapperMap.context.virtualMachine.V8Isolate;
	NSMutableDictionary *renameMap = l8_create_rename_map(protocol, isInstanceMethod);

	l8_for_each_method_in_protocol(protocol, YES, isInstanceMethod, ^(SEL sel, const char *types) {
		const char *selName;
		NSString *rawName;
		const char *extraTypes;

		if(l8_should_skip_method_when_copying(sel))
			return;

		selName = sel_getName(sel);
		rawName = @(selName);

		extraTypes = _protocol_getMethodTypeEncoding(protocol, sel, YES, isInstanceMethod);

		if(accessorMethods[rawName]) {
			accessorMethods[rawName] = [L8Value valueWithV8Value:String::NewFromUtf8(isolate,extraTypes)
													   inContext:wrapperMap.context];
		} else {
			NSString *propertyName;
			Local<String> v8Name;
			Local<FunctionTemplate> function;
			Local<Array> extraData;

			propertyName = renameMap[rawName];
			if(propertyName == nil)
				propertyName = l8_selector_to_property_name(selName,isInstanceMethod);

			v8Name = [propertyName V8StringInIsolate:isolate];

			function = FunctionTemplate::New(isolate);

			extraData = Array::New(isolate);
			extraData->Set(0, String::NewFromUtf8(isolate, selName));
			extraData->Set(1, String::NewFromUtf8(isolate, extraTypes));
			extraData->Set(2, v8::Boolean::New(isolate,!isInstanceMethod));
			function->SetCallHandler(ObjCMethodCall,extraData);

			theTemplate->Set(v8Name, function);
		}
	});
}

/*
 * Find useful attributes in the ObjC context about given property.
 */
void l8_parse_property_attributes(objc_property_t property,
								  char *&getterName,
								  char *&setterName,
								  bool &readonly,
								  char *&type)
{
	unsigned int count;
	objc_property_attribute_t *attributes = property_copyAttributeList(property, &count);
	readonly = false;

	for(unsigned int i = 0; i < count; i++) {
		switch(*(attributes[i].name)) {
			case 'R': // read-only (readonly)
				readonly = true;
				break;
			case 'G': // G<name> custom getter name (eg GcustomGetter)
				getterName = strdup(attributes[i].value);
				break;
			case 'S': // S<name> custom setter name (eg ScustomSetter:)
				setterName = strdup(attributes[i].value);
				break;
			case 'T': // T<encoding>, type
				type = strdup(attributes[i].value);
				break;
			case 'C': // copy of last value assigned (copy)
			case '&': // reference to last value assigned (retain)
			case 'N': // non-atomic (nonatomic)
			case 'D': // dynamic (@dynamic)
			case 'W': // weak reference (__weak / weak)
			case 'P': // eligible for garbage collection
			case 't': // t<encoding>, old style encoding
				break;
			default:
				break;
		}
	}

	free(attributes);
}

/*
 * Because the list of methods from a class also contains getters (and setters) for properties,
 * we first need to find all properties and get their getter (and setter). Then, when copying
 * the methods, we should skip these as they are already covered by the property-accessors
 */
void l8_copy_prototype_properties(L8WrapperMap *wrapperMap,
							 Local<ObjectTemplate> prototypeTemplate,
							 Local<ObjectTemplate> instanceTemplate,
							 Protocol *protocol)
{
	struct property_t {
		const char *name;
		char *getterName;
		char *setterName;
		char *type;
		bool readonly;
	};
	Isolate *isolate = wrapperMap.context.virtualMachine.V8Isolate;
	__block std::vector<property_t> propertyList;
	NSMutableDictionary *accessorMethods;
	L8Value *undefinedValue;

	// This is not neccesary, just move them inside the block
	// but it is to avoid analyzer errors: the allocation is in another loop
	// than the freeing.
	__block char *getterName = NULL;
	__block char *setterName = NULL;
	__block char *type = NULL;

	// Dictionary containing all accessor methods so they can be skipped when copying methods
	accessorMethods = [NSMutableDictionary dictionary];
	undefinedValue = [L8Value valueWithUndefinedInContext:wrapperMap.context];

	l8_for_each_property_in_protocol(protocol, ^(objc_property_t property) {
		getterName = NULL;
		setterName = NULL;
		type = NULL;
		bool readonly = false;
		property_t prop;
		const char *propertyName = property_getName(property);

		// Get property information
		l8_parse_property_attributes(property, getterName, setterName, readonly, type);

		// Getter
		if(getterName == NULL)
			getterName = strdup((char *)propertyName);
		accessorMethods[@(getterName)] = undefinedValue;

		// Setter, if applicable
		if(readonly == false) {
			if(setterName == NULL)
				setterName = l8_make_setter_name(propertyName);
			accessorMethods[@(setterName)] = undefinedValue;
		}

		prop = { propertyName, getterName, setterName, type, readonly };
		propertyList.push_back(prop);
	});

	// Copy the instance methods except the accessors, which we get info for
	l8_copy_method_to_object(wrapperMap, protocol, YES, prototypeTemplate, accessorMethods);

	// Add accessors for each property with correct name, setter, getter and attributes
	for(int i = 0; i < propertyList.size(); i++) {
		property_t& property = propertyList[i];

		Local<String> v8PropertyName = [@(property.name) V8StringInIsolate:isolate];
		Local<Array> extraData = Array::New(isolate);

		extraData->Set(0, v8PropertyName);
		extraData->Set(1, String::NewFromUtf8(isolate, property.type)); // value type
		extraData->Set(2, String::NewFromUtf8(isolate, property.getterName)); // getter SEL
		extraData->Set(3, [accessorMethods[@(property.getterName)] V8Value]); // getter Types

		if(!property.readonly) {
			extraData->Set(4, String::NewFromUtf8(isolate, property.setterName)); // setter SEL
			extraData->Set(5, [accessorMethods[@(property.setterName)] V8Value]); // setter Types
		}

		free(property.type);
		free(property.getterName);
		free(property.setterName);

		instanceTemplate->SetAccessor(v8PropertyName, ObjCAccessorGetter,
									  ObjCAccessorSetter, extraData,
									  AccessControl::DEFAULT,
									  property.readonly ? PropertyAttribute::ReadOnly : PropertyAttribute::None
									  /*| PropertyAttribute::DontEnum*/);
	}
}

SEL l8_initializer_selector_for_class(Class cls)
{
	__block SEL selector;
	__block BOOL found = NO;
	__block BOOL foundMultiple = NO;

	l8_for_each_protocol_implementing_protocol(cls, objc_getProtocol("L8Export"), ^(Protocol *protocol) {

		l8_for_each_method_in_protocol(protocol, YES, YES, ^(SEL sel, const char *encoding) {
			if(!l8_is_method_initializer(sel))
				return;

			if(sel_isEqual(sel, selector))
				return;

			if(found) {
				NSLog(@"Found multiple init methods for class %@. Falling back to -[init].",NSStringFromClass(cls));
				foundMultiple = YES;
				return;
			}

			found = YES;
			selector = sel;
		});

	});

	if(found && !foundMultiple)
		return selector;
	return @selector(init);
}

@implementation L8WrapperMap {
	std::map<std::string,Eternal<FunctionTemplate>> _classCache;
	__weak L8Context *_context;
}

- (id)initWithContext:(L8Context *)context
{
	self = [super init];
	if(self) {
		_context = context;
	}
	return self;
}

- (void)cacheFunctionTemplate:(Local<FunctionTemplate>)funcTemplate
					 forClass:(Class)cls
{
	std::string key(class_getName(cls));
	Eternal<FunctionTemplate> myEternal;

	assert(_classCache.find(key) == _classCache.end() && "Must only cache once");

	{
		Isolate *isolate = _context.virtualMachine.V8Isolate;
		HandleScope localScope(isolate);
		
		myEternal.Set(isolate, funcTemplate);
	}

	_classCache[key] = myEternal;
}

- (Local<FunctionTemplate>)getCachedFunctionTemplateForClass:(Class)cls
{
	std::string key(class_getName(cls));
	std::map<std::string,Eternal<FunctionTemplate>>::iterator it;
	Isolate *isolate = _context.virtualMachine.V8Isolate;

	it = _classCache.find(key);
	if(it != _classCache.end()) {
		Eternal<FunctionTemplate> eternal;

		eternal = it->second;
		return eternal.Get(isolate);
	}

	return Local<FunctionTemplate>();
}

- (Local<FunctionTemplate>)functionTemplateForClass:(Class)cls
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Local<FunctionTemplate> classTemplate;
	Local<ObjectTemplate> prototypeTemplate, instanceTemplate;
	Local<Array> extraClassData;
	NSString *className;
	Class parentClass;
	SEL initSelector;

	className = @(class_getName(cls));
	classTemplate = FunctionTemplate::New(isolate);

	parentClass = class_getSuperclass(cls);
	if(parentClass != Nil && cls != parentClass && class_isMetaClass(parentClass)) { // Top-level class
		Local<FunctionTemplate> parentTemplate;

		parentTemplate = [self getCachedFunctionTemplateForClass:parentClass];
		if(parentTemplate.IsEmpty())
			parentTemplate = [self functionTemplateForClass:parentClass];
		if(!parentTemplate.IsEmpty())
			classTemplate->Inherit(parentTemplate);
	}

	initSelector = l8_initializer_selector_for_class(cls);

	classTemplate->SetClassName([className V8StringInIsolate:isolate]);

	prototypeTemplate = classTemplate->PrototypeTemplate();
	instanceTemplate = classTemplate->InstanceTemplate();
	instanceTemplate->SetInternalFieldCount(1);

	l8_for_each_protocol_implementing_protocol(cls, objc_getProtocol("L8Export"), ^(Protocol *protocol) {
		l8_copy_prototype_properties(self, prototypeTemplate, instanceTemplate, protocol);

		l8_copy_method_to_object(self, protocol, NO, classTemplate);
	});

	// Set constructor callback
	extraClassData = Array::New(isolate);
	extraClassData->Set(0, String::NewFromUtf8(isolate, class_getName(cls))); // classname
	extraClassData->Set(1, String::NewFromUtf8(isolate, sel_getName(initSelector))); // init selector
	classTemplate->SetCallHandler(ObjCConstructor,extraClassData);

	[self cacheFunctionTemplate:classTemplate
					   forClass:cls];

	return classTemplate;
}

/**
 * Create a wrapper-to-JavaScript for an Objective-C object
 *
 * @return an L8Value containing the V8 handle wrapping the object
 */
- (L8Value *)JSWrapperForObjCObject:(id)object
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	EscapableHandleScope localScope(isolate);
	Local<FunctionTemplate> classTemplate;
	Local<Function> function;
	Class cls;

	cls = object_getClass(object);

	classTemplate = [self getCachedFunctionTemplateForClass:cls];
	if(classTemplate.IsEmpty())
		classTemplate = [self functionTemplateForClass:cls];

	// The class (constructor)
	function = classTemplate->GetFunction();

	if(class_isMetaClass(object_getClass(object)))
		return [L8Value valueWithV8Value:localScope.Escape(function) inContext:_context];

	_context.V8Context->SetEmbedderData(L8_CONTEXT_EMBEDDER_DATA_SKIP_CONSTRUCTING, True(isolate));
	Local<Object> instance = function->NewInstance();
	_context.V8Context->SetEmbedderData(L8_CONTEXT_EMBEDDER_DATA_SKIP_CONSTRUCTING, False(isolate));

	instance->SetInternalField(0, l8_make_wrapper(_context.V8Context, object));

	return [L8Value valueWithV8Value:localScope.Escape(instance) inContext:_context];
}

/**
 * Create a wrapper-to-JavaScript for a block object
 *
 * @return an L8Value containing the V8 handle wrapping the block object
 */
- (L8Value *)JSWrapperForBlock:(id)object
{
	Local<Function> function = l8_wrap_block(_context.V8Context,object);

	return [[L8Value alloc] initWithV8Value:function inContext:_context];
}

/**
 * Create a wrapper for any type of objective object
 *
 * @return an L8Value containing the V8 handle wrapping the object
 */
- (L8Value *)JSWrapperForObject:(id)object
{
	L8Value *wrapper;

	if([object isKindOfClass:BlockClass()])
		wrapper = [self JSWrapperForBlock:object];
	else
		wrapper = [self JSWrapperForObjCObject:object];

	return wrapper;
}

/**
 * Create a wrapper-to-ObjectiveC for the given JavaScript value
 *
 * @return an L8Value wrapping the value. Use the appropriate value-converter to retrieve the
 * wanted object.
 */
- (L8Value *)ObjCWrapperForValue:(Local<Value>)value
{
	return [[L8Value alloc] initWithV8Value:value inContext:_context];
}

@end

id l8_unwrap_objc_object(Isolate *isolate, Local<Value> value)
{
	Local<Object> object;

	if(!value->IsObject())
		return nil;

	object = value->ToObject();

	if(object->InternalFieldCount() > 0) { // Instance
		Local<Value> field;

		field = object->GetInternalField(0);
		if(!field.IsEmpty() && field->IsExternal())
			return (__bridge id)External::Cast(*field)->Value();
	}

	if(object->IsFunction()) { // Class (arguments.callee), or block
		Local<Value> isBlockInfo;
		bool isBlock;
		NSString *name;

		isBlockInfo = object->GetHiddenValue(String::NewFromUtf8(isolate, "isBlock"));
		isBlock = !isBlockInfo.IsEmpty() && isBlockInfo->IsTrue();

		name = [NSString stringWithV8Value:object.As<Function>()->GetName() inIsolate:isolate];

		if(isBlock) {
			if(id target = l8_unwrap_block(isolate, object)) // Block
				return target;
			return nil;
		}
		return objc_getClass([name UTF8String]);
	}

	return nil;
}

Local<Function> l8_wrap_block(Local<Context> context, id object)
{
	Isolate *isolate = context->GetIsolate();
	EscapableHandleScope localScope(isolate);
	Local<Function> function;
	Local<FunctionTemplate> functionTemplate;

	functionTemplate = FunctionTemplate::New(isolate);
	functionTemplate->SetCallHandler(ObjCBlockCall, l8_make_wrapper(context, object));
	functionTemplate->PrototypeTemplate()->SetInternalFieldCount(1);
	functionTemplate->InstanceTemplate()->SetInternalFieldCount(1);

	function = functionTemplate->GetFunction();
	function->SetHiddenValue(String::NewFromUtf8(isolate, "isBlock"),
							 v8::Boolean::New(isolate,true));
	function->SetHiddenValue(String::NewFromUtf8(isolate, "cBlock"),
							 l8_make_wrapper(context, object));

	return localScope.Escape(function);
}

id l8_unwrap_block(Isolate *isolate, Local<Object> object)
{
	Local<Value> cblock;
	id blockObject;

	assert(object->IsFunction());

	if(object->GetHiddenValue(String::NewFromUtf8(isolate, "isBlock"))->IsTrue() == false)
		return nil;

	cblock = object->GetHiddenValue(String::NewFromUtf8(isolate, "cBlock"));
	assert(cblock->IsExternal());

	blockObject = (__bridge id)External::Cast(*cblock)->Value();
	assert([blockObject isKindOfClass:BlockClass()]);

	return blockObject;
}

Class BlockClass()
{
	static Class cls = objc_getClass("NSBlock");
	return cls;
}