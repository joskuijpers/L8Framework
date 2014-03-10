//
//  L8Export.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

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