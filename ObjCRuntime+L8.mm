//
//  NSObject+ObjCRuntime.m
//  L8Framework
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "ObjCRuntime+L8.h"
#include <objc/runtime.h>

BOOL protocolImplementsProtocol(Protocol *candidate, Protocol *target)
{
	unsigned int count;
	Protocol * __unsafe_unretained *protocols = protocol_copyProtocolList(candidate, &count);

	for(unsigned int i = 0; i < count; i++) {
		if(protocol_isEqual(protocols[i], target)) {
			free(protocols);
			return YES;
		}
	}

	free(protocols);
	return NO;
}

void forEachProtocolImplementingProtocol(Class cls, Protocol *target, void (^callback)(Protocol *))
{
	Protocol * __unsafe_unretained *protocols;
	unsigned int count;

	protocols = class_copyProtocolList(cls, &count);
	for(int i = 0; i < count; i++) {
		Protocol *candidate = protocols[i];

		if(protocolImplementsProtocol(candidate, target))
			callback(candidate);
	}

	free(protocols);
}

void forEachMethodInProtocol(Protocol *protocol, BOOL isRequiredMethod, BOOL isInstanceMethod, void (^callback)(SEL name, const char *types))
{
	unsigned int count;
	struct objc_method_description *methods;

	methods = protocol_copyMethodDescriptionList(protocol, isRequiredMethod,
												 isInstanceMethod, &count);
	for(unsigned int i = 0; i < count; i++)
		callback(methods[i].name, methods[i].types);

	free(methods);
}

void forEachPropertyInProtocol(Protocol *protocol, void (^callback)(objc_property_t property))
{
	unsigned int count;
	objc_property_t *properties = protocol_copyPropertyList(protocol, &count);

	for(unsigned int i = 0; i < count; i++)
		callback(properties[i]);

	free(properties);
}

void forEachMethodInClass(Class cls, void (^callback)(Method method))
{
	unsigned int count;
	Method *methods = class_copyMethodList(cls, &count);

	for(unsigned int i = 0; i < count; i++)
		callback(methods[i]);

	free(methods);
}

