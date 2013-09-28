//
//  NSObject+ObjCRuntime.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#include <objc/runtime.h>

BOOL protocolImplementsProtocol(Protocol *candidate, Protocol *target);
void forEachProtocolImplementingProtocol(Class cls, Protocol *target, void (^callback)(Protocol *));
void forEachMethodInProtocol(Protocol *protocol, BOOL isRequiredMethod, BOOL isInstanceMethod, void (^callback)(SEL sel, const char *));
void forEachMethodInClass(Class cls, void (^callback)(Method method));
void forEachPropertyInProtocol(Protocol *protocol, void (^callback)(objc_property_t property));

extern "C" {
	const char *_protocol_getMethodTypeEncoding(Protocol *protocol, SEL sel, BOOL isRequiredMethod, BOOL isInstanceMethod);
	id objc_initWeak(id *, id);
	void objc_destroyWeak(id *);
	bool _Block_has_signature(void *);
	const char *_Block_signature(void *);
}
