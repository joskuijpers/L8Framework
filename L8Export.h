//
//  L8Export.h
//  L8Framework
//
//  Created by Jos Kuijpers on 9/13/13.
//  Copyright (c) 2013 Jarvix. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol L8Export <NSObject>
@end

#define L8ExportAs(PropertyName, Selector) \
	@optional Selector __L8_EXPORT_AS__##PropertyName:(id)argument; @required Selector