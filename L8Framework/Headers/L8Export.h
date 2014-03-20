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
 * @brief Export protocol for L8.
 */
@protocol L8Export
@end

/**
 * A name-changer for exported methods in L8 exports.
 *
 * @note Note that the L8Export macro may only be applied to a selector that takes one
 * or more argument. If you need to rename a method with no arguments, use
 * L8_EXPORT_AS_NO_ARG
 */
#define L8_EXPORT_AS(PropertyName, Selector) \
	@optional Selector __L8_EXPORT_AS__##PropertyName:(id)argument; @required Selector

/**
 * A name-changer for exported methods in L8 exports.
 *
 * @note Note that this only works for methods with no arguments. If you
 * arguments, use L8_EXPORT_AS instead.
 */
#define L8_EXPORT_AS_NO_ARGS(PropertyName, Selector) \
	@optional Selector##__L8_EXPORT_AS__##PropertyName; @required Selector

/**
 * @page exportas L8_EXPORT_AS: renaming of exported selectors
 *
 * A selector that will be exported to JavaScript can be renamed
 * using the L8_EXPORT_AS() macro.
 *
 *
 * @code
 * @protocol MyClass <JSExport>
 * L8_EXPORT_AS(foo,
 * - (void)doFoo:(id)foo withBar:(id)bar
 * );
 *
 * L8_EXPORT_AS_NO_ARGS(bar,
 * - (void)createCrowBar
 * );
 * @end
 * @endcode
 *
 * @code
 * #define L8_EXPORT_AS(PropertyName, Selector) \
 *   @optional Selector __L8_EXPORT_AS__##PropertyName:(id)argument; @required Selector
 
 * #define L8_EXPORT_AS_NO_ARGS(PropertyName, Selector) \
 *   @optional Selector##__L8_EXPORT_AS__##PropertyName; @required Selector
 * @endcode
 *
 */