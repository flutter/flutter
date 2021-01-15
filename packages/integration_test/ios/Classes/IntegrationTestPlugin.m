// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "IntegrationTestPlugin.h"

static NSString *const kIntegrationTestPluginChannel = @"plugins.flutter.io/integration_test";
static NSString *const kMethodTestFinished = @"allTestsFinished";

@interface IntegrationTestPlugin ()

@property(nonatomic, readwrite) NSDictionary<NSString *, NSString *> *testResults;

@end

@implementation IntegrationTestPlugin {
  NSDictionary<NSString *, NSString *> *_testResults;
}

+ (IntegrationTestPlugin *)instance {
  static dispatch_once_t onceToken;
  static IntegrationTestPlugin *sInstance;
  dispatch_once(&onceToken, ^{
    sInstance = [[IntegrationTestPlugin alloc] initForRegistration];
  });
  return sInstance;
}

- (instancetype)initForRegistration {
  return [super init];
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  // No initialization happens here because of the way XCTest loads the testing
  // bundles.  Setup on static variables can be disregarded when a new static
  // instance of IntegrationTestPlugin is allocated when the bundle is reloaded.
  // See also: https://github.com/flutter/plugins/pull/2465
}

- (void)setupChannels:(id<FlutterBinaryMessenger>)binaryMessenger {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kIntegrationTestPluginChannel
                                  binaryMessenger:binaryMessenger];
  [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    [self handleMethodCall:call result:result];
  }];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([kMethodTestFinished isEqual:call.method]) {
    self.testResults = call.arguments[@"results"];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
