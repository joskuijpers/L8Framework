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
#include <Availability.h>

/**
 * Get whether given target implements given candidate.
 *
 * @param candidate
 * @param target
 * @return YES when it is implemented, NO otherwise.
 */
BOOL l8_protocol_implements_protocol(Protocol *candidate,
									 Protocol *target);

/**
 * Enumerate over the protocols implementing given protocol
 * in the specified class.
 *
 * @param cls The class to search protocols for.
 * @param target The protocol each protocol must implement.
 * @param callback The callback block.
 */
void l8_for_each_protocol_implementing_protocol(Class cls,
												Protocol *target,
												void (^callback)(Protocol *protocol));

/**
 * Enumerate over the methods implemented by specified protocol.
 *
 * @param protocol The protocol to look into.
 * @param isRequiredMethod Whether the methods to enumerate over
 * must be set as @required.
 * @param isInstanceMethod Whether the methods to enumerate over are
 * instance methods (YES) or class methods (NO).
 * @param callback The callback block.
 */
void l8_for_each_method_in_protocol(Protocol *protocol,
									BOOL isRequiredMethod,
									BOOL isInstanceMethod,
									void (^callback)(SEL sel, const char *types));

/**
 * Enumerate over the methods in a class.
 *
 * @param cls The class to look into.
 * @param callback The callback block.
 */
void l8_for_each_method_in_class(Class cls,
								 void (^callback)(Method method, BOOL *stop));

/**
 * Enumerate over the properties in a protocol.
 *
 * @param protocol The protocol to look into.
 * @param callback The callback block.
 */
void l8_for_each_property_in_protocol(Protocol *protocol,
									  void (^callback)(objc_property_t property));

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
