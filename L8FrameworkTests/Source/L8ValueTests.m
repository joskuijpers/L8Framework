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
#import "L8Context.h"
#import "L8Value.h"
#import "L8Export.h"

@interface L8ValueTests : XCTestCase @end
@interface CustomSimpleObject : NSObject @end

@protocol CustomMethodClass <L8Export>
- (void)simpleMethod;
- (int)methodReturningInteger;
- (id)methodReturningId;
- (void)methodWithStringArgument:(NSString *)argument;
@end
@interface CustomMethodClass : NSObject <CustomMethodClass> @end

@protocol CustomPropertiesClass <L8Export>
@property NSString *stringVal;
@property double doubleVal;
@end
@interface CustomPropertiesClass : NSObject <CustomPropertiesClass> @end

@protocol CustomPropertiesClassWithAttributes <L8Export>
@property (strong,readonly) NSString *stringVal;
@property (assign,getter=isHidden) BOOL hidden;
@property (strong,setter=setMaker:,getter=seeMaker) NSString *maker;
@property (strong,setter=oddSetter:) NSString *oddities;
@end
@interface CustomPropertiesClassWithAttributes : NSObject <CustomPropertiesClassWithAttributes> @end

@interface CustomClass : NSObject
@end

@protocol InnerClass <L8Export>
@end
@interface InnerClass : NSObject <InnerClass>
@end

@protocol InnerClassProfile <L8Export>
@property (readonly) NSString *someString;
@end

@interface InnerClassProfile : NSObject <InnerClassProfile>
@end


@implementation L8ValueTests

- (void)testStringValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithObject:@"Hello World" inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:]");
			XCTAssertEqualObjects([value toObject], @"Hello World", "-[toObject]");
			XCTAssertEqualObjects([value toString], @"Hello World", "-[toString]");
			XCTAssertTrue([value isString], "-[isString]");


			context[@"string"] = @"Hello World";
			XCTAssertEqualObjects([context[@"string"] toString], @"Hello World", "Value from object");

			L8Value *retVal = [context evaluateScript:@"string" withName:@"test.js"];
			XCTAssertEqualObjects([retVal toString], @"Hello World", "Global string assignment script result");
		}];
	}
}

- (void)testBooleanValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithBool:YES inContext:context];

			XCTAssertNotNil(value, "-[valueWithBool:]");
			XCTAssertEqual([value toBool], YES, "-[toBool]");
			XCTAssertEqualObjects([value toObject], @YES, "-[toObject]");
			XCTAssertTrue([value isBoolean], "-[isBool]");

			XCTAssertEqual([value toBool],
						   [[L8Value valueWithObject:@YES inContext:context] toBool],
						   "-[valueWithObject:]");
		}];
	}
}

- (void)testNullValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithNullInContext:context];

			XCTAssertNotNil(value, "-[valueWithNull]");
			XCTAssertEqualObjects([value toObject], [NSNull null], "-[toObject]");
			XCTAssertTrue([value isNull], "-[isNull]");

			XCTAssertEqualObjects([value toObject],
								  [[L8Value valueWithObject:[NSNull null] inContext:context] toObject],
								  "-[valueWithObject:]");
		}];
	}
}

- (void)testUndefinedValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithUndefinedInContext:context];

			XCTAssertNotNil(value, "-[valueWithUndefined]");
			XCTAssertNil([value toObject], "-[toObject]");
			XCTAssertTrue([value isUndefined], "-[isUndefined]");

			XCTAssertNil([[L8Value valueWithObject:nil inContext:context] toObject],
						 "-[[valueWithObject:nil] toObject]");

			XCTAssertEqualObjects([value toObject],
								  [[L8Value valueWithObject:nil inContext:context] toObject],
								  "-[valueWithObject:]");
		}];
	}
}

- (void)testDateValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			NSDate *date = [NSDate date];
			L8Value *value = [L8Value valueWithObject:date inContext:context];

			XCTAssertNotNil(value, "-[valuewithObject:]");
			XCTAssertEqual((long long)[value toDouble],(long long)[date timeIntervalSince1970],"-[toDouble]");
			XCTAssertNotNil([value toObject], "-[toObject]");
			XCTAssertTrue([value isObject], "-[isObject]");
		}];
	}
}

- (void)testDoubleValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithDouble:5.0 inContext:context];

			XCTAssertNotNil(value, "-[valueWithDouble:]");
			XCTAssertEqualObjects([value toNumber], @5.0, "-[toNumber]");
			XCTAssertEqualObjects([value toObject], @5.0, "-[toObject]");
			XCTAssertTrue([value isNumber], "-[isNumber]");

			XCTAssertEqualObjects([value toNumber],
								  [[L8Value valueWithObject:@5.0 inContext:context] toNumber],
								  "-[valueWithObject:]");
		}];
	}
}

- (void)testArrayValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithObject:@[@"a",@"b"] inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:(NSArray)]");
			XCTAssertEqualObjects([value toArray], (@[@"a",@"b"]), "-[toArray]");
			XCTAssertEqualObjects([value toObject], (@[@"a",@"b"]), "-[toObject]");
			XCTAssertTrue([value isObject], "-[isObject]");

			value = [L8Value valueWithNewArrayInContext:context];
			XCTAssertNotNil(value, "-[valueWithNewArray]");
			XCTAssertEqualObjects([value toArray], @[], "-[toArray] (newArray)");
			XCTAssertEqualObjects([value toObject], @[], "-[toObject] (newArray)");
			XCTAssertTrue([value isObject], "-[isObject] (newArray)");
		}];
	}
}

- (void)testDictionaryValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithObject:@{@"a":@"1",@"b":@2} inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:(NSDictionary)]");
			XCTAssertEqualObjects([value toDictionary], (@{@"a":@"1",@"b":@2}), "-[toArray]");
			XCTAssertEqualObjects([value toObject], (@{@"a":@"1",@"b":@2}), "-[toObject]");
			XCTAssertTrue([value isObject], "-[isObject]");
		}];
	}
}

- (void)testObjectValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithNewObjectInContext:context];

			XCTAssertNotNil(value, "-[valueWithNewObject]");
			XCTAssertNotNil([value toObject], "-[toObject]");

			XCTAssertTrue([value isObject], "-[isObject]");
		}];
	}
}

- (void)testCustomClassValue
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			id object = [[CustomSimpleObject alloc] init];
			L8Value *value = [L8Value valueWithObject:object inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:(Custom)]");
			XCTAssertEqual([value toObject], object, "-[toObject]");
			XCTAssertTrue([value isObject], "-[isObject]");
		}];
	}
}

- (void)testProperties
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithNewObjectInContext:context];

			XCTAssertNotNil(value, "-[valueWithNewObject]");

			[value setValue:@"Hello World" forProperty:@"key"];
			XCTAssertNotNil([value valueForProperty:@"key"],"-[setValue:forProperty:]");
			XCTAssertEqualObjects([[value valueForProperty:@"key"] toString], @"Hello World", "-[valueForProperty:]");
			XCTAssertTrue([value hasProperty:@"key"], "-[hasProperty]");

			context[@"object"] = value;
			L8Value *returnValue = [context evaluateScript:@"object.key" withName:@""];
			XCTAssertEqualObjects([returnValue toString], @"Hello World", "getting value in JavaScript");

			XCTAssertEqualObjects([value toDictionary], (@{@"key":@"Hello World"}), "-[toDictionary] (Object conversion)");

			[value deleteProperty:@"key"];
			XCTAssertFalse([value hasProperty:@"key"], "-[deleteProperty:]");
		}];
	}
}

- (void)testKeyedProperties
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithNewObjectInContext:context];

			XCTAssertNotNil(value, "-[valueWithNewObject]");

			value[@"key"] = @"Hello World";
			XCTAssertNotNil(value[@"key"],"-[setObject:forKeyedSubscript:]");
			XCTAssertEqualObjects([value[@"key"] toString], @"Hello World", "-[objectForKeyedSubscript:]");
			XCTAssertTrue([value hasProperty:@"key"], "-[hasProperty]");
		}];
	}
}

- (void)testIndexedProperties
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value = [L8Value valueWithNewArrayInContext:context];

			XCTAssertNotNil(value, "-[valueWithNewArray]");

			value[0] = @"Hello World";
			XCTAssertNotNil(value[0],"-[setObject:forIndexedSubscript:]");
			XCTAssertEqualObjects([value[0] toString], @"Hello World", "-[objectForIndexedSubscript:]");
			XCTAssertTrue([value hasProperty:@"0"], "-[hasProperty]");

			context[@"object"] = value;
			L8Value *returnValue = [context evaluateScript:@"object" withName:@""];
			XCTAssertEqualObjects([returnValue toArray], @[@"Hello World"], "getting value in JavaScript and conversion to NSArray");

			[value deleteProperty:@"0"];
			XCTAssertFalse([value hasProperty:@"0"], "-[deleteProperty:]");
		}];
	}
}

- (void)testCustomObjectWithMethods
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *retVal;
			CustomMethodClass *object = [[CustomMethodClass alloc] init];
			L8Value *value = [L8Value valueWithObject:object inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:(CustomMethodClass)]");

			retVal = [value invokeMethod:@"simpleMethod" withArguments:@[]];
			XCTAssertTrue([retVal isUndefined], "-[invokeMethod:(void returning) withArguments:@[]], returns Undefined");

			retVal = [value invokeMethod:@"methodReturningInteger" withArguments:@[]];
			XCTAssertTrue([retVal isNumber], "-[isNumber]");

			XCTAssertEqualObjects([retVal toNumber], @42, "-[invokeMethod:(int returning) withArguments:@[]]");
			XCTAssertTrue([retVal isNumber], "-[retVal isNumber]");
		}];
	}
}

- (void)testCustomObjectWithProperties
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *retVal;
			CustomPropertiesClass *object = [[CustomPropertiesClass alloc] init];
			object.stringVal = @"Hello World";

			L8Value *value = [L8Value valueWithObject:object inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:(CustomPropertiesClass)]");

			context[@"object"] = object;
			retVal = [context evaluateScript:@"object.stringVal" withName:@""];
			XCTAssertEqualObjects([retVal toString], @"Hello World", "Property getting in JavaScript");

			[context evaluateScript:@"object.stringVal = 'John';" withName:@""];
			XCTAssertEqualObjects(object.stringVal, @"John", "Property setting in JavaScript");

			retVal = [context evaluateScript:@"object.notThere" withName:@""];
			XCTAssertTrue([retVal isUndefined], "Invalid property getting in JavaScript");
		}];
	}
}

- (void)testCustomObjectWithAttributedProperties
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *value;
			CustomPropertiesClassWithAttributes *object;

			object = [[CustomPropertiesClassWithAttributes alloc] init];
			value = [L8Value valueWithObject:object inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:(CustomPropertiesClassWithAttributes)]");

			XCTAssertEqual([value[@"hidden"] toBool], YES, "Boolean readonly property existence");
			XCTAssertEqualObjects([value[@"stringVal"] toString], @"String", "NSString readonly property existence");
			XCTAssertEqualObjects([value[@"maker"] toString], @"The Architect", "NSString renamed getter existence");
			XCTAssertEqualObjects([value[@"oddities"] toString], @"Bowie", "Property with renamed setter existence");

			value[@"oddities"] = @"David";
			XCTAssertEqualObjects([value[@"oddities"] toString], @"David", "Renamed setter workins");

			value[@"stringVal"] = @"Number";
			XCTAssertEqualObjects([value[@"stringVal"] toString], @"String", "Setter should not work when readonly");
		}];
	}
}

- (void)testCustomJSFunction
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			Class cls = [CustomClass class];
			L8Value *value = [L8Value valueWithObject:cls inContext:context];

			XCTAssertNotNil(value, "-[valueWithObject:(Class)]");
		}];
	}
}

- (void)testInnerClass
{
	@autoreleasepool {
		[[[L8Context alloc] init] executeBlockInContext:^(L8Context *context) {
			L8Value *innerClass, *obj;

			context[@"MyClass"] = [InnerClass class];
			context[@"MyClass"][@"Profile"] = [InnerClassProfile class];

			innerClass = [context evaluateScript:@"MyClass.Profile"];
			obj = [innerClass constructWithArguments:@[]];

			XCTAssertEqualObjects([obj[@"someString"] toString], @"CORRECT", "Value is correct");
		}];
	}
}

@end

@implementation CustomSimpleObject @end

@implementation CustomMethodClass
- (void)simpleMethod{}
- (int)methodReturningInteger{return 42;}
- (id)methodReturningId{return nil;}
- (void)methodWithStringArgument:(NSString *)argument {}
@end

@implementation CustomPropertiesClass
@synthesize stringVal, doubleVal;
@end

@implementation CustomClass
@end

@implementation CustomPropertiesClassWithAttributes
@synthesize stringVal=_stringVal,hidden=_hidden,maker=_maker,oddities=_oddities;

- (id)init
{
    self = [super init];
    if (self) {
        _maker = @"The Architect";
		_stringVal = @"String";
		_hidden = YES;
		_oddities = @"Bowie";
    }
    return self;
}
@end

@implementation InnerClass

+ (Class)profileClass
{
	return [InnerClassProfile class];
}

@end

@implementation InnerClassProfile

- (NSString *)someString
{
	return @"CORRECT";
}

@end