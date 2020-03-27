// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@interface PlatformView: NSObject<FlutterPlatformView>

@property (strong, nonatomic) UIView *platformView;

@end

@implementation PlatformView

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.platformView = [[UIView alloc] init];
    self.platformView.backgroundColor = [UIColor blueColor];
  }
  return self;
}

- (UIView *)view {
  return self.platformView;
}

@end

@interface ViewFactory: NSObject<FlutterPlatformViewFactory>

@end

@implementation ViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  PlatformView *platformView = [[PlatformView alloc] init];
  return platformView;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  [[self registrarForPlugin:@"flutter"] registerViewFactory:[ViewFactory new] withId:@"platform_view"];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
