// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERAPPDELEGATE_H_
#define FLUTTER_FLUTTERAPPDELEGATE_H_

#import <UIKit/UIKit.h>

#include "FlutterMacros.h"

// A simple app delegate that creates a single full-screen Flutter application.
// Using FlutterAppDelegate is optional. The framework provides this interface
// to make it easy to get started with simple Flutter apps.
FLUTTER_EXPORT
@interface FlutterAppDelegate : UIResponder<UIApplicationDelegate>

@property(strong, nonatomic) UIWindow* window;

@end

#endif  // FLUTTER_FLUTTERDARTPROJECT_H_
