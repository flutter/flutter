// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterWindowController.h"
#include <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#include "flutter/shell/platform/common/isolate_scope.h"

// A delegate for a Flutter managed window.
@interface FlutterWindowOwner : NSObject <NSWindowDelegate> {
  // Strong reference to the window. This is the only strong reference to the
  // window.
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
  if (contentSize.has_size) {
    [self setContentSize:NSMakeSize(contentSize.width, contentSize.height)];
  }
  if (contentSize.has_constraints) {
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

// Miniaturize does not trigger resize event, but for now there
// is no other way to get notification about the state change.
- (void)windowDidMiniaturize:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.on_size_change();
}

// Deminiaturize does not trigger resize event, but for now there
// is no other way to get notification about the state change.
- (void)windowDidDeminiaturize:(NSNotification*)notification {
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

int64_t InternalFlutter_WindowController_CreateRegularWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine enableMultiView];
  return [engine.windowController createRegularWindow:request];
}

void InternalFlutter_Window_Destroy(int64_t engine_id, void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine.windowController destroyWindow:w];
}

void* InternalFlutter_Window_GetHandle(int64_t engine_id, FlutterViewIdentifier view_id) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  FlutterViewController* controller = [engine viewControllerForIdentifier:view_id];
  return (__bridge void*)controller.view.window;
}

FlutterWindowSize InternalFlutter_Window_GetContentSize(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  return {
      .width = w.frame.size.width,
      .height = w.frame.size.height,
  };
}

void InternalFlutter_Window_SetContentSize(void* window, const FlutterWindowSizing* size) {
  NSWindow* w = (__bridge NSWindow*)window;
  [w flutterSetContentSize:*size];
}

void InternalFlutter_Window_SetTitle(void* window, const char* title) {
  NSWindow* w = (__bridge NSWindow*)window;
  w.title = [NSString stringWithUTF8String:title];
}

void InternalFlutter_Window_SetMaximized(void* window, bool maximized) {
  NSWindow* w = (__bridge NSWindow*)window;
  if (maximized & !w.isZoomed) {
    [w zoom:nil];
  } else if (!maximized && w.isZoomed) {
    [w zoom:nil];
  }
}

bool InternalFlutter_Window_IsMaximized(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  return w.isZoomed;
}

void InternalFlutter_Window_Minimize(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  [w miniaturize:nil];
}

void InternalFlutter_Window_Unminimize(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  [w deminiaturize:nil];
}

bool InternalFlutter_Window_IsMinimized(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  return w.isMiniaturized;
}

void InternalFlutter_Window_SetFullScreen(void* window, bool fullScreen) {
  NSWindow* w = (__bridge NSWindow*)window;
  bool isFullScreen = (w.styleMask & NSWindowStyleMaskFullScreen) != 0;
  if (fullScreen && !isFullScreen) {
    [w toggleFullScreen:nil];
  } else if (!fullScreen && isFullScreen) {
    [w toggleFullScreen:nil];
  }
}

bool InternalFlutter_Window_IsFullScreen(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  return (w.styleMask & NSWindowStyleMaskFullScreen) != 0;
}

void InternalFlutter_Window_Activate(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  [NSApplication.sharedApplication activateIgnoringOtherApps:YES];
  [w makeKeyAndOrderFront:nil];
}

// NOLINTEND(google-objc-function-naming)
