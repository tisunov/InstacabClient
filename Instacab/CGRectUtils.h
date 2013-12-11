//
//  CGRectUtils.h
//  InstacabDriver
//
//  Created by Pavel Tisunov on 24/11/13.
//  Copyright (c) 2013 Bright Stripe. All rights reserved.
//

#ifndef InstacabDriver_CGRectUtils_h
#define InstacabDriver_CGRectUtils_h

#include <CoreGraphics/CGGeometry.h>

CGRect CGRectSetWidth(CGRect rect, CGFloat width);
CGRect CGRectSetHeight(CGRect rect, CGFloat height);
CGRect CGRectSetSize(CGRect rect, CGSize size);
CGRect CGRectSetX(CGRect rect, CGFloat x);
CGRect CGRectSetY(CGRect rect, CGFloat y);
CGRect CGRectSetOrigin(CGRect rect, CGPoint origin);

#endif
