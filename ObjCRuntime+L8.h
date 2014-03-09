//
//  NSObject+ObjCRuntime.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/14/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#include <objc/runtime.h>
#include <Availability.h>

BOOL protocolImplementsProtocol(Protocol *candidate, Protocol *target);
void forEachProtocolImplementingProtocol(Class cls, Protocol *target, void (^callback)(Protocol *));
void forEachMethodInProtocol(Protocol *protocol, BOOL isRequiredMethod, BOOL isInstanceMethod, void (^callback)(SEL sel, const char *));
void forEachMethodInClass(Class cls, void (^callback)(Method method, BOOL *stop));
void forEachPropertyInProtocol(Protocol *protocol, void (^callback)(objc_property_t property));

extern "C" {
	/**
	 * Gets an extended type encoding for a method in given protocol.
	 *
	 * Objects can have extended types: the @ will then be followed by "classname".
	 *
	 * @param protocol The protocol containing the method
	 * @param sel The selector of the method
	 * @param isRequiredMethod whether the method is @required
	 * @param isInstanceMethod whether the method is an instance or class method
	 * @return char* string with extended encoding on the stack (do not free)
	 */
	const char *_protocol_getMethodTypeEncoding(Protocol *protocol, SEL sel,
												BOOL isRequiredMethod, BOOL isInstanceMethod)
		__OSX_AVAILABLE_STARTING(__MAC_10_8, __IPHONE_6_0);

	id objc_initWeak(id *addr, id val)
		__OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_5_0);

	void objc_destroyWeak(id *addr)
		__OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_5_0);

	bool _Block_has_signature(void *block)
		__OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_3_2);

	const char *_Block_signature(void *block)
		__OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_3_2);
}
