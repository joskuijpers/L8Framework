//
//  L8Runtime.h
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L8Value;
@protocol L8RuntimeDelegate;

@interface L8Runtime : NSObject

@property (weak) id<L8RuntimeDelegate> delegate;

- (void)start;

- (BOOL)loadScriptAtPath:(NSString *)filePath;
- (BOOL)loadScript:(NSString *)scriptData withName:(NSString *)name;
- (L8Value *)evaluateScript:(NSString *)scriptData withName:(NSString *)name;

- (L8Value *)globalObject;

+ (L8Runtime *)currentRuntime;
+ (L8Value *)currentThis;
+ (NSArray *)currentArguments; // L8Value

- (L8Value *)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;

@end
