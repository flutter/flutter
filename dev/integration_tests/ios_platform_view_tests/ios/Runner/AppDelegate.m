// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "ViewFactory.h"
#import "TextFieldFactory.h"
#import "ButtonFactory.h"
#import "WebViewFactory.h"
#import "DrawingWebViewFactory.h"
#import "FakeAdMobBannerFactory.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didInitializeImplicitFlutterEngine:(NSObject<FlutterImplicitEngineBridge> *)engineBridge {
  [GeneratedPluginRegistrant registerWithRegistry:engineBridge.pluginRegistry];
  id<FlutterPluginRegistrar> registrar = [engineBridge.pluginRegistry registrarForPlugin:@"flutter"];
  [registrar registerViewFactory:[[ViewFactory alloc] init] withId:@"platform_view"];
  [registrar registerViewFactory:[[TextFieldFactory alloc] init] withId:@"platform_text_field"];
  [registrar registerViewFactory:[[ButtonFactory alloc] init] withId:@"platform_button"];
  [registrar registerViewFactory:[[WebViewFactory alloc] init] withId:@"platform_web_view"];
  [registrar registerViewFactory:[[DrawingWebViewFactory alloc] init] withId:@"platform_drawing_web_view"];
  [registrar registerViewFactory:[[FakeAdMobBannerFactory alloc] init] withId:@"platform_fake_admob_banner"];
}

@end
