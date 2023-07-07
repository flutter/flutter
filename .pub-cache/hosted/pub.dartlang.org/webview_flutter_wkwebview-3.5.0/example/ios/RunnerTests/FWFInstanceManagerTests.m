// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

@import webview_flutter_wkwebview;
@import webview_flutter_wkwebview.Test;

@interface FWFInstanceManagerTests : XCTestCase
@end

@implementation FWFInstanceManagerTests
- (void)testAddDartCreatedInstance {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  NSObject *object = [[NSObject alloc] init];

  [instanceManager addDartCreatedInstance:object withIdentifier:0];
  XCTAssertEqualObjects([instanceManager instanceForIdentifier:0], object);
  XCTAssertEqual([instanceManager identifierWithStrongReferenceForInstance:object], 0);
}

- (void)testAddHostCreatedInstance {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  NSObject *object = [[NSObject alloc] init];
  [instanceManager addHostCreatedInstance:object];

  long identifier = [instanceManager identifierWithStrongReferenceForInstance:object];
  XCTAssertNotEqual(identifier, NSNotFound);
  XCTAssertEqualObjects([instanceManager instanceForIdentifier:identifier], object);
}

- (void)testRemoveInstanceWithIdentifier {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  NSObject *object = [[NSObject alloc] init];

  [instanceManager addDartCreatedInstance:object withIdentifier:0];

  XCTAssertEqualObjects([instanceManager removeInstanceWithIdentifier:0], object);
  XCTAssertEqual([instanceManager strongInstanceCount], 0);
}

- (void)testDeallocCallbackIsIgnoredIfNull {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  // This sets deallocCallback to nil to test that uses are null checked.
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] initWithDeallocCallback:nil];
#pragma clang diagnostic pop

  [instanceManager addDartCreatedInstance:[[NSObject alloc] init] withIdentifier:0];

  // Tests that this doesn't cause a EXC_BAD_ACCESS crash.
  [instanceManager removeInstanceWithIdentifier:0];
}
@end
