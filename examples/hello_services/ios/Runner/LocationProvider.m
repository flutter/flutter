// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "LocationProvider.h"

#import <CoreLocation/CoreLocation.h>

@implementation LocationProvider {
    CLLocationManager* _locationManager;
}

@synthesize messageName = _messageName;

- (instancetype) init {
    self = [super init];
    if (self)
        self->_messageName = @"getLocation";
    return self;
}

- (NSString*)didReceiveString:(NSString*)message {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager startMonitoringSignificantLocationChanges];
    }

    CLLocation* location = _locationManager.location;

    NSDictionary* response = @{
        @"latitude": @(location.coordinate.latitude),
        @"longitude": @(location.coordinate.longitude),
    };

    NSData* data = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
