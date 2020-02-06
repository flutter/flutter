// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

FLUTTER_ASSERT_ARC

@interface FlutteEngineTest : XCTestCase
@end

@implementation FlutteEngineTest

- (void)setUp {
}

- (void)tearDown {
}

- (void)testCreate {
  id project = OCMClassMock([FlutterDartProject class]);
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
}

- (void)testSendMessageBeforeRun {
  id project = OCMClassMock([FlutterDartProject class]);
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
  XCTAssertThrows([engine.binaryMessenger
      sendOnChannel:@"foo"
            message:[@"bar" dataUsingEncoding:NSUTF8StringEncoding]
        binaryReply:nil]);
}

- (void)testSetMessageHandlerBeforeRun {
  id project = OCMClassMock([FlutterDartProject class]);
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
  XCTAssertThrows([engine.binaryMessenger
      setMessageHandlerOnChannel:@"foo"
            binaryMessageHandler:^(NSData* _Nullable message, FlutterBinaryReply _Nonnull reply){

            }]);
}

- (void)testNotifyPluginOfDealloc {
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  OCMStub([plugin detachFromEngineForRegistrar:[OCMArg any]]);
  {
    id project = OCMClassMock([FlutterDartProject class]);
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"engine" project:project];
    NSObject<FlutterPluginRegistrar>* registrar = [engine registrarForPlugin:@"plugin"];
    [registrar publish:plugin];
    engine = nil;
  }
  OCMVerify([plugin detachFromEngineForRegistrar:[OCMArg any]]);
}

@end
