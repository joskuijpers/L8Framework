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

void forEachMethodInClass(Class cls, void (^callback)(Method method, BOOL *stop))
{
	unsigned int count;
	Method *methods = class_copyMethodList(cls, &count);
	BOOL stop = NO;

	for(unsigned int i = 0; i < count && !stop; i++)
		callback(methods[i],&stop);

	free(methods);
}

