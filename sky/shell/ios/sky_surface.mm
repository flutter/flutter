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

#ifndef NDEBUG
#include "document_watcher.h"
#endif

static inline sky::EventType EventTypeFromUITouchPhase(UITouchPhase phase) {
  switch (phase) {
    case UITouchPhaseBegan:
      return sky::EVENT_TYPE_POINTER_DOWN;
    case UITouchPhaseMoved:
    case UITouchPhaseStationary:
      // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
      // with the same coordinates
      return sky::EVENT_TYPE_POINTER_MOVE;
    case UITouchPhaseEnded:
      return sky::EVENT_TYPE_POINTER_UP;
    case UITouchPhaseCancelled:
      return sky::EVENT_TYPE_POINTER_CANCEL;
  }

  return sky::EVENT_TYPE_UNKNOWN;
}

static inline int64 InputEventTimestampFromNSTimeInterval(
    NSTimeInterval interval) {
  return base::TimeDelta::FromSecondsD(interval).InMilliseconds();
}

static sky::InputEventPtr BasicInputEventFromRecognizer(
    sky::EventType type,
    UIGestureRecognizer* recognizer) {
  auto input = sky::InputEvent::New();
  input->type = type;
  input->time_stamp = InputEventTimestampFromNSTimeInterval(
      CACurrentMediaTime());

  input->gesture_data = sky::GestureData::New();

  CGPoint windowCoordinates = [recognizer locationInView:recognizer.view];
  const CGFloat scale = [UIScreen mainScreen].scale;
  input->gesture_data->x = windowCoordinates.x * scale;
  input->gesture_data->y = windowCoordinates.y * scale;
  return input.Pass();
}

@implementation SkySurface {
  BOOL _platformViewInitialized;
  CGPoint _lastScrollTranslation;

  sky::SkyEnginePtr _sky_engine;
  scoped_ptr<sky::shell::ShellView> _shell_view;

#ifndef NDEBUG
  DocumentWatcher *_document_watcher;
#endif
}

-(instancetype) initWithShellView:(sky::shell::ShellView *) shellView {
  self = [super init];
  if (self) {
    _shell_view.reset(shellView);
    self.multipleTouchEnabled = YES;
    [self installGestureRecognizers];
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

- (NSString*)skyInitialLoadURL {
  NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
  NSString *target = [standardDefaults stringForKey:@"target"];
  NSString *server = [standardDefaults stringForKey:@"server"];
  if (server && target) {
    return [NSString stringWithFormat:@"http://%@/%@", server, target];
  }
  return [NSBundle mainBundle].infoDictionary[@"org.domokit.sky.load_url"];
}

- (NSString*)skyInitialBundleURL {
  NSString *skyxBundlePath = [[NSBundle mainBundle] pathForResource:@"app" ofType:@"skyx"];
#ifndef NDEBUG
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *skyxDocsPath = [documentsDirectory stringByAppendingPathComponent:@"app.skyx"];

  if ([fileManager fileExistsAtPath:skyxDocsPath] == NO) {
    if ([fileManager copyItemAtPath:skyxBundlePath toPath:skyxDocsPath error:&error]) {
      return skyxDocsPath;
    }
    NSLog(@"Error encountered copying app.skyx from the Bundle to the Documents directory. Dynamic reloading will not be possible. %@", error);
    return skyxBundlePath;
  }
  return skyxDocsPath;
#endif
  return skyxBundlePath;
}

- (void)connectToEngineAndLoad {
  auto interface_request = mojo::GetProxy(&_sky_engine);
  self.platformView->ConnectToEngine(interface_request.Pass());

  NSString *endpoint = self.skyInitialBundleURL;
  if (endpoint.length > 0) {
#ifndef NDEBUG
    _document_watcher = [[DocumentWatcher alloc] initWithDocumentPath:endpoint callbackBlock:^{
      mojo::String string(endpoint.UTF8String);
      _sky_engine->RunFromBundle(string);
    }];
#endif
    // Load from bundle
    mojo::String string(endpoint.UTF8String);
    _sky_engine->RunFromBundle(string);
    return;
  }

  endpoint = self.skyInitialLoadURL;
  if (endpoint.length > 0) {
    // Load from URL
    mojo::String string(endpoint.UTF8String);
    _sky_engine->RunFromNetwork(string);
    return;
  }
}

- (void)notifySurfaceDestruction {
  self.platformView->SurfaceDestroyed();
}

#ifndef NDEBUG
- (void)didMoveToWindow {
  if (self.window == nil) {
    [_document_watcher cancel];
    [_document_watcher release];
    _document_watcher = nil;
  }
}
#endif

#pragma mark - UIResponder overrides for raw touches

- (void)dispatchTouches:(NSSet*)touches phase:(UITouchPhase)phase {
  auto eventType = EventTypeFromUITouchPhase(phase);
  const CGFloat scale = [UIScreen mainScreen].scale;

  for (UITouch* touch in touches) {
    auto input = sky::InputEvent::New();
    input->type = eventType;
    input->time_stamp = InputEventTimestampFromNSTimeInterval(touch.timestamp);

    input->pointer_data = sky::PointerData::New();
    input->pointer_data->kind = sky::POINTER_KIND_TOUCH;

    #define LOWER_32(x) (*((int32_t *) &x))
    input->pointer_data->pointer = LOWER_32(touch);
    #undef LOWER_32

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

#pragma mark - Gesture Recognizers

-(void) installGestureRecognizers {
  // For:
  //   GESTURE_FLING_CANCEL
  //   GESTURE_FLING_START
  UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
    initWithTarget:self action:@selector(onFling:)];
  swipe.cancelsTouchesInView = NO;
  [self addGestureRecognizer: swipe];
  [swipe release];

  // For:
  //   GESTURE_LONG_PRESS
  //   GESTURE_SHOW_PRESS
  UILongPressGestureRecognizer *longPress =
    [[UILongPressGestureRecognizer alloc]
      initWithTarget:self action:@selector(onLongPress:)];
  longPress.cancelsTouchesInView = NO;
  [self addGestureRecognizer: longPress];
  [longPress release];

  // For:
  //   GESTURE_SCROLL_BEGIN
  //   GESTURE_SCROLL_END
  //   GESTURE_SCROLL_UPDATE
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
    initWithTarget:self action:@selector(onScroll:)];
  pan.cancelsTouchesInView = NO;
  [self addGestureRecognizer: pan];
  [pan release];

  // For:
  //   GESTURE_TAP
  //   GESTURE_TAP_DOWN
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
    initWithTarget:self action:@selector(onTap:)];
  tap.cancelsTouchesInView = NO;
  [self addGestureRecognizer: tap];
  [tap release];
}

-(void) onFling:(UISwipeGestureRecognizer *) recognizer {
  // Swipes are discrete gestures already. So there is no equivalent to a cancel
  if (recognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(
    sky::EVENT_TYPE_GESTURE_FLING_START, recognizer);
  _sky_engine->OnInputEvent(input.Pass());
}

-(void) onLongPress:(UILongPressGestureRecognizer *) recognizer {
  if (recognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(sky::EVENT_TYPE_GESTURE_LONG_PRESS,
                                             recognizer);
  _sky_engine->OnInputEvent(input.Pass());
}

-(void) onScroll:(UIPanGestureRecognizer *) recognizer {
  sky::EventType type = sky::EVENT_TYPE_UNKNOWN;
  switch (recognizer.state) {
    case UIGestureRecognizerStateBegan:
      _lastScrollTranslation = CGPointZero;
      type = sky::EVENT_TYPE_GESTURE_SCROLL_BEGIN;
      break;
    case UIGestureRecognizerStateChanged:
      type = sky::EVENT_TYPE_GESTURE_SCROLL_UPDATE;
      break;
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
      type = sky::EVENT_TYPE_GESTURE_SCROLL_END;
      break;
    default:
      break;
  }

  if (type == sky::EVENT_TYPE_UNKNOWN) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(type, recognizer);
  auto scale = [UIScreen mainScreen].scale;
  auto translation = [recognizer translationInView: self];
  auto velocity = [recognizer velocityInView: self];

  input->gesture_data->dx = (translation.x - _lastScrollTranslation.x) * scale;
  input->gesture_data->dy =  (translation.y - _lastScrollTranslation.y) * scale;

  _lastScrollTranslation = translation;

  input->gesture_data->velocityX = velocity.x * scale;
  input->gesture_data->velocityY =  velocity.y * scale;

  _sky_engine->OnInputEvent(input.Pass());
}

-(void) onTap:(UITapGestureRecognizer *) recognizer {

  if (recognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(sky::EVENT_TYPE_GESTURE_TAP,
                                             recognizer);
  _sky_engine->OnInputEvent(input.Pass());
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
