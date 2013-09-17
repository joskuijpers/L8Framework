//
//  L8Reporter_Private.h
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8Reporter.h"

#include "v8.h"

@interface L8Reporter ()

- (void)reportTryCatch:(v8::TryCatch *)tryCatch inIsolate:(v8::Isolate *)isolate;

@end
