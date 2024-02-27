#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterVSyncWaiter.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDisplayLink.h"

#include "flutter/fml/logging.h"

#include <optional>
#include <vector>

#if (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE)
#define VSYNC_TRACING_ENABLED 1
#endif

#if VSYNC_TRACING_ENABLED
#include <OSLog/OSLog.h>

// Trace vsync events using os_signpost so that they can be seen in Instruments "Points of
// Interest".
#define TRACE_VSYNC(event_type, baton)                                                     \
  do {                                                                                     \
    os_log_t log = os_log_create("FlutterVSync", "PointsOfInterest");                      \
    os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, event_type, "baton %lx", baton); \
  } while (0)
#else
#define TRACE_VSYNC(event_type, baton) \
  do {                                 \
  } while (0)
#endif

@interface FlutterVSyncWaiter () <FlutterDisplayLinkDelegate>
@end

// It's preferable to fire the timers slightly early than too late due to scheduling latency.
// 1ms before vsync should be late enough for all events to be processed.
static const CFTimeInterval kTimerLatencyCompensation = 0.001;

@implementation FlutterVSyncWaiter {
  std::optional<std::uintptr_t> _pending_baton;
  FlutterDisplayLink* _displayLink;
  void (^_block)(CFTimeInterval, CFTimeInterval, uintptr_t);
  NSRunLoop* _runLoop;
  CFTimeInterval _lastTargetTimestamp;
}

- (instancetype)initWithDisplayLink:(FlutterDisplayLink*)displayLink
                              block:(void (^)(CFTimeInterval timestamp,
                                              CFTimeInterval targetTimestamp,
                                              uintptr_t baton))block {
  FML_DCHECK([NSThread isMainThread]);
  if (self = [super init]) {
    _block = block;

    _displayLink = displayLink;
    _displayLink.delegate = self;
    // Get at least one callback to initialize _lastTargetTimestamp.
    _displayLink.paused = NO;
  }
  return self;
}

// Called on same thread as the vsync request (UI thread).
- (void)processDisplayLink:(CFTimeInterval)timestamp
           targetTimestamp:(CFTimeInterval)targetTimestamp {
  FML_DCHECK([NSRunLoop currentRunLoop] == _runLoop);

  _lastTargetTimestamp = targetTimestamp;

  // CVDisplayLink callback is called one and a half frame before the target
  // timestamp. That can cause frame-pacing issues if the frame is rendered too early,
  // it may also trigger frame start before events are processed.
  CFTimeInterval minStart = targetTimestamp - _displayLink.nominalOutputRefreshPeriod;
  CFTimeInterval current = CACurrentMediaTime();
  CFTimeInterval remaining = std::max(minStart - current - kTimerLatencyCompensation, 0.0);

  TRACE_VSYNC("DisplayLinkCallback-Original", _pending_baton.value_or(0));

  NSTimer* timer = [NSTimer
      timerWithTimeInterval:remaining
                    repeats:NO
                      block:^(NSTimer* _Nonnull timer) {
                        if (!_pending_baton.has_value()) {
                          TRACE_VSYNC("DisplayLinkPaused", size_t(0));
                          _displayLink.paused = YES;
                          return;
                        }
                        TRACE_VSYNC("DisplayLinkCallback-Delayed", _pending_baton.value_or(0));
                        _block(minStart, targetTimestamp, *_pending_baton);
                        _pending_baton = std::nullopt;
                      }];
  [_runLoop addTimer:timer forMode:NSRunLoopCommonModes];
}

// Called from display link thread.
- (void)onDisplayLink:(CFTimeInterval)timestamp targetTimestamp:(CFTimeInterval)targetTimestamp {
  @synchronized(self) {
    if (_runLoop == nil) {
      // Initial vsync - timestamp will be used to determine vsync phase.
      _lastTargetTimestamp = targetTimestamp;
      _displayLink.paused = YES;
    } else {
      [_runLoop performBlock:^{
        [self processDisplayLink:timestamp targetTimestamp:targetTimestamp];
      }];
    }
  }
}

// Called from UI thread.
- (void)waitForVSync:(uintptr_t)baton {
  // RunLoop is accessed both from main thread and from the display link thread.
  @synchronized(self) {
    if (_runLoop == nil) {
      _runLoop = [NSRunLoop currentRunLoop];
    }
  }

  FML_DCHECK(_runLoop == [NSRunLoop currentRunLoop]);
  if (_pending_baton.has_value()) {
    FML_LOG(WARNING) << "Engine requested vsync while another was pending";
    _block(0, 0, *_pending_baton);
    _pending_baton = std::nullopt;
  }

  TRACE_VSYNC("VSyncRequest", _pending_baton.value_or(0));

  CFTimeInterval tick_interval = _displayLink.nominalOutputRefreshPeriod;
  if (_displayLink.paused || tick_interval == 0) {
    // When starting display link the first notification will come in the middle
    // of next frame, which would incur a whole frame period of latency.
    // To avoid that, first vsync notification will be fired using a timer
    // scheduled to fire where the next frame is expected to start.
    // Also use a timer if display link does not belong to any display
    // (nominalOutputRefreshPeriod being 0)

    // Start of the vsync interval.
    CFTimeInterval start = CACurrentMediaTime();

    // Timer delay is calculated as the time to the next frame start.
    CFTimeInterval delay = 0;

    if (tick_interval != 0 && _lastTargetTimestamp != 0) {
      CFTimeInterval phase = fmod(_lastTargetTimestamp, tick_interval);
      CFTimeInterval now = start;
      start = now - (fmod(now, tick_interval)) + phase;
      if (start < now) {
        start += tick_interval;
      }
      delay = std::max(start - now - kTimerLatencyCompensation, 0.0);
    }

    NSTimer* timer = [NSTimer timerWithTimeInterval:delay
                                            repeats:NO
                                              block:^(NSTimer* timer) {
                                                CFTimeInterval targetTimestamp =
                                                    start + tick_interval;
                                                TRACE_VSYNC("SynthesizedInitialVSync", baton);
                                                _block(start, targetTimestamp, baton);
                                              }];
    [_runLoop addTimer:timer forMode:NSRunLoopCommonModes];
    _displayLink.paused = NO;
  } else {
    _pending_baton = baton;
  }
}

- (void)dealloc {
  if (_pending_baton.has_value()) {
    FML_LOG(WARNING) << "Deallocating FlutterVSyncWaiter with a pending vsync";
  }
  [_displayLink invalidate];
}

@end
