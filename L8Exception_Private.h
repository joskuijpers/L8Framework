//
//  L8Exception_Private.h
//  Sphere
//
//  Created by Jos Kuijpers on 23/02/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

#import "L8Exception.h"
#include "v8.h"

@interface L8Exception ()

@property (readonly,weak) id thrownObject;

+ (instancetype)exceptionWithV8Message:(v8::Local<v8::Message>)message
						  thrownObject:(__weak id)object;

- (v8::Handle<v8::Value>)v8exception;
+ (v8::Handle<v8::Value>)v8exceptionWithMessage:(NSString *)message;

@end
