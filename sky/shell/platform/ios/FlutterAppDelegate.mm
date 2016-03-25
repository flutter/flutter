// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/command_line.h"
#include "base/trace_event/trace_event.h"
#include "sky/shell/platform/ios/FlutterAppDelegate.h"
#include "sky/shell/platform/ios/public/FlutterViewController.h"
#include "sky/shell/switches.h"

NSURL* URLForSwitch(const char* name) {
  auto cmd = *base::CommandLine::ForCurrentProcess();
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  if (cmd.HasSwitch(name)) {
    auto url = [NSURL fileURLWithPath:@(cmd.GetSwitchValueASCII(name).c_str())];
    [defaults setURL:url forKey:@(name)];
    [defaults synchronize];
    return url;
  }

  return [defaults URLForKey:@(name)];
}

@implementation FlutterAppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  TRACE_EVENT0("flutter", "applicationDidFinishLaunchingWithOptions");

#if TARGET_IPHONE_SIMULATOR
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithFLXArchive:URLForSwitch(sky::shell::switches::kFLX)
                dartMain:URLForSwitch(sky::shell::switches::kMainDartFile)
             packageRoot:URLForSwitch(sky::shell::switches::kPackageRoot)];
#else
  NSString* bundlePath =
      [[NSBundle mainBundle] pathForResource:@"FlutterApplication"
                                      ofType:@"framework"
                                 inDirectory:@"Frameworks"];
  NSBundle* bundle = [NSBundle bundleWithPath:bundlePath];
  FlutterDartProject* project =
      [[FlutterDartProject alloc] initWithPrecompiledDartBundle:bundle];
#endif

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

@end
