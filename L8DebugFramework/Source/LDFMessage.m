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

#import "LDFMessage_Private.h"

@implementation LDFMessage

+ (LDFMessage *)messageWithJSONData:(NSData *)data
{
	NSDictionary *object;

	object = [NSJSONSerialization JSONObjectWithData:data
											 options:0
											   error:NULL];

	if([object[@"type"] isEqualToString:@"response"])
		return [[LDFResponseMessage alloc] initWithJSONObject:object];
	else if([object[@"type"] isEqualToString:@"event"])
		return [[LDFEventMessage alloc] initWithJSONObject:object];

	return nil;
}

- (instancetype)initWithJSONObject:(NSDictionary *)object
{
	self = [super init];
	if(self) {
		_seq = object[@"seq"];
	}
	return self;
}

@end

@implementation LDFRequestMessage

- (NSData *)JSONRepresentation
{
	NSDictionary *dict;

	if(self.seq == nil || self.command == nil)
		return nil;

	dict = @{
			 @"seq":self.seq,
			 @"type":@"request",
			 @"command":self.command,
			 @"arguments":(!self.arguments)?@{}:self.arguments
			 };
	return [NSJSONSerialization dataWithJSONObject:dict
										   options:0
											 error:NULL];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<LDFRequestMessage>{seq: %@, command: %@, arguments: %@}",
			self.seq,_command,_arguments];
}

@end

@implementation LDFResponseMessage

- (instancetype)initWithJSONObject:(NSDictionary *)object
{
	self = [super initWithJSONObject:object];
	if(self) {
		_requestSeq = object[@"request_seq"];
		_command = object[@"command"];
		_body = object[@"body"];
		_running = [object[@"running"] boolValue];
		_success = [object[@"success"] boolValue];
		_errorMessage = object[@"message"];
	}
	return self;
}

- (void)setRequest:(LDFRequestMessage *)request
{
	_request = request;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<LDFResponseMessage>{seq: %@, command: %@, body: %@, "
			@"running: %d, success: %d, error message: %@, request: %@",
			self.seq,_command,_body,_running,_success,_errorMessage,_request];
}

@end

@implementation LDFEventMessage

- (instancetype)initWithJSONObject:(NSDictionary *)object
{
	self = [super initWithJSONObject:object];
	if(self) {
		_event = object[@"event"];
		_body = object[@"body"];
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<LDFEventMessage>{seq: %@, event: %@, body: %@}",
			self.seq,_event,_body];
}

@end
