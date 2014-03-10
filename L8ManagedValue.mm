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

#import "L8ManagedValue.h"
#import "L8Value_Private.h"
#import "L8Runtime_Private.h"

#include "v8.h"

static void L8ManagedValueWeakReferenceCallback(const v8::WeakCallbackData<v8::Value, void>& data);

@interface L8ManagedValue (Private)
- (void)removeValue;
@end

@implementation L8ManagedValue {
	v8::Persistent<v8::Value> _persist;
	NSMapTable *_owners;
}

+ (L8ManagedValue *)managedValueWithValue:(L8Value *)value
{
	return [[self alloc] initWithValue:value];
}

+ (L8ManagedValue *)managedValueWithValue:(L8Value *)value andOwner:(id)owner
{
	L8ManagedValue *mValue;

	mValue = [[self alloc] initWithValue:value];
	[[L8Runtime currentRuntime] addManagedReference:mValue withOwner:owner];

	return mValue;
}

- (instancetype)init
{
	return [self initWithValue:nil];
}

- (instancetype)initWithValue:(L8Value *)value
{
	self = [super init];
	if(self) {
		if(!value)
			return self;

		_owners = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality
											valueOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality
												capacity:1];

		_persist.Reset(v8::Isolate::GetCurrent(), [value V8Value]);
		void *p = (__bridge void *)self;
		_persist.SetWeak(p, L8ManagedValueWeakReferenceCallback);
	}
	return self;
}

- (void)dealloc
{
	v8::Isolate *isolate;
	L8Runtime *runtime;

	isolate = v8::Isolate::GetCurrent();
	runtime = [L8Runtime currentRuntime];

	if(isolate != NULL) {
		NSMapTable *owners = [_owners copy];
		for(id owner in owners) {
			const void *key;
			size_t count;

			key = (__bridge void *)owner;
			count = reinterpret_cast<size_t>(NSMapGet(_owners, key));

			while(count--)
				[runtime removeManagedReference:self withOwner:owner];
		}
	}

	[self removeValue];
}

- (void)didAddOwner:(id)owner
{
	const void *key = (__bridge void *)owner;
	size_t count = reinterpret_cast<size_t>(NSMapGet(_owners, key));
	NSMapInsert(_owners, key, reinterpret_cast<void *>(count + 1));
}

- (void)didRemoveOwner:(id)owner
{
	const void *key = (__bridge void *)owner;
	size_t count = reinterpret_cast<size_t>(NSMapGet(_owners, key));

	if(count == 0)
		return;

	if(count == 1) {
		NSMapRemove(_owners, key);
		return;
	}

	NSMapInsert(_owners, key, reinterpret_cast<void *>(count - 1));
}

- (L8Value *)value
{
	v8::Local<v8::Value> v;

	if(_persist.IsEmpty())
		return nil;

	v = v8::Local<v8::Value>::New(v8::Isolate::GetCurrent(), _persist);

	return [L8Value valueWithV8Value:v];
}

- (void)removeValue
{
	_persist.Clear();
}

@end

static void L8ManagedValueWeakReferenceCallback(const v8::WeakCallbackData<v8::Value, void>& data)
{
	v8::Local<v8::Value> ext;
	L8ManagedValue *managedValue;

	ext = data.GetValue();
	managedValue = (__bridge L8ManagedValue *)data.GetParameter();

	[managedValue removeValue];
}