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
@interface FlutterWindowOwner : NSObject <NSWindowDelegate, FlutterViewSizingDelegate> {
  // Strong reference to the window. This is the only strong reference to the
  // window.
  NSWindow* _window;
  FlutterViewController* _flutterViewController;
  std::optional<flutter::Isolate> _isolate;
  FlutterWindowCreationRequest _creationRequest;

  // Extra size constraints coming from the window positioner.
  CGSize _positionerSizeConstraints;
}

@property(readonly, nonatomic) NSWindow* window;
@property(readonly, nonatomic) FlutterViewController* flutterViewController;
@property(readwrite, nonatomic) BOOL closeWhenParentResignsKey;

- (instancetype)initWithWindow:(NSWindow*)window
         flutterViewController:(FlutterViewController*)viewController
               creationRequest:(const FlutterWindowCreationRequest&)creationRequest;

@end

@interface NSWindow (FlutterWindowSizing)

- (void)flutterSetContentSize:(FlutterWindowSize)contentSize;
- (void)flutterSetConstraints:(FlutterWindowConstraints)constraints;

@end

@implementation NSWindow (FlutterWindowSizing)
- (void)flutterSetContentSize:(FlutterWindowSize)contentSize {
  [self setContentSize:NSMakeSize(contentSize.width, contentSize.height)];
}

- (void)flutterSetConstraints:(FlutterWindowConstraints)constraints {
  NSSize size = [self frameRectForContentRect:self.frame].size;
  NSSize originalSize = size;
  [self setContentMinSize:NSMakeSize(constraints.min_width, constraints.min_height)];
  size.width = std::max(size.width, constraints.min_width);
  size.height = std::max(size.height, constraints.min_height);
  if (constraints.max_width > 0 && constraints.max_height > 0) {
    [self setContentMaxSize:NSMakeSize(constraints.max_width, constraints.max_height)];
    size.width = std::min(size.width, constraints.max_width);
    size.height = std::min(size.height, constraints.max_height);
  } else {
    [self setContentMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
  }
  if (!NSEqualSizes(originalSize, size)) {
    [self setContentSize:size];
  }
}

@end

@interface FlutterWindowController () {
  NSMutableArray<FlutterWindowOwner*>* _windows;
}

- (void)windowDidResignKey:(FlutterWindowOwner*)window;

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
  [[_flutterViewController.engine windowController] windowDidResignKey:self];
}

- (BOOL)windowShouldClose:(NSWindow*)sender {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.on_should_close();
  return NO;
}

- (void)windowWillClose {
  _creationRequest.on_will_close();
}

- (void)windowDidResize:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.notify_listeners();
}

// Miniaturize does not trigger resize event, but for now there
// is no other way to get notification about the state change.
- (void)windowDidMiniaturize:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.notify_listeners();
}

// Deminiaturize does not trigger resize event, but for now there
// is no other way to get notification about the state change.
- (void)windowDidDeminiaturize:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.notify_listeners();
}

- (void)windowWillEnterFullScreen:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.notify_listeners();
}

- (void)windowWillExitFullScreen:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(*_isolate);
  _creationRequest.notify_listeners();
}

- (std::optional<NSSize>)minimumViewSize:(FlutterView*)view {
  if (_creationRequest.has_constraints) {
    return NSMakeSize(_creationRequest.constraints.min_width,
                      _creationRequest.constraints.min_height);
  } else {
    return std::nullopt;
  }
}

- (std::optional<NSSize>)maximumViewSize:(FlutterView*)view {
  if (!_creationRequest.has_constraints) {
    // Window is not sized to contents.
    return std::nullopt;
  }
  NSSize screenSize = self.window.screen.visibleFrame.size;
  double width = screenSize.width;
  width = std::min(width, _creationRequest.constraints.max_width);
  if (_positionerSizeConstraints.width > 0) {
    width = std::min(width, _positionerSizeConstraints.width);
  }
  double height = screenSize.height;
  height = std::min(height, _creationRequest.constraints.max_height);
  if (_positionerSizeConstraints.height > 0) {
    height = std::min(height, _positionerSizeConstraints.height);
  }
  return NSMakeSize(width, height);
}

// Returns the frame that includes all screen. This is used to flip coordinates
// of individual screen to match Flutter coordinate system.
static NSRect ComputeGlobalScreenFrame() {
  NSRect frame = NSZeroRect;
  for (NSScreen* screen in [NSScreen screens]) {
    NSRect screenFrame = screen.frame;
    if (NSIsEmptyRect(frame)) {
      frame = screenFrame;
    } else {
      frame = NSUnionRect(frame, screenFrame);
    }
  }
  return frame;
}

static void FlipRect(NSRect& rect, const NSRect& globalScreenFrame) {
  // Flip the y coordinate to match Flutter coordinate system.
  rect.origin.y = (globalScreenFrame.origin.y + globalScreenFrame.size.height) -
                  (rect.origin.y + rect.size.height);
}

- (void)updatePosition {
  [self viewDidUpdateContents:self.flutterViewController.flutterView
                     withSize:self.flutterViewController.flutterView.bounds.size];
}

- (void)viewDidUpdateContents:(FlutterView*)view withSize:(NSSize)newSize {
  if (_creationRequest.on_get_window_position == nullptr) {
    // There is no positioner associated with this window.
    return;
  }

  NSRect globalScreenFrame = ComputeGlobalScreenFrame();

  NSRect parentRect =
      [self.window.parentWindow contentRectForFrameRect:self.window.parentWindow.frame];
  FlipRect(parentRect, globalScreenFrame);

  NSRect screenRect = [self.window.screen visibleFrame];
  FlipRect(screenRect, globalScreenFrame);

  flutter::IsolateScope isolate_scope(*_isolate);
  auto position = _creationRequest.on_get_window_position(
      FlutterWindowSize::fromNSSize(newSize), FlutterWindowRect::fromNSRect(parentRect),
      FlutterWindowRect::fromNSRect(screenRect));

  NSRect positionRect = position->toNSRect();
  FlipRect(positionRect, globalScreenFrame);

  [self.window setFrame:positionRect display:NO animate:NO];

  free(position);

  // For windows sized to contents if the positioner size doesn't match actual size
  // the requested size needs to be passed through constraints.
  if (view.sizedToContents &&
      (positionRect.size.width < newSize.width || positionRect.size.height < newSize.height)) {
    _positionerSizeConstraints = positionRect.size;
    [view constraintsDidChange];
  } else {
    // Only show the window initially if positioner agrees with the size.
    self.window.alphaValue = 1.0;
  }
}

- (void)setConstraints:(FlutterWindowConstraints)constraints {
  if (_flutterViewController.flutterView.sizedToContents) {
    self->_creationRequest.constraints = constraints;
    [_flutterViewController.flutterView constraintsDidChange];
  } else {
    [self.window flutterSetConstraints:constraints];
  }
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

- (FlutterViewIdentifier)createDialogWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:_engine
                                                                            nibName:nil
                                                                             bundle:nil];

  NSWindow* window = [[NSWindow alloc] init];
  // If this is not set there will be double free on window close when
  // using ARC.
  [window setReleasedWhenClosed:NO];

  window.contentViewController = controller;
  window.styleMask =
      NSWindowStyleMaskResizable | NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
  window.collectionBehavior = NSWindowCollectionBehaviorFullScreenAuxiliary;
  if (request->has_size) {
    [window flutterSetContentSize:request->size];
  }
  if (request->has_constraints) {
    [window flutterSetConstraints:request->constraints];
  }

  FlutterWindowOwner* owner = [[FlutterWindowOwner alloc] initWithWindow:window
                                                   flutterViewController:controller
                                                         creationRequest:*request];
  window.delegate = owner;
  [_windows addObject:owner];

  NSWindow* parent = nil;

  if (request->parent_view_id != 0) {
    for (FlutterWindowOwner* owner in _windows) {
      if (owner.flutterViewController.viewIdentifier == request->parent_view_id) {
        parent = owner.window;
        break;
      }
    }
    if (parent == nil) {
      FML_LOG(WARNING) << "Failed to find parent window for ID " << request->parent_view_id;
    }
  }

  if (parent != nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      // beginCriticalSheet blocks with nested run loop until the
      // sheet animation is finished.
      [parent beginCriticalSheet:window
               completionHandler:^(NSModalResponse response){
               }];
    });

  } else {
    [window setIsVisible:YES];
    [window makeKeyAndOrderFront:nil];
  }

  return controller.viewIdentifier;
}

- (FlutterViewIdentifier)createTooltipWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:_engine
                                                                            nibName:nil
                                                                             bundle:nil];

  NSWindow* window = [[NSWindow alloc] init];
  // If this is not set there will be double free on window close when
  // using ARC.
  [window setReleasedWhenClosed:NO];

  window.contentViewController = controller;
  window.styleMask = NSWindowStyleMaskBorderless;
  window.hasShadow = NO;
  window.opaque = NO;
  window.backgroundColor = [NSColor clearColor];

  FlutterWindowOwner* owner = [[FlutterWindowOwner alloc] initWithWindow:window
                                                   flutterViewController:controller
                                                         creationRequest:*request];

  controller.flutterView.sizingDelegate = owner;
  controller.flutterView.backgroundColor = [NSColor clearColor];
  // Resend configure event after setting the sizing delegate.
  [controller.flutterView constraintsDidChange];
  owner.closeWhenParentResignsKey = YES;

  window.delegate = owner;
  [_windows addObject:owner];

  NSWindow* parent = nil;

  if (request->parent_view_id != 0) {
    for (FlutterWindowOwner* owner in _windows) {
      if (owner.flutterViewController.viewIdentifier == request->parent_view_id) {
        parent = owner.window;
        break;
      }
    }
  }

  NSAssert(parent != nil, @"Tooltip window must have a parent window.");

  window.ignoresMouseEvents = YES;
  window.collectionBehavior = NSWindowCollectionBehaviorAuxiliary;
  [parent addChildWindow:window ordered:NSWindowAbove];
  window.alphaValue = 0.0;
  return controller.viewIdentifier;
}

- (FlutterViewIdentifier)createRegularWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:_engine
                                                                            nibName:nil
                                                                             bundle:nil];

  NSWindow* window = [[NSWindow alloc] init];
  // If this is not set there will be double free on window close when
  // using ARC.
  [window setReleasedWhenClosed:NO];

  window.contentViewController = controller;
  window.styleMask = NSWindowStyleMaskResizable | NSWindowStyleMaskTitled |
                     NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
  if (request->has_size) {
    [window flutterSetContentSize:request->size];
  }
  if (request->has_constraints) {
    [window flutterSetConstraints:request->constraints];
  }
  [window setIsVisible:YES];
  [window makeKeyAndOrderFront:nil];

  FlutterWindowOwner* owner = [[FlutterWindowOwner alloc] initWithWindow:window
                                                   flutterViewController:controller
                                                         creationRequest:*request];
  window.delegate = owner;
  [_windows addObject:owner];

  return controller.viewIdentifier;
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
    for (NSWindow* win in owner.window.sheets) {
      [self destroyWindow:win];
    }

    for (NSWindow* win in owner.window.childWindows) {
      [self destroyWindow:win];
    }
    // Make sure to unregister the controller from the engine and remove the FlutterView
    // before destroying the window and Flutter NSView.
    [owner.flutterViewController dispose];
    owner.window.delegate = nil;
    [owner.window close];
    [owner windowWillClose];
  }
}

- (void)closeAllWindows {
  for (FlutterWindowOwner* owner in _windows) {
    [owner.flutterViewController dispose];
    [owner.window close];
  }
  [_windows removeAllObjects];
}

static BOOL IsChildAncestor(NSWindow* child, NSWindow* ancestor) {
  NSWindow* current = child.parentWindow;
  while (current) {
    if (current == ancestor) {
      return YES;
    }
    current = current.parentWindow;
  }

  return NO;
}

- (void)windowDidResignKey:(FlutterWindowOwner*)parent {
  for (FlutterWindowOwner* possibleChild in _windows) {
    if (possibleChild.closeWhenParentResignsKey &&
        IsChildAncestor(possibleChild.window, parent.window)) {
      [possibleChild windowShouldClose:possibleChild.window];
    }
  }
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

int64_t InternalFlutter_WindowController_CreateDialogWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine enableMultiView];
  return [engine.windowController createDialogWindow:request];
}

int64_t InternalFlutter_WindowController_CreateTooltipWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine enableMultiView];
  return [engine.windowController createTooltipWindow:request];
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
  NSRect contentRect = [w contentRectForFrameRect:w.frame];
  return {
      .width = contentRect.size.width,
      .height = contentRect.size.height,
  };
}

void InternalFlutter_Window_SetContentSize(void* window, const FlutterWindowSize* size) {
  NSWindow* w = (__bridge NSWindow*)window;
  [w flutterSetContentSize:*size];
}

FLUTTER_DARWIN_EXPORT
void InternalFlutter_Window_SetConstraints(void* window,
                                           const FlutterWindowConstraints* constraints) {
  NSWindow* w = (__bridge NSWindow*)window;
  FlutterWindowOwner* owner = (FlutterWindowOwner*)w.delegate;
  [owner setConstraints:*constraints];
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

char* InternalFlutter_Window_GetTitle(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  return strdup(w.title.UTF8String);
}

bool InternalFlutter_Window_IsActivated(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  return w.isKeyWindow;
}

void InternalFlutter_Window_UpdatePosition(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  FlutterWindowOwner* owner = (FlutterWindowOwner*)w.delegate;
  [owner updatePosition];
}

// NOLINTEND(google-objc-function-naming)
