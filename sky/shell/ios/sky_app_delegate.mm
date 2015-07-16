// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_app_delegate.h"
#import "sky_view_controller.h"

#include "sky/shell/shell.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/ui_delegate.h"
#include "base/lazy_instance.h"
#include "base/message_loop/message_loop.h"

@implementation SkyAppDelegate {
  base::LazyInstance<scoped_ptr<base::MessageLoop>> _main_message_loop;
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  [self setupSkyShell];
  [self setupViewport];

  return YES;
}

- (void)setupSkyShell {
  [self adoptPlatformRunLoop];

  auto service_provider_context =
      make_scoped_ptr(new sky::shell::ServiceProviderContext(
          _main_message_loop.Get()->task_runner()));
  sky::shell::Shell::Init(service_provider_context.Pass());
}

- (void)adoptPlatformRunLoop {
  _main_message_loop.Get().reset(new base::MessageLoopForUI);
  // One cannot start the message loop on the platform main thread. Instead,
  // we attach to the CFRunLoop
  base::MessageLoopForUI::current()->Attach();
}

- (void)setupViewport {
  CGRect frame = [UIScreen mainScreen].bounds;
  UIWindow* window = [[UIWindow alloc] initWithFrame:frame];
  SkyViewController* viewController = [[SkyViewController alloc] init];
  window.rootViewController = viewController;
  [viewController release];
  self.window = window;
  [window release];
  [self.window makeKeyAndVisible];
}

@end
