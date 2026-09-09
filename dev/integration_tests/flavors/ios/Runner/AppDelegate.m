// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didInitializeImplicitFlutterEngine:(NSObject<FlutterImplicitEngineBridge> *)engineBridge {
  [GeneratedPluginRegistrant registerWithRegistry:engineBridge.pluginRegistry];

  NSObject<FlutterPluginRegistrar> *assetRegistrar =
      [engineBridge.pluginRegistry registrarForPlugin:@"FlavorAssetLookup"];

  FlutterMethodChannel *flavorChannel = [FlutterMethodChannel methodChannelWithName:@"flavor" binaryMessenger:engineBridge.applicationRegistrar.messenger];

  [flavorChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    if ([call.method isEqualToString:@"loadBranchConfig"]) {
      NSString *key = [assetRegistrar lookupKeyForAsset:@"assets/branch-config.json"];
      NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
      NSError *error = nil;
      NSString *config = path == nil ? nil : [NSString stringWithContentsOfFile:path
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:&error];
      if (config == nil) {
        result([FlutterError errorWithCode:@"asset-read"
                                  message:error.localizedDescription ?: @"Asset not found"
                                  details:nil]);
      } else {
        result(config);
      }
      return;
    }
    NSString *flavor = (NSString *)[[NSBundle mainBundle].infoDictionary valueForKey:@"Flavor"];
    result(flavor);
  }];
}

@end
