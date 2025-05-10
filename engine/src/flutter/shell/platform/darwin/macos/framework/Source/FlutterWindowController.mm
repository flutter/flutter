// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterWindowController.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#include "flutter/shell/platform/common/isolate_scope.h"
#include "flutter/shell/platform/common/windowing.h"

/// A delegate for a Flutter managed window.
@interface FlutterWindowOwner : NSObject <NSWindowDelegate> {
  /// Strong reference to the window. This is the only strong reference to the
  /// window.
  NSWindow* _window;
  FlutterViewController* _flutterViewController;
  std::optional<flutter::Isolate> _isolate;
  FlutterWindowCreationRequest _creationRequest;
}

@property(readonly, nonatomic) NSWindow* window;
@property(readonly, nonatomic) FlutterViewController* flutterViewController;

- (instancetype)initWithWindow:(NSWindow*)window
         flutterViewController:(FlutterViewController*)viewController
               creationRequest:(const FlutterWindowCreationRequest&)creationRequest;

@end

@interface NSWindow (FlutterWindowSizing)

- (void)flutterSetContentSize:(FlutterWindowSizing)contentSize;

@end

@implementation NSWindow (FlutterWindowSizing)
- (void)flutterSetContentSize:(FlutterWindowSizing)contentSize {
  if (contentSize.hasSize) {
    [self setContentSize:NSMakeSize(contentSize.width, contentSize.height)];
  }
  if (contentSize.hasConstraints) {
    [self setContentMinSize:NSMakeSize(contentSize.min_width, contentSize.min_height)];
    if (contentSize.max_width > 0 && contentSize.max_height > 0) {
      [self setContentMaxSize:NSMakeSize(contentSize.max_width, contentSize.max_height)];
    } else {
      [self setContentMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    }
  }
}

@end

@implementation FlutterWindowOwner

@synthesize window = _window;
@synthesize flutterViewController = _flutterViewController;

- (instancetype)initWithWindow:(NSWindow*)window
         flutterViewController:(FlutterViewController*)viewController
               creationRequest:(const FlutterWindowCreationRequest&)creationRequest {
  if (self = [super init]) {
    _window = window;
    _flutterViewController = viewController;
    _creationRequest = creationRequest;
    _isolate = flutter::Isolate::Current();
  }
  return self;
}

- (void)windowDidBecomeKey:(NSNotification*)notification {
  [_flutterViewController.engine windowDidBecomeKey:_flutterViewController.viewIdentifier];
}

- (void)windowDidResignKey:(NSNotification*)notification {
  [_flutterViewController.engine windowDidResignKey:_flutterViewController.viewIdentifier];
}

- (BOOL)windowShouldClose:(NSWindow*)sender {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.on_close();
  return NO;
}

- (void)windowDidResize:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.on_size_change();
}

@end

@interface FlutterWindowController () {
  NSMutableArray<FlutterWindowOwner*>* _windows;
}

@end

@implementation FlutterWindowController

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _windows = [NSMutableArray array];
  }
  return self;
}

- (FlutterViewIdentifier)createRegularWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* c = [[FlutterViewController alloc] initWithEngine:_engine
                                                                   nibName:nil
                                                                    bundle:nil];

  NSWindow* window = [[NSWindow alloc] init];
  // If this is not set there will be double free on window close when
  // using ARC.
  [window setReleasedWhenClosed:NO];

  window.contentViewController = c;
  window.styleMask = NSWindowStyleMaskResizable | NSWindowStyleMaskTitled |
                     NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
  [window flutterSetContentSize:request->contentSize];
  [window setIsVisible:YES];
  [window makeKeyAndOrderFront:nil];

  FlutterWindowOwner* w = [[FlutterWindowOwner alloc] initWithWindow:window
                                               flutterViewController:c
                                                     creationRequest:*request];
  window.delegate = w;
  [_windows addObject:w];

  return c.viewIdentifier;
}

- (void)destroyWindow:(NSWindow*)window {
  FlutterWindowOwner* owner = nil;
  for (FlutterWindowOwner* o in _windows) {
    if (o.window == window) {
      owner = o;
      break;
    }
  }
  if (owner != nil) {
    [_windows removeObject:owner];
    // Make sure to unregister the controller from the engine and remove the FlutterView
    // before destroying the window and Flutter NSView.
    [owner.flutterViewController dispose];
    owner.window.delegate = nil;
    [owner.window close];
  }
}

- (void)closeAllWindows {
  for (FlutterWindowOwner* owner in _windows) {
    [owner.flutterViewController dispose];
    [owner.window close];
  }
  [_windows removeAllObjects];
}

@end

// NOLINTBEGIN(google-objc-function-naming)

int64_t FlutterCreateRegularWindow(int64_t engine_id, const FlutterWindowCreationRequest* request) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine enableMultiView];
  return [engine.windowController createRegularWindow:request];
}

void FlutterDestroyWindow(int64_t engine_id, void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine.windowController destroyWindow:w];
}

void* FlutterGetWindowHandle(int64_t engine_id, FlutterViewIdentifier view_id) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  FlutterViewController* controller = [engine viewControllerForIdentifier:view_id];
  return (__bridge void*)controller.view.window;
}

FlutterWindowSize FlutterGetWindowContentSize(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  return {
      .width = w.frame.size.width,
      .height = w.frame.size.height,
  };
}

void FlutterSetWindowContentSize(void* window, const FlutterWindowSizing* size) {
  NSWindow* w = (__bridge NSWindow*)window;
  [w flutterSetContentSize:*size];
}

void FlutterSetWindowTitle(void* window, const char* title) {
  NSWindow* w = (__bridge NSWindow*)window;
  w.title = [NSString stringWithUTF8String:title];
}

int64_t FlutterGetWindowState(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  if (w.isMiniaturized) {
    return static_cast<int64_t>(flutter::WindowState::kMinimized);
  } else if (w.isZoomed) {
    return static_cast<int64_t>(flutter::WindowState::kMaximized);
  } else {
    return static_cast<int64_t>(flutter::WindowState::kRestored);
  }
}

void FlutterSetWindowState(void* window, int64_t state) {
  flutter::WindowState windowState = static_cast<flutter::WindowState>(state);
  NSWindow* w = (__bridge NSWindow*)window;
  if (windowState == flutter::WindowState::kMaximized) {
    [w deminiaturize:nil];
    [w zoom:nil];
  } else if (state == static_cast<int64_t>(flutter::WindowState::kMinimized)) {
    [w miniaturize:nil];
  } else {
    if (w.isMiniaturized) {
      [w deminiaturize:nil];
    } else if (w.isZoomed) {
      [w zoom:nil];
    } else {
      bool isFullScreen = (w.styleMask & NSWindowStyleMaskFullScreen) != 0;
      if (isFullScreen) {
        [w toggleFullScreen:nil];
      }
    }
  }
}

// NOLINTEND(google-objc-function-naming)
