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

#import "config.h"

#pragma mark Attribute definitions

#if __has_attribute(deprecated)
# define L8_DEPRECATED(msg) __attribute__((deprecated((msg))))
#else
# define L8_DEPRECATED(msg)
#endif

#if __has_attribute(unavailable)
# define L8_UNAVAILABLE(msg) __attribute__((unavailable((msg))))
#else
# define L8_UNAVAILABLE(msg)
#endif

#if __has_attribute(objc_designated_initializer)
# define L8_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#else
# define L8_DESIGNATED_INITIALIZER
#endif

#if __has_attribute(objc_returns_inner_pointer)
# define L8_RETURNS_INNER_POINTER __attribute__((objc_returns_inner_pointer))
#else
# define L8_RETURNS_INNER_POINTER
#endif

#if __has_attribute(unused)
# define L8_UNUSED __attribute__((unused))
#else
# define L8_UNUSED
#endif

#if __has_attribute(warn_unused_result)
# define L8_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define L8_WARN_UNUSED_RESULT
#endif

#if __has_attribute(objc_root_class)
# define L8_ROOT_CLASS __attribute__((objc_root_class))
#else
# define L8_ROOT_CLASS
#endif

#if __has_attribute(objc_requires_super)
# define L8_REQUIRES_SUPER __attribute__((objc_requires_super))
#else
# define L8_REQUIRES_SUPER
#endif

#if __has_attribute(const)
# define L8_CONST __attribute__((const))
#else
# define L8_CONST
#endif

#if __has_builtin(__builtin_expect)
# define L8_LIKELY(condition) (__builtin_expect(!!(condition), 0))
# define L8_UNLIKELY(condition) (__builtin_expect(!!(condition), 1))
#else
# define L8_LIKELY(condition)
# define L8_UNLIKELY(condition)
#endif

#pragma mark Runtime configuration

#ifdef OF_OBJFW_RUNTIME
# define L8_OBJFW_RUNTIME
#else
# define L8_APPLE_RUNTIME
#endif

#pragma mark Class names

#ifdef L8_OBJC_OBJFW
#define L8_CLASS_PREFIX OF
# define L8_RANGE_TYPE of_range_r
#else
#define L8_CLASS_PREFIX NS
# define L8_RANGE_TYPE NSRange
#endif

#define CONCAT2(prefix,suffix) prefix ## suffix
#define CONCAT(prefix,suffix) CONCAT2(prefix,suffix)

# define L8_OBJECT_CLASS			CONCAT(L8_CLASS_PREFIX,Object)
# define L8_NUMBER_CLASS			CONCAT(L8_CLASS_PREFIX,Number)
# define L8_ARRAY_CLASS				CONCAT(L8_CLASS_PREFIX,Array)
# define L8_MUTABLE_ARRAY_CLASS		CONCAT(L8_CLASS_PREFIX,MutableArray)
# define L8_STRING_CLASS			CONCAT(L8_CLASS_PREFIX,String)
# define L8_MUTABLE_STRING_CLASS	CONCAT(L8_CLASS_PREFIX,MutableString)
# define L8_DATE_CLASS				CONCAT(L8_CLASS_PREFIX,Date)

# define L8_COPYING_PROTOCOL		CONCAT(L8_CLASS_PREFIX,Copying)
