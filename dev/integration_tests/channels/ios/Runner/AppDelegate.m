// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  FlutterViewController *flutterController =
      (FlutterViewController *)self.window.rootViewController;

  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"binary-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterBinaryCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"string-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterStringCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"json-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterJSONMessageCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"std-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterStandardMessageCodec sharedInstance]]];
  [self setupMethodCallSuccessHandshakeOnChannel:
    [FlutterMethodChannel methodChannelWithName:@"json-method"
                                binaryMessenger:flutterController
                                          codec:[FlutterJSONMethodCodec sharedInstance]]];
  [self setupMethodCallSuccessHandshakeOnChannel:
    [FlutterMethodChannel methodChannelWithName:@"std-method"
                                binaryMessenger:flutterController
                                          codec:[FlutterStandardMethodCodec sharedInstance]]];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)setupMessagingHandshakeOnChannel:(FlutterBasicMessageChannel*)channel {
  [channel setMessageHandler:^(id message, FlutterReply reply) {
    [channel sendMessage:message reply:^(id messageReply) {
      [channel sendMessage:messageReply];
      reply(message);
    }];
  }];
}

- (void)setupMethodCallSuccessHandshakeOnChannel:(FlutterMethodChannel*)channel {
  [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    if ([call.method isEqual:@"success"]) {
      [channel invokeMethod:call.method arguments:call.arguments result:^(id value) {
        [channel invokeMethod:call.method arguments:value];
        result(call.arguments);
      }];
    } else if ([call.method isEqual:@"error"]) {
      [channel invokeMethod:call.method arguments:call.arguments result:^(id value) {
        FlutterError* error = (FlutterError*) value;
        [channel invokeMethod:call.method arguments:error.details];
        result(error);
      }];
    } else {
      [channel invokeMethod:call.method arguments:call.arguments result:^(id value) {
        NSAssert(value == FlutterMethodNotImplemented, @"Result must be not implemented");
        [channel invokeMethod:call.method arguments:nil];
        result(FlutterMethodNotImplemented);
      }];
    }
  }];
}
@end
