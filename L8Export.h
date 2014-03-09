//
//  L8Export.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

/**
 * Export protocol for L8.
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