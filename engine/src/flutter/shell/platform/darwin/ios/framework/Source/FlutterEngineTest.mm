// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/common/settings.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterBinaryMessengerRelay.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Test.h"

FLUTTER_ASSERT_ARC

@interface FlutterEngineTest : XCTestCase
@end

@implementation FlutterEngineTest

- (void)setUp {
}

- (void)tearDown {
}

- (void)testCreate {
  id project = OCMClassMock([FlutterDartProject class]);
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
}

- (void)testDeallocated {
  __weak FlutterEngine* weakEngine = nil;
  {
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar"];
    weakEngine = engine;
    [engine run];
    XCTAssertNotNil(weakEngine);
  }
  XCTAssertNil(weakEngine);
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

- (void)testNilSetMessageHandlerBeforeRun {
  id project = OCMClassMock([FlutterDartProject class]);
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
  XCTAssertNoThrow([engine.binaryMessenger setMessageHandlerOnChannel:@"foo"
                                                 binaryMessageHandler:nil]);
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

- (void)testRunningInitialRouteSendsNavigationMessage {
  id mockBinaryMessenger = OCMClassMock([FlutterBinaryMessengerRelay class]);

  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine setBinaryMessenger:mockBinaryMessenger];

  // Run with an initial route.
  [engine runWithEntrypoint:FlutterDefaultDartEntrypoint initialRoute:@"test"];

  // Now check that an encoded method call has been made on the binary messenger to set the
  // initial route to "test".
  FlutterMethodCall* setInitialRouteMethodCall =
      [FlutterMethodCall methodCallWithMethodName:@"setInitialRoute" arguments:@"test"];
  NSData* encodedSetInitialRouteMethod =
      [[FlutterJSONMethodCodec sharedInstance] encodeMethodCall:setInitialRouteMethodCall];
  OCMVerify([mockBinaryMessenger sendOnChannel:@"flutter/navigation"
                                       message:encodedSetInitialRouteMethod]);
}

- (void)testPlatformViewsControllerRenderingMetalBackend {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine run];
  flutter::IOSRenderingAPI renderingApi = [engine platformViewsRenderingAPI];

  XCTAssertEqual(renderingApi, flutter::IOSRenderingAPI::kMetal);
}

- (void)testPlatformViewsControllerRenderingSoftware {
  auto settings = FLTDefaultSettingsForBundle();
  settings.enable_software_rendering = true;
  FlutterDartProject* project = [[FlutterDartProject alloc] initWithSettings:settings];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  [engine run];
  flutter::IOSRenderingAPI renderingApi = [engine platformViewsRenderingAPI];

  XCTAssertEqual(renderingApi, flutter::IOSRenderingAPI::kSoftware);
}

- (void)testWaitForFirstFrameTimeout {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar"];
  [engine run];
  XCTestExpectation* timeoutFirstFrame = [self expectationWithDescription:@"timeoutFirstFrame"];
  [engine waitForFirstFrame:0.1
                   callback:^(BOOL didTimeout) {
                     if (timeoutFirstFrame) {
                       [timeoutFirstFrame fulfill];
                     }
                   }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
