//
//  CGRectUtils.c
//  InstacabDriver
//
//  Created by Pavel Tisunov on 24/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#include "CGRectUtils.h"

CGRect CGRectSetWidth(CGRect rect, CGFloat width) {
    return CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height);
}

CGRect CGRectSetHeight(CGRect rect, CGFloat height) {
    return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
}

CGRect CGRectSetSize(CGRect rect, CGSize size) {
    return CGRectMake(rect.origin.x, rect.origin.y, size.width, size.height);
}

CGRect CGRectSetX(CGRect rect, CGFloat x) {
    return CGRectMake(x, rect.origin.y, rect.size.width, rect.size.height);
}

CGRect CGRectSetY(CGRect rect, CGFloat y) {
    return CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height);
}

CGRect CGRectSetOrigin(CGRect rect, CGPoint origin) {
    return CGRectMake(origin.x, origin.y, rect.size.width, rect.size.height);
}
