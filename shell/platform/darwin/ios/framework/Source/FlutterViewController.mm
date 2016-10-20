// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

#include <memory>

#include "base/mac/scoped_block.h"
#include "base/mac/scoped_nsobject.h"
#include "base/strings/sys_string_conversions.h"
#include "flutter/common/threads.h"
#include "flutter/shell/gpu/gpu_rasterizer.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/darwin/common/platform_mac.h"
#include "flutter/shell/platform/darwin/common/string_conversions.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/flutter_touch_mapper.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include "lib/ftl/functional/make_copyable.h"
#include "lib/ftl/time/time_delta.h"

namespace {

typedef void (^PlatformMessageResponseCallback)(NSString*);

class PlatformMessageResponseDarwin : public blink::PlatformMessageResponse {
  FRIEND_MAKE_REF_COUNTED(PlatformMessageResponseDarwin);

 public:
  void Complete(std::vector<uint8_t> data) override {
    ftl::RefPtr<PlatformMessageResponseDarwin> self(this);
    blink::Threads::Platform()->PostTask(
        ftl::MakeCopyable([ self, data = std::move(data) ]() mutable {
          self->callback_.get()(shell::GetNSStringFromVector(data));
        }));
  }

  void CompleteWithError() override { Complete(std::vector<uint8_t>()); }

 private:
  explicit PlatformMessageResponseDarwin(PlatformMessageResponseCallback callback)
      : callback_(callback, base::scoped_policy::RETAIN) {}

  base::mac::ScopedBlock<PlatformMessageResponseCallback> callback_;
};

}  // namespace

@interface FlutterViewController ()<UIAlertViewDelegate, FlutterTextInputDelegate>
@end

void FlutterInit(int argc, const char* argv[]) {
  NSBundle* bundle = [NSBundle bundleForClass:[FlutterViewController class]];
  NSString* icuDataPath = [bundle pathForResource:@"icudtl" ofType:@"dat"];
  shell::PlatformMacMain(argc, argv, icuDataPath.UTF8String);
}

@implementation FlutterViewController {
  base::scoped_nsprotocol<FlutterDartProject*> _dartProject;
  UIInterfaceOrientationMask _orientationPreferences;
  UIStatusBarStyle _statusBarStyle;
  sky::ViewportMetricsPtr _viewportMetrics;
  shell::TouchMapper _touchMapper;
  std::unique_ptr<shell::PlatformViewIOS> _platformView;
  base::scoped_nsprotocol<FlutterPlatformPlugin*> _platformPlugin;
  base::scoped_nsprotocol<FlutterTextInputPlugin*> _textInputPlugin;

  BOOL _initialized;
}

#pragma mark - Manage and override all designated initializers

- (instancetype)initWithProject:(FlutterDartProject*)project
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

  if (self) {
    if (project == nil)
      _dartProject.reset(
          [[FlutterDartProject alloc] initFromDefaultSourceForConfiguration]);
    else
      _dartProject.reset([project retain]);

    [self performCommonViewControllerInitialization];
  }

  return self;
}

- (instancetype)initWithNibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil {
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

  _orientationPreferences = UIInterfaceOrientationMaskAll;
  _statusBarStyle = UIStatusBarStyleDefault;
  _viewportMetrics = sky::ViewportMetrics::New();
  _platformView = std::make_unique<shell::PlatformViewIOS>(
      reinterpret_cast<CAEAGLLayer*>(self.view.layer));
  _platformView->SetupResourceContextOnIOThread();

  _platformPlugin.reset([[FlutterPlatformPlugin alloc] init]);
  [self addMessageListener:_platformPlugin.get()];


  _textInputPlugin.reset([[FlutterTextInputPlugin alloc] init]);
  _textInputPlugin.get().textInputDelegate = self;
  [self addMessageListener:_textInputPlugin.get()];

  [self setupNotificationCenterObservers];

  [self connectToEngineAndLoad];
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
             selector:@selector(keyboardWasShown:)
                 name:UIKeyboardDidShowNotification
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
}

#pragma mark - Initializing the engine

- (void)alertView:(UIAlertView*)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  exit(0);
}

- (void)connectToEngineAndLoad {
  TRACE_EVENT0("flutter", "connectToEngineAndLoad");

  _platformView->ConnectToEngineAndSetupServices();

  // We ask the VM to check what it supports.
  const enum VMType type =
      Dart_IsPrecompiledRuntime() ? VMTypePrecompilation : VMTypeInterpreter;

  [_dartProject launchInEngine:_platformView->engineProxy()
                embedderVMType:type
                        result:^(BOOL success, NSString* message) {
                          if (!success) {
                            UIAlertView* alert = [[UIAlertView alloc]
                                    initWithTitle:@"Launch Error"
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
  self.view.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [view release];
}

#pragma mark - Application lifecycle notifications

- (void)applicationBecameActive:(NSNotification*)notification {
  auto& engine = _platformView->engineProxy();
  if (engine) {
    engine->OnAppLifecycleStateChanged(sky::AppLifecycleState::RESUMED);
  }
}

- (void)applicationWillResignActive:(NSNotification*)notification {
  auto& engine = _platformView->engineProxy();
  if (engine) {
    engine->OnAppLifecycleStateChanged(sky::AppLifecycleState::PAUSED);
  }
}

#pragma mark - Touch event handling

enum MapperPhase {
  Accessed,
  Added,
  Removed,
};

using PointerChangeMapperPhase =
    std::pair<blink::PointerData::Change, MapperPhase>;
static inline PointerChangeMapperPhase PointerChangePhaseFromUITouchPhase(
    UITouchPhase phase) {
  switch (phase) {
    case UITouchPhaseBegan:
      return PointerChangeMapperPhase(blink::PointerData::Change::kDown,
                                      MapperPhase::Added);
    case UITouchPhaseMoved:
    case UITouchPhaseStationary:
      // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
      // with the same coordinates
      return PointerChangeMapperPhase(blink::PointerData::Change::kMove,
                                      MapperPhase::Accessed);
    case UITouchPhaseEnded:
      return PointerChangeMapperPhase(blink::PointerData::Change::kUp,
                                      MapperPhase::Removed);
    case UITouchPhaseCancelled:
      return PointerChangeMapperPhase(blink::PointerData::Change::kCancel,
                                      MapperPhase::Removed);
  }

  return PointerChangeMapperPhase(blink::PointerData::Change::kCancel,
                                  MapperPhase::Accessed);
}

- (void)dispatchTouches:(NSSet*)touches phase:(UITouchPhase)phase {
  auto eventTypePhase = PointerChangePhaseFromUITouchPhase(phase);
  const CGFloat scale = [UIScreen mainScreen].scale;
  auto packet = std::make_unique<blink::PointerDataPacket>(touches.count);

  int i = 0;
  for (UITouch* touch in touches) {
    int touch_identifier = 0;

    switch (eventTypePhase.second) {
      case Accessed:
        touch_identifier = _touchMapper.identifierOf(touch);
        break;
      case Added:
        touch_identifier = _touchMapper.registerTouch(touch);
        break;
      case Removed:
        touch_identifier = _touchMapper.unregisterTouch(touch);
        break;
    }

    DCHECK(touch_identifier != 0);
    CGPoint windowCoordinates = [touch locationInView:nil];

    blink::PointerData pointer_data;
    pointer_data.Clear();

    constexpr int kMicrosecondsPerSecond = 1000 * 1000;
    pointer_data.time_stamp = touch.timestamp * kMicrosecondsPerSecond;
    pointer_data.change = eventTypePhase.first;
    pointer_data.kind = blink::PointerData::DeviceKind::kTouch;
    pointer_data.pointer = touch_identifier;
    pointer_data.physical_x = windowCoordinates.x * scale;
    pointer_data.physical_y = windowCoordinates.y * scale;
    pointer_data.pressure = 1.0;
    pointer_data.pressure_max = 1.0;

    packet->SetPointerData(i++, pointer_data);
  }

  blink::Threads::UI()->PostTask(ftl::MakeCopyable([
    engine = _platformView->engine().GetWeakPtr(), packet = std::move(packet)
  ] {
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

- (void)viewDidLayoutSubviews {
  CGSize size = self.view.bounds.size;
  CGFloat scale = [UIScreen mainScreen].scale;

  _viewportMetrics->device_pixel_ratio = scale;
  _viewportMetrics->physical_width = size.width * scale;
  _viewportMetrics->physical_height = size.height * scale;
  _viewportMetrics->physical_padding_top =
      [UIApplication sharedApplication].statusBarFrame.size.height * scale;

  _platformView->engineProxy()->OnViewportMetricsChanged(
      _viewportMetrics.Clone());
}

#pragma mark - Keyboard events

- (void)keyboardWasShown:(NSNotification*)notification {
  NSDictionary* info = [notification userInfo];
  CGFloat bottom = CGRectGetHeight(
      [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue]);
  CGFloat scale = [UIScreen mainScreen].scale;
  _viewportMetrics->physical_padding_bottom = bottom * scale;
  _platformView->engineProxy()->OnViewportMetricsChanged(
      _viewportMetrics.Clone());
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
  _viewportMetrics->physical_padding_bottom = 0.0;
  _platformView->engineProxy()->OnViewportMetricsChanged(
      _viewportMetrics.Clone());
}

#pragma mark - Text input delegate

- (void)updateEditingClient:(int)client withState:(NSDictionary*)state {
  [self sendJSON:@{
    @"method": @"TextInputClient.updateEditingState",
    @"args": @[@(client), state],
  } withMessageName:@"flutter/textinputclient"];
}

#pragma mark - Orientation updates

- (void)onOrientationPreferencesUpdated:(NSNotification*)notification {
  // Notifications may not be on the iOS UI thread
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDictionary* info = notification.userInfo;

    NSNumber* update =
        info[@(shell::kOrientationUpdateNotificationKey)];

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

#pragma mark - Locale updates

- (void)onLocaleUpdated:(NSNotification*)notification {
  NSLocale* currentLocale = [NSLocale currentLocale];
  NSString* languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
  NSString* countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
  _platformView->engineProxy()->OnLocaleChanged(languageCode.UTF8String,
                                                countryCode.UTF8String);
}

#pragma mark - Surface creation and teardown updates

- (void)surfaceUpdated:(BOOL)appeared {
  CHECK(_platformView != nullptr);

  if (appeared) {
    _platformView->NotifyCreated(
        std::make_unique<shell::GPUSurfaceGL>(_platformView.get()));
  } else {
    _platformView->NotifyDestroyed();
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [self surfaceUpdated:YES];
  [self onLocaleUpdated:nil];
  [self onVoiceOverChanged:nil];

  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self surfaceUpdated:NO];

  [super viewWillDisappear:animated];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark - Status bar style

- (UIStatusBarStyle)preferredStatusBarStyle {
  return _statusBarStyle;
}

- (void)onPreferredStatusBarStyleUpdated:(NSNotification*)notification {
  // Notifications may not be on the iOS UI thread
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDictionary* info = notification.userInfo;

    NSNumber* update =
        info[@(shell::kOverlayStyleUpdateNotificationKey)];

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

#pragma mark - Application Messages

- (void)sendString:(NSString*)message withMessageName:(NSString*)channel {
  NSAssert(message, @"The message must not be null");
  NSAssert(channel, @"The channel must not be null");
  _platformView->DispatchPlatformMessage(
      ftl::MakeRefCounted<blink::PlatformMessage>(
          channel.UTF8String,
          shell::GetVectorFromNSString(message),
          nullptr));
}

- (void)sendString:(NSString*)message
    withMessageName:(NSString*)channel
           callback:(void (^)(NSString*))callback {
  NSAssert(message, @"The message must not be null");
  NSAssert(channel, @"The channel must not be null");
  NSAssert(callback, @"The callback must not be null");
  _platformView->DispatchPlatformMessage(
      ftl::MakeRefCounted<blink::PlatformMessage>(
          channel.UTF8String,
          shell::GetVectorFromNSString(message),
          ftl::MakeRefCounted<PlatformMessageResponseDarwin>(callback)));
}

- (void)sendJSON:(NSDictionary*)message withMessageName:(NSString*)channel {
  NSData* data = [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
  if (!data)
    return;
  const uint8_t* bytes = static_cast<const uint8_t*>(data.bytes);
  _platformView->DispatchPlatformMessage(
      ftl::MakeRefCounted<blink::PlatformMessage>(
          channel.UTF8String,
          std::vector<uint8_t>(bytes, bytes + data.length),
          nullptr));
}

- (void)addMessageListener:(NSObject<FlutterMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* channel = listener.messageName;
  NSAssert(channel, @"The channel must not be null");
  _platformView->platform_message_router().SetMessageListener(channel.UTF8String,
                                                              listener);
}

- (void)removeMessageListener:(NSObject<FlutterMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* channel = listener.messageName;
  NSAssert(channel, @"The channel must not be null");
  _platformView->platform_message_router().SetMessageListener(channel.UTF8String,
                                                              nil);
}

- (void)addAsyncMessageListener:
    (NSObject<FlutterAsyncMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* messageName = listener.messageName;
  NSAssert(messageName, @"The messageName must not be null");
  _platformView->platform_message_router().SetAsyncMessageListener(
      messageName.UTF8String, listener);
}

- (void)removeAsyncMessageListener:
    (NSObject<FlutterAsyncMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* messageName = listener.messageName;
  NSAssert(messageName, @"The messageName must not be null");
  _platformView->platform_message_router().SetAsyncMessageListener(
      messageName.UTF8String, nil);
}

@end
