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

#if 0

#import "SPRAppDelegate.h"
#import "L8.h"

@protocol Console <L8Export>
- (void)log:(NSString *)text;
@end

@interface Console : NSObject <Console>
@end

@implementation Console

- (void)log:(NSString *)text
{
	NSLog(@"JS: %@",text);
}

@end

@implementation SPRAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	L8Runtime *runtime = [[L8Runtime alloc] init];

	//	runtime.debuggerPort = 12345;
	//	runtime.waitForDebugger = NO;
	//	[runtime enableDebugging];

	[runtime executeBlockInRuntime:^(L8Runtime *runtime) {

		Console *console = [[Console alloc] init];
		runtime[@"Console"] = [Console class];
		runtime[@"console"] = console;

		runtime[@"gameTick"] = ^() {
			[[L8Runtime currentRuntime] loadScript:@"console.log('TICK!');" withName:@"test.js"];
		};

		runtime[@"sleep"] = ^(int time) {
			sleep(time);
		};
	}];

	[[NSRunLoop currentRunLoop] addTimer:[[NSTimer alloc] initWithFireDate:[NSDate date]
																  interval:5
																	target:self
																  selector:@selector(fire:)
																  userInfo:runtime
																   repeats:YES]
								 forMode:NSDefaultRunLoopMode];
}

- (void)fire:(NSTimer *)timer
{
	L8Runtime *runtime = timer.userInfo;

	@try {
		[runtime executeBlockInRuntime:^(L8Runtime *runtime) {
			[runtime evaluateScript:@"try { gameTick(); } catch(e) { console.log('Caught '+e); }"
						   withName:@""];
			//			[runtime.globalObject invokeMethod:@"gameTick" withArguments:nil];
			//			[runtime[@"console"] invokeMethod:@"log" withArguments:@[@"TICK"]];
		}];
	} @catch (L8Exception *e) {
		NSLog(@"Caught %@ in fire:",e);
	}


}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

@end

#endif
