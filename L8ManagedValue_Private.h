//
//  L8ManagedValue_Private.h
//  Sphere
//
//  Created by Jos Kuijpers on 10/03/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

#import "L8ManagedValue.h"

@interface L8ManagedValue ()

/**
 * Increases the reference count for given owner
 *
 * @param owner the owner
 */
- (void)didAddOwner:(id)owner;

/**
 * Decreases the reference count for given owner
 *
 * @param owner the owner
 */
- (void)didRemoveOwner:(id)owner;

@end
