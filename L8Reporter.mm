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

#import "L8Reporter_Private.h"
#import "NSString+L8.h"
#import "L8StackTrace_Private.h"
#import "L8Exception_Private.h"
#import "L8Value_Private.h"
#import "L8NativeException.h"

#include "v8.h"

static L8Reporter *g_sharedReporter = nil;

@implementation L8Reporter

+ (L8Reporter *)sharedReporter
{
	if(g_sharedReporter == nil) {
		@synchronized(self) {
			if(g_sharedReporter == nil)
				g_sharedReporter = [[L8Reporter alloc] init];
		}
	}
	return g_sharedReporter;
}

- (instancetype)init
{
	self = [super init];
	if(self) {
		self.exceptionHandler = ^(L8Exception *ex) {
			[L8Reporter printException:ex];
		};
	}
	return self;
}

+ (void)reportTryCatch:(v8::TryCatch *)tryCatch inIsolate:(v8::Isolate *)isolate
{
	L8Exception *exception;

	exception = [self objcExceptionForTryCatch:tryCatch
									 inIsolate:isolate];

	[[self sharedReporter] exceptionHandler](exception);
}

+ (L8Exception *)objcExceptionForTryCatch:(v8::TryCatch *)tryCatch inIsolate:(v8::Isolate *)isolate
{
	if(!tryCatch->HasCaught())
		return nil;

	v8::HandleScope localScope(isolate);
	L8Exception *exception;
	id ball;
	Class exceptionClass = [L8Exception class];

	@try {
		NSRange strRange;

		ball = [L8Value valueWithV8Value:tryCatch->Exception()];

		// If the exception is a JS native error, find the specific type
		if([(L8Value *)ball isNativeError]) {

			// Is some internal v8 object. Only thing we can do is make it a string
			v8::String::AsciiValue excStr(tryCatch->Exception());
			ball = [NSString stringWithV8String:v8::String::New(*excStr)];

			// Find prefix
			if((strRange = [ball rangeOfString:@"SyntaxError: "]).location != NSNotFound)
				exceptionClass = [L8SyntaxErrorException class];
			else if((strRange = [ball rangeOfString:@"TypeError: "]).location != NSNotFound)
				exceptionClass = [L8TypeErrorException class];

			// Remove prefix
			if(strRange.location != NSNotFound) {
				ball = [ball stringByReplacingCharactersInRange:strRange
													 withString:@""];
			}
		}
	} @catch (L8Exception *ex) {
		ball = @"<l8:Not available>";
	}

	// Make an objc exception
	exception = [exceptionClass exceptionWithV8Message:tryCatch->Message()
									thrownObject:ball];

	return exception;
}

+ (void)printException:(L8Exception *)exception
{
	NSLog(@"%@:%d:%d-%d: %@",
		  exception.resourceName,
		  exception.lineNumber,
		  exception.startColumn,
		  exception.endColumn,
		  exception.message);

	printf("%s\n",[exception.sourceLine UTF8String]);

	int i;
	for(i = 0; i < exception.startColumn; i++)
		printf(" ");
	for(; i < exception.endColumn; i++)
		printf("~");
	printf("\n");
}

@end
