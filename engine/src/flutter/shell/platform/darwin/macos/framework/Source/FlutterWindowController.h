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
  bool has_size;
  double width;
  double height;
  bool has_constraints;
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
int64_t InternalFlutter_WindowController_CreateRegularWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_Destroy(int64_t engine_id, void* window);

FLUTTER_DARWIN_EXPORT
void* InternalFlutter_Window_GetHandle(int64_t engine_id, FlutterViewIdentifier view_id);

FLUTTER_DARWIN_EXPORT
FlutterWindowSize InternalFlutter_Window_GetContentSize(void* window);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_SetContentSize(void* window, const FlutterWindowSizing* size);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_SetTitle(void* window, const char* title);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_SetMaximized(void* window, bool maximized);

FLUTTER_DARWIN_EXPORT
bool InternalFlutter_Window_IsMaximized(void* window);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_Minimize(void* window);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_Unminimize(void* window);

FLUTTER_DARWIN_EXPORT
bool InternalFlutter_Window_IsMinimized(void* window);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_SetFullScreen(void* window, bool fullScreen);

FLUTTER_DARWIN_EXPORT
bool InternalFlutter_Window_IsFullScreen(void* window);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_Activate(void* window);

// NOLINTEND(google-objc-function-naming)
}

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERWINDOWCONTROLLER_H_
