// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/framework/Headers/FlutterAppDelegate.h"
#include "sky/shell/platform/ios/framework/Headers/FlutterViewController.h"

@implementation FlutterAppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {

  FlutterDartProject* project =
      [[FlutterDartProject alloc] initFromDefaultSourceForConfiguration];

  CGRect frame = [UIScreen mainScreen].bounds;
  UIWindow* window = [[UIWindow alloc] initWithFrame:frame];
  FlutterViewController* viewController =
      [[FlutterViewController alloc] initWithProject:project
                                             nibName:nil
                                              bundle:nil];
  window.rootViewController = viewController;
  [viewController release];
  self.window = window;
  [window release];
  [self.window makeKeyAndVisible];

  return YES;
}

// Use the NSNotificationCenter to notify services when we're opened with URLs.
// TODO(jackson): Revisit this API once we have more services using URLs to make
// it more typed and less brittle
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            sourceApplication:(NSString *)sourceApplication
            annotation:(id)annotation
{
  NSDictionary *dict = [@{
    @"handled": [NSMutableDictionary dictionary],
    @"url": url,
    @"sourceApplication": sourceApplication,
  } mutableCopy];
  if (annotation != nil)
    [dict setValue:annotation forKey:@"annotation"];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"openURL"
                                                      object:self
                                                    userInfo:dict];
  return ((NSNumber *)dict[@"handled"][@"value"]).boolValue;
}

@end
