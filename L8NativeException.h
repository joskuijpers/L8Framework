//
//  L8NativeException.h
//  Sphere
//
//  Created by Jos Kuijpers on 23/02/14.
//  Copyright (c) 2014 Jarvix. All rights reserved.
//

#import "L8Exception.h"

@interface L8SyntaxErrorException : L8Exception @end
@interface L8TypeErrorException : L8Exception @end
@interface L8ReferenceErrorException : L8Exception @end
@interface L8RangeErrorException : L8Exception @end