// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

@interface FWFScrollViewHostApiTests : XCTestCase
@end

@implementation FWFScrollViewHostApiTests
- (void)testGetContentOffset {
  UIScrollView *mockScrollView = OCMClassMock([UIScrollView class]);
  OCMStub([mockScrollView contentOffset]).andReturn(CGPointMake(1.0, 2.0));

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockScrollView withIdentifier:0];

  FWFScrollViewHostApiImpl *hostAPI =
      [[FWFScrollViewHostApiImpl alloc] initWithInstanceManager:instanceManager];

  FlutterError *error;
  NSArray<NSNumber *> *expectedValue = @[ @1.0, @2.0 ];
  XCTAssertEqualObjects([hostAPI contentOffsetForScrollViewWithIdentifier:@0 error:&error],
                        expectedValue);
  XCTAssertNil(error);
}

- (void)testScrollBy {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  scrollView.contentOffset = CGPointMake(1, 2);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:scrollView withIdentifier:0];

  FWFScrollViewHostApiImpl *hostAPI =
      [[FWFScrollViewHostApiImpl alloc] initWithInstanceManager:instanceManager];

  FlutterError *error;
  [hostAPI scrollByForScrollViewWithIdentifier:@0 x:@1 y:@2 error:&error];
  XCTAssertEqual(scrollView.contentOffset.x, 2);
  XCTAssertEqual(scrollView.contentOffset.y, 4);
  XCTAssertNil(error);
}

- (void)testSetContentOffset {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:scrollView withIdentifier:0];

  FWFScrollViewHostApiImpl *hostAPI =
      [[FWFScrollViewHostApiImpl alloc] initWithInstanceManager:instanceManager];

  FlutterError *error;
  [hostAPI setContentOffsetForScrollViewWithIdentifier:@0 toX:@1 y:@2 error:&error];
  XCTAssertEqual(scrollView.contentOffset.x, 1);
  XCTAssertEqual(scrollView.contentOffset.y, 2);
  XCTAssertNil(error);
}
@end
