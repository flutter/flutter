// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"

#import <Flutter/Flutter.h>

@implementation AppDelegate {
    CLLocationManager* _locationManager;
}
- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  FlutterViewController* controller =
    (FlutterViewController*)self.window.rootViewController;
  FlutterMethodChannel* locationChannel = [FlutterMethodChannel
    methodChannelNamed:@"location"
       binaryMessenger:controller
                 codec:[FlutterStandardMethodCodec sharedInstance]];
  [locationChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResultReceiver result) {
    if ([@"getLocation" isEqualToString:call.method]) {
      if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager startMonitoringSignificantLocationChanges];
      }
      CLLocation* location = _locationManager.location;
      result(@[@(location.coordinate.latitude), @(location.coordinate.longitude)], nil);
    } else {
      result(nil, [FlutterError errorWithCode:@"unknown method"
                                      message:@"Unknown location method called"
                                      details:nil]);
    }
  }];
  return YES;
}

@end
