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

/**
 * When transferring JavaScript exceptions, Objective-C
 * exceptions are thrown when a JavaScript exception is caught.
 *
 * When not transferring, the exception handling block of 
 * L8Reporter is called instead.
 */
#define L8_TRANSFER_JS_EXCEPTIONS

/**
 * Enables typed arrays and their encapsulation.
 */
#define L8_ENABLE_TYPED_ARRAYS

/**
 * Enables symbols and their encapsulation.
 *
 * Enables an experimental V8 harmony feature.
 */
#define L8_ENABLE_SYMBOLS

//#define L8_OBJC_OBJFW

#pragma mark Definitions dependent on configuration

#ifndef L8_OBJC_OBJFW
# define L8_OBJC_FOUNDATION
#endif
