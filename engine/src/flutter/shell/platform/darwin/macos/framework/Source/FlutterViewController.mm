// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#include <Carbon/Carbon.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyPrimaryResponder.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyboardManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMetalRenderer.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterOpenGLRenderer.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderingBackend.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputSemanticsObject.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#import "flutter/shell/platform/embedder/embedder.h"

namespace {
using flutter::KeyboardLayoutNotifier;
using flutter::LayoutClue;

// Use different device ID for mouse and pan/zoom events, since we can't differentiate the actual
// device (mouse v.s. trackpad).
static constexpr int32_t kMousePointerDeviceId = 0;
static constexpr int32_t kPointerPanZoomDeviceId = 1;

/**
 * State tracking for mouse events, to adapt between the events coming from the system and the
 * events that the embedding API expects.
 */
struct MouseState {
  /**
   * Whether or not a kAdd event has been sent (or sent again since the last kRemove if tracking is
   * enabled). Used to determine whether to send a kAdd event before sending an incoming mouse
   * event, since Flutter expects pointers to be added before events are sent for them.
   */
  bool flutter_state_is_added = false;

  /**
   * Whether or not a kDown has been sent since the last kAdd/kUp.
   */
  bool flutter_state_is_down = false;

  /**
   * Whether or not mouseExited: was received while a button was down. Cocoa's behavior when
   * dragging out of a tracked area is to send an exit, then keep sending drag events until the last
   * button is released. Flutter doesn't expect to receive events after a kRemove, so the kRemove
   * for the exit needs to be delayed until after the last mouse button is released. If cursor
   * returns back to the window while still dragging, the flag is cleared in mouseEntered:.
   */
  bool has_pending_exit = false;

  /**
   * The currently pressed buttons, as represented in FlutterPointerEvent.
   */
  int64_t buttons = 0;

  /**
   * Pan gesture is currently sending us events.
   */
  bool pan_gesture_active = false;

  /**
   * The accumulated gesture pan.
   */
  CGFloat delta_x = 0;
  CGFloat delta_y = 0;

  /**
   * Scale gesture is currently sending us events.
   */
  bool scale_gesture_active = false;

  /**
   * The accumulated gesture zoom scale.
   */
  CGFloat scale = 0;

  /**
   * Rotate gesture is currently sending use events.
   */
  bool rotate_gesture_active = false;

  /**
   * The accumulated gesture rotation.
   */
  CGFloat rotation = 0;

  /**
   * Resets all gesture state to default values.
   */
  void GestureReset() {
    delta_x = 0;
    delta_y = 0;
    scale = 0;
    rotation = 0;
  }

  /**
   * Resets all state to default values.
   */
  void Reset() {
    flutter_state_is_added = false;
    flutter_state_is_down = false;
    has_pending_exit = false;
    buttons = 0;
    GestureReset();
  }
};

/**
 * Returns the current Unicode layout data (kTISPropertyUnicodeKeyLayoutData).
 *
 * To use the returned data, convert it to CFDataRef first, finds its bytes
 * with CFDataGetBytePtr, then reinterpret it into const UCKeyboardLayout*.
 * It's returned in NSData* to enable auto reference count.
 */
NSData* currentKeyboardLayoutData() {
  TISInputSourceRef source = TISCopyCurrentKeyboardInputSource();
  CFTypeRef layout_data = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData);
  if (layout_data == nil) {
    CFRelease(source);
    // TISGetInputSourceProperty returns null with Japanese keyboard layout.
    // Using TISCopyCurrentKeyboardLayoutInputSource to fix NULL return.
    // https://github.com/microsoft/node-native-keymap/blob/5f0699ded00179410a14c0e1b0e089fe4df8e130/src/keyboard_mac.mm#L91
    source = TISCopyCurrentKeyboardLayoutInputSource();
    layout_data = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData);
  }
  return (__bridge_transfer NSData*)CFRetain(layout_data);
}

}  // namespace

#pragma mark - Private interface declaration.

/**
 * FlutterViewWrapper is a convenience class that wraps a FlutterView and provides
 * a mechanism to attach AppKit views such as FlutterTextField without affecting
 * the accessibility subtree of the wrapped FlutterView itself.
 *
 * The FlutterViewController uses this class to create its content view. When
 * any of the accessibility services (e.g. VoiceOver) is turned on, the accessibility
 * bridge creates FlutterTextFields that interact with the service. The bridge has to
 * attach the FlutterTextField somewhere in the view hierarchy in order for the
 * FlutterTextField to interact correctly with VoiceOver. Those FlutterTextFields
 * will be attached to this view so that they won't affect the accessibility subtree
 * of FlutterView.
 */
@interface FlutterViewWrapper : NSView

@end

/**
 * Private interface declaration for FlutterViewController.
 */
@interface FlutterViewController () <FlutterViewReshapeListener>

/**
 * The tracking area used to generate hover events, if enabled.
 */
@property(nonatomic) NSTrackingArea* trackingArea;

/**
 * The current state of the mouse and the sent mouse events.
 */
@property(nonatomic) MouseState mouseState;

/**
 * Event monitor for keyUp events.
 */
@property(nonatomic) id keyUpMonitor;

/**
 * Pointer to a keyboard manager, a hub that manages how key events are
 * dispatched to various Flutter key responders, and whether the event is
 * propagated to the next NSResponder.
 */
@property(nonatomic, readonly, nonnull) FlutterKeyboardManager* keyboardManager;

@property(nonatomic) KeyboardLayoutNotifier keyboardLayoutNotifier;

@property(nonatomic) NSData* keyboardLayoutData;

/**
 * Starts running |engine|, including any initial setup.
 */
- (BOOL)launchEngine;

/**
 * Updates |trackingArea| for the current tracking settings, creating it with
 * the correct mode if tracking is enabled, or removing it if not.
 */
- (void)configureTrackingArea;

/**
 * Creates and registers keyboard related components.
 */
- (void)initializeKeyboard;

/**
 * Calls dispatchMouseEvent:phase: with a phase determined by self.mouseState.
 *
 * mouseState.buttons should be updated before calling this method.
 */
- (void)dispatchMouseEvent:(nonnull NSEvent*)event;

/**
 * Calls dispatchMouseEvent:phase: with a phase determined by event.phase.
 */
- (void)dispatchGestureEvent:(nonnull NSEvent*)event;

/**
 * Converts |event| to a FlutterPointerEvent with the given phase, and sends it to the engine.
 */
- (void)dispatchMouseEvent:(nonnull NSEvent*)event phase:(FlutterPointerPhase)phase;

/**
 * Called when the active keyboard input source changes.
 *
 * Input sources may be simple keyboard layouts, or more complex input methods involving an IME,
 * such as Chinese, Japanese, and Korean.
 */
- (void)onKeyboardLayoutChanged;

@end

#pragma mark - Private dependant functions

namespace {
void OnKeyboardLayoutChanged(CFNotificationCenterRef center,
                             void* observer,
                             CFStringRef name,
                             const void* object,
                             CFDictionaryRef userInfo) {
  FlutterViewController* controller = (__bridge FlutterViewController*)observer;
  if (controller != nil) {
    [controller onKeyboardLayoutChanged];
  }
}
}  // namespace

#pragma mark - FlutterViewWrapper implementation.

@implementation FlutterViewWrapper {
  FlutterView* _flutterView;
}

- (instancetype)initWithFlutterView:(FlutterView*)view {
  self = [super initWithFrame:NSZeroRect];
  if (self) {
    _flutterView = view;
    view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:view];
  }
  return self;
}

- (NSArray*)accessibilityChildren {
  return @[ _flutterView ];
}

@end

#pragma mark - FlutterViewController implementation.

@implementation FlutterViewController {
  // The project to run in this controller's engine.
  FlutterDartProject* _project;
}

@dynamic view;

/**
 * Performs initialization that's common between the different init paths.
 */
static void CommonInit(FlutterViewController* controller) {
  if (!controller->_engine) {
    controller->_engine = [[FlutterEngine alloc] initWithName:@"io.flutter"
                                                      project:controller->_project
                                       allowHeadlessExecution:NO];
  }
  controller->_mouseTrackingMode = FlutterMouseTrackingModeInKeyWindow;
  controller->_textInputPlugin = [[FlutterTextInputPlugin alloc] initWithViewController:controller];
  // macOS fires this message when changing IMEs.
  CFNotificationCenterRef cfCenter = CFNotificationCenterGetDistributedCenter();
  __weak FlutterViewController* weakSelf = controller;
  CFNotificationCenterAddObserver(cfCenter, (__bridge void*)weakSelf, OnKeyboardLayoutChanged,
                                  kTISNotifySelectedKeyboardInputSourceChanged, NULL,
                                  CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (instancetype)initWithCoder:(NSCoder*)coder {
  self = [super initWithCoder:coder];
  NSAssert(self, @"Super init cannot be nil");

  CommonInit(self);
  return self;
}

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  NSAssert(self, @"Super init cannot be nil");

  CommonInit(self);
  return self;
}

- (instancetype)initWithProject:(nullable FlutterDartProject*)project {
  self = [super initWithNibName:nil bundle:nil];
  NSAssert(self, @"Super init cannot be nil");

  _project = project;
  CommonInit(self);
  return self;
}

- (instancetype)initWithEngine:(nonnull FlutterEngine*)engine
                       nibName:(nullable NSString*)nibName
                        bundle:(nullable NSBundle*)nibBundle {
  NSAssert(engine != nil, @"Engine is required");
  self = [super initWithNibName:nibName bundle:nibBundle];
  if (self) {
    if (engine.viewController) {
      NSLog(@"The supplied FlutterEngine %@ is already used with FlutterViewController "
             "instance %@. One instance of the FlutterEngine can only be attached to one "
             "FlutterViewController at a time. Set FlutterEngine.viewController "
             "to nil before attaching it to another FlutterViewController.",
            [engine description], [engine.viewController description]);
    }
    _engine = engine;
    CommonInit(self);
    [engine setViewController:self];
  }

  return self;
}

- (BOOL)isDispatchingKeyEvent:(NSEvent*)event {
  return [_keyboardManager isDispatchingKeyEvent:event];
}

- (void)loadView {
  FlutterView* flutterView;
  if ([FlutterRenderingBackend renderUsingMetal]) {
    FlutterMetalRenderer* metalRenderer = reinterpret_cast<FlutterMetalRenderer*>(_engine.renderer);
    id<MTLDevice> device = metalRenderer.device;
    id<MTLCommandQueue> commandQueue = metalRenderer.commandQueue;
    if (!device || !commandQueue) {
      NSLog(@"Unable to create FlutterView; no MTLDevice or MTLCommandQueue available.");
      return;
    }
    flutterView = [[FlutterView alloc] initWithMTLDevice:device
                                            commandQueue:commandQueue
                                         reshapeListener:self];
  } else {
    FlutterOpenGLRenderer* openGLRenderer =
        reinterpret_cast<FlutterOpenGLRenderer*>(_engine.renderer);
    NSOpenGLContext* mainContext = openGLRenderer.openGLContext;
    if (!mainContext) {
      NSLog(@"Unable to create FlutterView; no GL context available.");
      return;
    }
    flutterView = [[FlutterView alloc] initWithMainContext:mainContext reshapeListener:self];
  }
  FlutterViewWrapper* wrapperView = [[FlutterViewWrapper alloc] initWithFlutterView:flutterView];
  self.view = wrapperView;
  _flutterView = flutterView;
}

- (void)viewDidLoad {
  [self configureTrackingArea];
}

- (void)viewWillAppear {
  [super viewWillAppear];
  if (!_engine.running) {
    [self launchEngine];
  }
  [self listenForMetaModifiedKeyUpEvents];
}

- (void)viewWillDisappear {
  // Per Apple's documentation, it is discouraged to call removeMonitor: in dealloc, and it's
  // recommended to be called earlier in the lifecycle.
  [NSEvent removeMonitor:_keyUpMonitor];
  _keyUpMonitor = nil;
}

- (void)dealloc {
  _engine.viewController = nil;
  CFNotificationCenterRef cfCenter = CFNotificationCenterGetDistributedCenter();
  CFNotificationCenterRemoveEveryObserver(cfCenter, (__bridge void*)self);
}

#pragma mark - Public methods

- (void)setMouseTrackingMode:(FlutterMouseTrackingMode)mode {
  if (_mouseTrackingMode == mode) {
    return;
  }
  _mouseTrackingMode = mode;
  [self configureTrackingArea];
}

- (void)onPreEngineRestart {
  [self initializeKeyboard];
}

#pragma mark - Private methods

- (BOOL)launchEngine {
  [self initializeKeyboard];

  _engine.viewController = self;
  if (![_engine runWithEntrypoint:nil]) {
    return NO;
  }
  return YES;
}

// macOS does not call keyUp: on a key while the command key is pressed. This results in a loss
// of a key event once the modified key is released. This method registers the
// ViewController as a listener for a keyUp event before it's handled by NSApplication, and should
// NOT modify the event to avoid any unexpected behavior.
- (void)listenForMetaModifiedKeyUpEvents {
  if (_keyUpMonitor != nil) {
    // It is possible for [NSViewController viewWillAppear] to be invoked multiple times
    // in a row. https://github.com/flutter/flutter/issues/105963
    return;
  }
  FlutterViewController* __weak weakSelf = self;
  _keyUpMonitor = [NSEvent
      addLocalMonitorForEventsMatchingMask:NSEventMaskKeyUp
                                   handler:^NSEvent*(NSEvent* event) {
                                     // Intercept keyUp only for events triggered on the current
                                     // view or textInputPlugin.
                                     NSResponder* firstResponder = [[event window] firstResponder];
                                     if (weakSelf.viewLoaded && weakSelf.flutterView &&
                                         (firstResponder == weakSelf.flutterView ||
                                          firstResponder == weakSelf.textInputPlugin) &&
                                         ([event modifierFlags] & NSEventModifierFlagCommand) &&
                                         ([event type] == NSEventTypeKeyUp)) {
                                       [weakSelf keyUp:event];
                                     }
                                     return event;
                                   }];
}

- (void)configureTrackingArea {
  if (!self.viewLoaded) {
    // The viewDidLoad will call configureTrackingArea again when
    // the view is actually loaded.
    return;
  }
  if (_mouseTrackingMode != FlutterMouseTrackingModeNone && self.flutterView) {
    NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved |
                                    NSTrackingInVisibleRect | NSTrackingEnabledDuringMouseDrag;
    switch (_mouseTrackingMode) {
      case FlutterMouseTrackingModeInKeyWindow:
        options |= NSTrackingActiveInKeyWindow;
        break;
      case FlutterMouseTrackingModeInActiveApp:
        options |= NSTrackingActiveInActiveApp;
        break;
      case FlutterMouseTrackingModeAlways:
        options |= NSTrackingActiveAlways;
        break;
      default:
        NSLog(@"Error: Unrecognized mouse tracking mode: %ld", _mouseTrackingMode);
        return;
    }
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                 options:options
                                                   owner:self
                                                userInfo:nil];
    [self.flutterView addTrackingArea:_trackingArea];
  } else if (_trackingArea) {
    [self.flutterView removeTrackingArea:_trackingArea];
    _trackingArea = nil;
  }
}

- (void)initializeKeyboard {
  // TODO(goderbauer): Seperate keyboard/textinput stuff into ViewController specific and Engine
  // global parts. Move the global parts to FlutterEngine.
  __weak FlutterViewController* weakSelf = self;
  _keyboardManager = [[FlutterKeyboardManager alloc] initWithViewDelegate:weakSelf];
}

- (void)dispatchMouseEvent:(nonnull NSEvent*)event {
  FlutterPointerPhase phase = _mouseState.buttons == 0
                                  ? (_mouseState.flutter_state_is_down ? kUp : kHover)
                                  : (_mouseState.flutter_state_is_down ? kMove : kDown);
  [self dispatchMouseEvent:event phase:phase];
}

- (void)dispatchGestureEvent:(nonnull NSEvent*)event {
  if (event.phase == NSEventPhaseBegan || event.phase == NSEventPhaseMayBegin) {
    [self dispatchMouseEvent:event phase:kPanZoomStart];
  } else if (event.phase == NSEventPhaseChanged) {
    [self dispatchMouseEvent:event phase:kPanZoomUpdate];
  } else if (event.phase == NSEventPhaseEnded || event.phase == NSEventPhaseCancelled) {
    [self dispatchMouseEvent:event phase:kPanZoomEnd];
  } else if (event.phase == NSEventPhaseNone && event.momentumPhase == NSEventPhaseNone) {
    [self dispatchMouseEvent:event phase:kHover];
  } else {
    // Skip momentum events, the framework will generate scroll momentum.
    NSAssert(event.momentumPhase != NSEventPhaseNone,
             @"Received gesture event with unexpected phase");
  }
}

- (void)dispatchMouseEvent:(NSEvent*)event phase:(FlutterPointerPhase)phase {
  NSAssert(self.viewLoaded, @"View must be loaded before it handles the mouse event");
  // There are edge cases where the system will deliver enter out of order relative to other
  // events (e.g., drag out and back in, release, then click; mouseDown: will be called before
  // mouseEntered:). Discard those events, since the add will already have been synthesized.
  if (_mouseState.flutter_state_is_added && phase == kAdd) {
    return;
  }

  // Multiple gesture recognizers could be active at once, we can't send multiple kPanZoomStart.
  // For example: rotation and magnification.
  if (phase == kPanZoomStart) {
    bool gestureAlreadyDown = _mouseState.pan_gesture_active || _mouseState.scale_gesture_active ||
                              _mouseState.rotate_gesture_active;
    if (event.type == NSEventTypeScrollWheel) {
      _mouseState.pan_gesture_active = true;
    } else if (event.type == NSEventTypeMagnify) {
      _mouseState.scale_gesture_active = true;
    } else if (event.type == NSEventTypeRotate) {
      _mouseState.rotate_gesture_active = true;
    }
    if (gestureAlreadyDown) {
      return;
    }
  }
  if (phase == kPanZoomEnd) {
    if (event.type == NSEventTypeScrollWheel) {
      _mouseState.pan_gesture_active = false;
    } else if (event.type == NSEventTypeMagnify) {
      _mouseState.scale_gesture_active = false;
    } else if (event.type == NSEventTypeRotate) {
      _mouseState.rotate_gesture_active = false;
    }
    if (_mouseState.pan_gesture_active || _mouseState.scale_gesture_active ||
        _mouseState.rotate_gesture_active) {
      return;
    }
  }

  // If a pointer added event hasn't been sent, synthesize one using this event for the basic
  // information.
  if (!_mouseState.flutter_state_is_added && phase != kAdd) {
    // Only the values extracted for use in flutterEvent below matter, the rest are dummy values.
    NSEvent* addEvent = [NSEvent enterExitEventWithType:NSEventTypeMouseEntered
                                               location:event.locationInWindow
                                          modifierFlags:0
                                              timestamp:event.timestamp
                                           windowNumber:event.windowNumber
                                                context:nil
                                            eventNumber:0
                                         trackingNumber:0
                                               userData:NULL];
    [self dispatchMouseEvent:addEvent phase:kAdd];
  }

  NSPoint locationInView = [self.flutterView convertPoint:event.locationInWindow fromView:nil];
  NSPoint locationInBackingCoordinates = [self.flutterView convertPointToBacking:locationInView];
  int32_t device = kMousePointerDeviceId;
  FlutterPointerDeviceKind deviceKind = kFlutterPointerDeviceKindMouse;
  if (phase == kPanZoomStart || phase == kPanZoomUpdate || phase == kPanZoomEnd) {
    device = kPointerPanZoomDeviceId;
    deviceKind = kFlutterPointerDeviceKindTrackpad;
  }
  FlutterPointerEvent flutterEvent = {
      .struct_size = sizeof(flutterEvent),
      .phase = phase,
      .timestamp = static_cast<size_t>(event.timestamp * USEC_PER_SEC),
      .x = locationInBackingCoordinates.x,
      .y = -locationInBackingCoordinates.y,  // convertPointToBacking makes this negative.
      .device = device,
      .device_kind = deviceKind,
      // If a click triggered a synthesized kAdd, don't pass the buttons in that event.
      .buttons = phase == kAdd ? 0 : _mouseState.buttons,
  };

  if (phase == kPanZoomUpdate) {
    if (event.type == NSEventTypeScrollWheel) {
      _mouseState.delta_x += event.scrollingDeltaX * self.flutterView.layer.contentsScale;
      _mouseState.delta_y += event.scrollingDeltaY * self.flutterView.layer.contentsScale;
    } else if (event.type == NSEventTypeMagnify) {
      _mouseState.scale += event.magnification;
    } else if (event.type == NSEventTypeRotate) {
      _mouseState.rotation += event.rotation * (M_PI / 180.0);
    }
    flutterEvent.pan_x = _mouseState.delta_x;
    flutterEvent.pan_y = _mouseState.delta_y;
    // Scale value needs to be normalized to range 0->infinity.
    flutterEvent.scale = pow(2.0, _mouseState.scale);
    flutterEvent.rotation = _mouseState.rotation;
  } else if (phase == kPanZoomEnd) {
    _mouseState.GestureReset();
  } else if (phase != kPanZoomStart && event.type == NSEventTypeScrollWheel) {
    flutterEvent.signal_kind = kFlutterPointerSignalKindScroll;

    double pixelsPerLine = 1.0;
    if (!event.hasPreciseScrollingDeltas) {
      // The scrollingDelta needs to be multiplied by the line height.
      // CGEventSourceGetPixelsPerLine() will return 10, which will result in
      // scrolling that is noticeably slower than in other applications.
      // Using 40.0 as the multiplier to match Chromium.
      // See https://source.chromium.org/chromium/chromium/src/+/main:ui/events/cocoa/events_mac.mm
      pixelsPerLine = 40.0;
    }
    double scaleFactor = self.flutterView.layer.contentsScale;
    flutterEvent.scroll_delta_x = -event.scrollingDeltaX * pixelsPerLine * scaleFactor;
    flutterEvent.scroll_delta_y = -event.scrollingDeltaY * pixelsPerLine * scaleFactor;
  }
  [_engine sendPointerEvent:flutterEvent];

  // Update tracking of state as reported to Flutter.
  if (phase == kDown) {
    _mouseState.flutter_state_is_down = true;
  } else if (phase == kUp) {
    _mouseState.flutter_state_is_down = false;
    if (_mouseState.has_pending_exit) {
      [self dispatchMouseEvent:event phase:kRemove];
      _mouseState.has_pending_exit = false;
    }
  } else if (phase == kAdd) {
    _mouseState.flutter_state_is_added = true;
  } else if (phase == kRemove) {
    _mouseState.Reset();
  }
}

- (void)onAccessibilityStatusChanged:(BOOL)enabled {
  if (!enabled && self.viewLoaded && [_textInputPlugin isFirstResponder]) {
    // Normally TextInputPlugin, when editing, is child of FlutterViewWrapper.
    // When accessiblity is enabled the TextInputPlugin gets added as an indirect
    // child to FlutterTextField. When disabling the plugin needs to be reparented
    // back.
    [self.view addSubview:_textInputPlugin];
  }
}

- (void)onKeyboardLayoutChanged {
  _keyboardLayoutData = nil;
  if (_keyboardLayoutNotifier != nil) {
    _keyboardLayoutNotifier();
  }
}

#pragma mark - FlutterViewReshapeListener

/**
 * Responds to view reshape by notifying the engine of the change in dimensions.
 */
- (void)viewDidReshape:(NSView*)view {
  [_engine updateWindowMetrics];
}

#pragma mark - FlutterPluginRegistry

- (id<FlutterPluginRegistrar>)registrarForPlugin:(NSString*)pluginName {
  return [_engine registrarForPlugin:pluginName];
}

#pragma mark - FlutterKeyboardViewDelegate

- (BOOL)isComposing {
  return [_textInputPlugin isComposing];
}

- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(nullable FlutterKeyEventCallback)callback
            userData:(nullable void*)userData {
  [_engine sendKeyEvent:event callback:callback userData:userData];
}

- (id<FlutterBinaryMessenger>)getBinaryMessenger {
  return _engine.binaryMessenger;
}

- (BOOL)onTextInputKeyEvent:(nonnull NSEvent*)event {
  return [_textInputPlugin handleKeyEvent:event];
}

- (void)subscribeToKeyboardLayoutChange:(nullable KeyboardLayoutNotifier)callback {
  _keyboardLayoutNotifier = callback;
}

- (LayoutClue)lookUpLayoutForKeyCode:(uint16_t)keyCode shift:(BOOL)shift {
  if (_keyboardLayoutData == nil) {
    _keyboardLayoutData = currentKeyboardLayoutData();
  }
  const UCKeyboardLayout* layout = reinterpret_cast<const UCKeyboardLayout*>(
      CFDataGetBytePtr((__bridge CFDataRef)_keyboardLayoutData));

  UInt32 deadKeyState = 0;
  UniCharCount stringLength = 0;
  UniChar resultChar;

  UInt32 modifierState = ((shift ? shiftKey : 0) >> 8) & 0xFF;
  UInt32 keyboardType = LMGetKbdLast();

  bool isDeadKey = false;
  OSStatus status =
      UCKeyTranslate(layout, keyCode, kUCKeyActionDown, modifierState, keyboardType,
                     kUCKeyTranslateNoDeadKeysBit, &deadKeyState, 1, &stringLength, &resultChar);
  // For dead keys, press the same key again to get the printable representation of the key.
  if (status == noErr && stringLength == 0 && deadKeyState != 0) {
    isDeadKey = true;
    status =
        UCKeyTranslate(layout, keyCode, kUCKeyActionDown, modifierState, keyboardType,
                       kUCKeyTranslateNoDeadKeysBit, &deadKeyState, 1, &stringLength, &resultChar);
  }

  if (status == noErr && stringLength == 1 && !std::iscntrl(resultChar)) {
    return LayoutClue{resultChar, isDeadKey};
  }
  return LayoutClue{0, false};
}

#pragma mark - NSResponder

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)keyDown:(NSEvent*)event {
  [_keyboardManager handleEvent:event];
}

- (void)keyUp:(NSEvent*)event {
  [_keyboardManager handleEvent:event];
}

- (void)flagsChanged:(NSEvent*)event {
  [_keyboardManager handleEvent:event];
}

- (void)mouseEntered:(NSEvent*)event {
  if (_mouseState.has_pending_exit) {
    _mouseState.has_pending_exit = false;
  } else {
    [self dispatchMouseEvent:event phase:kAdd];
  }
}

- (void)mouseExited:(NSEvent*)event {
  if (_mouseState.buttons != 0) {
    _mouseState.has_pending_exit = true;
    return;
  }
  [self dispatchMouseEvent:event phase:kRemove];
}

- (void)mouseDown:(NSEvent*)event {
  _mouseState.buttons |= kFlutterPointerButtonMousePrimary;
  [self dispatchMouseEvent:event];
}

- (void)mouseUp:(NSEvent*)event {
  _mouseState.buttons &= ~static_cast<uint64_t>(kFlutterPointerButtonMousePrimary);
  [self dispatchMouseEvent:event];
}

- (void)mouseDragged:(NSEvent*)event {
  [self dispatchMouseEvent:event];
}

- (void)rightMouseDown:(NSEvent*)event {
  _mouseState.buttons |= kFlutterPointerButtonMouseSecondary;
  [self dispatchMouseEvent:event];
}

- (void)rightMouseUp:(NSEvent*)event {
  _mouseState.buttons &= ~static_cast<uint64_t>(kFlutterPointerButtonMouseSecondary);
  [self dispatchMouseEvent:event];
}

- (void)rightMouseDragged:(NSEvent*)event {
  [self dispatchMouseEvent:event];
}

- (void)otherMouseDown:(NSEvent*)event {
  _mouseState.buttons |= (1 << event.buttonNumber);
  [self dispatchMouseEvent:event];
}

- (void)otherMouseUp:(NSEvent*)event {
  _mouseState.buttons &= ~static_cast<uint64_t>(1 << event.buttonNumber);
  [self dispatchMouseEvent:event];
}

- (void)otherMouseDragged:(NSEvent*)event {
  [self dispatchMouseEvent:event];
}

- (void)mouseMoved:(NSEvent*)event {
  [self dispatchMouseEvent:event];
}

- (void)scrollWheel:(NSEvent*)event {
  [self dispatchGestureEvent:event];
}

- (void)magnifyWithEvent:(NSEvent*)event {
  [self dispatchGestureEvent:event];
}

- (void)rotateWithEvent:(NSEvent*)event {
  [self dispatchGestureEvent:event];
}

- (void)swipeWithEvent:(NSEvent*)event {
  // Not needed, it's handled by scrollWheel.
}

@end
