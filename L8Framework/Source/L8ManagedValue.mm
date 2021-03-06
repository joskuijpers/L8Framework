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

#import "L8ManagedValue.h"
#import "L8Value_Private.h"
#import "L8Context_Private.h"
#import "L8VirtualMachine_Private.h"

#include "v8.h"

using namespace v8;

static void L8ManagedValueWeakReferenceCallback(const WeakCallbackData<Value, void>& data);

@interface L8ManagedValue (Private)
- (void)removeValue;
@end

@implementation L8ManagedValue {
	Persistent<Value> _persist;
	NSMapTable *_owners;
	L8Context *_context;
}

+ (instancetype)managedValueWithValue:(L8Value *)value
{
	return [[self alloc] initWithValue:value];
}

+ (instancetype)managedValueWithValue:(L8Value *)value andOwner:(id)owner
{
	L8ManagedValue *mValue;

	mValue = [[self alloc] initWithValue:value];
	[value.context.virtualMachine addManagedReference:mValue withOwner:owner];

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

		_context = value.context;

		_owners = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality
											valueOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality
												capacity:1];

		_persist.Reset(_context.virtualMachine.V8Isolate, value.V8Value);
		void *p = (__bridge void *)self;
		_persist.SetWeak(p, L8ManagedValueWeakReferenceCallback);
	}
	return self;
}

- (void)dealloc
{
	if(Isolate::GetCurrent() != NULL) {
		NSMapTable *owners = [_owners copy];
		for(id owner in owners) {
			const void *key;
			size_t count;

			key = (__bridge void *)owner;
			count = reinterpret_cast<size_t>(NSMapGet(_owners, key));

			while(count--)
				[_context.virtualMachine removeManagedReference:self withOwner:owner];
		}
	}

	[self removeValue];
}

- (void)didAddOwner:(id)owner
{
	const void *key = (__bridge void *)owner;
	size_t count = (size_t)NSMapGet(_owners, key);
	NSMapInsert(_owners, key, (void *)(count + 1));
}

- (void)didRemoveOwner:(id)owner
{
	const void *key = (__bridge void *)owner;
	size_t count = (size_t)NSMapGet(_owners, key);

	if(count == 0)
		return;

	if(count == 1) {
		NSMapRemove(_owners, key);
		return;
	}

	NSMapInsert(_owners, key, (void *)(count - 1));
}

- (L8Value *)value
{
	Isolate *isolate = _context.virtualMachine.V8Isolate;
	Context::Scope contextScope(_context.V8Context);
	EscapableHandleScope localScope(isolate);
	Local<Value> v;

	if(_persist.IsEmpty())
		return nil;

	v = Local<Value>::New(isolate, _persist);

	return [L8Value valueWithV8Value:localScope.Escape(v) inContext:_context];
}

- (void)removeValue
{
	_persist.ClearAndLeak();
}

@end

static void L8ManagedValueWeakReferenceCallback(const WeakCallbackData<Value, void>& data)
{
	Local<Value> ext;
	L8ManagedValue *managedValue;

	ext = data.GetValue();
	managedValue = (__bridge L8ManagedValue *)data.GetParameter();

	[managedValue removeValue];
}