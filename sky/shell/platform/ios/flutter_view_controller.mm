// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky/shell/platform/ios/public/FlutterViewController.h"
#import "sky/shell/platform/ios/public/FlutterViewController.h"

#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/wtf/MakeUnique.h"
#include "sky/services/engine/sky_engine.mojom.h"
#include "sky/services/platform/ios/system_chrome_impl.h"
#include "sky/shell/platform/ios/flutter_dynamic_service_loader.h"
#include "sky/shell/platform/ios/flutter_touch_mapper.h"
#include "sky/shell/platform/ios/flutter_view.h"
#include "sky/shell/platform/mac/platform_mac.h"
#include "sky/shell/platform/mac/platform_view_mac.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"

@implementation FlutterViewController {
  NSBundle* _dartBundle;
  UIInterfaceOrientationMask _orientationPreferences;
  FlutterDynamicServiceLoader* _dynamicServiceLoader;
  sky::ViewportMetricsPtr _viewportMetrics;
  sky::shell::TouchMapper _touchMapper;
  std::unique_ptr<sky::shell::ShellView> _shellView;
  sky::SkyEnginePtr _engine;
  BOOL _initialized;
}

#pragma mark - Manage and override all designated initializers

- (instancetype)initWithDartBundle:(NSBundle*)dartBundleOrNil
                           nibName:(NSString*)nibNameOrNil
                            bundle:(NSBundle*)bundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:bundleOrNil];

  if (self) {
    _dartBundle = [dartBundleOrNil retain];

    [self performCommonViewControllerInitialization];
  }

  return self;
}

- (instancetype)initWithNibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil {
  return [self initWithDartBundle:nil nibName:nil bundle:nil];
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
  return [self initWithDartBundle:nil nibName:nil bundle:nil];
}

#pragma mark - Implement convenience initializers

- (instancetype)initWithDartBundle:(NSBundle*)dartBundle {
  return [self initWithDartBundle:dartBundle nibName:nil bundle:nil];
}

#pragma mark - Common view controller initialization tasks

- (void)performCommonViewControllerInitialization {
  if (_initialized) {
    return;
  }

  _initialized = YES;

  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  NSString* icuDataPath = [bundle pathForResource:@"icudtl" ofType:@"dat"];

  sky::shell::PlatformMacMain(0, nullptr, icuDataPath.UTF8String);

  _orientationPreferences = UIInterfaceOrientationMaskAll;
  _dynamicServiceLoader = [[FlutterDynamicServiceLoader alloc] init];
  _viewportMetrics = sky::ViewportMetrics::New();
  _shellView =
      WTF::MakeUnique<sky::shell::ShellView>(sky::shell::Shell::Shared());

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
}

#pragma mark - Initializing the engine

- (void)connectToEngineAndLoad {
  TRACE_EVENT0("flutter", "connectToEngineAndLoad");

  _shellView->view()->ConnectToEngine(mojo::GetProxy(&_engine));

  [self setupPlatformServiceProvider];

#if TARGET_IPHONE_SIMULATOR
  [self runFromDartSource];
#else
  [self runFromPrecompiledSource];
#endif
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
  auto serviceResolutionCallback = base::Bind(
      &DynamicServiceResolve,
      base::Unretained(reinterpret_cast<void*>(_dynamicServiceLoader)));

  new sky::shell::PlatformServiceProvider(serviceProviderProxy.Pass(),
                                          serviceResolutionCallback);

  sky::ServicesDataPtr services = sky::ServicesData::New();
  services->services_provided_by_embedder = serviceProvider.Pass();
  _engine->SetServices(services.Pass());
}

#if TARGET_IPHONE_SIMULATOR

- (void)runFromDartSource {
  if (sky::shell::AttemptLaunchFromCommandLineSwitches(_engine)) {
    return;
  }

  UIAlertView* alert = [[UIAlertView alloc]
          initWithTitle:@"Error"
                message:@"Could not resolve one or all of either the main dart "
                        @"file path, the FLX bundle path or the package root "
                        @"on the host. Use the tooling to relaunch the "
                        @"application."
               delegate:self
      cancelButtonTitle:@"OK"
      otherButtonTitles:nil];
  [alert show];
  [alert release];
}

#else

- (void)runFromPrecompiledSource {
  mojo::String bundle_path([self flxBundlePath]);
  CHECK(bundle_path.size() != 0)
      << "There must be a valid FLX bundle to run the application";
  _engine->RunFromPrecompiledSnapshot(bundle_path);
}

- (const char*)flxBundlePath {
  // In case this runner is part of the precompilation SDK, the FLX bundle is
  // present in the application bundle instead of the runner bundle. Attempt
  // to resolve the path there first.

  NSString* path = [_dartBundle pathForResource:@"app" ofType:@"flx"];

  if (path.length != 0) {
    return path.UTF8String;
  }

  return
      [[NSBundle mainBundle] pathForResource:@"app" ofType:@"flx"].UTF8String;
}

#endif  // TARGET_IPHONE_SIMULATOR

#pragma mark - Loading the view

- (void)loadView {
  FlutterView* surface = [[FlutterView alloc] init];

  self.view = surface;
  self.view.multipleTouchEnabled = YES;
  self.view.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

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

#pragma mark - Locale updates

- (void)onLocaleUpdated:(NSNotification*)notification {
  NSLocale* currentLocale = [NSLocale currentLocale];
  NSString* languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
  NSString* countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
  _engine->OnLocaleChanged(languageCode.UTF8String, countryCode.UTF8String);
}

#pragma mark - Surface creation and teardown updates

- (void)surfaceUpdated:(BOOL)appeared {
  auto view =
      reinterpret_cast<sky::shell::PlatformViewMac*>(_shellView->view());

  // The widget is a reference to the CALayer (EAGL) of the view.
  auto widget = reinterpret_cast<gfx::AcceleratedWidget>(self.view.layer);

  if (appeared) {
    view->SurfaceCreated(widget);
  } else {
    view->SurfaceDestroyed();
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [self surfaceUpdated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self surfaceUpdated:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [_dynamicServiceLoader release];
  [_dartBundle release];

  [super dealloc];
}

@end
