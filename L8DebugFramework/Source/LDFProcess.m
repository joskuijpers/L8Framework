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

#import "LDFProcess_Private.h"
#import "LDFMessage_Private.h"

@interface LDFProcess () <NSStreamDelegate>
@end

@implementation LDFProcess {
	NSInputStream *_inputStream;
	NSOutputStream *_outputStream;

	/**
	 * Messages sent, waiting for reply. Used for matching
	 * request with response.
	 */
	NSMutableDictionary *_queuedMessages;
	unsigned int _sequenceCounter;
	NSMutableData *_sendQueue;

	NSMutableData *_receiveQueue;
}

- (instancetype)initWithPort:(uint16_t)port
{
	self = [super init];
	if(self) {
		_port = port;

		_queuedMessages = [[NSMutableDictionary alloc] init];
		_sendQueue = [[NSMutableData alloc] init];
		_receiveQueue = [[NSMutableData alloc] init];

		// Start at 1, so 0 can be used as 'undefined'
		_sequenceCounter = 1;
	}
	return self;
}

- (void)dealloc
{
	[self close];
}

- (void)connect
{
	CFReadStreamRef readStreamRef;
	CFWriteStreamRef writeStreamRef;

	CFStreamCreatePairWithSocketToHost(NULL,
									   (__bridge CFStringRef)@"localhost",
									   _port,
									   &readStreamRef,
									   &writeStreamRef);

	if(readStreamRef == NULL || writeStreamRef == NULL) {
		CFRelease(readStreamRef);
		CFRelease(writeStreamRef);

		if([_delegate respondsToSelector:@selector(process:failedToConnect:)]) {
			NSError *error;

			error = [NSError errorWithDomain:@"LDFErrorDomain"
										code:1
									userInfo:@{@"message":@"Failed to open streams."}];
			[_delegate process:self failedToConnect:error];
		}

		return;
	}

	_inputStream = (__bridge NSInputStream *)readStreamRef;
	_outputStream = (__bridge NSOutputStream *)writeStreamRef;

	_inputStream.delegate = self;
	_outputStream.delegate = self;

	[_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
							forMode:NSDefaultRunLoopMode];
	[_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
							 forMode:NSDefaultRunLoopMode];

	[_inputStream open];
	[_outputStream open];
}

- (void)close
{
	[_inputStream close];
	[_outputStream close];

	_inputStream = nil;
	_outputStream = nil;
}

- (BOOL)sendMessage:(LDFRequestMessage *)message
{
	NSData *json;
	NSMutableData *messageData;
	NSString *header;

	if(message.seq != 0)
		return NO;

	message.seq = @(_sequenceCounter++);
	_queuedMessages[message.seq] = message;

	json = [message JSONRepresentation];

	messageData = [[NSMutableData alloc] init];
	header = [NSString stringWithFormat:@"Content-Length: %lu\r\n\r\n",json.length];
	[messageData appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
	[messageData appendData:json];

	[_sendQueue appendData:messageData];

	if([_outputStream hasSpaceAvailable]) {
		NSInteger sent;

		sent = [_outputStream write:_sendQueue.bytes maxLength:_sendQueue.length];
		if(sent > 0)
			[_sendQueue replaceBytesInRange:NSMakeRange(0, sent)
								  withBytes:NULL
									 length:0];
	}

	return YES;
}

- (NSDictionary *)readMessageHeaderLength:(NSUInteger *)length
{
	NSMutableDictionary *header;
	NSData *newLine;
	BOOL stop = NO;
	NSUInteger seekPosition = 0;

	newLine = [NSData dataWithBytes:"\r\n" length:2];

	header = [NSMutableDictionary dictionary];
	while(!stop) {
		NSUInteger newlinePos;
		NSRange searchRange;

		searchRange = NSMakeRange(seekPosition, _receiveQueue.length - seekPosition);
		newlinePos = [_receiveQueue rangeOfData:newLine
										options:0
										  range:searchRange].location;

		if(newlinePos == NSNotFound) {
			return nil;
		}

		if(newlinePos == seekPosition)
			stop = YES;
		else {
			NSData *headerLineData;
			NSString *headerLine;
			NSArray *components;
			NSString *key, *value;

			headerLineData = [_receiveQueue subdataWithRange:NSMakeRange(seekPosition, newlinePos-seekPosition)];
			headerLine = [[NSString alloc] initWithData:headerLineData
											   encoding:NSUTF8StringEncoding];

			components = [headerLine componentsSeparatedByString:@":"];

			key = [components[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			value = [components[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			header[key] = value;
		}

		seekPosition = newlinePos+2;
	}

	*length = seekPosition;

	return header;
}

- (void)parseIncomingMessages
{
	while(_receiveQueue.length > 0) {
		NSDictionary *header;
		NSUInteger contentLength;
		NSUInteger headerLength;

		header = [self readMessageHeaderLength:&headerLength];

		if([header[@"Type"] isEqualToString:@"connect"]) {
			_v8Version = header[@"V8-Version"];
			_embeddingHost = header[@"Embedding-Host"];
			_protocolVersion = header[@"Protocol-Version"];

			[_receiveQueue replaceBytesInRange:NSMakeRange(0, headerLength)
									 withBytes:NULL
										length:0];

			LDFRequestMessage *req = [[LDFRequestMessage alloc] init];
			req.command = @"evaluate";
			req.arguments = @{@"expression":@"debugger",@"global":@YES,@"disable_break":@NO};
			[self sendMessage:req];

			return;
		}

		contentLength = [header[@"Content-Length"] integerValue];

		if(contentLength + headerLength <= _receiveQueue.length) {
			NSData *content;
			LDFMessage *message;
			BOOL handleMessage = YES;

			content = [_receiveQueue subdataWithRange:NSMakeRange(headerLength, contentLength)];

			message = [LDFMessage messageWithJSONData:content];

			if([message isKindOfClass:[LDFResponseMessage class]]) {
				LDFResponseMessage *respMessage;

				respMessage = (LDFResponseMessage *)message;
				respMessage.request = _queuedMessages[respMessage.requestSeq];
				if(respMessage.requestSeq)
					[_queuedMessages removeObjectForKey:respMessage.requestSeq];

			}

			[_receiveQueue replaceBytesInRange:NSMakeRange(0, contentLength + headerLength)
									 withBytes:NULL
										length:0];

			if([_delegate respondsToSelector:@selector(process:shouldHandleMessage:)])
				handleMessage = [_delegate process:self shouldHandleMessage:message];

			if(handleMessage) {
				// TODO Handle message
			}
		} else
			return;
	}
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventNone:
			break;
		case NSStreamEventOpenCompleted:
			if([_delegate respondsToSelector:@selector(processDidConnect:)])
				[_delegate processDidConnect:self];
			break;
		case NSStreamEventHasBytesAvailable: {
			uint8_t buffer[512];
			NSUInteger size;

			size = [_inputStream read:buffer maxLength:512];
			[_receiveQueue appendBytes:buffer length:size];

			dispatch_async(dispatch_get_main_queue(), ^{
				[self parseIncomingMessages];
			});
		}
			break;
		case NSStreamEventHasSpaceAvailable: {
			NSInteger sent;

			if(_sendQueue.length == 0)
				break;

			sent = [_outputStream write:_sendQueue.bytes maxLength:_sendQueue.length];
			if(sent < 0) {
				NSLog(@"Failed to send");
				break;
			}

			[_sendQueue replaceBytesInRange:NSMakeRange(0, sent)
								  withBytes:NULL
									 length:0];
		}
			break;
		case NSStreamEventErrorOccurred: {
			NSError *streamError, *error;

			streamError = aStream.streamError;

			if(streamError.code == 61) // Connection refused
				error = [NSError errorWithDomain:@"LDFErrorDomain"
											code:2
										userInfo:@{@"message":@"Connection refused."}];

			if(error && [_delegate respondsToSelector:@selector(process:failedToConnect:)])
				[_delegate process:self failedToConnect:error];
			else {
				NSLog(@"Stream Error %@",streamError);
			}
		}
			break;
		case NSStreamEventEndEncountered: {

			if(aStream == _inputStream) {
				NSLog(@"[LDFProcess] EOS (remote process quit)");
			} else {
				NSLog(@"[LDFProcess] EOS (sent too much)");
			}
		}
			break;
	}
}

@end
