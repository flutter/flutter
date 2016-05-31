// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "LocationProvider.h"

@implementation LocationProvider

@synthesize messageName = _messageName;

- (instancetype) init {
    self = [super init];
    if (self)
        self->_messageName = @"getLocation";
    return self;
}

- (NSString*)didReceiveString:(NSString*)message {
    NSDictionary* response = @{
        @"latitude": @3.29334,
        @"longitude": @8.2492492
    };

    NSData* data = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
