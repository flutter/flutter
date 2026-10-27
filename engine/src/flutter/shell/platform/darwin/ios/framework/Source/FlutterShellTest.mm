// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#include "flutter/fml/synchronization/waitable_event.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterShell.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterShell_Internal.h"

FLUTTER_ASSERT_ARC

@interface FlutterShellTest : XCTestCase
@end

@implementation FlutterShellTest

- (void)testInitialState {
  FlutterShell* shell = [[FlutterShell alloc] init];
  XCTAssertEqual(shell.threadHost, nullptr);
  XCTAssertNil(shell.threadLabel);
}

- (void)testCreateThreadHost {
  FlutterShell* shell = [[FlutterShell alloc] init];
  [shell createThreadHostWithLabelPrefix:@"foo"];

  const flutter::ThreadHost* threadHost = shell.threadHost;
  XCTAssertNotEqual(threadHost, nullptr);
  XCTAssertNotNil(shell.threadLabel);
  XCTAssertTrue([shell.threadLabel hasPrefix:@"foo."]);
  XCTAssertEqualObjects(@(threadHost->name_prefix.c_str()), shell.threadLabel);
  XCTAssertNotEqual(threadHost->raster_thread.get(), nullptr);
  XCTAssertNotEqual(threadHost->io_thread.get(), nullptr);
  XCTAssertEqual(threadHost->ui_thread.get(), nullptr);

  [shell destroyThreadHost];
}

- (void)testProfilerThreadMatchesRuntimeMode {
  FlutterShell* shell = [[FlutterShell alloc] init];
  [shell createThreadHostWithLabelPrefix:@"foo"];

#if (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG) || \
    (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE)
  XCTAssertNotEqual(shell.threadHost->profiler_thread.get(), nullptr);
#else
  XCTAssertEqual(shell.threadHost->profiler_thread.get(), nullptr);
#endif

  [shell destroyThreadHost];
}

- (void)testBackendsGetDistinctLabels {
  FlutterShell* shell1 = [[FlutterShell alloc] init];
  FlutterShell* shell2 = [[FlutterShell alloc] init];
  [shell1 createThreadHostWithLabelPrefix:@"foo"];
  [shell2 createThreadHostWithLabelPrefix:@"foo"];

  XCTAssertNotEqualObjects(shell1.threadLabel, shell2.threadLabel);

  [shell1 destroyThreadHost];
  [shell2 destroyThreadHost];
}

- (void)testDestroyThreadHostIsIdempotent {
  FlutterShell* shell = [[FlutterShell alloc] init];
  [shell createThreadHostWithLabelPrefix:@"foo"];
  XCTAssertNotEqual(shell.threadHost, nullptr);
  XCTAssertNotNil(shell.threadLabel);

  [shell destroyThreadHost];
  XCTAssertEqual(shell.threadHost, nullptr);
  XCTAssertNil(shell.threadLabel);

  [shell destroyThreadHost];
  XCTAssertEqual(shell.threadHost, nullptr);
  XCTAssertNil(shell.threadLabel);
}

- (void)testInheritThreadHostSharesLifetime {
  FlutterShell* parent = [[FlutterShell alloc] init];
  [parent createThreadHostWithLabelPrefix:@"foo"];

  FlutterShell* child = [[FlutterShell alloc] init];
  [child inheritThreadHostFromShell:parent];

  XCTAssertEqual(child.threadHost, parent.threadHost);
  XCTAssertEqualObjects(child.threadLabel, parent.threadLabel);

  [parent destroyThreadHost];
  XCTAssertEqual(parent.threadHost, nullptr);
  XCTAssertNotEqual(child.threadHost, nullptr);

  fml::AutoResetWaitableEvent latch;
  child.threadHost->raster_thread->GetTaskRunner()->PostTask([&latch]() { latch.Signal(); });
  latch.Wait();

  [child destroyThreadHost];
}

- (void)testDestroyStopsProfilerBeforeJoiningThread {
  FlutterShell* shell = [[FlutterShell alloc] init];
  [shell createThreadHostWithLabelPrefix:@"foo"];
  [shell startProfilerIfEnabled];
  [shell destroyThreadHost];
  XCTAssertEqual(shell.threadHost, nullptr);
}

@end
