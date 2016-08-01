// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky/shell/platform/ios/framework/Headers/FlutterViewController.h"

#include "base/bind.h"
#include "base/mac/scoped_block.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/mac/scoped_nsobject.h"
#include "base/strings/sys_string_conversions.h"
#include "base/trace_event/trace_event.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "sky/engine/wtf/MakeUnique.h"
#include "sky/services/engine/sky_engine.mojom.h"
#include "sky/services/platform/app_messages.mojom.h"
#include "sky/services/platform/ios/system_chrome_impl.h"
#include "sky/services/semantics/semantics.mojom.h"
#include "sky/shell/platform/ios/framework/Source/accessibility_bridge.h"
#include "sky/shell/platform/ios/framework/Source/application_messages_impl.h"
#include "sky/shell/platform/ios/framework/Source/flutter_touch_mapper.h"
#include "sky/shell/platform/ios/framework/Source/FlutterDartProject_Internal.h"
#include "sky/shell/platform/ios/framework/Source/FlutterDynamicServiceLoader.h"
#include "sky/shell/platform/ios/framework/Source/FlutterView.h"
#include "sky/shell/platform/ios/platform_view_ios.h"
#include "sky/shell/platform/mac/platform_mac.h"
#include "sky/shell/platform/mac/platform_service_provider.h"
#include "sky/shell/platform/mac/view_service_provider.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/shell.h"

@interface FlutterViewController ()<UIAlertViewDelegate>
@end

void FlutterInit(int argc, const char* argv[]) {
  NSBundle* bundle = [NSBundle bundleForClass:[FlutterViewController class]];
  NSString* icuDataPath = [bundle pathForResource:@"icudtl" ofType:@"dat"];
  sky::shell::PlatformMacMain(argc, argv, icuDataPath.UTF8String);
}

@implementation FlutterViewController {
  base::scoped_nsprotocol<FlutterDartProject*> _dartProject;
  UIInterfaceOrientationMask _orientationPreferences;
  UIStatusBarStyle _statusBarStyle;
  base::scoped_nsprotocol<FlutterDynamicServiceLoader*> _dynamicServiceLoader;
  sky::ViewportMetricsPtr _viewportMetrics;
  sky::shell::TouchMapper _touchMapper;
  std::unique_ptr<sky::shell::PlatformViewIOS> _platformView;
  sky::SkyEnginePtr _engine;
  mojo::ServiceProviderPtr _dartServices;
  std::unique_ptr<sky::shell::AccessibilityBridge> _accessibilityBridge;
  flutter::platform::ApplicationMessagesPtr _appMessageSender;
  sky::shell::ApplicationMessagesImpl _appMessageReceiver;
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
  _dynamicServiceLoader.reset([[FlutterDynamicServiceLoader alloc] init]);
  _viewportMetrics = sky::ViewportMetrics::New();
  _platformView = WTF::MakeUnique<sky::shell::PlatformViewIOS>(
      reinterpret_cast<CAEAGLLayer*>(self.view.layer));
  _platformView->SetupResourceContextOnIOThread();

  [self setupTracing];

  [self setupNotificationCenterObservers];

  [self connectToEngineAndLoad];
}

- (void)setupTracing {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  base::FilePath tracesPath =
      base::FilePath::FromUTF8Unsafe([paths.firstObject UTF8String]);

  sky::shell::Shell::Shared().tracing_controller().set_traces_base_path(
      tracesPath);
}

- (void)setupNotificationCenterObservers {
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onOrientationPreferencesUpdated:)
                 name:@(flutter::platform::kOrientationUpdateNotificationName)
               object:nil];

  [center addObserver:self
             selector:@selector(onPreferredStatusBarStyleUpdated:)
                 name:@(flutter::platform::kOverlayStyleUpdateNotificationName)
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

  _platformView->ConnectToEngine(mojo::GetProxy(&_engine));

  [self setupPlatformServiceProvider];

  // We ask the VM to check what it supports.
  const enum VMType type =
      Dart_IsPrecompiledRuntime() ? VMTypePrecompilation : VMTypeInterpreter;

  [_dartProject launchInEngine:_engine
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

  DCHECK(_dartServices);
  mojo::ConnectToService(_dartServices.get(),
                         mojo::GetProxy(&_appMessageSender));
}

static void DynamicServiceResolve(void* baton,
                                  const mojo::String& service_name,
                                  mojo::ScopedMessagePipeHandle handle) {
  base::mac::ScopedNSAutoreleasePool pool;
  auto loader = reinterpret_cast<FlutterDynamicServiceLoader*>(baton);
  [loader resolveService:@(service_name.data()) handle:handle.Pass()];
}

- (void)setupPlatformServiceProvider {
  mojo::ServiceProviderPtr serviceProvider;

  auto serviceProviderProxy = mojo::GetProxy(&serviceProvider);
  // TODO(eseidel): this unretained reference might not be safe since
  // the engine could outlive this controller
  auto serviceResolutionCallback = base::Bind(
      &DynamicServiceResolve,
      base::Unretained(reinterpret_cast<void*>(_dynamicServiceLoader.get())));

  new sky::shell::PlatformServiceProvider(serviceProviderProxy.Pass(),
                                          serviceResolutionCallback);

  mojo::ServiceProviderPtr viewServiceProvider;
  new sky::shell::ViewServiceProvider(
      base::Bind(&sky::shell::ApplicationMessagesImpl::AddBinding,
                 _appMessageReceiver.GetWeakPtr()),
      mojo::GetProxy(&viewServiceProvider));

  DCHECK(!_dartServices.is_bound());
  sky::ServicesDataPtr services = sky::ServicesData::New();
  services->incoming_services = serviceProvider.Pass();
  services->outgoing_services = mojo::GetProxy(&_dartServices);
  services->view_services = viewServiceProvider.Pass();
  _engine->SetServices(services.Pass());
}

#pragma mark - Loading the view

- (void)loadView {
  FlutterView* surface = [[FlutterView alloc] init];

  self.view = surface;
  self.view.multipleTouchEnabled = YES;
  self.view.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [self onVoiceOverChanged:nil];

  [surface release];
}

#pragma mark - Application lifecycle notifications

- (void)applicationBecameActive:(NSNotification*)notification {
  if (_engine) {
    _engine->OnAppLifecycleStateChanged(sky::AppLifecycleState::RESUMED);
  }
}

- (void)applicationWillResignActive:(NSNotification*)notification {
  if (_engine) {
    _engine->OnAppLifecycleStateChanged(sky::AppLifecycleState::PAUSED);
  }
}

#pragma mark - Touch event handling

enum MapperPhase {
  Accessed,
  Added,
  Removed,
};

using PointerTypeMapperPhase = std::pair<pointer::PointerType, MapperPhase>;
static inline PointerTypeMapperPhase PointerTypePhaseFromUITouchPhase(
    UITouchPhase phase) {
  switch (phase) {
    case UITouchPhaseBegan:
      return PointerTypeMapperPhase(pointer::PointerType::DOWN,
                                    MapperPhase::Added);
    case UITouchPhaseMoved:
    case UITouchPhaseStationary:
      // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
      // with the same coordinates
      return PointerTypeMapperPhase(pointer::PointerType::MOVE,
                                    MapperPhase::Accessed);
    case UITouchPhaseEnded:
      return PointerTypeMapperPhase(pointer::PointerType::UP,
                                    MapperPhase::Removed);
    case UITouchPhaseCancelled:
      return PointerTypeMapperPhase(pointer::PointerType::CANCEL,
                                    MapperPhase::Removed);
  }

  return PointerTypeMapperPhase(pointer::PointerType::CANCEL,
                                MapperPhase::Accessed);
}

- (void)dispatchTouches:(NSSet*)touches phase:(UITouchPhase)phase {
  auto eventTypePhase = PointerTypePhaseFromUITouchPhase(phase);
  const CGFloat scale = [UIScreen mainScreen].scale;
  auto pointer_packet = pointer::PointerPacket::New();

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

    auto pointer_time =
        base::TimeDelta::FromSecondsD(touch.timestamp).InMicroseconds();

    auto pointer_data = pointer::Pointer::New();

    pointer_data->time_stamp = pointer_time;
    pointer_data->type = eventTypePhase.first;
    pointer_data->kind = pointer::PointerKind::TOUCH;
    pointer_data->pointer = touch_identifier;
    pointer_data->x = windowCoordinates.x * scale;
    pointer_data->y = windowCoordinates.y * scale;
    pointer_data->buttons = 0;
    pointer_data->down = false;
    pointer_data->primary = false;
    pointer_data->obscured = false;
    pointer_data->pressure = 1.0;
    pointer_data->pressure_min = 0.0;
    pointer_data->pressure_max = 1.0;
    pointer_data->distance = 0.0;
    pointer_data->distance_min = 0.0;
    pointer_data->distance_max = 0.0;
    pointer_data->radius_major = 0.0;
    pointer_data->radius_minor = 0.0;
    pointer_data->radius_min = 0.0;
    pointer_data->radius_max = 0.0;
    pointer_data->orientation = 0.0;
    pointer_data->tilt = 0.0;

    pointer_packet->pointers.push_back(pointer_data.Pass());
  }

  _engine->OnPointerPacket(pointer_packet.Pass());
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

  _engine->OnViewportMetricsChanged(_viewportMetrics.Clone());

  [self onLocaleUpdated:nil];
}

#pragma mark - Keyboard events

- (void)keyboardWasShown:(NSNotification*)notification {
  NSDictionary* info = [notification userInfo];
  CGFloat bottom = CGRectGetHeight(
      [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue]);
  CGFloat scale = [UIScreen mainScreen].scale;
  _viewportMetrics->physical_padding_bottom = bottom * scale;
  _engine->OnViewportMetricsChanged(_viewportMetrics.Clone());
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
  _viewportMetrics->physical_padding_bottom = 0.0;
  _engine->OnViewportMetricsChanged(_viewportMetrics.Clone());
}

#pragma mark - Orientation updates

- (void)onOrientationPreferencesUpdated:(NSNotification*)notification {
  // Notifications may not be on the iOS UI thread
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDictionary* info = notification.userInfo;

    NSNumber* update =
        info[@(flutter::platform::kOrientationUpdateNotificationKey)];

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
  bool enable = true;
#else
  bool enable = UIAccessibilityIsVoiceOverRunning();
#endif
  if (enable) {
    if (!_accessibilityBridge) {
      _accessibilityBridge.reset(
          new sky::shell::AccessibilityBridge(self.view, _dartServices.get()));
    }
  } else {
    _accessibilityBridge = nullptr;
  }
}

#pragma mark - Locale updates

- (void)onLocaleUpdated:(NSNotification*)notification {
  NSLocale* currentLocale = [NSLocale currentLocale];
  NSString* languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
  NSString* countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
  _engine->OnLocaleChanged(languageCode.UTF8String, countryCode.UTF8String);
}

#pragma mark - Surface creation and teardown updates

- (void)surfaceUpdated:(BOOL)appeared {
  CHECK(_platformView != nullptr);

  if (appeared) {
    _platformView->NotifyCreated();
  } else {
    _platformView->NotifyDestroyed();
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [self surfaceUpdated:YES];

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
        info[@(flutter::platform::kOverlayStyleUpdateNotificationKey)];

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

- (void)sendString:(NSString*)message withMessageName:(NSString*)messageName {
  NSAssert(message, @"The message must not be null");
  NSAssert(messageName, @"The messageName must not be null");
  _appMessageSender->SendString(messageName.UTF8String, message.UTF8String,
                                [](const mojo::String& response) {});
}

- (void)sendString:(NSString*)message
    withMessageName:(NSString*)messageName
           callback:(void (^)(NSString*))callback {
  NSAssert(message, @"The message must not be null");
  NSAssert(messageName, @"The messageName must not be null");
  NSAssert(callback, @"The callback must not be null");
  base::mac::ScopedBlock<void (^)(NSString*)> callback_ptr(
      callback, base::scoped_policy::RETAIN);
  _appMessageSender->SendString(
      messageName.UTF8String, message.UTF8String,
      [callback_ptr](const mojo::String& response) {
        callback_ptr.get()(base::SysUTF8ToNSString(response));
      });
}

- (void)addMessageListener:(NSObject<FlutterMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* messageName = listener.messageName;
  NSAssert(messageName, @"The messageName must not be null");
  _appMessageReceiver.SetMessageListener(messageName.UTF8String, listener);
}

- (void)removeMessageListener:(NSObject<FlutterMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* messageName = listener.messageName;
  NSAssert(messageName, @"The messageName must not be null");
  _appMessageReceiver.SetMessageListener(messageName.UTF8String, nil);
}

- (void)addAsyncMessageListener:
    (NSObject<FlutterAsyncMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* messageName = listener.messageName;
  NSAssert(messageName, @"The messageName must not be null");
  _appMessageReceiver.SetAsyncMessageListener(messageName.UTF8String, listener);
}

- (void)removeAsyncMessageListener:
    (NSObject<FlutterAsyncMessageListener>*)listener {
  NSAssert(listener, @"The listener must not be null");
  NSString* messageName = listener.messageName;
  NSAssert(messageName, @"The messageName must not be null");
  _appMessageReceiver.SetAsyncMessageListener(messageName.UTF8String, nil);
}

@end
