// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

FLUTTER_ASSERT_ARC

@interface FlutterSharedApplicationTest : XCTestCase
@end

@implementation FlutterSharedApplicationTest

- (void)testWhenNSExtensionInBundle {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"NSExtension"]).andReturn(@{
    @"NSExtensionPointIdentifier" : @"com.apple.share-services"
  });
  XCTAssertTrue(FlutterSharedApplication.isAppExtension);
  XCTAssertFalse(FlutterSharedApplication.isAvailable);
  [mockBundle stopMocking];
}

- (void)testWhenNSExtensionEmptyInBundle {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"NSExtension"])
      .andReturn([[NSDictionary alloc] init]);
  XCTAssertTrue(FlutterSharedApplication.isAppExtension);
  XCTAssertFalse(FlutterSharedApplication.isAvailable);
  [mockBundle stopMocking];
}

- (void)testWhenNSExtensionNotInBundle {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  XCTAssertFalse(FlutterSharedApplication.isAppExtension);
  XCTAssertTrue(FlutterSharedApplication.isAvailable);
  [mockBundle stopMocking];
}

- (void)testSharedApplicationNotCalledIfIsAvailableFalse {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"NSExtension"]).andReturn(@{
    @"NSExtensionPointIdentifier" : @"com.apple.share-services"
  });
  id mockApplication = OCMClassMock([UIApplication class]);
  XCTAssertFalse(FlutterSharedApplication.isAvailable);
  OCMReject([mockApplication sharedApplication]);
  XCTAssertNil(FlutterSharedApplication.application);
  [mockBundle stopMocking];
}

- (void)testSharedApplicationCalledIfIsAvailableTrue {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  id mockApplication = OCMClassMock([UIApplication class]);
  XCTAssertTrue(FlutterSharedApplication.isAvailable);
  XCTAssertNotNil(FlutterSharedApplication.application);
  OCMVerify([mockApplication sharedApplication]);
  [mockBundle stopMocking];
}

- (void)testHasSceneDelegate {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  XCTAssertTrue(FlutterSharedApplication.isAvailable);
  XCTAssertNotNil(FlutterSharedApplication.application);

  id mockSceneWithDelegate = OCMClassMock([UIScene class]);
  id mockSceneDelegate = OCMProtocolMock(@protocol(UISceneDelegate));
  OCMStub([mockSceneWithDelegate delegate]).andReturn(mockSceneDelegate);
  NSSet<UIScene*>* connectedScenes = [NSSet setWithObjects:mockSceneWithDelegate, nil];
  OCMStub([mockApplication connectedScenes]).andReturn(connectedScenes);

  XCTAssertTrue(FlutterSharedApplication.hasSceneDelegate);

  [mockBundle stopMocking];
}

- (void)testHasNoSceneDelegate {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  XCTAssertTrue(FlutterSharedApplication.isAvailable);
  XCTAssertNotNil(FlutterSharedApplication.application);

  id mockScene = OCMClassMock([UIScene class]);
  NSSet<UIScene*>* connectedScenes = [NSSet setWithObjects:mockScene, nil];
  OCMStub([mockApplication connectedScenes]).andReturn(connectedScenes);

  XCTAssertFalse(FlutterSharedApplication.hasSceneDelegate);
  [mockBundle stopMocking];
}

- (void)testFlutterDeeplinkingEnabledWhenNil {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"FlutterDeepLinkingEnabled"]).andReturn(nil);

  XCTAssertTrue(FlutterSharedApplication.isFlutterDeepLinkingEnabled);
  [mockBundle stopMocking];
}

- (void)testFlutterDeeplinkingEnabledWhenYes {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"FlutterDeepLinkingEnabled"]).andReturn(@YES);

  XCTAssertTrue(FlutterSharedApplication.isFlutterDeepLinkingEnabled);
  [mockBundle stopMocking];
}

- (void)testFlutterDeeplinkingEnabledWhenNo {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"FlutterDeepLinkingEnabled"]).andReturn(@NO);

  XCTAssertFalse(FlutterSharedApplication.isFlutterDeepLinkingEnabled);
  [mockBundle stopMocking];
}

- (void)testFlutterDeeplinkingEnabledWhenBogus {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"FlutterDeepLinkingEnabled"]).andReturn(@"hello");

  XCTAssertFalse(FlutterSharedApplication.isFlutterDeepLinkingEnabled);
  [mockBundle stopMocking];
}

@end
