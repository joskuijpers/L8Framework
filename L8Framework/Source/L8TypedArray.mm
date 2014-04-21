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

#import "l8-defs.h"
#import "L8Value_Private.h"
#import "L8TypedArray_Private.h"

#ifdef L8_ENABLE_TYPED_ARRAYS

using namespace v8;

@implementation L8TypedArray

- (instancetype)initWithArrayBuffer:(L8Value *)arrayBuffer
						 byteOffset:(size_t)byteOffset
							 length:(size_t)length
{
	self = [super init];
	if(self) {
		_arrayBuffer = arrayBuffer;
		_byteOffset = byteOffset;
		_length = length;
	}
	return self;
}

- (instancetype)initWithV8Value:(Local<Value>)v8value
{
	L8Value *arrayBuffer;
	Local<TypedArray> typedArray;

	typedArray = v8value.As<TypedArray>();

	return [self initWithArrayBuffer:arrayBuffer
						  byteOffset:typedArray->ByteOffset()
							  length:typedArray->ByteLength()];
}

- (Local<Value>)createV8ValueInIsolate:(Isolate *)isolate
{
	Local<ArrayBufferView> ret;
	Local<ArrayBuffer> arrayBuffer;

	arrayBuffer = ([_arrayBuffer V8Value]).As<ArrayBuffer>();
	ret = DataView::New(arrayBuffer,_byteOffset,_length);

	return ret;
}

- (uint8_t *)mutableBytes
{
	NSData *data;

	data = [_arrayBuffer toData];

	return (uint8_t *)[data bytes] + _byteOffset;
}

@end

#endif
