// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import <objc/runtime.h>

#import "flutter/common/settings.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterBinaryMessengerRelay.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"

FLUTTER_ASSERT_ARC

@interface FlutterEngine () <FlutterTextInputDelegate>

@end

@interface FlutterEngineTest : XCTestCase
@end

@implementation FlutterEngineTest

- (void)setUp {
}

- (void)tearDown {
}

- (void)testCreate {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
}

- (void)testInfoPlist {
  // Check the embedded Flutter.framework Info.plist, not the linked dylib.
  NSURL* flutterFrameworkURL =
      [NSBundle.mainBundle.privateFrameworksURL URLByAppendingPathComponent:@"Flutter.framework"];
  NSBundle* flutterBundle = [NSBundle bundleWithURL:flutterFrameworkURL];
  XCTAssertEqualObjects(flutterBundle.bundleIdentifier, @"io.flutter.flutter");

  NSDictionary<NSString*, id>* infoDictionary = flutterBundle.infoDictionary;

  // OS version can have one, two, or three digits: "8", "8.0", "8.0.0"
  NSError* regexError = NULL;
  NSRegularExpression* osVersionRegex =
      [NSRegularExpression regularExpressionWithPattern:@"((0|[1-9]\\d*)\\.)*(0|[1-9]\\d*)"
                                                options:NSRegularExpressionCaseInsensitive
                                                  error:&regexError];
  XCTAssertNil(regexError);

  // Smoke test the test regex.
  NSString* testString = @"9";
  NSUInteger versionMatches =
      [osVersionRegex numberOfMatchesInString:testString
                                      options:NSMatchingAnchored
                                        range:NSMakeRange(0, testString.length)];
  XCTAssertEqual(versionMatches, 1UL);
  testString = @"9.1";
  versionMatches = [osVersionRegex numberOfMatchesInString:testString
                                                   options:NSMatchingAnchored
                                                     range:NSMakeRange(0, testString.length)];
  XCTAssertEqual(versionMatches, 1UL);
  testString = @"9.0.1";
  versionMatches = [osVersionRegex numberOfMatchesInString:testString
                                                   options:NSMatchingAnchored
                                                     range:NSMakeRange(0, testString.length)];
  XCTAssertEqual(versionMatches, 1UL);
  testString = @".0.1";
  versionMatches = [osVersionRegex numberOfMatchesInString:testString
                                                   options:NSMatchingAnchored
                                                     range:NSMakeRange(0, testString.length)];
  XCTAssertEqual(versionMatches, 0UL);

  // Test Info.plist values.
  NSString* minimumOSVersion = infoDictionary[@"MinimumOSVersion"];
  versionMatches = [osVersionRegex numberOfMatchesInString:minimumOSVersion
                                                   options:NSMatchingAnchored
                                                     range:NSMakeRange(0, minimumOSVersion.length)];
  XCTAssertEqual(versionMatches, 1UL);

  // SHA length is 40.
  XCTAssertEqual(((NSString*)infoDictionary[@"FlutterEngine"]).length, 40UL);

  // {clang_version} placeholder is 15 characters. The clang string version
  // is longer than that, so check if the placeholder has been replaced, without
  // actually checking a literal string, which could be different on various machines.
  XCTAssertTrue(((NSString*)infoDictionary[@"ClangVersion"]).length > 15UL);
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
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
  XCTAssertThrows([engine.binaryMessenger
      sendOnChannel:@"foo"
            message:[@"bar" dataUsingEncoding:NSUTF8StringEncoding]
        binaryReply:nil]);
}

- (void)testSetMessageHandlerBeforeRun {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
  XCTAssertThrows([engine.binaryMessenger
      setMessageHandlerOnChannel:@"foo"
            binaryMessageHandler:^(NSData* _Nullable message, FlutterBinaryReply _Nonnull reply){

            }]);
}

- (void)testNilSetMessageHandlerBeforeRun {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  XCTAssertNotNil(engine);
  XCTAssertNoThrow([engine.binaryMessenger setMessageHandlerOnChannel:@"foo"
                                                 binaryMessageHandler:nil]);
}

- (void)testNotifyPluginOfDealloc {
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  OCMStub([plugin detachFromEngineForRegistrar:[OCMArg any]]);
  {
    FlutterDartProject* project = [[FlutterDartProject alloc] init];
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

- (void)testInitialRouteSettingsSendsNavigationMessage {
  id mockBinaryMessenger = OCMClassMock([FlutterBinaryMessengerRelay class]);

  auto settings = FLTDefaultSettingsForBundle();
  settings.route = "test";
  FlutterDartProject* project = [[FlutterDartProject alloc] initWithSettings:settings];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  [engine setBinaryMessenger:mockBinaryMessenger];
  [engine run];

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
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testSpawn {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar"];
  [engine run];
  FlutterEngine* spawn = [engine spawnWithEntrypoint:nil
                                          libraryURI:nil
                                        initialRoute:nil
                                      entrypointArgs:nil];
  XCTAssertNotNil(spawn);
}

- (void)testDeallocNotification {
  XCTestExpectation* deallocNotification = [self expectationWithDescription:@"deallocNotification"];
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  id<NSObject> observer;
  @autoreleasepool {
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar"];
    observer = [center addObserverForName:kFlutterEngineWillDealloc
                                   object:engine
                                    queue:[NSOperationQueue mainQueue]
                               usingBlock:^(NSNotification* note) {
                                 [deallocNotification fulfill];
                               }];
  }
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [center removeObserver:observer];
}

- (void)testSetHandlerAfterRun {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar"];
  XCTestExpectation* gotMessage = [self expectationWithDescription:@"gotMessage"];
  dispatch_async(dispatch_get_main_queue(), ^{
    NSObject<FlutterPluginRegistrar>* registrar = [engine registrarForPlugin:@"foo"];
    fml::AutoResetWaitableEvent latch;
    [engine run];
    flutter::Shell& shell = engine.shell;
    engine.shell.GetTaskRunners().GetUITaskRunner()->PostTask([&latch, &shell] {
      flutter::Engine::Delegate& delegate = shell;
      auto message = std::make_unique<flutter::PlatformMessage>("foo", nullptr);
      delegate.OnEngineHandlePlatformMessage(std::move(message));
      latch.Signal();
    });
    latch.Wait();
    [registrar.messenger setMessageHandlerOnChannel:@"foo"
                               binaryMessageHandler:^(NSData* message, FlutterBinaryReply reply) {
                                 [gotMessage fulfill];
                               }];
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThreadPrioritySetCorrectly {
  XCTestExpectation* prioritiesSet = [self expectationWithDescription:@"prioritiesSet"];
  prioritiesSet.expectedFulfillmentCount = 3;

  IMP mockSetThreadPriority =
      imp_implementationWithBlock(^(NSThread* thread, double threadPriority) {
        if ([thread.name hasSuffix:@".ui"]) {
          XCTAssertEqual(threadPriority, 1.0);
          [prioritiesSet fulfill];
        } else if ([thread.name hasSuffix:@".raster"]) {
          XCTAssertEqual(threadPriority, 1.0);
          [prioritiesSet fulfill];
        } else if ([thread.name hasSuffix:@".io"]) {
          XCTAssertEqual(threadPriority, 0.5);
          [prioritiesSet fulfill];
        }
      });
  Method method = class_getInstanceMethod([NSThread class], @selector(setThreadPriority:));
  IMP originalSetThreadPriority = method_getImplementation(method);
  method_setImplementation(method, mockSetThreadPriority);

  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine run];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  method_setImplementation(method, originalSetThreadPriority);
}

- (void)testCanEnableDisableEmbedderAPIThroughInfoPlist {
  {
    // Not enable embedder API by default
    auto settings = FLTDefaultSettingsForBundle();
    settings.enable_software_rendering = true;
    FlutterDartProject* project = [[FlutterDartProject alloc] initWithSettings:settings];
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
    XCTAssertFalse(engine.enableEmbedderAPI);
  }
  {
    // Enable embedder api
    id mockMainBundle = OCMPartialMock([NSBundle mainBundle]);
    OCMStub([mockMainBundle objectForInfoDictionaryKey:@"FLTEnableIOSEmbedderAPI"])
        .andReturn(@"YES");
    auto settings = FLTDefaultSettingsForBundle();
    settings.enable_software_rendering = true;
    FlutterDartProject* project = [[FlutterDartProject alloc] initWithSettings:settings];
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
    XCTAssertTrue(engine.enableEmbedderAPI);
  }
}

- (void)testFlutterTextInputViewDidResignFirstResponderWillCallTextInputClientConnectionClosed {
  id mockBinaryMessenger = OCMClassMock([FlutterBinaryMessengerRelay class]);
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine setBinaryMessenger:mockBinaryMessenger];
  [engine runWithEntrypoint:FlutterDefaultDartEntrypoint initialRoute:@"test"];
  [engine flutterTextInputView:nil didResignFirstResponderWithTextInputClient:1];
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"TextInputClient.onConnectionClosed"
                                        arguments:@[ @(1) ]];
  NSData* encodedMethodCall = [[FlutterJSONMethodCodec sharedInstance] encodeMethodCall:methodCall];
  OCMVerify([mockBinaryMessenger sendOnChannel:@"flutter/textinput" message:encodedMethodCall]);
}

- (void)testFlutterEngineUpdatesDisplays {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  id mockEngine = OCMPartialMock(engine);

  [engine run];
  OCMVerify(times(1), [mockEngine updateDisplays]);
  engine.viewController = nil;
  OCMVerify(times(2), [mockEngine updateDisplays]);
}

@end
