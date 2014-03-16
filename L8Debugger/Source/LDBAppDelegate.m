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

#import "LDBAppDelegate.h"
#import "L8DebugFramework.h"

#import <AppKit/AppKit.h>

@implementation LDBAppDelegate {
	LDFProcess *_remoteProcess;
}

- (instancetype)initWithArguments:(NSArray *)arguments
{
	self = [super init];
	if(self) {
		_arguments = arguments;
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
	_remoteProcess = [[LDFProcess alloc] initWithPort:12345];
	_remoteProcess.delegate = self;

	NSLog(@"Connecting to port %hu...",_remoteProcess.port);
	[_remoteProcess connect];

#if 0
	// WIP: Will be LDBInputHandler, with a -[requestUserInput] to activate STDIN for duration
	// of one input string. ('(l8db) step')
	NSFileHandle *input;
	input = [NSFileHandle fileHandleWithStandardInput];
	[input readInBackgroundAndNotify];

	[[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleReadCompletionNotification
													  object:nil
													   queue:nil
												  usingBlock:^(NSNotification *note) {
													  NSData *data;

													  data = note.userInfo[@"NSFileHandleNotificationDataItem"];
													  NSLog(@"INPUT [%@]",[[NSString alloc] initWithData:data
																								encoding:NSUTF8StringEncoding]);

													  [note.object readInBackgroundAndNotify];
												  }];
#endif
}

- (void)process:(LDFProcess *)process failedToConnect:(NSError *)error
{
	NSLog(@"Failed to connect with error %@",error);
}

- (void)processDidConnect:(LDFProcess *)process
{
	NSLog(@"Process did connect");
}

- (BOOL)process:(LDFProcess *)process shouldHandleMessage:(LDFMessage *)message
{
	NSLog(@"Received message: %@",message);

	return YES;
}

@end
