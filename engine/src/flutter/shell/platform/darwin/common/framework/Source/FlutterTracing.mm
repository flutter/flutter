// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Source/FlutterTracing.h"

#include "flutter/fml/trace_event.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@implementation FlutterTracing

+ (void)traceScope:(NSString*)name work:(void(NS_NOESCAPE ^)(void))work {
  TRACE_EVENT0("flutter", [name UTF8String] ?: "");
  work();
}

+ (void)tracePlatformVsyncWithStartTime:(int64_t)startTimeMicroseconds
                             targetTime:(int64_t)targetTimeMicroseconds {
  TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time", startTimeMicroseconds,
                   "frame_target_time", targetTimeMicroseconds);
}

+ (void)traceAsyncBegin:(NSString*)name eventId:(int64_t)eventId {
  TRACE_EVENT_ASYNC_BEGIN0("flutter", [name UTF8String] ?: "", eventId);
}

+ (void)traceAsyncEnd:(NSString*)name eventId:(int64_t)eventId {
  TRACE_EVENT_ASYNC_END0("flutter", [name UTF8String] ?: "", eventId);
}

@end
