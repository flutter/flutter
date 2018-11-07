// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_INTERNAL_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

#import "FlutterPlatformViews_Internal.h"

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

@interface FlutterEngine () <FlutterViewEngineDelegate>

- (shell::Shell&)shell;

- (void)updateViewportMetrics:(blink::ViewportMetrics)viewportMetrics;
- (void)dispatchPointerDataPacket:(std::unique_ptr<blink::PointerDataPacket>)packet;

- (fml::RefPtr<fml::TaskRunner>)platformTaskRunner;

- (fml::WeakPtr<shell::PlatformView>)platformView;

- (shell::Rasterizer::Screenshot)screenshot:(shell::Rasterizer::ScreenshotType)type
                               base64Encode:(bool)base64Encode;

- (FlutterPlatformPlugin*)platformPlugin;
- (shell::FlutterPlatformViewsController*)platformViewsController;
- (FlutterTextInputPlugin*)textInputPlugin;
- (void)launchEngine:(NSString*)entrypoint libraryURI:(NSString*)libraryOrNil;
- (BOOL)createShell:(NSString*)entrypoint libraryURI:(NSString*)libraryOrNil;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_INTERNAL_H_
