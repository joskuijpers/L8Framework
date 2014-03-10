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

@class L8Value;

/**
 * @brief Value store with garbage collection handling
 */
@interface L8ManagedValue : NSObject

/**
 * Get the JSValue from the JSManagedValue.
 *
 * @result The corresponding JSValue for this JSManagedValue or
 *  nil if the JSValue has been collected.
 */
@property (readonly) L8Value *value;

/**
 * Create a JSManagedValue from a JSValue.
 *
 * @param value
 * @result The new JSManagedValue.
 */
+ (L8ManagedValue *)managedValueWithValue:(L8Value *)value;

/**
 * Create a JSManagedValue from a JSValue and add it to the runtime.
 *
 * @param value
 * @param owner
 * @result The new JSManagedValue.
 */
+ (L8ManagedValue *)managedValueWithValue:(L8Value *)value andOwner:(id)owner;

/**
 * Create a JSManagedValue.
 *
 * @param value
 * @result The new JSManagedValue.
 */
- (instancetype)initWithValue:(L8Value *)value;

@end
