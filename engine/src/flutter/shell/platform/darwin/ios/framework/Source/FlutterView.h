// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_

#include <UIKit/UIKit.h>

#include <memory>

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"

@protocol FlutterScreenshotDelegate <NSObject>

- (shell::Rasterizer::Screenshot)takeScreenshot:(shell::Rasterizer::ScreenshotType)type
                                asBase64Encoded:(BOOL)base64Encode;

@end

@interface FlutterView : UIView

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<FlutterScreenshotDelegate>)delegate
                          opaque:(BOOL)opaque NS_DESIGNATED_INITIALIZER;
- (std::unique_ptr<shell::IOSSurface>)createSurface;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_VIEW_H_
