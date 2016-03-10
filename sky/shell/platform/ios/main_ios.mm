// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#include "sky/shell/platform/ios/flutter_app_delegate.h"
#include "sky/shell/platform/mac/platform_mac.h"

int main(int argc, const char* argv[]) {
  // iOS does use the FlutterViewController that initializes the platform but
  // we have the command line args here. So call it now.
  sky::shell::PlatformMacMain(argc, argv, "");
  return UIApplicationMain(argc, (char**)argv, nil,
                           NSStringFromClass([FlutterAppDelegate class]));
}
