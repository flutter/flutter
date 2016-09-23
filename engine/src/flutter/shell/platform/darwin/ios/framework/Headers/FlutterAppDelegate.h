// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERAPPDELEGATE_H_
#define FLUTTER_FLUTTERAPPDELEGATE_H_

#import <UIKit/UIKit.h>

#include "FlutterMacros.h"

// Empty implementation of UIApplicationDelegate, for simple apps
// that don't need to customize the application delegate.
FLUTTER_EXPORT
@interface FlutterAppDelegate : UIResponder<UIApplicationDelegate>

@property(strong, nonatomic) UIWindow* window;

@end

#endif  // FLUTTER_FLUTTERDARTPROJECT_H_
