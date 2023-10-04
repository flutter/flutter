// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTouchInterceptingView_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObjectTestMocks.h"

FLUTTER_ASSERT_NOT_ARC

@interface SemanticsObjectTestMRC : XCTestCase
@end

@implementation SemanticsObjectTestMRC

- (void)testAccessibilityHitTestSearchCanReturnPlatformView {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object0 = [[[SemanticsObject alloc] initWithBridge:bridge uid:0] autorelease];
  SemanticsObject* object1 = [[[SemanticsObject alloc] initWithBridge:bridge uid:1] autorelease];
  SemanticsObject* object3 = [[[SemanticsObject alloc] initWithBridge:bridge uid:3] autorelease];
  FlutterTouchInterceptingView* platformView =
      [[[FlutterTouchInterceptingView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)] autorelease];
  FlutterPlatformViewSemanticsContainer* platformViewSemanticsContainer =
      [[[FlutterPlatformViewSemanticsContainer alloc] initWithBridge:bridge
                                                                 uid:1
                                                        platformView:platformView] autorelease];

  object0.children = @[ object1 ];
  object0.childrenInHitTestOrder = @[ object1 ];
  object1.children = @[ platformViewSemanticsContainer, object3 ];
  object1.childrenInHitTestOrder = @[ platformViewSemanticsContainer, object3 ];

  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  node0.label = "0";
  [object0 setSemanticsNode:&node0];

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  node1.label = "1";
  [object1 setSemanticsNode:&node1];

  flutter::SemanticsNode node2;
  node2.id = 2;
  node2.rect = SkRect::MakeXYWH(0, 0, 100, 100);
  node2.label = "2";
  [platformViewSemanticsContainer setSemanticsNode:&node2];

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  node3.label = "3";
  [object3 setSemanticsNode:&node3];

  CGPoint point = CGPointMake(10, 10);
  id hitTestResult = [object0 _accessibilityHitTest:point withEvent:nil];

  XCTAssertEqual(hitTestResult, platformView);
}

- (void)testFlutterPlatformViewSemanticsContainer {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterTouchInterceptingView* platformView =
      [[[FlutterTouchInterceptingView alloc] init] autorelease];
  @autoreleasepool {
    FlutterPlatformViewSemanticsContainer* container =
        [[[FlutterPlatformViewSemanticsContainer alloc] initWithBridge:bridge
                                                                   uid:1
                                                          platformView:platformView] autorelease];
    XCTAssertEqualObjects(platformView.accessibilityContainer, container);
    XCTAssertEqual(platformView.retainCount, 2u);
  }
  // Check if there's no more strong references to `platformView` after container and platformView
  // are released.
  XCTAssertEqual(platformView.retainCount, 1u);
}

@end
