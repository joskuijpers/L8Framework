L8Framework
===========
A framework wrapping V8 into Objective-C.

Nearly compatible with the JavaScriptCore Objective-C API by Apple Inc.

## Building L8Framework ##

To build L8Framework, only a couple of simple steps are required:

First, clone the repository and load the submodules:
```sh
$ git clone https://github.com/joskuijpers/L8Framework.git
$ cd L8Framework
$ git submodule init
$ git submodule update
```

Then run the v8_build script, to download v8 dependencies, configure
and patch the build system, and to build v8:
```sh
$ ./v8_build.sh
```

Then either open the Xcode project and build, or use:
```sh
$ xcodebuild
```

## Examples ##

A simple 2+2 program:
```objc
L8Runtime *runtime = [[L8Runtime alloc] init];
L8Value *value = [runtime evaluateScript:@"2+2"];

// The -description of an L8Value is the same as value.toString()
// in JavaScript.
NSLog(@"2+2 = %@",value);

// You can also convert to an NSNumber and take the integer value.
NSLog(@"2+2 = %ld",[[value toNumber] integerValue]);
```

A hello world program using an Objective-C console class. V8 does not supply
a console natively.
```objc
// The protocol, inheriting from L8Export, tells the L8Framework
// what properties and methods to export to JavaScript.
@protocol MyConsole <L8Export>
- (void)log:(NSString *)message;
@end

@interface MyConsole : NSObject <MyConsole>
@end

@implementation MyConsole

// The L8Framework will convert any input type to the requested class:
// here that is an NSString. So even if console.log(5) is ran, you will
// receive @"5".
// To request the 'raw' arguments, all of them, you can run
// [L8Runtime currentArguments]. This works just like the this.arguments
// in JavaScript.
- (void)log:(NSString *)message
{
	NSLog(@"[JS] %@",message);
}

@end

L8Runtime *runtime = [[L8Runtime alloc] init];

// Because of the way V8 works with scoped memory management,
// and because of how Cocoa works with events, we need to enter
// the runtime context before doing some actual code.
// Any methods in classes called by the runtime are within context.
[runtime executeBlockInRuntime:^(L8Runtime *runtime) {
	runtime[@"console"] = [[MyConsole alloc] init];
}];

[runtime evaluateScript:@"console.log('Hello World!')"];
```

HINT: If you are not sure about whether you need `-[executeBlockInRuntime:]`,
then do not use it. When it runs and it is not in context, V8 will tell you
you are not in a context scope and abort.

## License ##
This software is released under the 2 clause BSD license. See LICENSE.

```
Copyright (c) 2014 Jos Kuijpers. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
