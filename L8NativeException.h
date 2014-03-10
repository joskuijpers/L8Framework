//
//  L8NativeException.h
//  Sphere
//
//  Created by Jos Kuijpers on 23/02/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

#import "L8Exception.h"

/**
 * @brief A syntax error exception
 */
@interface L8SyntaxErrorException : L8Exception @end

/**
 * @brief A type error exception
 */
@interface L8TypeErrorException : L8Exception @end

/**
 * @brief A reference error exception
 */
@interface L8ReferenceErrorException : L8Exception @end

/**
 * @brief A range error exception
 */
@interface L8RangeErrorException : L8Exception @end