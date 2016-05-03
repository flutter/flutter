// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#include "sky/shell/platform/ios/framework/Headers/FlutterAppDelegate.h"
#include "sky/shell/platform/ios/framework/Headers/FlutterViewController.h"

int main(int argc, const char* argv[]) {
  FlutterInit(argc, argv);
  return UIApplicationMain(argc, (char**)argv, nil,
                           NSStringFromClass([FlutterAppDelegate class]));
}
