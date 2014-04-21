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

@class L8Context, L8ArrayBuffer;

/**
 * @brief Wrapper of a JavaScript value.
 *
 * A L8Value holds a strong reference to the L8Context, thus as long as 
 * a L8Value is active, the context remains alive.
 *
 * Avoid storing any L8Values in instance variables or collections.
 * Use L8ManagedValue instead.
 *
 */
@interface L8Value : NSObject

/**
 * The L8Context that this value originated from.
 */
@property (nonatomic,readonly) L8Context *context;

/**
 * Create a L8Value by converting an Objective-C object.
 *
 * The resulting L8Value retains the Objective-C object.
 *
 * @param value The Objective-C object to be converted.
 * @param context The context to create the value in.
 * @return The new L8Value
 */
+ (instancetype)valueWithObject:(id)value inContext:(L8Context *)context;

/**
 * Create a L8Value from a BOOL primitive.
 *
 * @param value The BOOL primitive.
 * @param context The context to create the value in.
 * @return The new L8Value representing the equivalent boolean value.
 */
+ (instancetype)valueWithBool:(BOOL)value inContext:(L8Context *)context;

/**
 * Create a L8Value from a double primitive.
 *
 * @param value The double primitive.
 * @param context The context to create the value in.
 * @return The new L8Value representing the equivalent double value.
 */
+ (instancetype)valueWithDouble:(double)value inContext:(L8Context *)context;

/**
 * Create a L8Value from an integer primitive.
 *
 * @param value The integer primitive.
 * @param context The context to create the value in.
 * @return The new L8Value representing the equivalent integer value.
 */
+ (instancetype)valueWithInt32:(int32_t)value inContext:(L8Context *)context;

/**
 * Create a L8Value from an unsigned integer primitive.
 *
 * @param value The unsigned integer primitive.
 * @param context The context to create the value in.
 * @return The new L8Value representing the 
 * equivalent unsigned integer value.
 */
+ (instancetype)valueWithUInt32:(uint32_t)value inContext:(L8Context *)context;

/**
 * Create a new, empty JavaScript object.
 *
 * @param context The context to create the value in.
 * @return The new JavaScript object.
 */
+ (instancetype)valueWithNewObjectInContext:(L8Context *)context;

/**
 * Create a new, empty JavaScript array.
 *
 * @param context The context to create the value in.
 * @return The new JavaScript array.
 */
+ (instancetype)valueWithNewArrayInContext:(L8Context *)context;

/**
 * Create a new JavaScript regular expression object.
 *
 * @param pattern The regular expression pattern.
 * @param flags The regular expression flags.
 * @param context The context to create the value in.
 * @return The new JavaScript regular expression object.
 */
+ (instancetype)valueWithNewRegularExpressionFromPattern:(NSString *)pattern
												   flags:(NSString *)flags
											   inContext:(L8Context *)context;

/**
 * Create a new JavaScript error object.
 *
 * @param message The error message.
 * @param context The context to create the value in.
 * @return The new JavaScript error object.
 */
+ (instancetype)valueWithNewErrorFromMessage:(NSString *)message inContext:(L8Context *)context;

/**
 * Create a new JavaScript value <code>null</code>.
 *
 * @param context The context to create the value in.
 * @return The new JavaScript <code>null</code> value.
 */
+ (instancetype)valueWithNullInContext:(L8Context *)context;

/**
 * Create a new JavaScript value <code>undefined</code>.
 *
 * @param context The context to create the value in.
 * @return The new JavaScript <code>undefined</code> value.
 */
+ (instancetype)valueWithUndefinedInContext:(L8Context *)context;

#ifdef L8_ENABLE_SYMBOLS
/**
 * Create a new JavaScript Symbol.
 *
 * @param The name of the symbol.
 * @param context The context to create the value in.
 * @return The new JavaScript symbol.
 */
+ (instancetype)valueWithSymbol:(NSString *)symbol inContext:(L8Context *)context;

/**
 * Create a new Symbol.
 *
 * @param context The context to create the value in.
 * @return The new JavaScript Symbol.
 */
+ (instancetype)valueWithNewSymbolInContext:(L8Context *)context;
#endif

#ifdef L8_ENABLE_TYPED_ARRAYS
/**
 * Create a new JavaScript ArrayBuffer.
 *
 * @param length The length of the array buffer.
 * @param context The context to create the value in.
 * @return The new JavaScript ArrayBuffer
 */
+ (instancetype)valueWithArrayBufferOfLength:(size_t)length inContext:(L8Context *)context;
#endif

/**
 * @page convertingtypes Converting to Objective-C Types
 * When converting between JavaScript values and Objective-C objects a copy is
 * performed. Values of types listed below are copied to the corresponding
 * types on conversion in each direction. For NSDictionaries, entries in the
 * dictionary that are keyed by strings are copied onto a JavaScript object.
 * For dictionaries and arrays, conversion is recursive, with the same object
 * conversion being applied to all entries in the collection.
 *
 * <pre>
 * Objective-C type  |   JavaScript type
 * ------------------+---------------------
 * nil               |     undefined
 * NSNull            |        null
 * NSString          |       string
 * NSNumber          |   number, boolean
 * NSDictionary      |    Object object
 * NSArray           |    Array object
 * NSDate            |     Date object
 * NSData            |  ArrayBuffer object
 * L8Value           |    Symbol object
 * NSBlock *         |  Function object *
 * id **             |  Wrapper object **
 * Class ***         |Constructor object ***
 * </pre>
 *
 * * Instances of NSBlock with supported arguments types will be presented to
 * JavaScript as a callable Function object. For more information on supported
 * argument types see L8Export.h. If a JavaScript Function originating from an
 * Objective-C block is converted back to an Objective-C object the block will
 * be returned. All other JavaScript functions will be converted in the same
 * manner as a JavaScript object of type Object.
 *
 * ** For Objective-C instances that do not derive from the set of types listed
 * above, a wrapper object to provide a retaining handle to the Objective-C
 * instance from JavaScript. For more information on these wrapper objects, see
 * L8Export.h. When a JavaScript wrapper object is converted back to Objective-C
 * the Objective-C instance being retained by the wrapper is returned.
 *
 * *** For Objective-C Class objects a constructor object containing exported
 * class methods will be returned. See L8Export.h for more information on
 * constructor objects.
 *
 * For all methods taking arguments of type id, arguments will be converted
 * into a JavaScript value according to the above conversion.
 */

/**
 * Convert this L8Value to an Objective-C object.
 *
 * The L8Value is converted to an Objective-C object according
 * to the conversion rules specified above.
 *
 * @return The Objective-C representation of this L8Value.
 */
- (id)toObject;

/**
 * Convert a L8Value to an Objective-C object of a specific class.
 *
 * The L8Value is converted to an Objective-C object of the given class.
 * If the object is not of the specified class, <code>nil</code> is returned.
 *
 * @return An Objective-C object of the specified class or <code>nil</code>
 */
- (id)toObjectOfClass:(Class)expectedClass;

/**
 * Convert a L8Value to a block.
 *
 * This method can only return a block when actual blocks are used
 * to generate the function.
 *
 * @return A block object or <code>nil</code> if not a function
 * or not a native function.
 */
- (id)toBlockFunction;

/**
 * Convert a L8Value to a boolean.
 *
 * The L8Value is converted to a boolean according to the rules
 * specified by the JavaScript language.
 *
 * @return The boolean result of the conversion.
 */
- (BOOL)toBool;

/**
 * Convert a L8Value to a double.
 *
 * The L8Value is converted to a number according to the rules
 * specified by the JavaScript language.
 *
 * @return The double result of the conversion.
 */
- (double)toDouble;

/**
 * Convert a L8Value to an <code>int32_t</code>.
 *
 * The L8Value is converted to an integer according to the rules specified
 * by the JavaScript language.
 *
 * @return The <code>int32_t</code> result of the conversion.
 */
- (int32_t)toInt32;

/**
 * Convert a L8Value to a <code>uint32_t</code>.
 * 
 * The L8Value is converted to an integer according to the rules
 * specified by the JavaScript language.
 *
 * @return The <code>uint32_t</code> result of the conversion.
 */
- (uint32_t)toUInt32;

/**
 * Convert a L8Value to a NSNumber.
 *
 * If the L8Value represents a boolean, a NSNumber value of YES or NO
 * will be returned. For all other types the value will be converted to a number according
 * to the rules specified by the JavaScript language.
 *
 * @return The NSNumber result of the conversion.
 */
- (NSNumber *)toNumber;

/**
 * Convert a L8Value to a NSString.
 *
 * The L8Value is converted to a string according to the rules specified
 * by the JavaScript language.
 *
 * @return The NSString containing the result of the conversion.
 */
- (NSString *)toString;

/**
 * Convert a L8Value to a NSDate.
 *
 * The value is converted to a number representing a time interval
 * since 1970 which is then used to create a new NSDate instance.
 *
 * @return The NSDate created using the converted time interval.
 */
- (NSDate *)toDate;

/**
 * Convert a L8Value to a NSArray.
 *
 * If the value is <code>null</code> or <code>undefined</code> then <code>nil</code> is returned.
 * If the value is not an object then a JavaScript TypeError will be thrown.
 * The property <code>length</code> is read from the object, converted to an unsigned
 * integer, and an NSArray of this size is allocated. Properties corresponding
 * to indicies within the array bounds will be copied to the array, with
 * L8Values converted to equivalent Objective-C objects as specified.
 *
 * @return The NSArray containing the recursively converted contents of the
 * converted JavaScript array.
 */
- (NSArray *)toArray;

/**
 * Convert a L8Value to a NSDictionary.
 *
 * If the value is <code>null</code> or <code>undefined</code> then <code>nil</code> is returned.
 * If the value is not an object then a JavaScript TypeError will be thrown.
 * All enumerable properties of the object are copied to the dictionary, with
 * L8Values converted to equivalent Objective-C objects as specified.
 *
 * @return The NSDictionary containing the recursively converted contents of
 * the converted JavaScript object.
 */
- (NSDictionary *)toDictionary;

#ifdef L8_ENABLE_TYPED_ARRAYS
/**
 * Convert a L8Value to NSData.
 *
 * If the value is <code>null</code> or <code>undefined</code> then <code>nil</code> is returned.
 * If the value is not an ArrayBufer, a JavaScript TypeError will be thrown.
 *
 * @return The NSData object containing the ArrayBuffer data.
 */
- (L8ArrayBuffer *)toArrayBuffer;
#endif

/**
 * Access a property of a L8Value.
 *
 * @param property The name of the property.
 * @return The L8Value for the requested property or the L8Value <code>undefined</code>
 * if the property does not exist.
 */
- (L8Value *)valueForProperty:(NSString *)property;

/**
 * Set a property on a L8Value.
 *
 * @param value The value of the property.
 * @param property The name of the property.
 */
- (void)setValue:(id)value forProperty:(NSString *)property;

/**
 * Delete a property from a L8Value.
 *
 * @return YES if deletion is successful, NO otherwise.
 */
- (BOOL)deleteProperty:(NSString *)property;

/**
 * Check if a L8Value has a property.
 *
 * This method has the same function as the JavaScript operator <code>in</code>.
 *
 * @param property The name of the property.
 * @return Returns YES if property is present on the value.
 */
- (BOOL)hasProperty:(NSString *)property;

/**
 * Access an indexed (numerical) property on a L8Value.
 *
 * @param index The index that is the property.
 * @return The L8Value for the property at the specified index.
 * Returns the JavaScript value <code>undefined</code> if no property
 * exists at that index.
 */
- (L8Value *)valueAtIndex:(NSUInteger)index;

/**
 * Set an indexed (numerical) property on a L8Value.
 *
 * For L8Values that are JavaScript arrays, indices greater than
 * UINT_MAX - 1 will not affect the length of the array.
 *
 * @param value The value for the property.
 * @param index Index that is the property.
 */
- (void)setValue:(id)value atIndex:(NSUInteger)index;

/**
 * Define properties with custom descriptors on L8Values.
 *
 * This method may be used to create a data or accessor property on an object.
 * This method operates in accordance with the Object.defineProperty 
 * method in the JavaScript language.
 *
 * @param property The name of the property
 * @param descriptor The property descriptor
 */
- (void)defineProperty:(NSString *)property descriptor:(id)descriptor;

/**
 * Check if a L8Value corresponds to the JavaScript value <code>undefined</code>.
 *
 * @return YES if the value is <code>undefined</code>, NO otherwise.
 */
- (BOOL)isUndefined;

/**
 * Check if a L8Value corresponds to the JavaScript value <code>null</code>.
 *
 * @return YES if the L8Value is <code>null</code>. NO otherwise.
 */
- (BOOL)isNull;

/**
 * Check if a L8Value is a boolean.
 *
 * @return YES if the L8Value is a boolean. NO otherwise.
 */
- (BOOL)isBoolean;

/**
 * Check if a L8Value is a number.
 *
 * In JavaScript, there is no differentiation between types of numbers.
 * Semantically all numbers behave like doubles except in special 
 * cases like operations.
 *
 * @return YES if the L8Value is a number. NO otherwise.
 */
- (BOOL)isNumber;

/**
 * Check if a L8Value is a string.
 *
 * @return YES if the L8Value is a string. NO otherwise.
 */
- (BOOL)isString;

/**
 * Check if a L8Value is an object.
 *
 * @return YES if the L8Value is an object. NO otherwise.
 */
- (BOOL)isObject;

/**
 * Check if a L8Value is a function.
 *
 * @return YES if the L8Value is a function. NO otherwise.
 */
- (BOOL)isFunction;

/**
 * Check if a L8Value is a regular expression.
 *
 * @return YES if the L8Value is a regular expression. NO otherwise.
 */
- (BOOL)isRegularExpression;

/**
 * Check if a L8Value is a native error.
 *
 * @return YES if this L8Value represents a native error. NO otherwise.
 */
- (BOOL)isNativeError;

#ifdef L8_ENABLE_SYMBOLS
/**
 * Check if the L8Value is a Symbol.
 *
 * @return YES if this L8Value represents a Symbol. NO otherwise.
 */
- (BOOL)isSymbol;
#endif

#ifdef L8_ENABLE_TYPED_ARRAYS
/**
 * Check if the L8Value is a ArrayBuffer.
 *
 * @return YES if this L8Value represents an ArrayBuffer. NO otherwise.
 */
- (BOOL)isArrayBuffer;
#endif

/**
 * Compare two L8Values using JavaScript's <code>===</code> operator.
 *
 * @param value The value to compare to.
 * @return YES if equal, NO if not.
 */
- (BOOL)isEqualToObject:(id)value;

/**
 * Compare two L8Values using JavaScript's <code>==</code> operator.
 *
 * @param value The value to compare to.
 * @return YES if equal, NO if not.
 */
- (BOOL)isEqualWithTypeCoercionToObject:(id)value;

/**
 * Check if a L8Value is an instance of another object.
 *
 * This method has the same function as the JavaScript operator 
 * <code>instanceof</code>. If an object other than a L8Value is passed,
 * it will first be converted according to the aforementioned rules.
 *
 * @param value The value to check against.
 * @return YES if this L8Value is an instance of value.
 */
- (BOOL)isInstanceOf:(id)value;

/**
 * Throws this L8Value as an exception in current running L8Context.
 */
- (void)throwValue;

/**
 * Invoke a L8Value as a function.
 *
 * In JavaScript, if a function doesn't explicitly return a value then it
 * implicitly returns the JavaScript value <code>undefined</code>.
 *
 * @param arguments The arguments to pass to the function.
 * @return The return value of the function call.
 */
- (L8Value *)callWithArguments:(NSArray *)arguments;

/**
 * Invoke a L8Value as a constructor.
 *
 * This is equivalent to using the <code>new</code> syntax in JavaScript.
 *
 * @param arguments The arguments to pass to the constructor.
 * @return The return value of the constructor call.
 */
- (L8Value *)constructWithArguments:(NSArray *)arguments L8_WARN_UNUSED_RESULT;

/**
 * Invoke a method on a L8Value.
 *
 * Accesses the property named <code>method</code> from this value and
 * calls the resulting value as a function, passing this L8Value as the 
 * <code>this</code> value along with the specified arguments.
 *
 * @param method The name of the method to be invoked.
 * @param arguments The arguments to pass to the method.
 * @return The return value of the method call.
 */
- (L8Value *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments;

@end

/**
 * @brief Subscripting support for L8Value.
 */
@interface L8Value (Subscripting)

/**
 * Access a property of a L8Value.
 *
 * @param key The name of the property.
 * @return The L8Value for the requested property or the L8Value <code>undefined</code>
 * if the property does not exist.
 */
- (L8Value *)objectForKeyedSubscript:(id)key;

/**
 * Access an indexed (numerical) property on a L8Value.
 *
 * @param index The index that is the property.
 * @return The L8Value for the property at the specified index.
 * Returns the JavaScript value <code>undefined</code> if no property
 * exists at that index.
 */
- (L8Value *)objectAtIndexedSubscript:(NSUInteger)index;

/**
 * Set a property on a L8Value.
 *
 * @param object The value of the property.
 * @param key The name of the property.
 */
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;

/**
 * Set an indexed (numerical) property on a L8Value.
 *
 * For L8Values that are JavaScript arrays, indices greater than
 * UINT_MAX - 1 will not affect the length of the array.
 *
 * @param object The value for the property.
 * @param index Index that is the property.
 */
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

@end
