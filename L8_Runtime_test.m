//
//  SPRAppDelegate.m
//  SphereRuntime
//
//  Created by Jos Kuijpers on 8/27/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

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
