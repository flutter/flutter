// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_surface.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#include "base/command_line.h"
#include "base/logging.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "sky/services/engine/input_event.mojom.h"
#include "sky/services/pointer/pointer.mojom.h"
#include "sky/shell/platform/ios/sky_dynamic_service_loader.h"
#include "sky/shell/platform/mac/platform_mac.h"
#include "sky/shell/platform/mac/platform_service_provider.h"
#include "sky/shell/platform/mac/platform_view_mac.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"
#include "sky/shell/switches.h"
#include "sky/shell/ui_delegate.h"
#include <strings.h>

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

static inline int64 InputEventTimestampFromNSTimeInterval(
    NSTimeInterval interval) {
  return base::TimeDelta::FromSecondsD(interval).InMicroseconds();
}

// UITouch pointers cannot be used as touch ids (even though they remain
// constant throughout the multitouch sequence) because internal components
// assume that ids are < 16. This class maps touch pointers to ids
class TouchMapper {
 public:
  TouchMapper() : free_spots_(~0) {}

  int registerTouch(uintptr_t touch) {
    int freeSpot = ffsll(free_spots_);
    touch_map_[touch] = freeSpot;
    free_spots_ &= ~(1 << (freeSpot - 1));
    return freeSpot;
  }

  int unregisterTouch(uintptr_t touch) {
    auto index = touch_map_[touch];
    free_spots_ |= 1 << (index - 1);
    touch_map_.erase(touch);
    return index;
  }

  int identifierOf(uintptr_t touch) { return touch_map_[touch]; }

 private:
  using BitSet = long long int;
  BitSet free_spots_;
  std::map<uintptr_t, int> touch_map_;
};

static void DynamicServiceResolve(void* baton,
                                  const mojo::String& service_name,
                                  mojo::ScopedMessagePipeHandle handle) {
  @autoreleasepool {
    auto loader = reinterpret_cast<SkyDynamicServiceLoader*>(baton);
    [loader resolveService:@(service_name.data()) handle:handle.Pass()];
  }
}

@interface SkySurface ()<UIInputViewAudioFeedback>

@end

@implementation SkySurface {
  BOOL _platformViewInitialized;
  CGPoint _lastScrollTranslation;
  sky::ViewportMetricsPtr _viewportMetrics;

  sky::SkyEnginePtr _engine;
  SkyDynamicServiceLoader* _dynamic_service_loader;
  std::unique_ptr<sky::shell::ShellView> _shell_view;
  TouchMapper _touch_mapper;
}

static std::string TracesBasePath() {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  return [paths.firstObject UTF8String];
}

- (instancetype)initWithShellView:(sky::shell::ShellView*)shellView {
  TRACE_EVENT0("flutter", "initWithShellView");
  self = [super init];
  if (self) {
    _viewportMetrics = sky::ViewportMetrics::New();

    base::FilePath tracesPath =
        base::FilePath::FromUTF8Unsafe(TracesBasePath());
    sky::shell::Shell::Shared().tracing_controller().set_traces_base_path(
        tracesPath);

    _shell_view.reset(shellView);
    self.multipleTouchEnabled = YES;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(applicationBecameActive:)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(applicationWillResignActive:)
               name:UIApplicationWillResignActiveNotification
             object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(keyboardWasShown:)
               name:UIKeyboardDidShowNotification
             object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(keyboardWillBeHidden:)
               name:UIKeyboardWillHideNotification
             object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(onLocaleUpdated:)
               name:NSCurrentLocaleDidChangeNotification
             object:nil];
  }
  return self;
}

- (gfx::AcceleratedWidget)acceleratedWidget {
  return (gfx::AcceleratedWidget)self.layer;
}

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

- (void)onLocaleUpdated:(NSNotification*)notification {
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    _engine->OnLocaleChanged(languageCode.UTF8String, countryCode.UTF8String);
}

- (void)layoutSubviews {
  TRACE_EVENT0("flutter", "layoutSubviews");
  [super layoutSubviews];

  [self configureLayerDefaults];

  [self setupPlatformViewIfNecessary];

  CGSize size = self.bounds.size;
  CGFloat scale = [UIScreen mainScreen].scale;

  _viewportMetrics->device_pixel_ratio = scale;
  _viewportMetrics->physical_width = size.width * scale;
  _viewportMetrics->physical_height = size.height * scale;
  _viewportMetrics->physical_padding_top =
      [UIApplication sharedApplication].statusBarFrame.size.height * scale;

  _engine->OnViewportMetricsChanged(_viewportMetrics.Clone());
}

- (void)configureLayerDefaults {
  CAEAGLLayer* layer = reinterpret_cast<CAEAGLLayer*>(self.layer);
  layer.allowsGroupOpacity = YES;
  layer.opaque = YES;
  CGFloat screenScale = [UIScreen mainScreen].scale;
  layer.contentsScale = screenScale;
  // Note: shouldRasterize is still NO. This is just a defensive measure
  layer.rasterizationScale = screenScale;
}

- (void)setupPlatformViewIfNecessary {
  if (_platformViewInitialized) {
    return;
  }

  _platformViewInitialized = YES;

  [self connectToEngineAndLoad];
}

- (sky::shell::PlatformViewMac*)platformView {
  auto view = static_cast<sky::shell::PlatformViewMac*>(_shell_view->view());
  DCHECK(view);
  return view;
}

- (const char*)flxBundlePath {
  // In case this runner is part of the precompilation SDK, the FLX bundle is
  // present in the application bundle instead of the runner bundle. Attempt
  // to resolve the path there first.
  NSBundle* applicationBundle = [NSBundle
      bundleWithIdentifier:@"io.flutter.application.FlutterApplication"];
  NSString* path = [applicationBundle pathForResource:@"app" ofType:@"flx"];
  if (path.length != 0) {
    return path.UTF8String;
  }
  return
      [[NSBundle mainBundle] pathForResource:@"app" ofType:@"flx"].UTF8String;
}

- (void)connectToEngineAndLoad {
  TRACE_EVENT0("flutter", "connectToEngineAndLoad");
  self.platformView->ConnectToEngine(mojo::GetProxy(&_engine));

  _dynamic_service_loader = [[SkyDynamicServiceLoader alloc] init];
  void* baton = _dynamic_service_loader;
  mojo::ServiceProviderPtr service_provider;
  new sky::shell::PlatformServiceProvider(
      mojo::GetProxy(&service_provider),
      base::Bind(&DynamicServiceResolve, base::Unretained(baton)));
  sky::ServicesDataPtr services = sky::ServicesData::New();
  services->services_provided_by_embedder = service_provider.Pass();
  _engine->SetServices(services.Pass());

  // Initialize to current locale
  [self onLocaleUpdated:nil];

#if TARGET_IPHONE_SIMULATOR
  [self runFromDartSource];
#else
  [self runFromPrecompiledSource];
#endif
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

#endif  // TARGET_IPHONE_SIMULATOR

#pragma mark - UIResponder overrides for raw touches

- (void)dispatchTouches:(NSSet*)touches phase:(UITouchPhase)phase {
  auto eventTypePhase = PointerTypePhaseFromUITouchPhase(phase);
  const CGFloat scale = [UIScreen mainScreen].scale;
  auto pointer_packet = pointer::PointerPacket::New();

  for (UITouch* touch in touches) {
    int touch_identifier = 0;
    uintptr_t touch_ptr = reinterpret_cast<uintptr_t>(touch);

    switch (eventTypePhase.second) {
      case Accessed:
        touch_identifier = _touch_mapper.identifierOf(touch_ptr);
        break;
      case Added:
        touch_identifier = _touch_mapper.registerTouch(touch_ptr);
        break;
      case Removed:
        touch_identifier = _touch_mapper.unregisterTouch(touch_ptr);
        break;
    }
    DCHECK(touch_identifier != 0);
    CGPoint windowCoordinates = [touch locationInView:nil];
    auto pointer_time = InputEventTimestampFromNSTimeInterval(touch.timestamp);

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

#pragma mark - Input Clicks

- (BOOL)enableInputClicksWhenVisible {
  return YES;
}

#pragma mark - Surface Lifecycle

- (void)notifySurfaceCreation {
  TRACE_EVENT0("flutter", "notifySurfaceCreation");
  self.platformView->SurfaceCreated(self.acceleratedWidget);
}

- (void)notifySurfaceDestruction {
  TRACE_EVENT0("flutter", "notifySurfaceDestruction");
  self.platformView->SurfaceDestroyed();
}

- (void)visibilityDidChange:(BOOL)visible {
  if (visible) {
    [self notifySurfaceCreation];
  } else {
    [self notifySurfaceDestruction];
  }
}

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

#pragma mark - Misc.

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void)dealloc {
  [_dynamic_service_loader release];
  [self notifySurfaceDestruction];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

@end
