// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
@import Flutter;
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  NSObject<FlutterPluginRegistrar>* registrar = [self registrarForPlugin:@"Echo"];
  FlutterBasicMessageChannel* reset = [[FlutterBasicMessageChannel alloc] initWithName:@"dev.flutter.echo.reset" binaryMessenger:registrar.messenger codec:FlutterStandardMessageCodec.sharedInstance];
  [reset setMessageHandler:^(id  _Nullable message, FlutterReply  _Nonnull callback) {
    // noop
  }];
  FlutterBasicMessageChannel* basicStandard = [[FlutterBasicMessageChannel alloc] initWithName:@"dev.flutter.echo.basic.standard" binaryMessenger:registrar.messenger codec:FlutterStandardMessageCodec.sharedInstance];
  [basicStandard setMessageHandler:^(id  _Nullable message, FlutterReply  _Nonnull callback) {
    callback(message);
  }];
  FlutterBasicMessageChannel* basicBinary = [[FlutterBasicMessageChannel alloc] initWithName:@"dev.flutter.echo.basic.binary" binaryMessenger:registrar.messenger codec:FlutterBinaryCodec.sharedInstance];
  [basicBinary setMessageHandler:^(id  _Nullable message, FlutterReply  _Nonnull callback) {
    callback(message);
  }];
  NSObject<FlutterTaskQueue>* taskQueue = [registrar.messenger makeBackgroundTaskQueue];
  FlutterBasicMessageChannel* background =
  [[FlutterBasicMessageChannel alloc] initWithName:@"dev.flutter.echo.background.standard" binaryMessenger:registrar.messenger codec:FlutterStandardMessageCodec.sharedInstance taskQueue:taskQueue];
  [background setMessageHandler:^(id  _Nullable message, FlutterReply  _Nonnull callback) {
    callback(message);
  }];
  return YES;
}

@end
