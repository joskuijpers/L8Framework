//
//  L8Runtime.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L8Value;

@interface L8Runtime : NSObject

- (void)executeBlockInRuntime:(void(^)(L8Runtime *runtime))block;

- (BOOL)loadScriptAtPath:(NSString *)filePath;
- (BOOL)loadScript:(NSString *)scriptData withName:(NSString *)name;

- (L8Value *)evaluateScript:(NSString *)scriptData;
- (L8Value *)evaluateScript:(NSString *)scriptData withName:(NSString *)name;

- (L8Value *)globalObject;

+ (L8Runtime *)currentRuntime;
+ (L8Value *)currentThis;
+ (L8Value *)currentCallee;
+ (NSArray *)currentArguments; // L8Value

@end

@interface L8Runtime (Subscripting)

- (L8Value *)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;

@end