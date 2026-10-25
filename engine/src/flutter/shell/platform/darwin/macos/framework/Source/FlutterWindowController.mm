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
@interface FlutterWindowOwner
    : NSObject <NSWindowDelegate, FlutterViewContentDelegate, FlutterViewSizingDelegate> {
  // Strong reference to the window. This is the only strong reference to the
  // window.
  NSWindow* _window;
  FlutterViewController* _flutterViewController;
  std::optional<flutter::Isolate> _isolate;
  FlutterWindowCreationRequest _creationRequest;

  // Window geometry pushed by the framework via
  // InternalFlutter_Window_SetContentRect and
  // InternalFlutter_Window_SetContentSize. Size changes are pending until they
  // are applied in viewDidUpdateContents, i.e. on the surface commit, so that
  // resizing the window and swapping in the corresponding surface happen in
  // the same hop. Otherwise the window would be resized while the layer still
  // presents a surface sized for the previous metrics. The pending rect is in
  // Flutter global coordinates and its size is already clamped.
  std::optional<FlutterWindowRect> _pendingContentRect;
  std::optional<NSSize> _pendingContentSize;

  // Set when the view constraints changed while a size changing geometry is
  // pending. The view metrics are regenerated once the geometry is applied:
  // regenerating earlier would report a width and height outside the newly
  // set constraints.
  BOOL _constraintsDidChangePending;

  // Set when the framework finished sizing the window to its content while a
  // size change is pending. The sizing delegate is removed once the size has
  // been applied.
  BOOL _sizingCompletePending;
}

@property(readonly, nonatomic) NSWindow* window;
@property(readonly, nonatomic) FlutterViewController* flutterViewController;
@property(readwrite, nonatomic) BOOL closeWhenParentResignsKey;
@property(readwrite, nonatomic) dispatch_block_t onFirstFrame;

- (instancetype)initWithWindow:(NSWindow*)window
         flutterViewController:(FlutterViewController*)viewController
               creationRequest:(const FlutterWindowCreationRequest&)creationRequest;

- (void)setPendingContentRect:(FlutterWindowRect)contentRect;
- (void)setPendingContentSize:(FlutterWindowSize)contentSize;
- (void)sizingComplete;

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
  BOOL _runLoopModeFixApplied;
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
  NSScreen* screen = self.window.parentWindow.screen ?: self.window.screen;
  if (screen == nil) {
    // The window is not on screen yet. Without a display there is no
    // meaningful maximum; FlutterView.maximumContentSize falls back to the
    // current bounds in that case, which keeps the metrics valid.
    return std::nullopt;
  }
  NSSize screenSize = screen.visibleFrame.size;
  double width = std::min(screenSize.width, _creationRequest.constraints.max_width);
  double height = std::min(screenSize.height, _creationRequest.constraints.max_height);
  // Keep the constraints feasible: the maximum must never go below the
  // minimum, the engine rejects metrics otherwise.
  std::optional<NSSize> minimumSize = [self minimumViewSize:view];
  if (minimumSize) {
    width = std::max(width, minimumSize->width);
    height = std::max(height, minimumSize->height);
  }
  return NSMakeSize(width, height);
}

// Clamps a content size into the view size constraints. The applied window
// size must never be outside the constraints that are reported with the
// window metrics since the engine rejects those metrics.
- (NSSize)clampContentSizeToConstraints:(NSSize)contentSize {
  if (!_flutterViewController.flutterView.sizedToContents) {
    return contentSize;
  }
  const FlutterWindowConstraints& constraints = _creationRequest.constraints;
  // Without a screen there is no view maximum; the requested constraints
  // still apply.
  NSSize maximumSize = [self maximumViewSize:_flutterViewController.flutterView].value_or(
      NSMakeSize(constraints.max_width, constraints.max_height));
  contentSize.width =
      std::max(std::min(contentSize.width, maximumSize.width), constraints.min_width);
  contentSize.height =
      std::max(std::min(contentSize.height, maximumSize.height), constraints.min_height);
  return contentSize;
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

- (NSSize)currentContentSize {
  return [self.window contentRectForFrameRect:self.window.frame].size;
}

- (BOOL)hasPendingGeometry {
  return _pendingContentRect || _pendingContentSize;
}

// Whether a size change must wait for the surface commit. Only views sized to
// their contents need this; other views are resized through the resize
// synchronizer, which waits for a frame of the new size by itself.
- (BOOL)shouldDeferResizeTo:(NSSize)size {
  return _flutterViewController.flutterView.sizedToContents &&
         !NSEqualSizes(size, self.currentContentSize);
}

// Moves the window so that its content rect matches the given rect in Flutter
// global coordinates.
- (void)applyContentRect:(FlutterWindowRect)contentRect {
  NSRect rect = contentRect.toNSRect();
  FlipRect(rect, ComputeGlobalScreenFrame());
  [self.window setFrame:[self.window frameRectForContentRect:rect] display:NO animate:NO];
}

- (void)setPendingContentRect:(FlutterWindowRect)contentRect {
  NSSize size =
      [self clampContentSizeToConstraints:NSMakeSize(contentRect.width, contentRect.height)];
  contentRect.width = size.width;
  contentRect.height = size.height;
  if (![self shouldDeferResizeTo:size]) {
    // Supersede any pending rect since this is the latest intent.
    _pendingContentRect.reset();
    [self applyContentRect:contentRect];
    return;
  }
  // Defer until the surface is committed so that resizing the window and
  // presenting the corresponding surface are synchronized.
  _pendingContentRect = contentRect;
}

- (void)setPendingContentSize:(FlutterWindowSize)contentSize {
  NSSize size =
      [self clampContentSizeToConstraints:NSMakeSize(contentSize.width, contentSize.height)];
  if (![self shouldDeferResizeTo:size]) {
    // Supersede any pending size since this is the latest intent.
    _pendingContentSize.reset();
    [self.window setContentSize:size];
    return;
  }
  // Size change: defer until the surface is committed, see
  // setPendingContentRect:.
  _pendingContentSize = size;
}

- (void)sizingComplete {
  if (self.hasPendingGeometry) {
    _sizingCompletePending = YES;
  } else {
    [self removeSizingDelegate];
  }
}

// Hands the window size over to the user. The view metrics are regenerated so
// that the framework lays out to the window size instead of the content.
- (void)removeSizingDelegate {
  FlutterView* view = _flutterViewController.flutterView;
  view.sizingDelegate = nil;
  [view constraintsDidChange];
}

// Applies the geometry pushed by the framework. This must only be called from
// viewDidUpdateContents, i.e. when a surface has just been committed, so that
// the window is never resized while the layer displays a surface that does not
// match the new size.
- (void)applyPendingGeometry {
  if (_pendingContentSize) {
    [self.window setContentSize:*_pendingContentSize];
    _pendingContentSize.reset();
  }
  if (_pendingContentRect) {
    [self applyContentRect:*_pendingContentRect];
    _pendingContentRect.reset();
  }
  if (_sizingCompletePending) {
    // Removing the sizing delegate regenerates the metrics, which also covers
    // a pending constraints change.
    _sizingCompletePending = NO;
    _constraintsDidChangePending = NO;
    [self removeSizingDelegate];
  }
  if (_constraintsDidChangePending) {
    // The window size has been applied; it is safe to regenerate the view
    // metrics now, they will be within the constraints.
    _constraintsDidChangePending = NO;
    [_flutterViewController.flutterView constraintsDidChange];
  }
}

- (void)viewDidUpdateContents:(FlutterView*)view withSize:(NSSize)newSize {
  // The framework owns the window geometry: it pushes the window position and
  // size from the window controller's updateContentSize using
  // InternalFlutter_Window_SetContentRect and
  // InternalFlutter_Window_SetContentSize. Geometry that does not change the
  // size is applied right away when it is pushed; geometry that changes the
  // size is queued and applied here, on the surface commit, so that resizing
  // the window and presenting the corresponding surface are synchronized.
  [self applyPendingGeometry];
  // Reveal the window once the pushed geometry has been applied. The reveal
  // must not additionally wait for a surface that matches the window size:
  // for content that resizes continuously the surface is always one frame
  // behind the window size and the window would never be revealed.
  if (!self.hasPendingGeometry && self.onFirstFrame) {
    self.onFirstFrame();
    self.onFirstFrame = nil;
  }
}

- (void)setConstraints:(FlutterWindowConstraints)constraints {
  if (_flutterViewController.flutterView.sizedToContents) {
    self->_creationRequest.constraints = constraints;
    if (self.hasPendingGeometry) {
      // A size change is pending; regenerate the view metrics only once it has
      // been applied, they would otherwise be outside the newly set
      // constraints.
      _constraintsDidChangePending = YES;
    } else {
      [_flutterViewController.flutterView constraintsDidChange];
    }
  } else {
    [self.window flutterSetConstraints:constraints];
  }
}

@end

@interface FlutterPopupWindow : NSPanel
@end

@implementation FlutterPopupWindow

- (BOOL)canBecomeKeyWindow {
  return NO;
}

- (BOOL)acceptsFirstResponder {
  return NO;
}

- (BOOL)canBecomeMainWindow {
  return NO;
}

@end

// Satellite window will only become key window when Flutter explicitly
// request the view to be first responder.
@interface FlutterSatelliteWindow : NSPanel {
  BOOL _canBecomeKeyWindow;
}
@end

@implementation FlutterSatelliteWindow

- (BOOL)canBecomeKeyWindow {
  return _canBecomeKeyWindow;
}

- (BOOL)acceptsFirstResponder {
  return NO;
}

- (BOOL)canBecomeMainWindow {
  return NO;
}

- (BOOL)makeFirstResponder:(NSResponder*)responder {
  _canBecomeKeyWindow = YES;
  return [super makeFirstResponder:responder];
}

- (void)resignKeyWindow {
  _canBecomeKeyWindow = NO;
  [super resignKeyWindow];
}

@end

@interface _FlutterRunLoopModeFixWindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation _FlutterRunLoopModeFixWindowDelegate

- (NSRect)windowWillUseStandardFrame:(NSWindow*)window defaultFrame:(NSRect)newFrame {
  // Small frame difference (100px to 110px) to trigger the animation but make it fast.
  newFrame.size.width = 110;
  newFrame.size.height = 110;
  return newFrame;
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

- (void)fixMoveRunLoopModeIfNeeded {
  if (_runLoopModeFixApplied) {
    return;
  }
  // When modal sheet is presented, for the duration of the animation the run loop
  // is running in _NSMoveTimerRunLoopMode. This prevents Flutter content from
  // being rendered. The solution is to add _NSMoveTimerRunLoopMode to common
  // run loop modes, but referencing it directly may be flagged as SPI usage.
  // Instead as a workaround a very short window zoom animation is triggered, which
  // runs in _NSMoveTimerRunLoopMode adding the mode to CFRunLoop all modes list.
  // After that it can be queried and added to common modes.
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                 styleMask:NSWindowStyleMaskResizable
                                                   backing:NSBackingStoreNonretained
                                                     defer:NO];
  _FlutterRunLoopModeFixWindowDelegate* delegate =
      [[_FlutterRunLoopModeFixWindowDelegate alloc] init];
  window.releasedWhenClosed = NO;
  window.delegate = delegate;
  window.ignoresMouseEvents = YES;
  window.alphaValue = 0;
  [window orderFront:nil];
  [window zoom:nil];
  [window close];
  NSArray* modes = (__bridge_transfer NSArray*)CFRunLoopCopyAllModes(CFRunLoopGetCurrent());
  for (NSString* mode in modes) {
    if ([mode hasSuffix:@"MoveTimerRunLoopMode"]) {
      CFRunLoopAddCommonMode(CFRunLoopGetCurrent(), (__bridge CFStringRef)mode);
    }
  }
  _runLoopModeFixApplied = YES;
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
  window.styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
  if (request->resizable) {
    window.styleMask |= NSWindowStyleMaskResizable;
  }

  window.collectionBehavior = NSWindowCollectionBehaviorFullScreenAuxiliary;
  if (request->has_size) {
    [window flutterSetContentSize:request->size];
  }
  if (request->resizable && request->has_constraints) {
    [window flutterSetConstraints:request->constraints];
  }

  FlutterWindowOwner* owner = [[FlutterWindowOwner alloc] initWithWindow:window
                                                   flutterViewController:controller
                                                         creationRequest:*request];
  window.delegate = owner;
  [_windows addObject:owner];

  if (!request->has_size) {
    controller.flutterView.sizingDelegate = owner;
    [controller.flutterView constraintsDidChange];
  }
  controller.flutterView.contentDelegate = owner;

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

  FML_DCHECK(owner.onFirstFrame == nil);
  owner.onFirstFrame = ^{
    if (parent != nil) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self fixMoveRunLoopModeIfNeeded];
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
  };

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
  controller.flutterView.contentDelegate = owner;
  controller.flutterView.backgroundColor = [NSColor clearColor];
  // Resend configure event after setting the sizing delegate.
  [controller.flutterView constraintsDidChange];
  owner.closeWhenParentResignsKey = YES;

  window.delegate = owner;
  [_windows addObject:owner];

  NSWindow* parent = nil;

  FML_DCHECK(request->parent_view_id != 0);
  for (FlutterWindowOwner* owner in _windows) {
    if (owner.flutterViewController.viewIdentifier == request->parent_view_id) {
      parent = owner.window;
      break;
    }
  }

  NSAssert(parent != nil, @"Tooltip window must have a parent window.");

  window.ignoresMouseEvents = YES;
  window.collectionBehavior = NSWindowCollectionBehaviorAuxiliary;
  [parent addChildWindow:window ordered:NSWindowAbove];
  window.alphaValue = 0.0;

  FML_DCHECK(owner.onFirstFrame == nil);
  owner.onFirstFrame = ^{
    window.alphaValue = 1.0;
  };

  return controller.viewIdentifier;
}

- (FlutterViewIdentifier)createPopupWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:_engine
                                                                            nibName:nil
                                                                             bundle:nil];
  // By default this is kFlutterMouseTrackingModeInKeyWindow but popup window is never
  // key window.
  controller.mouseTrackingMode = kFlutterMouseTrackingModeInActiveApp;

  NSWindow* window = [[FlutterPopupWindow alloc] init];
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
  controller.flutterView.contentDelegate = owner;
  [controller.flutterView setBackgroundColor:[NSColor clearColor]];
  // Resend configure event after setting the sizing delegate.
  [controller.flutterView constraintsDidChange];
  owner.closeWhenParentResignsKey = NO;

  window.delegate = owner;
  [_windows addObject:owner];

  NSWindow* parent = nil;

  FML_DCHECK(request->parent_view_id != 0);
  for (FlutterWindowOwner* owner in _windows) {
    if (owner.flutterViewController.viewIdentifier == request->parent_view_id) {
      parent = owner.window;
      break;
    }
  }

  NSAssert(parent != nil, @"Popup window must have a parent window.");

  window.collectionBehavior = NSWindowCollectionBehaviorAuxiliary;
  [parent addChildWindow:window ordered:NSWindowAbove];
  window.alphaValue = 0.0;

  FML_DCHECK(owner.onFirstFrame == nil);
  owner.onFirstFrame = ^{
    window.alphaValue = 1.0;
  };

  return controller.viewIdentifier;
}

- (FlutterViewIdentifier)createSatelliteWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:_engine
                                                                            nibName:nil
                                                                             bundle:nil];

  NSPanel* window = [[FlutterSatelliteWindow alloc] init];
  // If this is not set there will be double free on window close when
  // using ARC.
  [window setReleasedWhenClosed:NO];

  window.contentViewController = controller;
  window.styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                     NSWindowStyleMaskUtilityWindow | NSWindowStyleMaskNonactivatingPanel;
  if (request->resizable) {
    window.styleMask |= NSWindowStyleMaskResizable;
  }

  window.collectionBehavior = NSWindowCollectionBehaviorAuxiliary |
                              NSWindowCollectionBehaviorTransient |
                              NSWindowCollectionBehaviorMoveToActiveSpace;
  window.hidesOnDeactivate = YES;
  window.floatingPanel = YES;
  // Without this the satellite immediately steals focus from the parent.
  window.becomesKeyOnlyIfNeeded = YES;

  if (request->has_size) {
    [window flutterSetContentSize:request->size];
  }
  if (request->resizable && request->has_constraints) {
    [window flutterSetConstraints:request->constraints];
  }

  FlutterWindowOwner* owner = [[FlutterWindowOwner alloc] initWithWindow:window
                                                   flutterViewController:controller
                                                         creationRequest:*request];

  controller.flutterView.contentDelegate = owner;

  if (!request->has_size) {
    controller.flutterView.sizingDelegate = owner;
    [controller.flutterView constraintsDidChange];
  }

  window.delegate = owner;
  [_windows addObject:owner];

  NSWindow* parent = nil;
  FML_DCHECK(request->parent_view_id != 0);
  for (FlutterWindowOwner* owner in _windows) {
    if (owner.flutterViewController.viewIdentifier == request->parent_view_id) {
      parent = owner.window;
      break;
    }
  }

  NSAssert(parent != nil, @"Satellite window must have a parent window.");

  [parent addChildWindow:window ordered:NSWindowAbove];
  window.alphaValue = 0.0;

  FML_DCHECK(owner.onFirstFrame == nil);
  owner.onFirstFrame = ^{
    window.alphaValue = 1.0;
  };

  return controller.viewIdentifier;
}

- (void)reparentWindow:(NSWindow*)window newParentId:(int64_t)parentViewId {
  NSWindow* parent = nil;

  for (FlutterWindowOwner* owner in _windows) {
    if (owner.flutterViewController.viewIdentifier == parentViewId) {
      parent = owner.window;
      break;
    }
  }

  FML_CHECK(parent != nil);

  // Check if the new parent is not a child of the window being reparented.
  NSWindow* child = parent;
  while (child != nil) {
    if (child == window) {
      NSLog(@"Cannot reparent to a child window.");
      return;
    }
    child = child.parentWindow;
  }

  if (parent != window.parentWindow) {
    [window.parentWindow removeChildWindow:window];
    [parent addChildWindow:window ordered:NSWindowAbove];
  }
}

- (FlutterViewIdentifier)createRegularWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:_engine
                                                                            nibName:nil
                                                                             bundle:nil];

  NSWindow* window = [[NSWindow alloc] init];
  // If this is not set there will be double free on window close when
  // using ARC.
  [window setReleasedWhenClosed:NO];

  window.styleMask =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
  if (request->resizable) {
    window.styleMask |= NSWindowStyleMaskResizable;
  }

  window.contentViewController = controller;

  if (request->has_size) {
    [window flutterSetContentSize:request->size];
  }
  if (request->resizable && request->has_constraints) {
    [window flutterSetConstraints:request->constraints];
  }

  FlutterWindowOwner* owner = [[FlutterWindowOwner alloc] initWithWindow:window
                                                   flutterViewController:controller
                                                         creationRequest:*request];

  controller.flutterView.contentDelegate = owner;

  if (!request->has_size) {
    controller.flutterView.sizingDelegate = owner;
    [controller.flutterView constraintsDidChange];
  }

  window.delegate = owner;
  [_windows addObject:owner];

  FML_DCHECK(owner.onFirstFrame == nil);
  owner.onFirstFrame = ^{
    [window setIsVisible:YES];
    [window makeKeyAndOrderFront:nil];
  };

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

int64_t InternalFlutter_WindowController_CreateSatelliteWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine enableMultiView];
  return [engine.windowController createSatelliteWindow:request];
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

int64_t InternalFlutter_WindowController_CreatePopupWindow(
    int64_t engine_id,
    const FlutterWindowCreationRequest* request) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine enableMultiView];
  return [engine.windowController createPopupWindow:request];
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
  FlutterWindowOwner* owner = (FlutterWindowOwner*)w.delegate;
  [owner setPendingContentSize:*size];
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

void InternalFlutter_Window_Reparent(int64_t engineId, void* window, int64_t newParentId) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engineId];
  NSWindow* w = (__bridge NSWindow*)window;
  [engine.windowController reparentWindow:w newParentId:newParentId];
}

FlutterWindowOffset InternalFlutter_Window_GetOffsetInParent(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  NSWindow* parent = w.parentWindow;
  if (!parent) {
    return {0, 0};
  }
  NSRect globalScreenFrame = ComputeGlobalScreenFrame();

  NSRect parentRect = [parent contentRectForFrameRect:parent.frame];
  FlipRect(parentRect, globalScreenFrame);

  NSRect childRect = w.frame;
  FlipRect(childRect, globalScreenFrame);

  return {
      .x = childRect.origin.x - parentRect.origin.x,
      .y = childRect.origin.y - parentRect.origin.y,
  };
}

void InternalFlutter_Window_SetContentRect(void* window, const FlutterWindowRect* rect) {
  NSWindow* w = (__bridge NSWindow*)window;
  FlutterWindowOwner* owner = (FlutterWindowOwner*)w.delegate;
  [owner setPendingContentRect:*rect];
}

FlutterWindowRect InternalFlutter_Window_ParentContentRect(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  NSWindow* parent = w.parentWindow;
  if (!parent) {
    return {0, 0, 0, 0};
  }
  NSRect globalScreenFrame = ComputeGlobalScreenFrame();
  NSRect parentRect = [parent contentRectForFrameRect:parent.frame];
  FlipRect(parentRect, globalScreenFrame);
  return FlutterWindowRect::fromNSRect(parentRect);
}

FlutterWindowRect InternalFlutter_Window_ScreenVisibleFrame(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  NSScreen* screen = w.parentWindow.screen ?: w.screen;
  if (!screen) {
    return {0, 0, 0, 0};
  }
  NSRect globalScreenFrame = ComputeGlobalScreenFrame();
  NSRect visibleFrame = screen.visibleFrame;
  FlipRect(visibleFrame, globalScreenFrame);
  return FlutterWindowRect::fromNSRect(visibleFrame);
}

void InternalFlutter_Window_SizingComplete(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  FlutterWindowOwner* owner = (FlutterWindowOwner*)w.delegate;
  [owner sizingComplete];
}

// NOLINTEND(google-objc-function-naming)
