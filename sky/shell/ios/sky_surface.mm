// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_surface.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#include "base/time/time.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "sky/services/engine/input_event.mojom.h"
#include "sky/shell/mac/platform_view_mac.h"
#include "sky/shell/shell_view.h"
#include "sky/shell/shell.h"
#include "sky/shell/ui_delegate.h"
#include <strings.h>

enum MapperPhase {
  Accessed,
  Added,
  Removed,
};

using EventTypeMapperPhase = std::pair<sky::EventType, MapperPhase>;
static inline EventTypeMapperPhase EventTypePhaseFromUITouchPhase(
    UITouchPhase phase) {
  switch (phase) {
    case UITouchPhaseBegan:
      return EventTypeMapperPhase(sky::EventType::POINTER_DOWN,
                                  MapperPhase::Added);
    case UITouchPhaseMoved:
    case UITouchPhaseStationary:
      // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
      // with the same coordinates
      return EventTypeMapperPhase(sky::EventType::POINTER_MOVE,
                                  MapperPhase::Accessed);
    case UITouchPhaseEnded:
      return EventTypeMapperPhase(sky::EventType::POINTER_UP,
                                  MapperPhase::Removed);
    case UITouchPhaseCancelled:
      return EventTypeMapperPhase(sky::EventType::POINTER_CANCEL,
                                  MapperPhase::Removed);
  }

  return EventTypeMapperPhase(sky::EventType::UNKNOWN, MapperPhase::Accessed);
}

static inline int64 InputEventTimestampFromNSTimeInterval(
    NSTimeInterval interval) {
  return base::TimeDelta::FromSecondsD(interval).InMilliseconds();
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

@implementation SkySurface {
  BOOL _platformViewInitialized;
  CGPoint _lastScrollTranslation;

  sky::SkyEnginePtr _sky_engine;
  scoped_ptr<sky::shell::ShellView> _shell_view;
  TouchMapper _touch_mapper;
}

static std::string SkPictureTracingPath() {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  return [paths.firstObject UTF8String];
}

- (instancetype)initWithShellView:(sky::shell::ShellView*)shellView {
  self = [super init];
  if (self) {
    base::FilePath pictureTracingPath =
        base::FilePath::FromUTF8Unsafe(SkPictureTracingPath());
    sky::shell::Shell::Shared()
        .tracing_controller()
        .set_picture_tracing_base_path(pictureTracingPath);

    _shell_view.reset(shellView);
    self.multipleTouchEnabled = YES;
  }
  return self;
}

- (gfx::AcceleratedWidget)acceleratedWidget {
  return (gfx::AcceleratedWidget)self.layer;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  [self configureLayerDefaults];

  [self setupPlatformViewIfNecessary];

  CGSize size = self.bounds.size;
  CGFloat scale = [UIScreen mainScreen].scale;

  sky::ViewportMetricsPtr metrics = sky::ViewportMetrics::New();
  metrics->physical_width = size.width * scale;
  metrics->physical_height = size.height * scale;
  metrics->device_pixel_ratio = scale;
  metrics->padding_top =
      [UIApplication sharedApplication].statusBarFrame.size.height;

  _sky_engine->OnViewportMetricsChanged(metrics.Pass());
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

  [self notifySurfaceCreation];
  [self connectToEngineAndLoad];
}

- (sky::shell::PlatformViewMac*)platformView {
  auto view = static_cast<sky::shell::PlatformViewMac*>(_shell_view->view());
  DCHECK(view);
  return view;
}

- (void)notifySurfaceCreation {
  self.platformView->SurfaceCreated(self.acceleratedWidget);
}

-(const char *) flxBundlePath {
  // In case this runner is part of the precompilation SDK, the FLX bundle is
  // present in the application bundle instead of the runner bundle. Attempt
  // to resolve the path there first.
  // TODO: Allow specification of the application bundle identifier
  NSBundle* applicationBundle = [NSBundle
      bundleWithIdentifier:@"io.flutter.aplication.FlutterApplication"];
  NSString* path = [applicationBundle pathForResource:@"app" ofType:@"flx"];
  if (path.length != 0) {
    return path.UTF8String;
  }
  return
      [[NSBundle mainBundle] pathForResource:@"app" ofType:@"flx"].UTF8String;
}

- (void)connectToEngineAndLoad {
  auto interface_request = mojo::GetProxy(&_sky_engine);
  self.platformView->ConnectToEngine(interface_request.Pass());
  mojo::String bundle_path([self flxBundlePath]);
  _sky_engine->RunFromPrecompiledSnapshot(bundle_path);
}

- (void)notifySurfaceDestruction {
  self.platformView->SurfaceDestroyed();
}

#pragma mark - UIResponder overrides for raw touches

- (void)dispatchTouches:(NSSet*)touches phase:(UITouchPhase)phase {
  auto eventTypePhase = EventTypePhaseFromUITouchPhase(phase);
  const CGFloat scale = [UIScreen mainScreen].scale;

  for (UITouch* touch in touches) {
    auto input = sky::InputEvent::New();
    input->type = eventTypePhase.first;
    input->time_stamp = InputEventTimestampFromNSTimeInterval(touch.timestamp);

    input->pointer_data = sky::PointerData::New();
    input->pointer_data->kind = sky::PointerKind::TOUCH;

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
    input->pointer_data->pointer = touch_identifier;

    CGPoint windowCoordinates = [touch locationInView:nil];

    input->pointer_data->x = windowCoordinates.x * scale;
    input->pointer_data->y = windowCoordinates.y * scale;

    _sky_engine->OnInputEvent(input.Pass());
  }
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

#pragma mark - Misc.

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void)dealloc {
  [self notifySurfaceDestruction];
  [super dealloc];
}

@end
