// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "sky/shell/ios/sky_app_delegate.h"

#include "sky/shell/mac/platform_mac.h"

extern "C" {
// TODO(csg): HACK! boringssl accesses this on Android using a weak symbol
// instead of a global. Till the patch for that lands and propagates to Sky, we
// specify the same here to get workable builds on iOS. This is a hack! Will
// go away.
unsigned long getauxval(unsigned long type) {
  return 0;
}
}

int main(int argc, const char * argv[]) {
  return PlatformMacMain(argc, argv, ^(){
    return UIApplicationMain(argc, (char **)argv, nil,
                             NSStringFromClass([SkyAppDelegate class]));
  });
}
