//
//  V8Value.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L8Runtime;

@interface L8Value : NSObject

@property (readonly,strong) L8Runtime *runtime;

+ (L8Value *)valueWithObject:(id)value;

+ (L8Value *)valueWithBool:(BOOL)value;
+ (L8Value *)valueWithDouble:(double)value;
+ (L8Value *)valueWithInt32:(int32_t)value;
+ (L8Value *)valueWithUInt32:(uint32_t)value;

+ (L8Value *)valueWithNewObject;
+ (L8Value *)valueWithNewArray;
+ (L8Value *)valueWithNewRegularExpressionFromPattern:(NSString *)pattern flags:(NSString *)flags;
+ (L8Value *)valueWithNewErrorFromMessage:(NSString *)message;
+ (L8Value *)valueWithNull;
+ (L8Value *)valueWithUndefined;

- (id)toObject;
- (id)toObjectOfClass:(Class)expectedClass;
- (id)toFunction;

- (BOOL)toBool;
- (double)toDouble;
- (int32_t)toInt32;
- (uint32_t)toUInt32;

- (NSNumber *)toNumber;
- (NSString *)toString;
- (NSDate *)toDate;
- (NSArray *)toArray;
- (NSDictionary *)toDictionary;

// Keyed properties
- (L8Value *)valueForProperty:(NSString *)property;
- (void)setValue:(id)value forProperty:(NSString *)property;
- (BOOL)deleteProperty:(NSString *)property;
- (BOOL)hasProperty:(NSString *)property;

// Indexed properties
- (L8Value *)valueAtIndex:(NSUInteger)index;
- (void)setValue:(id)value atIndex:(NSUInteger)index;

- (BOOL)isUndefined;
- (BOOL)isNull;
- (BOOL)isBoolean;
- (BOOL)isNumber;
- (BOOL)isString;
- (BOOL)isObject;
- (BOOL)isFunction;
- (BOOL)isRegularExpression;
- (BOOL)isNativeError;

- (BOOL)isEqualToObject:(id)value;
- (BOOL)isEqualWithTypeCoercionToObject:(id)value;
- (BOOL)isInstanceOf:(id)value;

- (void)throwValue;

- (L8Value *)callWithArguments:(NSArray *)arguments;
- (L8Value *)constructWithArguments:(NSArray *)arguments;
- (L8Value *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments;

@end

@interface L8Value (Subscripting)

- (L8Value *)objectForKeyedSubscript:(id)key;
- (L8Value *)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

@end
