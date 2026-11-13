// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include "flutter/fml/synchronization/sync_switch.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngineGroup.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine+Test.h"

FLUTTER_ASSERT_ARC

@interface FlutterEngineGroup ()
- (FlutterEngine*)makeEngine;
@end

@interface FlutterEngineGroupTest : XCTestCase
@end

@implementation FlutterEngineGroupTest

- (void)testMake {
  FlutterEngineGroup* group = [[FlutterEngineGroup alloc] initWithName:@"foo" project:nil];
  FlutterEngine* engine = [group makeEngineWithEntrypoint:nil libraryURI:nil];
  XCTAssertNotNil(engine);
}

- (void)testSpawn {
  FlutterEngineGroup* group = [[FlutterEngineGroup alloc] initWithName:@"foo" project:nil];
  FlutterEngine* spawner = [group makeEngineWithEntrypoint:nil libraryURI:nil];
  spawner.isGpuDisabled = YES;
  FlutterEngine* spawnee = [group makeEngineWithEntrypoint:nil libraryURI:nil];

  // Verify engines exist.
  XCTAssertNotNil(spawner);
  XCTAssertNotNil(spawnee);

  // Verify engine properties match.
  XCTAssertEqual(&spawner.threadHost, &spawnee.threadHost);
  XCTAssertEqual(spawner.isGpuDisabled, spawnee.isGpuDisabled);

  // Verify the shell came up with GPU disabled.
  BOOL gpuDisabled = NO;
  [spawnee shell].GetIsGpuDisabledSyncSwitch()->Execute(
      fml::SyncSwitch::Handlers().SetIfTrue([&] { gpuDisabled = YES; }));
  XCTAssertTrue(gpuDisabled);
}

// Verifies that the Dart VM, isolate group snapshot, and task runners are shared between engines.
- (void)testSpawnSharesDartVMAndTaskRunners {
  FlutterEngineGroup* group = [[FlutterEngineGroup alloc] initWithName:@"foo" project:nil];
  FlutterEngine* spawner = [group makeEngineWithEntrypoint:nil libraryURI:nil];
  FlutterEngine* spawnee = [group makeEngineWithEntrypoint:nil libraryURI:nil];
  XCTAssertNotNil(spawner);
  XCTAssertNotNil(spawnee);

  // A single Dart VM backs every engine in the group.
  XCTAssertEqual([spawner shell].GetDartVM(), [spawnee shell].GetDartVM());

  // The engine-managed threads are shared; only the Dart isolate differs.
  const flutter::TaskRunners& spawnerRunners = [spawner shell].GetTaskRunners();
  const flutter::TaskRunners& spawneeRunners = [spawnee shell].GetTaskRunners();
  XCTAssertEqual(spawnerRunners.GetRasterTaskRunner(), spawneeRunners.GetRasterTaskRunner());
  XCTAssertEqual(spawnerRunners.GetIOTaskRunner(), spawneeRunners.GetIOTaskRunner());
  XCTAssertEqual(spawnerRunners.GetPlatformTaskRunner(), spawneeRunners.GetPlatformTaskRunner());

  // Platform and UI are merged on iOS, so this holds for the spawned engine too.
  XCTAssertEqual(spawneeRunners.GetUITaskRunner(), spawneeRunners.GetPlatformTaskRunner());
}

- (void)testDeleteLastEngine {
  __weak FlutterEngine* weakSpawner;
  FlutterEngineGroup* group = [[FlutterEngineGroup alloc] initWithName:@"foo" project:nil];
  @autoreleasepool {
    FlutterEngine* spawner = [group makeEngineWithEntrypoint:nil libraryURI:nil];
    weakSpawner = spawner;
    XCTAssertNotNil(spawner);
    XCTAssertNotNil(weakSpawner);
  }
  XCTAssertNil(weakSpawner);

  FlutterEngine* spawnee = [group makeEngineWithEntrypoint:nil libraryURI:nil];
  XCTAssertNotNil(spawnee);
}

- (void)testCustomEntrypoint {
  FlutterEngineGroup* group = OCMPartialMock([[FlutterEngineGroup alloc] initWithName:@"foo"
                                                                              project:nil]);
  FlutterEngine* mockEngine = OCMClassMock([FlutterEngine class]);
  OCMStub([group makeEngine]).andReturn(mockEngine);
  OCMStub([mockEngine spawnWithEntrypoint:[OCMArg any]
                               libraryURI:[OCMArg any]
                             initialRoute:[OCMArg any]
                           entrypointArgs:[OCMArg any]])
      .andReturn(OCMClassMock([FlutterEngine class]));
  FlutterEngine* spawner = [group makeEngineWithEntrypoint:@"firstEntrypoint"
                                                libraryURI:@"firstLibraryURI"];
  XCTAssertNotNil(spawner);
  OCMVerify([spawner runWithEntrypoint:@"firstEntrypoint"
                            libraryURI:@"firstLibraryURI"
                          initialRoute:nil
                        entrypointArgs:nil]);

  FlutterEngine* spawnee = [group makeEngineWithEntrypoint:@"secondEntrypoint"
                                                libraryURI:@"secondLibraryURI"];
  XCTAssertNotNil(spawnee);
  OCMVerify([spawner spawnWithEntrypoint:@"secondEntrypoint"
                              libraryURI:@"secondLibraryURI"
                            initialRoute:nil
                          entrypointArgs:nil]);
}

- (void)testCustomInitialRoute {
  FlutterEngineGroup* group = OCMPartialMock([[FlutterEngineGroup alloc] initWithName:@"foo"
                                                                              project:nil]);
  FlutterEngine* mockEngine = OCMClassMock([FlutterEngine class]);
  OCMStub([group makeEngine]).andReturn(mockEngine);
  OCMStub([mockEngine spawnWithEntrypoint:[OCMArg any]
                               libraryURI:[OCMArg any]
                             initialRoute:[OCMArg any]
                           entrypointArgs:[OCMArg any]])
      .andReturn(OCMClassMock([FlutterEngine class]));
  FlutterEngine* spawner = [group makeEngineWithEntrypoint:nil libraryURI:nil initialRoute:@"foo"];
  XCTAssertNotNil(spawner);
  OCMVerify([spawner runWithEntrypoint:nil libraryURI:nil initialRoute:@"foo" entrypointArgs:nil]);

  FlutterEngine* spawnee = [group makeEngineWithEntrypoint:nil libraryURI:nil initialRoute:@"bar"];
  XCTAssertNotNil(spawnee);
  OCMVerify([spawner spawnWithEntrypoint:nil
                              libraryURI:nil
                            initialRoute:@"bar"
                          entrypointArgs:nil]);
}

- (void)testCustomEntrypointArgs {
  FlutterEngineGroup* group = OCMPartialMock([[FlutterEngineGroup alloc] initWithName:@"foo"
                                                                              project:nil]);
  FlutterEngine* mockEngine = OCMClassMock([FlutterEngine class]);
  OCMStub([group makeEngine]).andReturn(mockEngine);
  OCMStub([mockEngine spawnWithEntrypoint:[OCMArg any]
                               libraryURI:[OCMArg any]
                             initialRoute:[OCMArg any]
                           entrypointArgs:[OCMArg any]])
      .andReturn(OCMClassMock([FlutterEngine class]));
  FlutterEngineGroupOptions* firstOptions = [[FlutterEngineGroupOptions alloc] init];
  NSArray* firstEntrypointArgs = @[ @"foo", @"first" ];
  firstOptions.entrypointArgs = firstEntrypointArgs;
  FlutterEngine* spawner = [group makeEngineWithOptions:firstOptions];
  XCTAssertNotNil(spawner);
  OCMVerify([spawner runWithEntrypoint:nil
                            libraryURI:nil
                          initialRoute:nil
                        entrypointArgs:firstEntrypointArgs]);

  NSArray* secondEntrypointArgs = @[ @"bar", @"second" ];
  FlutterEngineGroupOptions* secondOptions = [[FlutterEngineGroupOptions alloc] init];
  secondOptions.entrypointArgs = secondEntrypointArgs;
  FlutterEngine* spawnee = [group makeEngineWithOptions:secondOptions];
  XCTAssertNotNil(spawnee);
  OCMVerify([spawner spawnWithEntrypoint:nil
                              libraryURI:nil
                            initialRoute:nil
                          entrypointArgs:secondEntrypointArgs]);
}

- (void)testReleasesProjectOnDealloc {
  __weak FlutterDartProject* weakProject;
  @autoreleasepool {
    FlutterDartProject* mockProject = OCMClassMock([FlutterDartProject class]);
    FlutterEngineGroup* group = [[FlutterEngineGroup alloc] initWithName:@"foo"
                                                                 project:mockProject];
    XCTAssertNotNil(group);
    weakProject = mockProject;
    XCTAssertNotNil(weakProject);
    group = nil;
    mockProject = nil;
  }
  XCTAssertNil(weakProject);
}

@end
