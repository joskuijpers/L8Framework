//
//  L8Runtime.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

@class L8Value;

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
 * @param scriptdata the script
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

- (void)addManagedReference:(id)object withOwner:(id)owner;
- (void)removeManagedReference:(id)object withOwner:(id)owner;

- (void)runGarbageCollector;

@end

@interface L8Runtime (Subscripting)

- (L8Value *)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;

@end