// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "AppDelegate.h"
#include "PluginRegistry.h"

@implementation AppDelegate {
  PluginRegistry *plugins;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  FlutterViewController *flutterController =
      (FlutterViewController *)self.window.rootViewController;
  plugins = [[PluginRegistry alloc] initWithController:flutterController];

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
  return YES;
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
