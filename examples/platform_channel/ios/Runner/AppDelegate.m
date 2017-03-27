// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"

#import <Flutter/Flutter.h>

@implementation AppDelegate {
  FlutterResultReceiver _events;
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  FlutterViewController* controller =
      (FlutterViewController*)self.window.rootViewController;
  FlutterMethodChannel* batteryChannel = [FlutterMethodChannel
      methodChannelWithName:@"battery"
            binaryMessenger:controller
                      codec:[FlutterStandardMethodCodec sharedInstance]];
  [batteryChannel setMethodCallHandler:^(FlutterMethodCall* call,
                                         FlutterResultReceiver result) {
      if ([@"getBatteryLevel" isEqualToString:call.method])
          [self getBatteryLevel:result];
      else
          result(FlutterMethodNotImplemented);
  }];
  FlutterEventChannel* chargingChannel = [FlutterEventChannel
      eventChannelWithName:@"io.flutter.samples/charging"
           binaryMessenger:controller];
  [chargingChannel setStreamHandler:self];
  return YES;
}

- (void)getBatteryLevel:(FlutterResultReceiver)result {
  UIDevice* device = UIDevice.currentDevice;
  device.batteryMonitoringEnabled = YES;
  if (device.batteryState == UIDeviceBatteryStateUnknown)
    result([FlutterError errorWithCode:@"UNAVAILABLE"
                               message:@"Battery info unavailable"
                               details:nil]);
  else
    result(@((int)(device.batteryLevel * 100)));
}

- (FlutterError*)onListenWithArguments:(id)arguments
                         eventReceiver:(FlutterResultReceiver)events {
  _events = events;
  [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(onBatteryStateDidChange:)
           name:UIDeviceBatteryStateDidChangeNotification
         object:nil];
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  _events = nil;
  return nil;
}

- (void)onBatteryStateDidChange:(NSNotification*)notification {
  if (!_events)
    return;
  UIDeviceBatteryState state = [[UIDevice currentDevice] batteryState];
  switch(state) {
    case UIDeviceBatteryStateCharging:
    case UIDeviceBatteryStateFull:
    _events(@"charging");
    break;
  case UIDeviceBatteryStateUnplugged:
    _events(@"discharging");
    break;
  default:
    _events([FlutterError errorWithCode:@"UNKNOWN"
                                message:@"Battery state is unknown"
                                details:nil]);
  }
}
@end
