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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

@class L8Value;

/**
 * @brief The JavaScript runtime
 */
@interface L8Runtime : NSObject

/**
 * Executes a block in the runtime.
 *
 * This is the only way to work with JSValues, besides in callbacks.
 * That is due to the current design of L8 and the Scoping system of V8.
 *
 * @param block Block to execute within handlescope of V8
 */
- (void)executeBlockInRuntime:(void(^)(L8Runtime *runtime))block;

/**
 * Loads a script at given path into the system by evaluating it.
 *
 * @param filePath path of the script file
 * @return YES on success, NO otherwise
 */
- (BOOL)loadScriptAtPath:(NSString *)filePath;

/**
 * Loads given script with given name into the runtime.
 *
 * @param scriptData the script
 * @param name name of the script. Used in stacktraces and errors.
 * @return YES on success, NO otherwise
 */
- (BOOL)loadScript:(NSString *)scriptData withName:(NSString *)name;

/**
 * Evaluate given script in the runtime.
 *
 * @param scriptData the script contents
 * @return the scripts return value
 */
- (L8Value *)evaluateScript:(NSString *)scriptData;

/**
 * Evaluate given script in the runtime.
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
 * Returns the runtime the caller is running in.
 *
 * This returns <code>nil</code> when the caller is not in a callback and not
 * in an executeBlockInRuntime block.
 *
 * @return L8Runtime of the current runtime
 */
+ (L8Runtime *)currentRuntime;

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
 * This method is blocking.
 */
- (void)runGarbageCollector;

@end

/**
 * @brief Subscripting support
 */
@interface L8Runtime (Subscripting)

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