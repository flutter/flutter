// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/UIViewController+FlutterScreenAndSceneIfLoaded.h"

#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@implementation UIViewController (FlutterScreenAndSceneIfLoaded)

- (UIWindowScene*)flutterWindowSceneIfViewLoaded {
  if (self.viewIfLoaded == nil) {
    [FlutterLogger logWarning:@"Trying to access the window scene before the view is loaded."];
    return nil;
  }
  return self.viewIfLoaded.window.windowScene;
}

- (UIScreen*)flutterScreenIfViewLoaded {
  if (self.viewIfLoaded == nil) {
    [FlutterLogger logWarning:@"Trying to access the screen before the view is loaded."];
    return nil;
  }
  return [self flutterWindowSceneIfViewLoaded].screen;
}

@end
