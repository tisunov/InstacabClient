//
//  DCTReporter.h
//  DoubleClick for Publishers (DFP) Conversion Tracking.
//  Copyright 2011 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ACTReporter.h"

/// Reports a DoubleClick for Publisher (DFP) conversion to Google.
@interface DCTConversionReporter : ACTReporter

/// String representation of conversion value. Example: @"3.99".
@property(nonatomic, copy) NSString *value;

/// Reports conversion information to Google.
+ (void)reportWithConversionID:(NSString *)conversionID
                         value:(NSString *)value
                  isRepeatable:(BOOL)isRepeatable;

/// Returns an initialized conversion ACTConversionReporter object for conversion ID/label
/// reporting. Use this method to separate conversion tracker initialization and reporting.
- (instancetype)initWithConversionID:(NSString *)conversionID
                               value:(NSString *)value
                        isRepeatable:(BOOL)isRepeatable;

@end
