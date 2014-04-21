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
#import "L8ArrayBuffer_Private.h"

#ifdef L8_ENABLE_TYPED_ARRAYS

using namespace v8;

/// Weak callback
static void L8ArrayBufferWeakReferenceCallback(const WeakCallbackData<ArrayBuffer, void>& data);

@interface L8ArrayBuffer ()
{
@public
	// Allow the weak callback to access the persistent store.
	Persistent<ArrayBuffer> _v8value;
}

/// A reference to self, to keep the wrapper alive while JS has it alive too.
@property (strong) L8ArrayBuffer *selfReference;

@end

@implementation L8ArrayBuffer {
	Isolate *_isolate;
}

- (instancetype)initWithV8Value:(Local<Value>)v8value inIsolate:(Isolate *)isolate
{
	self = [super init];
	if L8_LIKELY(self) {
		Local<ArrayBuffer> array;
		ArrayBuffer::Contents contents;

		array = v8value.As<ArrayBuffer>();
		assert(!array->IsExternal());

		_v8value.Reset(isolate, array);
		_isolate = isolate;

		contents = array->Externalize();
		_buffer = contents.Data();
		_length = contents.ByteLength();

		array->SetAlignedPointerInInternalField(0, (__bridge void *)self);

		// Yes, this indeed causes a retain cycle.
		// It also causes this object to stay alive.
		// This ivar is cleared by the Weak callback for the JS object.
		// As long as JS has a reference, so does this object.
		_selfReference = self;
		_v8value.SetWeak((__bridge void *)self, L8ArrayBufferWeakReferenceCallback);
	}
	return self;
}

- (instancetype)initWithData:(NSData *)data
{
	self = [super init];
	if L8_LIKELY(self) {
		Local<ArrayBuffer> array;

		_isolate = Isolate::GetCurrent();

		_length = data.length;
		_buffer = malloc(_length);
		memcpy(_buffer, [data bytes], _length);

		array = ArrayBuffer::New(_isolate, _buffer, _length);
		array->SetAlignedPointerInInternalField(0, (__bridge void *)self);

		_selfReference = self;

		_v8value.Reset(_isolate,array);
		_v8value.SetWeak((__bridge void *)self, L8ArrayBufferWeakReferenceCallback);
	}
	return self;
}

+ (instancetype)arrayBufferWithV8Value:(Local<Value>)v8value inIsolate:(Isolate *)isolate
{
	Local<ArrayBuffer> array;

	array = v8value.As<ArrayBuffer>();
	if(array->IsExternal())
		return (__bridge L8ArrayBuffer *)array->GetAlignedPointerFromInternalField(0);
	return [[L8ArrayBuffer alloc] initWithV8Value:v8value inIsolate:isolate];
}

- (void)dealloc
{
	free(_buffer);
}

- (Local<Value>)V8Value
{
	return Local<ArrayBuffer>::New(_isolate, _v8value);
}

- (NSMutableData *)data
{
	return [NSMutableData dataWithBytesNoCopy:_buffer length:_length freeWhenDone:NO];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<L8ArrayBuffer>(%@)",self.data];
}

@end

static void L8ArrayBufferWeakReferenceCallback(const WeakCallbackData<ArrayBuffer, void>& data)
{
	Local<ArrayBuffer> ext;
	L8ArrayBuffer *arrayBuffer;

	ext = data.GetValue();
	arrayBuffer = (__bridge L8ArrayBuffer *)data.GetParameter();

	arrayBuffer.selfReference = nil;
	arrayBuffer->_v8value.Reset();
}

#endif
