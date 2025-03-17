// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"
#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@interface FlutterSharedApplication ()

+ (UIApplication*)sharedApplication;

@end

@implementation FlutterSharedApplication

// The application object (such as from `UIApplication.sharedApplication`) is unavailable
// when the framework is being used in an app extension.
+ (BOOL)isAvailable {
  NSDictionary* nsExtension = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSExtension"];
  return ![nsExtension isKindOfClass:[NSDictionary class]];
}

+ (UIApplication*)uiApplication {
  if (![FlutterSharedApplication isAvailable]) {
    FML_LOG(ERROR) << "Attempting to access the application is not allowed.";
    return nil;
  }
  return [FlutterSharedApplication sharedApplication];
}

+ (UIApplication*)
    sharedApplication NS_EXTENSION_UNAVAILABLE_IOS("Accesses unavailable sharedApplication.") {
  return UIApplication.sharedApplication;
}

@end
