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

#import <XCTest/XCTest.h>
#import "L8.h"

@interface L8ClassTests : XCTestCase
@end

// Exports for the superclass
@protocol SuperClassA <L8Export>
- (void)testSuper;
@end

// The superclass
@interface SuperClassA : NSObject <SuperClassA>
@end

// Exports for the subclass
@protocol SubClassA <L8Export>
- (void)testSub;
@end

// The subclass
@interface SubClassA : SuperClassA <SubClassA>
@end

@implementation L8ClassTests

- (void)testInheritance
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			context[@"a"] = [[SuperClassA alloc] init];
			context[@"b"] = [[SubClassA alloc] init];

			// Make sure the classes respond to their own methods
			XCTAssertNoThrow([context[@"a"] invokeMethod:@"testSuper" withArguments:@[]],"class must have own methods");
			XCTAssertNoThrow([context[@"b"] invokeMethod:@"testSub" withArguments:@[]],"class must have own methods");

			// Make sure the subclass responds to the superclass (L8Export up)
			XCTAssertNoThrow([context[@"b"] invokeMethod:@"testSuper" withArguments:@[]],"subclass must inherit from superclass");
		}];
	}
}

@end

@implementation SuperClassA
- (void)testSuper{}
@end

@implementation SubClassA
- (void)testSub {}
@end