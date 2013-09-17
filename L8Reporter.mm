//
//  L8Reporter.m
//  V8Test
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import "L8Reporter_Private.h"
#import "NSString+L8.h"

#include "v8.h"

static L8Reporter *g_sharedReporter = nil;

@implementation L8Reporter

+ (L8Reporter *)sharedReporter
{
	if(g_sharedReporter == nil)
		g_sharedReporter = [[L8Reporter alloc] init];
	return g_sharedReporter;
}

- (void)reportTryCatch:(v8::TryCatch *)tryCatch inIsolate:(v8::Isolate *)isolate
{
	if(!tryCatch->HasCaught())
		return;

	v8::HandleScope localScope(isolate);
	v8::Local<v8::Message> message = tryCatch->Message();

	int line = tryCatch->Message()->GetLineNumber();
	NSLog(@"%@:%d:%d-%d: %@",
		  [NSString stringWithV8Value:message->GetScriptResourceName()],
		  line,
		  message->GetStartColumn(),
		  message->GetEndColumn(),
		  [NSString stringWithV8Value:tryCatch->Exception()]);

	printf("%s\n",[[NSString stringWithV8String:message->GetSourceLine()] UTF8String]);
	int i;
	for(i = 0; i < message->GetStartColumn(); i++)
		printf(" ");
	for(; i < message->GetEndColumn(); i++)
		printf("~");
	printf("\n");

	v8::Handle<v8::StackTrace> trace = message->GetStackTrace();
	if(!trace.IsEmpty()) {
		for(int i = 0; i < trace->GetFrameCount(); i++) {
			v8::Local<v8::StackFrame> frame = trace->GetFrame(i);
			NSLog(@"%@ at %@:%d:%d",
				  [NSString stringWithV8String:frame->GetFunctionName()],
				  [NSString stringWithV8String:frame->GetScriptName()],frame->GetLineNumber(),frame->GetColumn());
		}
	}
}

@end
