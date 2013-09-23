//
//  L8RuntimeDelegate.h
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol L8RuntimeDelegate <NSObject>

@optional

- (void)runtimeDidFinishCreatingContext:(L8Runtime *)runtime;
- (void)runtimeDidRunMain:(L8Runtime *)runtime;
- (void)runtimeWillRunMain:(L8Runtime *)runtime;

@end
