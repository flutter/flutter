// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterShell.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterShell_Internal.h"

FLUTTER_ASSERT_ARC

namespace {

// Builds the same task runner configuration as FlutterEngine: the current (platform) thread is also
// the UI thread, and the raster and IO threads come from the thread host.
flutter::TaskRunners MakeTaskRunners(FlutterShell* shell) {
  fml::RefPtr<fml::TaskRunner> platform_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  return flutter::TaskRunners(shell.threadLabel.UTF8String,                      // label
                              platform_runner,                                   // platform
                              shell.threadHost->raster_thread->GetTaskRunner(),  // raster
                              platform_runner,                                   // ui
                              shell.threadHost->io_thread->GetTaskRunner()       // io
  );
}

}  // namespace

@interface FlutterShellTest : XCTestCase
@end

@implementation FlutterShellTest

- (void)testInitialState {
  FlutterShell* shell = [[FlutterShell alloc] init];
  XCTAssertEqual(shell.threadHost, nullptr);
  XCTAssertNil(shell.threadLabel);
  XCTAssertNil(shell.platformTaskRunner);
  XCTAssertNil(shell.uiTaskRunner);
  XCTAssertNil(shell.rasterTaskRunner);
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
  // Ensure a VM has been created since the profiler names its thread via the VM.
  flutter::DartVMRef vm = flutter::DartVMRef::Create(FLTDefaultSettingsForBundle());
  XCTAssertTrue(vm);

  FlutterShell* shell = [[FlutterShell alloc] init];
  [shell createThreadHostWithLabelPrefix:@"foo"];
  [shell startProfilerIfEnabled];
  [shell destroyThreadHost];
  XCTAssertEqual(shell.threadHost, nullptr);
}

- (void)testAdoptTaskRunners {
  FlutterShell* shell = [[FlutterShell alloc] init];
  [shell createThreadHostWithLabelPrefix:@"foo"];
  [shell adoptTaskRunners:MakeTaskRunners(shell)];

  XCTAssertNotNil(shell.platformTaskRunner);
  XCTAssertNotNil(shell.rasterTaskRunner);
  // The platform and UI threads are always merged on iOS.
  XCTAssertEqual(shell.uiTaskRunner, shell.platformTaskRunner);
  XCTAssertNotEqual(shell.rasterTaskRunner, shell.platformTaskRunner);

  // The platform task runner is the calling thread.
  XCTAssertTrue([shell.platformTaskRunner runsTasksOnCurrentThread]);
  XCTAssertFalse([shell.rasterTaskRunner runsTasksOnCurrentThread]);

  // The raster task runner runs tasks on the thread host's raster thread.
  fml::AutoResetWaitableEvent latch;
  fml::AutoResetWaitableEvent* latchPtr = &latch;
  __block BOOL ranOnRasterThread = NO;
  [shell.rasterTaskRunner postTask:^{
    ranOnRasterThread = [shell.rasterTaskRunner runsTasksOnCurrentThread];
    latchPtr->Signal();
  }];
  latch.Wait();
  XCTAssertTrue(ranOnRasterThread);

  [shell resetTaskRunners];
  [shell destroyThreadHost];
}

- (void)testResetTaskRunners {
  FlutterShell* shell = [[FlutterShell alloc] init];
  [shell createThreadHostWithLabelPrefix:@"foo"];
  [shell adoptTaskRunners:MakeTaskRunners(shell)];
  XCTAssertNotNil(shell.platformTaskRunner);
  XCTAssertNotNil(shell.rasterTaskRunner);

  [shell resetTaskRunners];
  XCTAssertNil(shell.platformTaskRunner);
  XCTAssertNil(shell.uiTaskRunner);
  XCTAssertNil(shell.rasterTaskRunner);

  // Resetting again is a no-op.
  [shell resetTaskRunners];
  XCTAssertNil(shell.platformTaskRunner);
  XCTAssertNil(shell.rasterTaskRunner);

  [shell destroyThreadHost];
}

@end
