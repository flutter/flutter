// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERWINDOWCONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERWINDOWCONTROLLER_H_

#import <Cocoa/Cocoa.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"

@class FlutterEngine;

@interface FlutterWindowController : NSObject

@property(nonatomic, weak) FlutterEngine* engine;

@end

@interface FlutterWindowController (Testing)

- (void)closeAllWindows;

@end

struct FlutterWindowSizing {
  bool hasSize;
  double width;
  double height;
  bool hasConstraints;
  double min_width;
  double min_height;
  double max_width;
  double max_height;
};

struct FlutterWindowCreationRequest {
  FlutterWindowSizing contentSize;
  void (*on_close)();
  void (*on_size_change)();
};

struct FlutterWindowSize {
  double width;
  double height;
};

extern "C" {

// NOLINTBEGIN(google-objc-function-naming)

FLUTTER_DARWIN_EXPORT
int64_t FlutterCreateRegularWindow(int64_t engine_id, const FlutterWindowCreationRequest* request);

FLUTTER_DARWIN_EXPORT
void FlutterDestroyWindow(int64_t engine_id, void* window);

FLUTTER_DARWIN_EXPORT
void* FlutterGetWindowHandle(int64_t engine_id, FlutterViewIdentifier view_id);

FLUTTER_DARWIN_EXPORT
void* FlutterGetWindowHandle(int64_t engine_id, FlutterViewIdentifier view_id);

FLUTTER_DARWIN_EXPORT
FlutterWindowSize FlutterGetWindowContentSize(void* window);

FLUTTER_DARWIN_EXPORT
void FlutterSetWindowContentSize(void* window, const FlutterWindowSizing* size);

FLUTTER_DARWIN_EXPORT
void FlutterSetWindowTitle(void* window, const char* title);

FLUTTER_DARWIN_EXPORT
int64_t FlutterGetWindowState(void* window);

FLUTTER_DARWIN_EXPORT
void FlutterSetWindowState(void* window, int64_t state);

// NOLINTEND(google-objc-function-naming)
}

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERWINDOWCONTROLLER_H_
