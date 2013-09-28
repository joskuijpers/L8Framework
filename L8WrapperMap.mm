//
//  L8WrapperMap.m
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <objc/runtime.h>
#include <map>
#include <vector>

#import "L8WrapperMap.h"

#import "L8Runtime_Private.h"
#import "L8Value_Private.h"
#import "L8Export.h"

#import "NSString+L8.h"
#import "ObjCRuntime+L8.h"
#import "ObjCCallback.h"

#include "v8.h"

/*Opt*/ static v8::Handle<v8::String> V8StringWithCString(const char *cstr) {
	return [@(cstr) V8String];
}

/*!
 * Extract a propertyname from a selectorname.
 *
 * Removes ':' and makes every letter following such colon uppercase. For example,
 * 'initWithName:surname:' becomes 'initWithNameSurname'. Return value is stored in
 * an NSString due to the locally allocated buffer.
 *
 * @return An NSString containing the property name
 */
static NSString *selectorToPropertyName(const char *start, bool instanceMethod = true)
{
	// Find the first semicolon
	const char *firstColon = index(start, ':');
	if(!firstColon)
		return [NSString stringWithUTF8String:start];

	size_t header = firstColon - start;
	char *buffer = (char *)malloc(header + strlen(firstColon + 1) + 1);
	memcpy(buffer, start, header);

	if(!instanceMethod)
		buffer[0] = toupper(buffer[0]);

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

/*!
 * Creates a v8 handle containing the given ObjC object, with memory management
 * taken care of.
 *
 * @return v8 Handle containing the wrapped object
 */
v8::Handle<v8::External> makeWrapper(v8::Handle<v8::Context> context, id wrappedObject)
{
	void *voidObject = (void *)CFBridgingRetain(wrappedObject);

	v8::Handle<v8::External> ext = v8::External::New(voidObject);
	v8::Persistent<v8::External> persist(context->GetIsolate(),ext);
	persist.MakeWeak((__bridge void *)wrappedObject, ObjCWeakReferenceCallback);

	return ext;
}

/*!
 * Obtains the ObjC object withing the wrapper
 *
 * @return Objective-C object withing wrapper, or nil on failure
 */
id objectFromWrapper(v8::Handle<v8::Value> wrapper)
{
	if(!wrapper->IsExternal())
		return nil;

	id object = (__bridge id)v8::External::Cast(*wrapper)->Value();
	return object;
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

/*
 * Create the default setter name using only the property name.
 * A setter name is built with: 'set'<name with first letter capital>':'
 */
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

/*
 * Install the ObjC methods from the protocol in the JS prototype.
 * If isInstanceMethod is YES, only instance methods will be installed.
 * If non-YES, it will install class-methods.
 * This method also stores type-information of accessor methods in the given
 * dictionary, if given.
 */
void copyMethodsToObject(L8WrapperMap *wrapperMap, Protocol *protocol,
						 BOOL isInstanceMethod,
						 v8::Handle<v8::Template> theTemplate,
						 NSMutableDictionary *accessorMethods = nil)
{
	NSMutableDictionary *renameMap = createRenameMap(protocol, isInstanceMethod);

	forEachMethodInProtocol(protocol, YES, isInstanceMethod, ^(SEL sel, const char *types) {

		const char *selName = sel_getName(sel);
		NSString *rawName = @(selName);

		if(accessorMethods[rawName]) {
			accessorMethods[rawName] = [L8Value valueWithV8Value:v8::String::New(types)];
		} else {
			NSString *propertyName = renameMap[rawName];

			if(propertyName == nil)
				propertyName = selectorToPropertyName(selName,isInstanceMethod);

			v8::Handle<v8::String> v8Name = [propertyName V8String];

			v8::Handle<v8::FunctionTemplate> function = v8::FunctionTemplate::New();

			// only if want to suply data
			v8::Handle<v8::Array> extraData = v8::Array::New();
			extraData->Set(0, v8::String::New(selName));
			extraData->Set(1, v8::String::New(types));
			extraData->Set(2, v8::Boolean::New(!isInstanceMethod));

			function->SetCallHandler(ObjCMethodCall,extraData);

			theTemplate->Set(v8Name, function);
		}
	});
}

/*
 * Find useful attributes in the ObjC runtime about given property.
 */
void parsePropertyAttributes(objc_property_t property, char *&getterName, char *&setterName, bool &readonly, char *&type)
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
void copyPrototypeProperties(L8WrapperMap *wrapperMap, v8::Handle<v8::ObjectTemplate> prototypeTemplate,
							 v8::Handle<v8::ObjectTemplate> instanceTemplate, Protocol *protocol)
{
	// Find all properties in the protocol
	struct property_t {
		const char *name;
		char *getterName;
		char *setterName;
		char *type;
		bool readonly;
	};

	__block std::vector<property_t> propertyList;

	// Dictionary containing all accessor methods so they can be skipped when copying methods
	NSMutableDictionary *accessorMethods = [NSMutableDictionary dictionary];
	L8Value *undefinedValue = [L8Value valueWithUndefined];

	// This is not neccesary, just move them inside the block
	// but it is to avoid analyzer errors
	__block char *getterName = NULL;
	__block char *setterName = NULL;
	__block char *type = NULL;

	forEachPropertyInProtocol(protocol, ^(objc_property_t property) {
		getterName = NULL;
		setterName = NULL;
		type = NULL;
		bool readonly = false;
		const char *propertyName = property_getName(property);

		// Get property information
		parsePropertyAttributes(property, getterName, setterName, readonly, type);

		// Getter
		if(getterName == NULL)
			getterName = strdup((char *)propertyName);
		accessorMethods[@(getterName)] = undefinedValue;

		// Setter, if applicable
		if(readonly == false) {
			if(setterName == NULL)
				setterName = makeSetterName(propertyName);
			accessorMethods[@(setterName)] = undefinedValue;
		}

		property_t prop = { propertyName, getterName, setterName, type, readonly };
		propertyList.push_back(prop);
	});

	// Copy the instance methods except the accessors, which we get info for
	copyMethodsToObject(wrapperMap, protocol, YES, prototypeTemplate, accessorMethods);

	// Add accessors for each property with correct name, setter, getter and attributes
	for(int i = 0; i < propertyList.size(); i++) {
		property_t& property = propertyList[i];

		v8::Handle<v8::String> v8PropertyName = V8StringWithCString(property.name);
		v8::Handle<v8::Array> extraData = v8::Array::New();

		extraData->Set(0, v8PropertyName);
		extraData->Set(1, v8::String::New(property.type)); // value type
		extraData->Set(2, v8::String::New(property.getterName)); // getter SEL
		extraData->Set(3, [accessorMethods[@(property.getterName)] V8Value]); // getter Types
		extraData->Set(4, v8::String::New(property.setterName)); // setter SEL
		extraData->Set(5, [accessorMethods[@(property.setterName)] V8Value]); // setter Types

		free(property.type);
		free(property.getterName);
		free(property.setterName);

		instanceTemplate->SetAccessor(v8PropertyName, ObjCAccessorGetter, ObjCAccessorSetter, extraData,
									  v8::AccessControl::DEFAULT,
									  property.readonly ? v8::PropertyAttribute::ReadOnly : v8::PropertyAttribute::None
									  /*| v8::PropertyAttribute::DontEnum*/);
	}
}

/*
 * Sets keyed and indexed subscription handles depending on whether they are implemented
 * in the ObjC class.
 */
void installSubscriptionMethods(L8WrapperMap *wrapperMap, v8::Handle<v8::ObjectTemplate> instanceTemplate, Class cls)
{
	bool readonly = true;

	if(class_respondsToSelector(cls, @selector(objectForKeyedSubscript:))) {
		if(class_respondsToSelector(cls, @selector(setObject:forKeyedSubscript:)))
			readonly = false;

		instanceTemplate->SetNamedPropertyHandler(ObjCNamedPropertyGetter,
												  readonly ? 0 : ObjCNamedPropertySetter,
												  ObjCNamedPropertyQuery, 0, 0); // DATA
	}

	if(class_respondsToSelector(cls, @selector(objectAtIndexedSubscript:))) {
		if(class_respondsToSelector(cls, @selector(setObject:atIndexedSubscript:)))
			readonly = false;

		instanceTemplate->SetIndexedPropertyHandler(ObjCIndexedPropertyGetter,
													readonly ? 0 : ObjCIndexedPropertySetter,
													ObjCIndexedPropertyQuery, 0, 0); // DATA
	}
}

@implementation L8WrapperMap {
	L8Runtime * _runtime;
	NSMutableDictionary *_cachedJSWrappers;
//	NSMapTable *_cachedObjCWrappers;
}

- (id)initWithRuntime:(L8Runtime *)runtime
{
	self = [super init];
	if(self) {
//		_cachedObjCWrappers = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaqueMemory
//														valueOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality
//															capacity:0];
		_runtime = runtime;
		_cachedJSWrappers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

/*!
 * Create a wrapper-to-JavaScript for an Objective-C object
 *
 * @return an L8Value containing the V8 handle wrapping the object
 */
- (L8Value *)JSWrapperForObjCObject:(id)object
{
	Class cls = object_getClass(object);
	NSString *className = @(class_getName(cls));

	v8::HandleScope localScope(v8::Isolate::GetCurrent());

	v8::Handle<v8::FunctionTemplate> classTemplate = v8::FunctionTemplate::New();

	// TODO set prototype of the prototype to prototype of the superclass
//	v8::Handle<v8::FunctionTemplate> parentTemplate; // need to store the function templates for each class and have function that returns those
//	classTemplate->Inherit(parentTemplate);

	classTemplate->SetClassName([className V8String]);

	v8::Handle<v8::ObjectTemplate> prototypeTemplate = classTemplate->PrototypeTemplate();
	v8::Handle<v8::ObjectTemplate> instanceTemplate = classTemplate->InstanceTemplate();
	instanceTemplate->SetInternalFieldCount(1);

	installSubscriptionMethods(self, instanceTemplate, (class_isMetaClass(cls)) ? object : cls);

	forEachProtocolImplementingProtocol(cls, objc_getProtocol("L8Export"), ^(Protocol *protocol) {
		copyPrototypeProperties(self, prototypeTemplate, instanceTemplate, protocol);

		// Copy class methods
		copyMethodsToObject(self, protocol, NO, classTemplate);
	});

	// The class (constructor)
	v8::Handle<v8::Function> function = classTemplate->GetFunction();

	if(class_isMetaClass(object_getClass(object))) {
		classTemplate->SetCallHandler(ObjCConstructor,v8::String::New(class_getName(cls)));
		return [L8Value valueWithV8Value:localScope.Close(function)];
	} else {
		// The objcConstructor should not be called when the object already exists
		// so we set the constructor after use
		v8::Handle<v8::Object> instance = function->NewInstance();

		classTemplate->SetCallHandler(ObjCConstructor,v8::String::New(class_getName(cls)));
		instance->SetInternalField(0, makeWrapper([_runtime V8Context], object));

		return [L8Value valueWithV8Value:localScope.Close(instance)];
	}

	return nil;
}

/*!
 * Create a wrapper-to-JavaScript for a block object
 *
 * @return an L8Value containing the V8 handle wrapping the block object
 */
- (L8Value *)JSWrapperForBlock:(id)object
{
	v8::Handle<v8::Function> function = wrapBlock(object);

	return [L8Value valueWithV8Value:function];
}

/*!
 * Create a wrapper for any type of objective object
 *
 * @return an L8Value containing the V8 handle wrapping the object
 */
- (L8Value *)JSWrapperForObject:(id)object
{
	L8Value *wrapper;// = _cachedJSWrappers[[object className]];
//	if(wrapper)
//		return wrapper;

	if([object isKindOfClass:BlockClass()]) {
		NSLog(@"Is Block %@",object);
		wrapper = [self JSWrapperForBlock:object];
	} else
		wrapper = [self JSWrapperForObjCObject:object];

//	_cachedJSWrappers[[object className]] = wrapper;

	return wrapper;
}

/*!
 * Create a wrapper-to-ObjectiveC for the given JavaScript value
 *
 * @return an L8Value wrapping the value. Use the appropriate value-converter to retrieve the
 * wanted object.
 */
- (L8Value *)ObjCWrapperForValue:(v8::Handle<v8::Value>)value
{
//	NSLog(@"%@%@",NSStringFromSelector(_cmd),[NSString stringWithV8Value:value]);

	L8Value *wrapper;// = static_cast<L8Value *>(NSMapGet(_cachedObjCWrappers, value));
//	if(!wrapper) {
		wrapper = [[L8Value alloc] initWithV8Value:value];
//		NSMapInsert(_cachedObjCWrappers, (void *)*value, wrapper);
//	}
	return wrapper;
}

@end

id unwrapObjcObject(v8::Handle<v8::Context> context, v8::Handle<v8::Value> value) {
	if(!value->IsObject())
		return nil;

	v8::Handle<v8::Object> object = value->ToObject();

	if(object->InternalFieldCount() > 0) { // Instance
		v8::Handle<v8::Value> field = object->GetInternalField(0);
		if(!field.IsEmpty() && field->IsExternal())
			return (__bridge id)v8::External::Cast(*field)->Value();
	}

	if(object->IsFunction()) { // Class
		NSString *name = [NSString stringWithV8Value:object.As<v8::Function>()->GetName()];
		return objc_getClass([name UTF8String]);
	}

	if(id target = unwrapBlock(object)) // Block
		return target;

	return nil;
}

v8::Handle<v8::Function> wrapBlock(id object)
{
	v8::HandleScope localScope(v8::Isolate::GetCurrent());

	v8::Handle<v8::FunctionTemplate> functionTemplate = v8::FunctionTemplate::New();
	functionTemplate->SetCallHandler(ObjCBlockCall, makeWrapper([[L8Runtime currentRuntime] V8Context], object));
	functionTemplate->PrototypeTemplate()->SetInternalFieldCount(1);
	functionTemplate->InstanceTemplate()->SetInternalFieldCount(1);

	v8::Handle<v8::Function> function = functionTemplate->GetFunction();
	function->SetHiddenValue(v8::String::New("isBlock"), v8::Boolean::New(true));
//	function->SetInternalField(0, v8::String::New("TEST"));

	return localScope.Close(function);
}

id unwrapBlock(v8::Handle<v8::Object> object)
{
	assert(object->IsExternal());

	id blockObject = (__bridge id)v8::External::Cast(*object)->Value();
	assert([blockObject isKindOfClass:BlockClass()]);

	return blockObject;
}

Class BlockClass()
{
	static Class cls = objc_getClass("NSBlock");
	return cls;
}