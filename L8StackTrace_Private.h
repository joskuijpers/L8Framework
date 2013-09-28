//
//  L8StackTrace_Private.h
//  Sphere
//
//  Created by Jos Kuijpers on 9/26/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8StackTrace.h"
#include "v8.h"

@interface L8StackTrace ()

- (id)initWithV8StackTrace:(v8::Handle<v8::StackTrace>)v8stackTrace;

@end

@interface L8StackFrame ()

- (id)initWithV8StackFrame:(v8::Handle<v8::StackFrame>)v8stackFrame;

@end