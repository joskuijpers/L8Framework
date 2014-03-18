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

#import "L8VirtualMachine_Private.h"
#import "L8Runtime_Private.h"
#import "L8Value_Private.h"
#import "L8ManagedValue_Private.h"
#import "L8WrapperMap.h"

using namespace v8;

@implementation L8VirtualMachine {
	Isolate *_v8isolate;
	NSMapTable *_managedObjectGraph;
}

+ (void)initialize
{
	V8::SetCaptureStackTraceForUncaughtExceptions(true);
}

- (instancetype)init
{
	self = [super init];
	if(self) {
		_v8isolate = Isolate::New();
		_v8isolate->Enter();

		_managedObjectGraph = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality
														valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality
															capacity:0];

	}
	return self;
}

- (void)dealloc
{
	if(Isolate::GetCurrent() == _v8isolate)
	   _v8isolate->Exit();

	_v8isolate->Dispose();
	_v8isolate = NULL;
}

- (v8::Isolate *)V8Isolate
{
	return _v8isolate;
}

- (id)getInternalObjCObject:(id)object
{
	HandleScope localScope(_v8isolate);

	if([object isKindOfClass:[L8ManagedValue class]]) {
		id temp;
		L8Value *value;

		value = [(L8ManagedValue *)object value];
		temp = unwrapObjCObject(_v8isolate, value.V8Value);

		if(temp)
			return temp;
		return object;
	}

	if([object isKindOfClass:[L8Value class]]) {
		L8Value *value;

		value = (L8Value *)object;
		object = unwrapObjCObject(_v8isolate, value.V8Value);
	}

	return object;
}

- (void)addManagedReference:(id)object withOwner:(id)owner
{
	NSMapTable *objectsOwned;
	const void *key;
	size_t count;

	if([object isKindOfClass:[L8ManagedValue class]])
		[object didAddOwner:owner];

	object = [self getInternalObjCObject:object];
	owner = [self getInternalObjCObject:owner];

	if(object == nil || owner == nil)
		return;

	objectsOwned = [_managedObjectGraph objectForKey:object];
	if(!objectsOwned) {
		objectsOwned = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality
												 valueOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality
													 capacity:1];

		[_managedObjectGraph setObject:objectsOwned forKey:owner];
	}

	key = (__bridge void *)object;
	count = reinterpret_cast<size_t>(NSMapGet(objectsOwned, key));
	NSMapInsert(objectsOwned, key, reinterpret_cast<void *>(count + 1));
}

- (void)removeManagedReference:(id)object withOwner:(id)owner
{
	NSMapTable *objectsOwned;
	const void *key;
	size_t count;

	if([object isKindOfClass:[L8ManagedValue class]])
		[object didRemoveOwner:owner];

	object = [self getInternalObjCObject:object];
	owner = [self getInternalObjCObject:owner];

	if(object == nil || owner == nil)
		return;

	objectsOwned = [_managedObjectGraph objectForKey:object];
	if(!objectsOwned)
		return;

	key = (__bridge void *)object;
	count = reinterpret_cast<size_t>(NSMapGet(objectsOwned, key));
	if(count > 1) {
		NSMapInsert(objectsOwned, key, reinterpret_cast<void *>(count - 1));
		return;
	}

	if(count == 1)
		NSMapRemove(objectsOwned, key);

	if(![objectsOwned count])
		[_managedObjectGraph removeObjectForKey:owner];
}

- (void)runGarbageCollector
{
#ifdef DEBUG
	while(!V8::IdleNotification()) {};
#endif
}

@end
