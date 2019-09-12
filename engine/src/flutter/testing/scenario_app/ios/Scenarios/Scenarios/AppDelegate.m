// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "AppDelegate.h"
#import "FlutterEngine+ScenariosTest.h"
#import "ScreenBeforeFlutter.h"
#import "TextPlatformView.h"

@interface NoStatusBarFlutterViewController : FlutterViewController

@end

@implementation NoStatusBarFlutterViewController
- (BOOL)prefersStatusBarHidden {
  return YES;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  // This argument is used by the XCUITest for Platform Views so that the app
  // under test will create platform views.
  if ([[[NSProcessInfo processInfo] arguments] containsObject:@"--platform-view"]) {
    FlutterEngine* engine = [[FlutterEngine alloc] initWithScenario:@"text_platform_view"
                                                     withCompletion:nil];
    [engine runWithEntrypoint:nil];

    FlutterViewController* flutterViewController =
        [[NoStatusBarFlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
    TextPlatformViewFactory* textPlatformViewFactory =
        [[TextPlatformViewFactory alloc] initWithMessenger:flutterViewController.binaryMessenger];
    NSObject<FlutterPluginRegistrar>* registrar =
        [flutterViewController.engine registrarForPlugin:@"scenarios/TextPlatformViewPlugin"];
    [registrar registerViewFactory:textPlatformViewFactory withId:@"scenarios/textPlatformView"];
    self.window.rootViewController = flutterViewController;
  } else if ([[[NSProcessInfo processInfo] arguments] containsObject:@"--screen-before-flutter"]) {
    self.window.rootViewController = [[ScreenBeforeFlutter alloc] initWithEngineRunCompletion:nil];
  } else {
    self.window.rootViewController = [[UIViewController alloc] init];
  }
  [self.window makeKeyAndVisible];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
