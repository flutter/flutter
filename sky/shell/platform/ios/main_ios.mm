// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "sky/shell/platform/ios/sky_app_delegate.h"

#include "sky/shell/platform/mac/platform_mac.h"

int main(int argc, const char * argv[]) {
  return PlatformMacMain(argc, argv, ^(){
    return UIApplicationMain(argc, (char **)argv, nil,
                             NSStringFromClass([SkyAppDelegate class]));
  });
}
