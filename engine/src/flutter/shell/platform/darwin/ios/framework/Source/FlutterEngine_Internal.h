// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_INTERNAL_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

@interface FlutterEngine () <FlutterViewEngineDelegate>

- (flutter::Shell&)shell;

- (void)updateViewportMetrics:(flutter::ViewportMetrics)viewportMetrics;
- (void)dispatchPointerDataPacket:(std::unique_ptr<flutter::PointerDataPacket>)packet;

- (fml::RefPtr<fml::TaskRunner>)platformTaskRunner;
- (fml::RefPtr<fml::TaskRunner>)RasterTaskRunner;

- (fml::WeakPtr<flutter::PlatformView>)platformView;

- (flutter::Rasterizer::Screenshot)screenshot:(flutter::Rasterizer::ScreenshotType)type
                                 base64Encode:(bool)base64Encode;

- (FlutterPlatformPlugin*)platformPlugin;
- (std::shared_ptr<flutter::FlutterPlatformViewsController>&)platformViewsController;
- (FlutterTextInputPlugin*)textInputPlugin;
- (void)launchEngine:(NSString*)entrypoint libraryURI:(NSString*)libraryOrNil;
- (BOOL)createShell:(NSString*)entrypoint
         libraryURI:(NSString*)libraryOrNil
       initialRoute:(NSString*)initialRoute;
- (void)attachView;
- (void)notifyLowMemory;
- (flutter::PlatformViewIOS*)iosPlatformView;

- (void)waitForFirstFrame:(NSTimeInterval)timeout callback:(void (^)(BOOL didTimeout))callback;
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERENGINE_INTERNAL_H_
