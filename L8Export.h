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

/**
 * @brief Export protocol for L8.
 */
@protocol L8Export <NSObject>
@end

/**
 * A name-changer for exported methods in L8 exports.
 *
 * Note that the JSExport macro may only be applied to a selector that takes one
 * or more argument.
 */
#define L8ExportAs(PropertyName, Selector) \
	@optional Selector __L8_EXPORT_AS__##PropertyName:(id)argument; @required Selector

/**
 * @page exportas L8ExportAs: renaming of exported selectors
 *
 * A selector that will be exported to JavaScript can be renamed
 * using the L8ExportAs() macro.
 *
 *
 * @code
 * @protocol MyClass <JSExport>
 * L8ExportAs(foo,
 * - (void)doFoo:(id)foo withBar:(id)bar
 * );
 * @end
 * @endcode
 *
 * Note that this can only be used for selectors with one or more arguments.
 *
 * @code
 * #define L8ExportAs(PropertyName, Selector) \
 *   @optional Selector __L8_EXPORT_AS__##PropertyName:(id)argument; @required Selector
 * @endcode
 *
 */