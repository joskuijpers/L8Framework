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

@class L8VirtualMachine, L8Value;

/**
 * @brief The JavaScript context
 */
@interface L8Context : NSObject

/// The virtual machine containing this context.
@property (nonatomic,readonly) L8VirtualMachine *virtualMachine;

/**
 * Initialize a new context in a new virtual machine.
 *
 * @return self.
 */
- (instancetype)init;

/**
 * Initialize a new context in a specific, existing, virtual machine.
 *
 * @param virtualMachine The virtual machine.
 * @return self.
 */
- (instancetype)initWithVirtualMachine:(L8VirtualMachine *)virtualMachine L8_DESIGNATED_INITIALIZER;

/**
 * Executes a block in the context.
 *
 * This is the only way to work with JSValues, besides in callbacks.
 * That is due to the current design of L8 and the Scoping system of V8.
 *
 * @param block Block to execute within handlescope of V8
 */
- (void)executeBlockInContext:(void(^)(L8Context *context))block;
//	L8_DEPRECATED("No need to use this construct anymore.");

/**
 * Loads a script at given path into the system by evaluating it.
 *
 * @param filePath path of the script file
 * @return YES on success, NO otherwise
 */
- (BOOL)loadScriptAtPath:(NSString *)filePath;

/**
 * Loads given script with given name into the context.
 *
 * @param scriptData the script
 * @param name name of the script. Used in stacktraces and errors.
 * @return YES on success, NO otherwise
 */
- (BOOL)loadScript:(NSString *)scriptData withName:(NSString *)name;

/**
 * Evaluate given script in the context.
 *
 * @param scriptData the script contents
 * @return the scripts return value
 */
- (L8Value *)evaluateScript:(NSString *)scriptData;

/**
 * Evaluate given script in the context.
 *
 * @param scriptData the script contents
 * @param name name used in stacktraces and errors
 * @return the scripts return value
 */
- (L8Value *)evaluateScript:(NSString *)scriptData withName:(NSString *)name;

/**
 * Returns the object depicting the global object.
 *
 * @return L8Value, an JS object
 */
- (L8Value *)globalObject;

/**
 * Returns the context the caller is running in.
 *
 * This returns <code>nil</code> when the caller is not in a callback and not
 * in an executeBlockInContext block.
 *
 * @return L8Context of the current context
 */
+ (instancetype)currentContext;

/**
 * Returns the current <code>this</code> object.
 *
 * This returns <code>nil</code> when the caller is not in a callback.
 *
 * @return L8Value containing the current <code>this</code> object
 */
+ (L8Value *)currentThis;

/**
 * Returns the current running function. Also <code>arguments.callee</code>.
 *
 * This returns <code>nil</code> when the caller is not in a callback.
 *
 * @return L8Value containing a JS function.
 */

+ (L8Value *)currentCallee;

/**
 * Returns the arguments of the function called for the callback to trigger.
 *
 * This returns <code>nil</code> when the caller is not in a callback.
 *
 * @return An NSArray of JSValue objects, one for each argument
 */
+ (NSArray *)currentArguments; // L8Value

@end

/**
 * @brief Subscripting support
 */
@interface L8Context (Subscripting)

/**
 * Access a property of the globalObject.
 *
 * @param key The name of the property.
 * @return The L8Value for the requested property or the L8Value <code>undefined</code>
 * if the property does not exist.
 */
- (L8Value *)objectForKeyedSubscript:(id)key;

/**
 * Set a property on the globalObject.
 *
 * @param object The value of the property.
 * @param key The name of the property.
 */
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;

@end