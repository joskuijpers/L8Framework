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

#import "NSString+L8.h"
#include "v8.h"

using namespace v8;

class L8ExternalStringResource : public String::ExternalStringResource
{
public:
	NSString *_resource;

	L8ExternalStringResource(NSString *resource) {
		_resource = resource;
	}

	~L8ExternalStringResource() {
		_resource = nil;
	}

	const uint16_t *data() const {
		return (uint16_t *)[_resource cStringUsingEncoding:NSUTF16StringEncoding];
	}

	size_t length() const {
		return [_resource length];
	}

	void Dispose() {
		_resource = nil;
	}
};

@implementation NSString (L8)

+ (NSString *)stringWithV8String:(Local<String>)v8string
{
	char *buffer;
	NSString *ret;

	if(v8string.IsEmpty())
		return nil;

	if(v8string->IsExternal()) {
		L8ExternalStringResource *resource;

		resource = reinterpret_cast<L8ExternalStringResource *>(v8string->GetExternalStringResource());

		return resource->_resource;
	}

	buffer = (char *)malloc(v8string->Length()+1);
	if(buffer == NULL)
		return nil;

	v8string->WriteUtf8(buffer);
	ret = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
	free(buffer);

	return ret;
}

+ (NSString *)stringWithV8Value:(v8::Local<v8::Value>)v8value
{
	return [self stringWithV8Value:v8value inIsolate:NULL];
}

+ (NSString *)stringWithV8Value:(Local<Value>)v8value
						inIsolate:(Isolate *)isolate
{
	if(v8value.IsEmpty())
		return nil;

	if(isolate == NULL)
		// We are allowed to do this, as the only reason we need an isolate
		// is to _temporarily_ convert a Value to a String.
		isolate = Isolate::GetCurrent();

	HandleScope handleScope(isolate);
	Local<String> string = v8value->ToString();

	return [NSString stringWithV8String:string];
}

- (Local<String>)V8StringInIsolate:(Isolate *)isolate
{
	EscapableHandleScope scope(isolate);
	Local<String> ret;

	if(self.length < 128) {
		ret = String::NewFromUtf8(isolate,
								  [self UTF8String],
								  String::NewStringType::kNormalString,
								  (int)[self length]);
	} else {
		L8ExternalStringResource *resource;

		resource = new L8ExternalStringResource(self);

		ret = String::NewExternal(isolate,
								  resource);
	}

	return scope.Escape(ret);
}

@end
