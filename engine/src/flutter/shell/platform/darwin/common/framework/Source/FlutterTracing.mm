// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Source/FlutterTracing.h"

#include "flutter/fml/trace_event.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@implementation FlutterTracing

+ (void)tracePlatformVsyncWithStartTime:(NSTimeInterval)startTime
                             targetTime:(NSTimeInterval)targetTime {
  int64_t startTimeMicroseconds = (int64_t)(startTime * 1000000);
  int64_t targetTimeMicroseconds = (int64_t)(targetTime * 1000000);
  TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time", startTimeMicroseconds,
                   "frame_target_time", targetTimeMicroseconds);
}

+ (void)traceAsyncBegin:(NSString*)name eventID:(int64_t)eventID {
  TRACE_EVENT_ASYNC_BEGIN0("flutter", [name UTF8String] ?: "", eventID);
}

+ (void)traceAsyncEnd:(NSString*)name eventID:(int64_t)eventID {
  TRACE_EVENT_ASYNC_END0("flutter", [name UTF8String] ?: "", eventID);
}

+ (void)beginSection:(NSString*)name {
  ::fml::tracing::TraceEvent0("flutter", [name UTF8String] ?: "", 0, nullptr);
}

+ (void)endSection:(NSString*)name {
  ::fml::tracing::TraceEventEnd([name UTF8String] ?: "");
}

@end
