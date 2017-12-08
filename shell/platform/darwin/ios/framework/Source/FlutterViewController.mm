// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

#include <memory>

#include "flutter/common/threads.h"
#include "flutter/flow/texture.h"
#include "flutter/fml/platform/darwin/platform_version.h"
#include "flutter/fml/platform/darwin/scoped_block.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "flutter/shell/platform/darwin/common/buffer_conversions.h"
#include "flutter/shell/platform/darwin/common/platform_mac.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCodecs.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/flutter_main_ios.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/flutter_touch_mapper.h"
#include "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/fxl/time/time_delta.h"

namespace {

typedef void (^PlatformMessageResponseCallback)(NSData*);

class PlatformMessageResponseDarwin : public blink::PlatformMessageResponse {
  FRIEND_MAKE_REF_COUNTED(PlatformMessageResponseDarwin);

 public:
  void Complete(std::vector<uint8_t> data) override {
    fxl::RefPtr<PlatformMessageResponseDarwin> self(this);
    blink::Threads::Platform()->PostTask(
        fxl::MakeCopyable([ self, data = std::move(data) ]() mutable {
          self->callback_.get()(shell::GetNSDataFromVector(data));
        }));
  }

  void CompleteEmpty() override {
    fxl::RefPtr<PlatformMessageResponseDarwin> self(this);
    blink::Threads::Platform()->PostTask(
        fxl::MakeCopyable([self]() mutable { self->callback_.get()(nil); }));
  }

 private:
  explicit PlatformMessageResponseDarwin(PlatformMessageResponseCallback callback)
      : callback_(callback, fml::OwnershipPolicy::Retain) {}

  fml::ScopedBlock<PlatformMessageResponseCallback> callback_;
};

}  // namespace

@interface FlutterViewController ()<UIAlertViewDelegate, FlutterTextInputDelegate>
@end

@implementation FlutterViewController {
  fml::scoped_nsprotocol<FlutterDartProject*> _dartProject;
  UIInterfaceOrientationMask _orientationPreferences;
  UIStatusBarStyle _statusBarStyle;
  blink::ViewportMetrics _viewportMetrics;
  shell::TouchMapper _touchMapper;
  std::shared_ptr<shell::PlatformViewIOS> _platformView;
  fml::scoped_nsprotocol<FlutterPlatformPlugin*> _platformPlugin;
  fml::scoped_nsprotocol<FlutterTextInputPlugin*> _textInputPlugin;
  fml::scoped_nsprotocol<FlutterMethodChannel*> _localizationChannel;
  fml::scoped_nsprotocol<FlutterMethodChannel*> _navigationChannel;
  fml::scoped_nsprotocol<FlutterMethodChannel*> _platformChannel;
  fml::scoped_nsprotocol<FlutterMethodChannel*> _textInputChannel;
  fml::scoped_nsprotocol<FlutterBasicMessageChannel*> _lifecycleChannel;
  fml::scoped_nsprotocol<FlutterBasicMessageChannel*> _systemChannel;
  fml::scoped_nsprotocol<FlutterBasicMessageChannel*> _settingsChannel;
  fml::scoped_nsprotocol<UIView*> _launchView;
  int64_t _nextTextureId;
  bool _platformSupportsTouchTypes;
  bool _platformSupportsTouchPressure;
  bool _platformSupportsTouchOrientationAndTilt;
  bool _platformSupportsSafeAreaInsets;
  BOOL _initialized;
  BOOL _connected;
}

+ (void)initialize {
  if (self == [FlutterViewController class]) {
    shell::FlutterMain();
  }
}

#pragma mark - Manage and override all designated initializers

- (instancetype)initWithProject:(FlutterDartProject*)project
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

  if (self) {
    if (project == nil)
      _dartProject.reset([[FlutterDartProject alloc] initFromDefaultSourceForConfiguration]);
    else
      _dartProject.reset([project retain]);

    [self performCommonViewControllerInitialization];
  }

  return self;
}

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
  return [self initWithProject:nil nibName:nil bundle:nil];
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
  return [self initWithProject:nil nibName:nil bundle:nil];
}

#pragma mark - Common view controller initialization tasks

- (void)performCommonViewControllerInitialization {
  if (_initialized)
    return;

  _initialized = YES;

  _platformSupportsTouchTypes = fml::IsPlatformVersionAtLeast(9);
  _platformSupportsTouchPressure = fml::IsPlatformVersionAtLeast(9);
  _platformSupportsTouchOrientationAndTilt = fml::IsPlatformVersionAtLeast(9, 1);
  _platformSupportsSafeAreaInsets = fml::IsPlatformVersionAtLeast(11, 0);

  _orientationPreferences = UIInterfaceOrientationMaskAll;
  _statusBarStyle = UIStatusBarStyleDefault;
  _platformView = std::make_shared<shell::PlatformViewIOS>(
      reinterpret_cast<CAEAGLLayer*>(self.view.layer), self);

  _platformView->Attach(
      // First frame callback.
      [self]() {
        TRACE_EVENT0("flutter", "First Frame");
        if (_launchView) {
          [UIView animateWithDuration:0.2
              animations:^{
                _launchView.get().alpha = 0;
              }
              completion:^(BOOL finished) {
                [_launchView.get() removeFromSuperview];
                _launchView.reset();
              }];
        }
      });
  _platformView->SetupResourceContextOnIOThread();

  _localizationChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/localization"
      binaryMessenger:self
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _navigationChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/navigation"
      binaryMessenger:self
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _platformChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/platform"
      binaryMessenger:self
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _textInputChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/textinput"
      binaryMessenger:self
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _lifecycleChannel.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/lifecycle"
      binaryMessenger:self
                codec:[FlutterStringCodec sharedInstance]]);

  _systemChannel.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/system"
      binaryMessenger:self
                codec:[FlutterJSONMessageCodec sharedInstance]]);

  _settingsChannel.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/settings"
      binaryMessenger:self
                codec:[FlutterJSONMessageCodec sharedInstance]]);

  _platformPlugin.reset([[FlutterPlatformPlugin alloc] init]);
  [_platformChannel.get() setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    [_platformPlugin.get() handleMethodCall:call result:result];
  }];

  _textInputPlugin.reset([[FlutterTextInputPlugin alloc] init]);
  _textInputPlugin.get().textInputDelegate = self;
  [_textInputChannel.get() setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    [_textInputPlugin.get() handleMethodCall:call result:result];
  }];

  [self setupNotificationCenterObservers];
}

- (void)setupNotificationCenterObservers {
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onOrientationPreferencesUpdated:)
                 name:@(shell::kOrientationUpdateNotificationName)
               object:nil];

  [center addObserver:self
             selector:@selector(onPreferredStatusBarStyleUpdated:)
                 name:@(shell::kOverlayStyleUpdateNotificationName)
               object:nil];

  [center addObserver:self
             selector:@selector(applicationBecameActive:)
                 name:UIApplicationDidBecomeActiveNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationWillResignActive:)
                 name:UIApplicationWillResignActiveNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationDidEnterBackground:)
                 name:UIApplicationDidEnterBackgroundNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationWillEnterForeground:)
                 name:UIApplicationWillEnterForegroundNotification
               object:nil];

  [center addObserver:self
             selector:@selector(keyboardWillChangeFrame:)
                 name:UIKeyboardWillChangeFrameNotification
               object:nil];

  [center addObserver:self
             selector:@selector(keyboardWillBeHidden:)
                 name:UIKeyboardWillHideNotification
               object:nil];

  [center addObserver:self
             selector:@selector(onLocaleUpdated:)
                 name:NSCurrentLocaleDidChangeNotification
               object:nil];

  [center addObserver:self
             selector:@selector(onVoiceOverChanged:)
                 name:UIAccessibilityVoiceOverStatusChanged
               object:nil];

  [center addObserver:self
             selector:@selector(onMemoryWarning:)
                 name:UIApplicationDidReceiveMemoryWarningNotification
               object:nil];

  [center addObserver:self
             selector:@selector(onUserSettingsChanged:)
                 name:UIContentSizeCategoryDidChangeNotification
               object:nil];
}

- (void)setInitialRoute:(NSString*)route {
  [_navigationChannel.get() invokeMethod:@"setInitialRoute" arguments:route];
}
#pragma mark - Initializing the engine

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  exit(0);
}

- (void)connectToEngineAndLoad {
  if (_connected)
    return;
  _connected = YES;

  TRACE_EVENT0("flutter", "connectToEngineAndLoad");

  // We ask the VM to check what it supports.
  const enum VMType type = Dart_IsPrecompiledRuntime() ? VMTypePrecompilation : VMTypeInterpreter;

  [_dartProject launchInEngine:&_platformView->engine()
                embedderVMType:type
                        result:^(BOOL success, NSString* message) {
                          if (!success) {
                            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Launch Error"
                                                                            message:message
                                                                           delegate:self
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                            [alert show];
                            [alert release];
                          }
                        }];
}

#pragma mark - Loading the view

- (void)loadView {
  FlutterView* view = [[FlutterView alloc] init];

  self.view = view;
  self.view.multipleTouchEnabled = YES;
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [view release];

  // Show the launch screen view again on top of the FlutterView if available.
  // This launch screen view will be removed once the first Flutter frame is rendered.
  NSString* launchStoryboardName =
      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UILaunchStoryboardName"];
  if (launchStoryboardName && !self.isBeingPresented && !self.isMovingToParentViewController) {
    UIViewController* launchViewController =
        [[UIStoryboard storyboardWithName:launchStoryboardName bundle:nil]
            instantiateInitialViewController];
    _launchView.reset([launchViewController.view retain]);
    _launchView.get().frame = self.view.bounds;
    _launchView.get().autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_launchView.get()];
  }
}

#pragma mark - Surface creation and teardown updates

- (void)surfaceUpdated:(BOOL)appeared {
  FXL_CHECK(_platformView != nullptr);

  // NotifyCreated/NotifyDestroyed are synchronous and require hops between the UI and GPU thread.
  if (appeared) {
    _platformView->NotifyCreated();
  } else {
    _platformView->NotifyDestroyed();
  }
}

#pragma mark - UIViewController lifecycle notifications

- (void)viewWillAppear:(BOOL)animated {
  TRACE_EVENT0("flutter", "viewWillAppear");
  [self connectToEngineAndLoad];
  // Only recreate surface on subsequent appearances when viewport metrics are known.
  // First time surface creation is done on viewDidLayoutSubviews.
  if (_viewportMetrics.physical_width)
    [self surfaceUpdated:YES];
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.inactive"];

  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  TRACE_EVENT0("flutter", "viewDidAppear");
  [self onLocaleUpdated:nil];
  [self onUserSettingsChanged:nil];
  [self onVoiceOverChanged:nil];
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.resumed"];

  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  TRACE_EVENT0("flutter", "viewWillDisappear");
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.inactive"];

  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  TRACE_EVENT0("flutter", "viewDidDisappear");
  [self surfaceUpdated:NO];
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.paused"];

  [super viewDidDisappear:animated];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark - Application lifecycle notifications

- (void)applicationBecameActive:(NSNotification*)notification {
  TRACE_EVENT0("flutter", "applicationBecameActive");
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.resumed"];
}

- (void)applicationWillResignActive:(NSNotification*)notification {
  TRACE_EVENT0("flutter", "applicationWillResignActive");
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.inactive"];
}

- (void)applicationDidEnterBackground:(NSNotification*)notification {
  TRACE_EVENT0("flutter", "applicationDidEnterBackground");
  [self surfaceUpdated:NO];
  // GrContext operations are blocked when the app is in the background.
  blink::ResourceContext::Freeze();
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.paused"];
}

- (void)applicationWillEnterForeground:(NSNotification*)notification {
  TRACE_EVENT0("flutter", "applicationWillEnterForeground");
  if (_viewportMetrics.physical_width)
    [self surfaceUpdated:YES];
  blink::ResourceContext::Unfreeze();
  [_lifecycleChannel.get() sendMessage:@"AppLifecycleState.inactive"];
}

#pragma mark - Touch event handling

enum MapperPhase {
  Accessed,
  Added,
  Removed,
};

using PointerChangeMapperPhase = std::pair<blink::PointerData::Change, MapperPhase>;
static inline PointerChangeMapperPhase PointerChangePhaseFromUITouchPhase(UITouchPhase phase) {
  switch (phase) {
    case UITouchPhaseBegan:
      return PointerChangeMapperPhase(blink::PointerData::Change::kDown, MapperPhase::Added);
    case UITouchPhaseMoved:
    case UITouchPhaseStationary:
      // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
      // with the same coordinates
      return PointerChangeMapperPhase(blink::PointerData::Change::kMove, MapperPhase::Accessed);
    case UITouchPhaseEnded:
      return PointerChangeMapperPhase(blink::PointerData::Change::kUp, MapperPhase::Removed);
    case UITouchPhaseCancelled:
      return PointerChangeMapperPhase(blink::PointerData::Change::kCancel, MapperPhase::Removed);
  }

  return PointerChangeMapperPhase(blink::PointerData::Change::kCancel, MapperPhase::Accessed);
}

static inline blink::PointerData::DeviceKind DeviceKindFromTouchType(UITouch* touch,
                                                                     bool touchTypeSupported) {
  if (!touchTypeSupported) {
    return blink::PointerData::DeviceKind::kTouch;
  }

  switch (touch.type) {
    case UITouchTypeDirect:
    case UITouchTypeIndirect:
      return blink::PointerData::DeviceKind::kTouch;
    case UITouchTypeStylus:
      return blink::PointerData::DeviceKind::kStylus;
  }

  return blink::PointerData::DeviceKind::kTouch;
}

- (void)dispatchTouches:(NSSet*)touches phase:(UITouchPhase)phase {
  // Note: we cannot rely on touch.phase, since in some cases, e.g.,
  // handleStatusBarTouches, we synthesize touches from existing events.
  //
  // TODO(cbracken) consider creating out own class with the touch fields we
  // need.
  auto eventTypePhase = PointerChangePhaseFromUITouchPhase(phase);
  const CGFloat scale = [UIScreen mainScreen].scale;
  auto packet = std::make_unique<blink::PointerDataPacket>(touches.count);

  int i = 0;
  for (UITouch* touch in touches) {
    int device_id = 0;

    switch (eventTypePhase.second) {
      case Accessed:
        device_id = _touchMapper.identifierOf(touch);
        break;
      case Added:
        device_id = _touchMapper.registerTouch(touch);
        break;
      case Removed:
        device_id = _touchMapper.unregisterTouch(touch);
        break;
    }

    FXL_DCHECK(device_id != 0);
    CGPoint windowCoordinates = [touch locationInView:nil];

    blink::PointerData pointer_data;
    pointer_data.Clear();

    constexpr int kMicrosecondsPerSecond = 1000 * 1000;
    pointer_data.time_stamp = touch.timestamp * kMicrosecondsPerSecond;

    pointer_data.change = eventTypePhase.first;

    pointer_data.kind = DeviceKindFromTouchType(touch, _platformSupportsTouchTypes);

    pointer_data.device = device_id;

    pointer_data.physical_x = windowCoordinates.x * scale;
    pointer_data.physical_y = windowCoordinates.y * scale;

    // pressure_min is always 0.0
    if (_platformSupportsTouchPressure) {
      // These properties were introduced in iOS 9.0.
      pointer_data.pressure = touch.force;
      pointer_data.pressure_max = touch.maximumPossibleForce;
    } else {
      pointer_data.pressure = 1.0;
      pointer_data.pressure_max = 1.0;
    }

    // These properties were introduced in iOS 8.0
    pointer_data.radius_major = touch.majorRadius;
    pointer_data.radius_min = touch.majorRadius - touch.majorRadiusTolerance;
    pointer_data.radius_max = touch.majorRadius + touch.majorRadiusTolerance;

    // These properties were introduced in iOS 9.1
    if (_platformSupportsTouchOrientationAndTilt) {
      // iOS Documentation: altitudeAngle
      // A value of 0 radians indicates that the stylus is parallel to the surface. The value of
      // this property is Pi/2 when the stylus is perpendicular to the surface.
      //
      // PointerData Documentation: tilt
      // The angle of the stylus, in radians in the range:
      //    0 <= tilt <= pi/2
      // giving the angle of the axis of the stylus, relative to the axis perpendicular to the input
      // surface (thus 0.0 indicates the stylus is orthogonal to the plane of the input surface,
      // while pi/2 indicates that the stylus is flat on that surface).
      //
      // Discussion:
      // The ranges are the same. Origins are swapped.
      pointer_data.tilt = M_PI_2 - touch.altitudeAngle;

      // iOS Documentation: azimuthAngleInView:
      // With the tip of the stylus touching the screen, the value of this property is 0 radians
      // when the cap end of the stylus (that is, the end opposite of the tip) points along the
      // positive x axis of the device's screen. The azimuth angle increases as the user swings the
      // cap end of the stylus in a clockwise direction around the tip.
      //
      // PointerData Documentation: orientation
      // The angle of the stylus, in radians in the range:
      //    -pi < orientation <= pi
      // giving the angle of the axis of the stylus projected onto the input surface, relative to
      // the positive y-axis of that surface (thus 0.0 indicates the stylus, if projected onto that
      // surface, would go from the contact point vertically up in the positive y-axis direction, pi
      // would indicate that the stylus would go down in the negative y-axis direction; pi/4 would
      // indicate that the stylus goes up and to the right, -pi/2 would indicate that the stylus
      // goes to the left, etc).
      //
      // Discussion:
      // Sweep direction is the same. Phase of M_PI_2.
      pointer_data.orientation = [touch azimuthAngleInView:nil] - M_PI_2;
    }

    packet->SetPointerData(i++, pointer_data);
  }

  blink::Threads::UI()->PostTask(fxl::MakeCopyable(
      [ engine = _platformView->engine().GetWeakPtr(), packet = std::move(packet) ] {
        if (engine.get())
          engine->DispatchPointerDataPacket(*packet);
      }));
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseBegan];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseMoved];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseEnded];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseCancelled];
}

#pragma mark - Handle view resizing

- (void)updateViewportMetrics {
  blink::Threads::UI()->PostTask(
      [ weak_platform_view = _platformView->GetWeakPtr(), metrics = _viewportMetrics ] {
        if (!weak_platform_view) {
          return;
        }
        weak_platform_view->UpdateSurfaceSize();
        weak_platform_view->engine().SetViewportMetrics(metrics);
      });
}

- (CGFloat)statusBarPadding {
  UIScreen* screen = self.view.window.screen;
  CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
  CGRect viewFrame =
      [self.view convertRect:self.view.bounds toCoordinateSpace:screen.coordinateSpace];
  CGRect intersection = CGRectIntersection(statusFrame, viewFrame);
  return CGRectIsNull(intersection) ? 0.0 : intersection.size.height;
}

- (void)viewDidLayoutSubviews {
  CGSize viewSize = self.view.bounds.size;
  CGFloat scale = [UIScreen mainScreen].scale;

  // First time since creation that the dimensions of its view is known.
  bool firstViewBoundsUpdate = !_viewportMetrics.physical_width;
  _viewportMetrics.device_pixel_ratio = scale;
  _viewportMetrics.physical_width = viewSize.width * scale;
  _viewportMetrics.physical_height = viewSize.height * scale;

  [self updateViewportPadding];
  [self updateViewportMetrics];

  // This must run after updateViewportMetrics so that the surface creation tasks are queued after
  // the viewport metrics update tasks.
  if (firstViewBoundsUpdate)
    [self surfaceUpdated:YES];
}

- (void)viewSafeAreaInsetsDidChange {
  if (_platformSupportsSafeAreaInsets) {
    [self updateViewportPadding];
    [self updateViewportMetrics];
    [super viewSafeAreaInsetsDidChange];
  }
}

// Updates _viewportMetrics physical padding.
//
// Viewport padding represents the iOS safe area insets.
- (void)updateViewportPadding {
  CGFloat scale = [UIScreen mainScreen].scale;
  // TODO(cbracken) once clang toolchain compiler-rt has been updated, replace with
  // if (@available(iOS 11, *)) {
  if (_platformSupportsSafeAreaInsets) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
    _viewportMetrics.physical_padding_top = self.view.safeAreaInsets.top * scale;
    _viewportMetrics.physical_padding_left = self.view.safeAreaInsets.left * scale;
    _viewportMetrics.physical_padding_right = self.view.safeAreaInsets.right * scale;
    _viewportMetrics.physical_padding_bottom = self.view.safeAreaInsets.bottom * scale;
#pragma clang diagnostic pop
  } else {
    _viewportMetrics.physical_padding_top = [self statusBarPadding] * scale;
  }
}

#pragma mark - Keyboard events

- (void)keyboardWillChangeFrame:(NSNotification*)notification {
  NSDictionary* info = [notification userInfo];
  CGFloat bottom = CGRectGetHeight([[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]);
  CGFloat scale = [UIScreen mainScreen].scale;
  _viewportMetrics.physical_view_inset_bottom = bottom * scale;
  [self updateViewportMetrics];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
  _viewportMetrics.physical_view_inset_bottom = 0;
  [self updateViewportMetrics];
}

#pragma mark - Text input delegate

- (void)updateEditingClient:(int)client withState:(NSDictionary*)state {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.updateEditingState"
                              arguments:@[ @(client), state ]];
}

- (void)performAction:(FlutterTextInputAction)action withClient:(int)client {
  NSString* actionString;
  switch (action) {
    case FlutterTextInputActionDone:
      actionString = @"TextInputAction.done";
      break;
    case FlutterTextInputActionNewline:
      actionString = @"TextInputAction.newline";
      break;
  }
  [_textInputChannel.get() invokeMethod:@"TextInputClient.performAction"
                              arguments:@[ @(client), actionString ]];
}

#pragma mark - Orientation updates

- (void)onOrientationPreferencesUpdated:(NSNotification*)notification {
  // Notifications may not be on the iOS UI thread
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDictionary* info = notification.userInfo;

    NSNumber* update = info[@(shell::kOrientationUpdateNotificationKey)];

    if (update == nil) {
      return;
    }

    NSUInteger new_preferences = update.unsignedIntegerValue;

    if (new_preferences != _orientationPreferences) {
      _orientationPreferences = new_preferences;
      [UIViewController attemptRotationToDeviceOrientation];
    }
  });
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return _orientationPreferences;
}

#pragma mark - Accessibility

- (void)onVoiceOverChanged:(NSNotification*)notification {
#if TARGET_OS_SIMULATOR
  // There doesn't appear to be any way to determine whether the accessibility
  // inspector is enabled on the simulator. We conservatively always turn on the
  // accessibility bridge in the simulator.
  bool enabled = true;
#else
  bool enabled = UIAccessibilityIsVoiceOverRunning();
#endif
  _platformView->ToggleAccessibility(self.view, enabled);
}

#pragma mark - Memory Notifications

- (void)onMemoryWarning:(NSNotification*)notification {
  [_systemChannel.get() sendMessage:@{@"type" : @"memoryPressure"}];
}

#pragma mark - Locale updates

- (void)onLocaleUpdated:(NSNotification*)notification {
  NSLocale* currentLocale = [NSLocale currentLocale];
  NSString* languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
  NSString* countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
  [_localizationChannel.get() invokeMethod:@"setLocale" arguments:@[ languageCode, countryCode ]];
}

#pragma mark - Set user settings

- (void)onUserSettingsChanged:(NSNotification*)notification {
  [_settingsChannel.get() sendMessage:@{
    @"textScaleFactor" : @([self textScaleFactor]),
    @"alwaysUse24HourFormat" : @([self isAlwaysUse24HourFormat]),
  }];
}

- (CGFloat)textScaleFactor {
  UIContentSizeCategory category = [UIApplication sharedApplication].preferredContentSizeCategory;
  // The delta is computed based on the following:
  // - L (large) is the default 1.0 scale.
  // - The scale is linear spanning from XS to XXXL.
  // - XXXL = 1.4 * XS.
  //
  // L    = 1.0      = XS + 3 * delta
  // XXXL = 1.4 * XS = XS + 6 * delta
  const CGFloat delta = 0.055555;
  if ([category isEqualToString:UIContentSizeCategoryExtraSmall])
    return 1.0 - 3 * delta;
  else if ([category isEqualToString:UIContentSizeCategorySmall])
    return 1.0 - 2 * delta;
  else if ([category isEqualToString:UIContentSizeCategoryMedium])
    return 1.0 - delta;
  else if ([category isEqualToString:UIContentSizeCategoryLarge])
    return 1.0;
  else if ([category isEqualToString:UIContentSizeCategoryExtraLarge])
    return 1.0 + delta;
  else if ([category isEqualToString:UIContentSizeCategoryExtraExtraLarge])
    return 1.0 + 2 * delta;
  else if ([category isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge])
    return 1.0 + 3 * delta;
  else
    return 1.0;
}

- (BOOL)isAlwaysUse24HourFormat {
  // iOS does not report its "24-Hour Time" user setting in the API. Instead, it applies
  // it automatically to NSDateFormatter when used with [NSLocale currentLocale]. It is
  // essential that [NSLocale currentLocale] is used. Any custom locale, even the one
  // that's the same as [NSLocale currentLocale] will ignore the 24-hour option (there
  // must be some internal field that's not exposed to developers).
  //
  // Therefore this option behaves differently across Android and iOS. On Android this
  // setting is exposed standalone, and can therefore be applied to all locales, whether
  // the "current system locale" or a custom one. On iOS it only applies to the current
  // system locale. Widget implementors must take this into account in order to provide
  // platform-idiomatic behavior in their widgets.
  NSString* dateFormat =
      [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
  return [dateFormat rangeOfString:@"a"].location == NSNotFound;
}

#pragma mark - Status Bar touch event handling

// Standard iOS status bar height in pixels.
constexpr CGFloat kStandardStatusBarHeight = 20.0;

- (void)handleStatusBarTouches:(UIEvent*)event {
  // If the status bar is double-height, don't handle status bar taps. iOS
  // should open the app associated with the status bar.
  CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
  if (statusBarFrame.size.height != kStandardStatusBarHeight) {
    return;
  }

  // If we detect a touch in the status bar, synthesize a fake touch begin/end.
  for (UITouch* touch in event.allTouches) {
    if (touch.phase == UITouchPhaseBegan && touch.tapCount > 0) {
      CGPoint windowLoc = [touch locationInView:nil];
      CGPoint screenLoc = [touch.window convertPoint:windowLoc toWindow:nil];
      if (CGRectContainsPoint(statusBarFrame, screenLoc)) {
        NSSet* statusbarTouches = [NSSet setWithObject:touch];
        [self dispatchTouches:statusbarTouches phase:UITouchPhaseBegan];
        [self dispatchTouches:statusbarTouches phase:UITouchPhaseEnded];
        return;
      }
    }
  }
}

#pragma mark - Status bar style

- (UIStatusBarStyle)preferredStatusBarStyle {
  return _statusBarStyle;
}

- (void)onPreferredStatusBarStyleUpdated:(NSNotification*)notification {
  // Notifications may not be on the iOS UI thread
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDictionary* info = notification.userInfo;

    NSNumber* update = info[@(shell::kOverlayStyleUpdateNotificationKey)];

    if (update == nil) {
      return;
    }

    NSInteger style = update.integerValue;

    if (style != _statusBarStyle) {
      _statusBarStyle = static_cast<UIStatusBarStyle>(style);
      [self setNeedsStatusBarAppearanceUpdate];
    }
  });
}

#pragma mark - FlutterBinaryMessenger

- (void)sendOnChannel:(NSString*)channel message:(NSData*)message {
  [self sendOnChannel:channel message:message binaryReply:nil];
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData*)message
          binaryReply:(FlutterBinaryReply)callback {
  NSAssert(channel, @"The channel must not be null");
  fxl::RefPtr<PlatformMessageResponseDarwin> response =
      (callback == nil) ? nullptr
                        : fxl::MakeRefCounted<PlatformMessageResponseDarwin>(^(NSData* reply) {
                            callback(reply);
                          });
  fxl::RefPtr<blink::PlatformMessage> platformMessage =
      (message == nil) ? fxl::MakeRefCounted<blink::PlatformMessage>(channel.UTF8String, response)
                       : fxl::MakeRefCounted<blink::PlatformMessage>(
                             channel.UTF8String, shell::GetVectorFromNSData(message), response);
  _platformView->DispatchPlatformMessage(platformMessage);
}

- (void)setMessageHandlerOnChannel:(NSString*)channel
              binaryMessageHandler:(FlutterBinaryMessageHandler)handler {
  NSAssert(channel, @"The channel must not be null");
  _platformView->platform_message_router().SetMessageHandler(channel.UTF8String, handler);
}

#pragma mark - FlutterTextureRegistry

- (int64_t)registerTexture:(NSObject<FlutterTexture>*)texture {
  int64_t textureId = _nextTextureId++;
  _platformView->RegisterExternalTexture(textureId, texture);
  return textureId;
}

- (void)unregisterTexture:(int64_t)textureId {
  _platformView->UnregisterTexture(textureId);
}

- (void)textureFrameAvailable:(int64_t)textureId {
  _platformView->MarkTextureFrameAvailable(textureId);
}
@end
