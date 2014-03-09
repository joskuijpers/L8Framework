//
//  L8Value_Private.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8Value.h"
#include "v8.h"

@interface L8Value ()

+ (L8Value *)valueWithV8Value:(v8::Handle<v8::Value>)value;
- (v8::Handle<v8::Value>)V8Value;

- (L8Value *)init;
- (L8Value *)initWithV8Value:(v8::Handle<v8::Value>)value;

@end

v8::Local<v8::Value> objectToValue(L8Runtime *runtime, id object);

id valueToObject(L8Runtime *runtime, v8::Handle<v8::Value> value);
NSNumber *valueToNumber(L8Runtime *runtime, v8::Handle<v8::Value> value);
NSString *valueToString(L8Runtime *runtime, v8::Handle<v8::Value> value);
NSDate *valueToDate(L8Runtime *runtime, v8::Handle<v8::Value> value);
NSArray *valueToArray(L8Runtime *runtime, v8::Handle<v8::Value> value);
NSDictionary *valueToDictionary(L8Runtime *runtime, v8::Handle<v8::Value> value);
