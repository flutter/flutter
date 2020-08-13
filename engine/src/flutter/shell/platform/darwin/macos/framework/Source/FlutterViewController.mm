// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// FLUTTER_NOLINT

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMouseCursorPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#import "flutter/shell/platform/embedder/embedder.h"

namespace {

/// Clipboard plain text format.
constexpr char kTextPlainFormat[] = "text/plain";

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
   * button is released. If it was released inside the view, mouseEntered: is sent the next time the
   * mouse moves. Flutter doesn't expect to receive events after a kRemove, so the kRemove for the
   * exit needs to be delayed until after the last mouse button is released.
   */
  bool has_pending_exit = false;

  /**
   * The currently pressed buttons, as represented in FlutterPointerEvent.
   */
  int64_t buttons = 0;

  /**
   * Resets all state to default values.
   */
  void Reset() {
    flutter_state_is_added = false;
    flutter_state_is_down = false;
    has_pending_exit = false;
    buttons = 0;
  }
};

/**
 * State tracking for keyboard events, to adapt between the events coming from the system and the
 * events that the embedding API expects.
 */
struct KeyboardState {
  /**
   * The last known pressed modifier flag keys.
   */
  uint64_t previously_pressed_flags = 0;
};

}  // namespace

#pragma mark - Private interface declaration.

/**
 * Private interface declaration for FlutterViewController.
 */
@interface FlutterViewController () <FlutterViewReshapeListener>

/**
 * A list of additional responders to keyboard events. Keybord events are forwarded to all of them.
 */
@property(nonatomic) NSMutableOrderedSet<NSResponder*>* additionalKeyResponders;

/**
 * The tracking area used to generate hover events, if enabled.
 */
@property(nonatomic) NSTrackingArea* trackingArea;

/**
 * The current state of the mouse and the sent mouse events.
 */
@property(nonatomic) MouseState mouseState;

/**
 * The current state of the keyboard and pressed keys.
 */
@property(nonatomic) KeyboardState keyboardState;

/**
 * Event monitor for keyUp events.
 */
@property(nonatomic) id keyUpMonitor;

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
 * Creates and registers plugins used by this view controller.
 */
- (void)addInternalPlugins;

/**
 * Calls dispatchMouseEvent:phase: with a phase determined by self.mouseState.
 *
 * mouseState.buttons should be updated before calling this method.
 */
- (void)dispatchMouseEvent:(nonnull NSEvent*)event;

/**
 * Converts |event| to a FlutterPointerEvent with the given phase, and sends it to the engine.
 */
- (void)dispatchMouseEvent:(nonnull NSEvent*)event phase:(FlutterPointerPhase)phase;

/**
 * Converts |event| to a key event channel message, and sends it to the engine.
 */
- (void)dispatchKeyEvent:(NSEvent*)event ofType:(NSString*)type;

/**
 * Initializes the KVO for user settings and passes the initial user settings to the engine.
 */
- (void)sendInitialSettings;

/**
 * Responds to updates in the user settings and passes this data to the engine.
 */
- (void)onSettingsChanged:(NSNotification*)notification;

/**
 * Handles messages received from the Flutter engine on the _*Channel channels.
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

/**
 * Plays a system sound. |soundType| specifies which system sound to play. Valid
 * values can be found in the SystemSoundType enum in the services SDK package.
 */
- (void)playSystemSound:(NSString*)soundType;

/**
 * Reads the data from the clipboard. |format| specifies the media type of the
 * data to obtain.
 */
- (NSDictionary*)getClipboardData:(NSString*)format;

/**
 * Clears contents and writes new data into clipboard. |data| is a dictionary where
 * the keys are the type of data, and tervalue the data to be stored.
 */
- (void)setClipboardData:(NSDictionary*)data;

@end

#pragma mark - FlutterViewController implementation.

@implementation FlutterViewController {
  // The project to run in this controller's engine.
  FlutterDartProject* _project;

  // The plugin used to handle text input. This is not an FlutterPlugin, so must be owned
  // separately.
  FlutterTextInputPlugin* _textInputPlugin;

  // A message channel for passing key events to the Flutter engine. This should be replaced with
  // an embedding API; see Issue #47.
  FlutterBasicMessageChannel* _keyEventChannel;

  // A message channel for sending user settings to the flutter engine.
  FlutterBasicMessageChannel* _settingsChannel;

  // A method channel for miscellaneous platform functionality.
  FlutterMethodChannel* _platformChannel;
}

@dynamic view;

/**
 * Performs initialization that's common between the different init paths.
 */
static void CommonInit(FlutterViewController* controller) {
  controller->_engine = [[FlutterEngine alloc] initWithName:@"io.flutter"
                                                    project:controller->_project
                                     allowHeadlessExecution:NO];
  controller->_additionalKeyResponders = [[NSMutableOrderedSet alloc] init];
  controller->_mouseTrackingMode = FlutterMouseTrackingModeInKeyWindow;
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

- (void)loadView {
  NSOpenGLContext* resourceContext = _engine.resourceContext;
  if (!resourceContext) {
    NSLog(@"Unable to create FlutterView; no resource context available.");
    return;
  }
  FlutterView* flutterView = [[FlutterView alloc] initWithShareContext:resourceContext
                                                       reshapeListener:self];
  self.view = flutterView;
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
}

#pragma mark - Public methods

- (void)setMouseTrackingMode:(FlutterMouseTrackingMode)mode {
  if (_mouseTrackingMode == mode) {
    return;
  }
  _mouseTrackingMode = mode;
  [self configureTrackingArea];
}

#pragma mark - Framework-internal methods

- (FlutterView*)flutterView {
  return static_cast<FlutterView*>(self.view);
}

- (void)addKeyResponder:(NSResponder*)responder {
  [self.additionalKeyResponders addObject:responder];
}

- (void)removeKeyResponder:(NSResponder*)responder {
}

#pragma mark - Private methods

- (BOOL)launchEngine {
  // Register internal plugins before starting the engine.
  [self addInternalPlugins];

  _engine.viewController = self;
  if (![_engine runWithEntrypoint:nil]) {
    return NO;
  }
  // Send the initial user settings such as brightness and text scale factor
  // to the engine.
  // TODO(stuartmorgan): Move this logic to FlutterEngine.
  [self sendInitialSettings];
  return YES;
}

// macOS does not call keyUp: on a key while the command key is pressed. This results in a loss
// of a key event once the modified key is released. This method registers the
// ViewController as a listener for a keyUp event before it's handled by NSApplication, and should
// NOT modify the event to avoid any unexpected behavior.
- (void)listenForMetaModifiedKeyUpEvents {
  NSAssert(_keyUpMonitor == nil, @"_keyUpMonitor was already created");
  FlutterViewController* __weak weakSelf = self;
  _keyUpMonitor = [NSEvent
      addLocalMonitorForEventsMatchingMask:NSEventMaskKeyUp
                                   handler:^NSEvent*(NSEvent* event) {
                                     // Intercept keyUp only for events triggered on the current
                                     // view.
                                     if (weakSelf.view &&
                                         ([[event window] firstResponder] == weakSelf.view) &&
                                         ([event modifierFlags] & NSEventModifierFlagCommand) &&
                                         ([event type] == NSEventTypeKeyUp))
                                       [weakSelf keyUp:event];
                                     return event;
                                   }];
}

- (void)configureTrackingArea {
  if (_mouseTrackingMode != FlutterMouseTrackingModeNone && self.view) {
    NSTrackingAreaOptions options =
        NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect;
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
    [self.view addTrackingArea:_trackingArea];
  } else if (_trackingArea) {
    [self.view removeTrackingArea:_trackingArea];
    _trackingArea = nil;
  }
}

- (void)addInternalPlugins {
  [FlutterMouseCursorPlugin registerWithRegistrar:[self registrarForPlugin:@"mousecursor"]];
  _textInputPlugin = [[FlutterTextInputPlugin alloc] initWithViewController:self];
  _keyEventChannel =
      [FlutterBasicMessageChannel messageChannelWithName:@"flutter/keyevent"
                                         binaryMessenger:_engine.binaryMessenger
                                                   codec:[FlutterJSONMessageCodec sharedInstance]];
  _settingsChannel =
      [FlutterBasicMessageChannel messageChannelWithName:@"flutter/settings"
                                         binaryMessenger:_engine.binaryMessenger
                                                   codec:[FlutterJSONMessageCodec sharedInstance]];
  _platformChannel =
      [FlutterMethodChannel methodChannelWithName:@"flutter/platform"
                                  binaryMessenger:_engine.binaryMessenger
                                            codec:[FlutterJSONMethodCodec sharedInstance]];
  __weak FlutterViewController* weakSelf = self;
  [_platformChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    [weakSelf handleMethodCall:call result:result];
  }];
}

- (void)dispatchMouseEvent:(nonnull NSEvent*)event {
  FlutterPointerPhase phase = _mouseState.buttons == 0
                                  ? (_mouseState.flutter_state_is_down ? kUp : kHover)
                                  : (_mouseState.flutter_state_is_down ? kMove : kDown);
  [self dispatchMouseEvent:event phase:phase];
}

- (void)dispatchMouseEvent:(NSEvent*)event phase:(FlutterPointerPhase)phase {
  // There are edge cases where the system will deliver enter out of order relative to other
  // events (e.g., drag out and back in, release, then click; mouseDown: will be called before
  // mouseEntered:). Discard those events, since the add will already have been synthesized.
  if (_mouseState.flutter_state_is_added && phase == kAdd) {
    return;
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

  NSPoint locationInView = [self.view convertPoint:event.locationInWindow fromView:nil];
  NSPoint locationInBackingCoordinates = [self.view convertPointToBacking:locationInView];
  FlutterPointerEvent flutterEvent = {
      .struct_size = sizeof(flutterEvent),
      .phase = phase,
      .timestamp = static_cast<size_t>(event.timestamp * USEC_PER_SEC),
      .x = locationInBackingCoordinates.x,
      .y = -locationInBackingCoordinates.y,  // convertPointToBacking makes this negative.
      .device_kind = kFlutterPointerDeviceKindMouse,
      // If a click triggered a synthesized kAdd, don't pass the buttons in that event.
      .buttons = phase == kAdd ? 0 : _mouseState.buttons,
  };

  if (event.type == NSEventTypeScrollWheel) {
    flutterEvent.signal_kind = kFlutterPointerSignalKindScroll;

    double pixelsPerLine = 1.0;
    if (!event.hasPreciseScrollingDeltas) {
      CGEventSourceRef source = CGEventCreateSourceFromEvent(event.CGEvent);
      pixelsPerLine = CGEventSourceGetPixelsPerLine(source);
      if (source) {
        CFRelease(source);
      }
    }
    double scaleFactor = self.view.layer.contentsScale;
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

- (void)dispatchKeyEvent:(NSEvent*)event ofType:(NSString*)type {
  NSMutableDictionary* keyMessage = [@{
    @"keymap" : @"macos",
    @"type" : type,
    @"keyCode" : @(event.keyCode),
    @"modifiers" : @(event.modifierFlags),
  } mutableCopy];
  // Calling these methods on any other type of event will raise an exception.
  if (event.type == NSEventTypeKeyDown || event.type == NSEventTypeKeyUp) {
    keyMessage[@"characters"] = event.characters;
    keyMessage[@"charactersIgnoringModifiers"] = event.charactersIgnoringModifiers;
  }
  [_keyEventChannel sendMessage:keyMessage];
}

- (void)onSettingsChanged:(NSNotification*)notification {
  // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/32015.
  NSString* brightness =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
  [_settingsChannel sendMessage:@{
    @"platformBrightness" : [brightness isEqualToString:@"Dark"] ? @"dark" : @"light",
    // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/32006.
    @"textScaleFactor" : @1.0,
    @"alwaysUse24HourFormat" : @false
  }];
}

- (void)sendInitialSettings {
  // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/32015.
  [[NSDistributedNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(onSettingsChanged:)
             name:@"AppleInterfaceThemeChangedNotification"
           object:nil];
  [self onSettingsChanged:nil];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"SystemNavigator.pop"]) {
    [NSApp terminate:self];
    result(nil);
  } else if ([call.method isEqualToString:@"SystemSound.play"]) {
    [self playSystemSound:call.arguments];
    result(nil);
  } else if ([call.method isEqualToString:@"Clipboard.getData"]) {
    result([self getClipboardData:call.arguments]);
  } else if ([call.method isEqualToString:@"Clipboard.setData"]) {
    [self setClipboardData:call.arguments];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)playSystemSound:(NSString*)soundType {
  if ([soundType isEqualToString:@"SystemSoundType.alert"]) {
    NSBeep();
  }
}

- (NSDictionary*)getClipboardData:(NSString*)format {
  NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
  if ([format isEqualToString:@(kTextPlainFormat)]) {
    NSString* stringInPasteboard = [pasteboard stringForType:NSPasteboardTypeString];
    return stringInPasteboard == nil ? nil : @{@"text" : stringInPasteboard};
  }
  return nil;
}

- (void)setClipboardData:(NSDictionary*)data {
  NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
  NSString* text = data[@"text"];
  if (text && ![text isEqual:[NSNull null]]) {
    [pasteboard clearContents];
    [pasteboard setString:text forType:NSPasteboardTypeString];
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

#pragma mark - NSResponder

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)keyDown:(NSEvent*)event {
  [self dispatchKeyEvent:event ofType:@"keydown"];
  for (NSResponder* responder in self.additionalKeyResponders) {
    if ([responder respondsToSelector:@selector(keyDown:)]) {
      [responder keyDown:event];
    }
  }
}

- (void)keyUp:(NSEvent*)event {
  [self dispatchKeyEvent:event ofType:@"keyup"];
  for (NSResponder* responder in self.additionalKeyResponders) {
    if ([responder respondsToSelector:@selector(keyUp:)]) {
      [responder keyUp:event];
    }
  }
}

- (void)flagsChanged:(NSEvent*)event {
  if (event.modifierFlags < _keyboardState.previously_pressed_flags) {
    [self keyUp:event];
  } else {
    [self keyDown:event];
  }
  _keyboardState.previously_pressed_flags = event.modifierFlags;
}

- (void)mouseEntered:(NSEvent*)event {
  [self dispatchMouseEvent:event phase:kAdd];
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
  // TODO: Add gesture-based (trackpad) scroll support once it's supported by the engine rather
  // than always using kHover.
  [self dispatchMouseEvent:event phase:kHover];
}

@end
