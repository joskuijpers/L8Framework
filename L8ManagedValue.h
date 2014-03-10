//
//  L8ManagedValue.h
//  Sphere
//
//  Created by Jos Kuijpers on 10/03/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

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
