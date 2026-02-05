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

- (void)closeAllWindows;

@end

struct FlutterWindowRect {
  double left;
  double top;
  double width;
  double height;

  static FlutterWindowRect fromNSRect(const NSRect& rect) {
    return {
        rect.origin.x,
        rect.origin.y,
        rect.size.width,
        rect.size.height,
    };
  }

  NSRect toNSRect() const { return NSMakeRect(left, top, width, height); }
};

struct FlutterWindowSize {
  double width;
  double height;

  static FlutterWindowSize fromNSSize(const NSSize& size) {
    return {
        size.width,
        size.height,
    };
  }
};

struct FlutterWindowConstraints {
  double min_width;
  double min_height;
  double max_width;
  double max_height;
};

struct FlutterWindowCreationRequest {
  bool has_size;
  struct FlutterWindowSize size;
  bool has_constraints;
  struct FlutterWindowConstraints constraints;
  int64_t parent_view_id;
  void (*on_should_close)();
  void (*on_will_close)();
  void (*notify_listeners)();
  // For sized to content windows with positioner returns the desired window position for given
  // configuration. All coordinates are in logical space.
  FlutterWindowRect* (*on_get_window_position)(const FlutterWindowSize& child_size,
                                               const FlutterWindowRect& parent_rect,
                                               const FlutterWindowRect& output_rect);
};

extern "C" {

// NOLINTBEGIN(google-objc-function-naming)

FLUTTER_DARWIN_EXPORT
int64_t InternalFlutter_WindowController_CreateRegularWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request);

FLUTTER_DARWIN_EXPORT
int64_t InternalFlutter_WindowController_CreateDialogWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request);

FLUTTER_DARWIN_EXPORT
int64_t InternalFlutter_WindowController_CreateTooltipWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_Destroy(int64_t engine_id, void* window);

FLUTTER_DARWIN_EXPORT
void* InternalFlutter_Window_GetHandle(int64_t engine_id, FlutterViewIdentifier view_id);

FLUTTER_DARWIN_EXPORT
FlutterWindowSize InternalFlutter_Window_GetContentSize(void* window);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_SetContentSize(void* window, const FlutterWindowSize* size);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_SetConstraints(void* window,
                                           const FlutterWindowConstraints* constraints);

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

FLUTTER_DARWIN_EXPORT
char* InternalFlutter_Window_GetTitle(void* window);

FLUTTER_DARWIN_EXPORT
bool InternalFlutter_Window_IsActivated(void* window);

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_UpdatePosition(void* window);

// NOLINTEND(google-objc-function-naming)
}

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERWINDOWCONTROLLER_H_
