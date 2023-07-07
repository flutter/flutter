// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

@interface FWFUIViewHostApiTests : XCTestCase
@end

@implementation FWFUIViewHostApiTests
- (void)testSetBackgroundColor {
  UIView *mockUIView = OCMClassMock([UIView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockUIView withIdentifier:0];

  FWFUIViewHostApiImpl *hostAPI =
      [[FWFUIViewHostApiImpl alloc] initWithInstanceManager:instanceManager];

  FlutterError *error;
  [hostAPI setBackgroundColorForViewWithIdentifier:@0 toValue:@123 error:&error];

  OCMVerify([mockUIView setBackgroundColor:[UIColor colorWithRed:(123 >> 16 & 0xff) / 255.0
                                                           green:(123 >> 8 & 0xff) / 255.0
                                                            blue:(123 & 0xff) / 255.0
                                                           alpha:(123 >> 24 & 0xff) / 255.0]]);
  XCTAssertNil(error);
}

- (void)testSetOpaque {
  UIView *mockUIView = OCMClassMock([UIView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockUIView withIdentifier:0];

  FWFUIViewHostApiImpl *hostAPI =
      [[FWFUIViewHostApiImpl alloc] initWithInstanceManager:instanceManager];

  FlutterError *error;
  [hostAPI setOpaqueForViewWithIdentifier:@0 isOpaque:@YES error:&error];
  OCMVerify([mockUIView setOpaque:YES]);
  XCTAssertNil(error);
}

@end
