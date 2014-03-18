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

/**
 * @brief JavaScript Virtual Machine.
 *
 * A Virtual Machine contains one or more contexts.
 */
@interface L8VirtualMachine : NSObject

/**
 * Initialize a new virtual machine.
 *
 * @return self.
 */
- (instancetype)init L8_DESIGNATED_INITIALIZER;

/**
 * Notify the JSVirtualMachine of an external object relationship.
 *
 * @param object Referenced object
 * @param owner Owner of the reference
 */
- (void)addManagedReference:(id)object withOwner:(id)owner;

/**
 * Notify the JSVirtualMachine that a previous object relationship no longer exists.
 *
 * @param object Referenced object
 * @param owner Owner of the reference
 */
- (void)removeManagedReference:(id)object withOwner:(id)owner;

/**
 * Attempt to run the garbage collector.
 *
 * @note This method is blocking and should only be used in
 * debug builds.
 */
- (void)runGarbageCollector;

@end
