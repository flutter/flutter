// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
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

@end
