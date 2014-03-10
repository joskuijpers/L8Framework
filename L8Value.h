//
//  V8Value.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

@class L8Runtime;

/**
 * @brief Wrapper of a JavaScript value.
 *
 * A L8Value holds a strong reference to the L8Runtime, thus as long as 
 * a L8Value is active, the runtime remains alive.
 *
 * Avoid storing any L8Values in instance variables or collections.
 * Use L8ManagedValue instead.
 *
 */
@interface L8Value : NSObject

/**
 * The L8Runtime that this value originated from.
 */
@property (readonly) L8Runtime *runtime;

/**
 * Create a L8Value by converting an Objective-C object.
 *
 * The resulting L8Value retains the Objective-C object.
 *
 * @param value The Objective-C object to be converted.
 * @return The new L8Value
 */
+ (L8Value *)valueWithObject:(id)value;

/**
 * Create a L8Value from a BOOL primitive.
 *
 * @param value The BOOL primitive
 * @return The new L8Value representing the equivalent boolean value.
 */
+ (L8Value *)valueWithBool:(BOOL)value;

/**
 * Create a L8Value from a double primitive.
 *
 * @param value The double primitive
 * @return The new L8Value representing the equivalent double value.
 */
+ (L8Value *)valueWithDouble:(double)value;

/**
 * Create a L8Value from an integer primitive.
 *
 * @param value The integer primitive
 * @return The new L8Value representing the equivalent integer value.
 */
+ (L8Value *)valueWithInt32:(int32_t)value;

/**
 * Create a L8Value from an unsigned integer primitive.
 *
 * @param value The unsigned integer primitive
 * @return The new L8Value representing the 
 * equivalent unsigned integer value.
 */
+ (L8Value *)valueWithUInt32:(uint32_t)value;

/**
 * Create a new, empty JavaScript object.
 *
 * @return The new JavaScript object.
 */
+ (L8Value *)valueWithNewObject;

/**
 * Create a new, empty JavaScript array.
 *
 * @return The new JavaScript array.
 */
+ (L8Value *)valueWithNewArray;

/**
 * Create a new JavaScript regular expression object.
 *
 * @param pattern The regular expression pattern.
 * @param flags The regular expression flags.
 * @return The new JavaScript regular expression object.
 */
+ (L8Value *)valueWithNewRegularExpressionFromPattern:(NSString *)pattern
												flags:(NSString *)flags;

/**
 * Create a new JavaScript error object.
 *
 * @param message The error message
 * @return The new JavaScript error object.
 */
+ (L8Value *)valueWithNewErrorFromMessage:(NSString *)message;

/**
 * Create a new JavaScript value <code>null</code>.
 *
 * @return The new JavaScript <code>null</code> value.
 */
+ (L8Value *)valueWithNull;

/**
 * Create a new JavaScript value <code>undefined</code>.
 *
 * @return The new JavaScript <code>undefined</code> value.
 */
+ (L8Value *)valueWithUndefined;

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
 * NSDictionary      |   Object object
 * NSArray           |    Array object
 * NSDate            |     Date object
 * NSBlock *         |   Function object *
 * id **             |   Wrapper object **
 * Class ***         | Constructor object ***
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
 * @return A block object or <code>nil</code> if not a function.
 */
- (id)toFunction;

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
 * Throws this L8Value as an exception in current running L8Runtime.
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
- (L8Value *)constructWithArguments:(NSArray *)arguments;

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
