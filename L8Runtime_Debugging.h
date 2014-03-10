//
//  L8Runtime+Debugging.h
//  Sphere
//
//  Created by Jos Kuijpers on 9/28/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8Runtime.h"

/**
 * @Brief Runtime extension for debugging.
 */
@interface L8Runtime ()

/// Port for the debugger to attach to.
@property (assign) uint16_t debuggerPort;

/**
 * Whether to wait for the debugger to attach.
 *
 * If this property equals YES, enableDebugging will block
 * until a remote debugger has attached.
 */
@property (assign) BOOL waitForDebugger;

/**
 * Enable support for debugging.
 *
 * If waitForDebugger is <code>YES</code>, this method
 * will block until a remote debugger attached.
 */
- (void)enableDebugging;

/**
 * Disable support for debugging.
 */
- (void)disableDebugging;

@end
