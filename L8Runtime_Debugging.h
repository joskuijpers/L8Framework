//
//  L8Runtime+Debugging.h
//  Sphere
//
//  Created by Jos Kuijpers on 9/28/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8Runtime.h"

@interface L8Runtime ()

@property (assign) uint16_t debuggerPort;
@property (assign) BOOL waitForDebugger;

- (void)enableDebugging;
- (void)disableDebugging;

@end
