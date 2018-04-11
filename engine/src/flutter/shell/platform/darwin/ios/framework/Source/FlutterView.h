// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_

#include <UIKit/UIKit.h>

#include <memory>

#include "flutter/shell/platform/darwin/ios/ios_surface.h"

@interface FlutterView : UIView

- (std::unique_ptr<shell::IOSSurface>)createSurface;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
