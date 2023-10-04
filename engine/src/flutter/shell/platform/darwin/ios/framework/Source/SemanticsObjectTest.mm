// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObjectTestMocks.h"

FLUTTER_ASSERT_ARC

@interface SemanticsObjectTest : XCTestCase
@end

@implementation SemanticsObjectTest

- (void)testCreate {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  XCTAssertNotNil(object);
}

- (void)testSetChildren {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  parent.children = @[ child ];
  XCTAssertEqual(parent, child.parent);
  parent.children = @[];
  XCTAssertNil(child.parent);
}

- (void)testAccessibilityHitTestFocusAtLeaf {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object0 = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* object1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* object2 = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  SemanticsObject* object3 = [[SemanticsObject alloc] initWithBridge:bridge uid:3];
  object0.children = @[ object1 ];
  object0.childrenInHitTestOrder = @[ object1 ];
  object1.children = @[ object2, object3 ];
  object1.childrenInHitTestOrder = @[ object2, object3 ];

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
  [object2 setSemanticsNode:&node2];

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  node3.label = "3";
  [object3 setSemanticsNode:&node3];

  CGPoint point = CGPointMake(10, 10);
  id hitTestResult = [object0 _accessibilityHitTest:point withEvent:nil];

  // Focus to object2 because it's the first object in hit test order
  XCTAssertEqual(hitTestResult, object2);
}

- (void)testAccessibilityHitTestNoFocusableItem {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object0 = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* object1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* object2 = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  SemanticsObject* object3 = [[SemanticsObject alloc] initWithBridge:bridge uid:3];
  object0.children = @[ object1 ];
  object0.childrenInHitTestOrder = @[ object1 ];
  object1.children = @[ object2, object3 ];
  object1.childrenInHitTestOrder = @[ object2, object3 ];

  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  [object0 setSemanticsNode:&node0];

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  [object1 setSemanticsNode:&node1];

  flutter::SemanticsNode node2;
  node2.id = 2;
  node2.rect = SkRect::MakeXYWH(0, 0, 100, 100);
  [object2 setSemanticsNode:&node2];

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  [object3 setSemanticsNode:&node3];

  CGPoint point = CGPointMake(10, 10);
  id hitTestResult = [object0 _accessibilityHitTest:point withEvent:nil];

  XCTAssertNil(hitTestResult);
}

- (void)testAccessibilityScrollToVisible {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object3 = [[SemanticsObject alloc] initWithBridge:bridge uid:3];

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  [object3 setSemanticsNode:&node3];

  [object3 accessibilityScrollToVisible];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 3);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testAccessibilityScrollToVisibleWithChild {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object3 = [[SemanticsObject alloc] initWithBridge:bridge uid:3];

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  [object3 setSemanticsNode:&node3];

  [object3 accessibilityScrollToVisibleWithChild:object3];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 3);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testAccessibilityHitTestOutOfRect {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object0 = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* object1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* object2 = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  SemanticsObject* object3 = [[SemanticsObject alloc] initWithBridge:bridge uid:3];
  object0.children = @[ object1 ];
  object0.childrenInHitTestOrder = @[ object1 ];
  object1.children = @[ object2, object3 ];
  object1.childrenInHitTestOrder = @[ object2, object3 ];

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
  [object2 setSemanticsNode:&node2];

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  node3.label = "3";
  [object3 setSemanticsNode:&node3];

  CGPoint point = CGPointMake(300, 300);
  id hitTestResult = [object0 _accessibilityHitTest:point withEvent:nil];

  XCTAssertNil(hitTestResult);
}

- (void)testReplaceChildAtIndex {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* child2 = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  parent.children = @[ child1 ];
  [parent replaceChildAtIndex:0 withChild:child2];
  XCTAssertNil(child1.parent);
  XCTAssertEqual(parent, child2.parent);
  XCTAssertEqualObjects(parent.children, @[ child2 ]);
}

- (void)testPlainSemanticsObjectWithLabelHasStaticTextTrait {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitStaticText);
}

- (void)testNodeWithImplicitScrollIsAnAccessibilityElementWhenItisHidden {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling) |
               static_cast<int32_t>(flutter::SemanticsFlags::kIsHidden);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual(object.isAccessibilityElement, YES);
}

- (void)testNodeWithImplicitScrollIsNotAnAccessibilityElementWhenItisNotHidden {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual(object.isAccessibilityElement, NO);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  object.children = @[ child1 ];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitNone);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait1 {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsTextField);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitNone);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait2 {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsButton);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitButton);
}

- (void)testVerticalFlutterScrollableSemanticsObject {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float screenScale = [[bridge->view() window] screen].scale;
  float effectivelyScale = transformScale / screenScale;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = 500.0;
  float scrollPosition = 150.0;

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kVerticalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(x, y, w, h);
  node.scrollExtentMax = scrollExtentMax;
  node.scrollPosition = scrollPosition;
  node.transform = {
      transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, 1.0};
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];
  XCTAssertTrue(
      CGRectEqualToRect(scrollView.frame, CGRectMake(x * effectivelyScale, y * effectivelyScale,
                                                     w * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGSizeEqualToSize(
      scrollView.contentSize,
      CGSizeMake(w * effectivelyScale, (h + scrollExtentMax) * effectivelyScale)));
  XCTAssertTrue(CGPointEqualToPoint(scrollView.contentOffset,
                                    CGPointMake(0, scrollPosition * effectivelyScale)));
}

- (void)testVerticalFlutterScrollableSemanticsObjectNoWindowDoesNotCrash {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridgeNoWindow());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = 500.0;
  float scrollPosition = 150.0;

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kVerticalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(x, y, w, h);
  node.scrollExtentMax = scrollExtentMax;
  node.scrollPosition = scrollPosition;
  node.transform = {
      transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, 1.0};
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  XCTAssertNoThrow([scrollable accessibilityBridgeDidFinishUpdate]);
}

- (void)testHorizontalFlutterScrollableSemanticsObject {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float screenScale = [[bridge->view() window] screen].scale;
  float effectivelyScale = transformScale / screenScale;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = 500.0;
  float scrollPosition = 150.0;

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(x, y, w, h);
  node.scrollExtentMax = scrollExtentMax;
  node.scrollPosition = scrollPosition;
  node.transform = {
      transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, 1.0};
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];
  XCTAssertTrue(
      CGRectEqualToRect(scrollView.frame, CGRectMake(x * effectivelyScale, y * effectivelyScale,
                                                     w * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGSizeEqualToSize(
      scrollView.contentSize,
      CGSizeMake((w + scrollExtentMax) * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGPointEqualToPoint(scrollView.contentOffset,
                                    CGPointMake(scrollPosition * effectivelyScale, 0)));
}

- (void)testCanHandleInfiniteScrollExtent {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float screenScale = [[bridge->view() window] screen].scale;
  float effectivelyScale = transformScale / screenScale;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = INFINITY;
  float scrollPosition = 150.0;

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kVerticalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(x, y, w, h);
  node.scrollExtentMax = scrollExtentMax;
  node.scrollPosition = scrollPosition;
  node.transform = {
      transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, 1.0};
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];
  XCTAssertTrue(
      CGRectEqualToRect(scrollView.frame, CGRectMake(x * effectivelyScale, y * effectivelyScale,
                                                     w * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGSizeEqualToSize(
      scrollView.contentSize,
      CGSizeMake(w * effectivelyScale,
                 (h + kScrollExtentMaxForInf + scrollPosition) * effectivelyScale)));
  XCTAssertTrue(CGPointEqualToPoint(scrollView.contentOffset,
                                    CGPointMake(0, scrollPosition * effectivelyScale)));
}

- (void)testCanHandleNaNScrollExtentAndScrollPoisition {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float screenScale = [[bridge->view() window] screen].scale;
  float effectivelyScale = transformScale / screenScale;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = std::nan("");
  float scrollPosition = std::nan("");

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kVerticalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(x, y, w, h);
  node.scrollExtentMax = scrollExtentMax;
  node.scrollPosition = scrollPosition;
  node.transform = {
      transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, transformScale, 0, 0, 0, 0, 1.0};
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];
  XCTAssertTrue(
      CGRectEqualToRect(scrollView.frame, CGRectMake(x * effectivelyScale, y * effectivelyScale,
                                                     w * effectivelyScale, h * effectivelyScale)));
  // Content size equal to the scrollable size.
  XCTAssertTrue(CGSizeEqualToSize(scrollView.contentSize,
                                  CGSizeMake(w * effectivelyScale, h * effectivelyScale)));
  XCTAssertTrue(CGPointEqualToPoint(scrollView.contentOffset, CGPointMake(0, 0)));
}

- (void)testFlutterScrollableSemanticsObjectIsNotHittestable {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;

  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];
  XCTAssertEqual([scrollView hitTest:CGPointMake(10, 10) withEvent:nil], nil);
}

- (void)testFlutterScrollableSemanticsObjectIsHiddenWhenVoiceOverIsRunning {
  flutter::MockAccessibilityBridge* mock = new flutter::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = false;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;

  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];
  XCTAssertTrue(scrollView.isAccessibilityElement);
  mock->isVoiceOverRunningValue = true;
  XCTAssertFalse(scrollView.isAccessibilityElement);
}

- (void)testFlutterScrollableSemanticsObjectWithLabelValueHintIsNotHiddenWhenVoiceOverIsRunning {
  flutter::MockAccessibilityBridge* mock = new flutter::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.label = "label";
  node.value = "value";
  node.hint = "hint";
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;

  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];
  XCTAssertTrue(scrollView.isAccessibilityElement);
  XCTAssertTrue(
      [scrollView.accessibilityLabel isEqualToString:NSLocalizedString(@"label", @"test")]);
  XCTAssertTrue(
      [scrollView.accessibilityValue isEqualToString:NSLocalizedString(@"value", @"test")]);
  XCTAssertTrue([scrollView.accessibilityHint isEqualToString:NSLocalizedString(@"hint", @"test")]);
}

- (void)testFlutterSemanticsObjectMergeTooltipToLabel {
  flutter::MockAccessibilityBridge* mock = new flutter::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.label = "label";
  node.tooltip = "tooltip";
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertTrue(object.isAccessibilityElement);
  XCTAssertTrue([object.accessibilityLabel isEqualToString:@"label\ntooltip"]);
}

- (void)testFlutterSemanticsObjectAttributedStringsDoNotCrashWhenEmpty {
  flutter::MockAccessibilityBridge* mock = new flutter::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertTrue(object.accessibilityAttributedLabel == nil);
}

- (void)testFlutterScrollableSemanticsObjectReturnsParentContainerIfNoChildren {
  flutter::MockAccessibilityBridge* mock = new flutter::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode parent;
  parent.id = 0;
  parent.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  parent.label = "label";
  parent.value = "value";
  parent.hint = "hint";

  flutter::SemanticsNode node;
  node.id = 1;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.label = "label";
  node.value = "value";
  node.hint = "hint";
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;
  parent.childrenInTraversalOrder.push_back(1);

  FlutterSemanticsObject* parentObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                    uid:0];
  [parentObject setSemanticsNode:&parent];

  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:1];
  [scrollable setSemanticsNode:&node];
  UIScrollView* scrollView = [scrollable nativeAccessibility];

  parentObject.children = @[ scrollable ];
  [parentObject accessibilityBridgeDidFinishUpdate];
  [scrollable accessibilityBridgeDidFinishUpdate];
  XCTAssertTrue(scrollView.isAccessibilityElement);
  SemanticsObjectContainer* container =
      static_cast<SemanticsObjectContainer*>(scrollable.accessibilityContainer);
  XCTAssertEqual(container.semanticsObject, parentObject);
}

- (void)testFlutterScrollableSemanticsObjectHidesScrollBar {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;

  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];
  UIScrollView* scrollView = [scrollable nativeAccessibility];

  XCTAssertFalse(scrollView.showsHorizontalScrollIndicator);
  XCTAssertFalse(scrollView.showsVerticalScrollIndicator);
}

- (void)testSemanticsObjectBuildsAttributedString {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "label";
  std::shared_ptr<flutter::SpellOutStringAttribute> attribute =
      std::make_shared<flutter::SpellOutStringAttribute>();
  attribute->start = 1;
  attribute->end = 2;
  attribute->type = flutter::StringAttributeType::kSpellOut;
  node.labelAttributes.push_back(attribute);
  node.value = "value";
  attribute = std::make_shared<flutter::SpellOutStringAttribute>();
  attribute->start = 2;
  attribute->end = 3;
  attribute->type = flutter::StringAttributeType::kSpellOut;
  node.valueAttributes.push_back(attribute);
  node.hint = "hint";
  std::shared_ptr<flutter::LocaleStringAttribute> local_attribute =
      std::make_shared<flutter::LocaleStringAttribute>();
  local_attribute->start = 3;
  local_attribute->end = 4;
  local_attribute->type = flutter::StringAttributeType::kLocale;
  local_attribute->locale = "en-MX";
  node.hintAttributes.push_back(local_attribute);
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  NSMutableAttributedString* expectedAttributedLabel =
      [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"label", @"test")];
  NSDictionary* attributeDict = @{
    UIAccessibilitySpeechAttributeSpellOut : @YES,
  };
  [expectedAttributedLabel setAttributes:attributeDict range:NSMakeRange(1, 1)];
  XCTAssertTrue(
      [object.accessibilityAttributedLabel isEqualToAttributedString:expectedAttributedLabel]);

  NSMutableAttributedString* expectedAttributedValue =
      [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"value", @"test")];
  attributeDict = @{
    UIAccessibilitySpeechAttributeSpellOut : @YES,
  };
  [expectedAttributedValue setAttributes:attributeDict range:NSMakeRange(2, 1)];
  XCTAssertTrue(
      [object.accessibilityAttributedValue isEqualToAttributedString:expectedAttributedValue]);

  NSMutableAttributedString* expectedAttributedHint =
      [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"hint", @"test")];
  attributeDict = @{
    UIAccessibilitySpeechAttributeLanguage : @"en-MX",
  };
  [expectedAttributedHint setAttributes:attributeDict range:NSMakeRange(3, 1)];
  XCTAssertTrue(
      [object.accessibilityAttributedHint isEqualToAttributedString:expectedAttributedHint]);
}

- (void)testShouldTriggerAnnouncement {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];

  // Handle nil with no node set.
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:nil]);

  // Handle initial setting of node with liveRegion
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsLiveRegion);
  node.label = "foo";
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&node]);

  // Handle nil with node set.
  [object setSemanticsNode:&node];
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:nil]);

  // Handle new node, still has live region, same label.
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:&node]);

  // Handle update node with new label, still has live region.
  flutter::SemanticsNode updatedNode;
  updatedNode.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsLiveRegion);
  updatedNode.label = "bar";
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&updatedNode]);

  // Handle dropping the live region flag.
  updatedNode.flags = 0;
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:&updatedNode]);

  // Handle adding the flag when the label has not changed.
  updatedNode.label = "foo";
  [object setSemanticsNode:&updatedNode];
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&node]);
}

- (void)testShouldDispatchShowOnScreenActionForHeader {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsHeader);
  node.label = "foo";

  [object setSemanticsNode:&node];

  // Simulate accessibility focus.
  [object accessibilityElementDidBecomeFocused];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 1);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testShouldDispatchShowOnScreenActionForHidden {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:1];

  // Handle initial setting of node with hidden.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsHidden);
  node.label = "foo";

  [object setSemanticsNode:&node];

  // Simulate accessibility focus.
  [object accessibilityElementDidBecomeFocused];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 1);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testFlutterSwitchSemanticsObjectMatchesUISwitch {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterSwitchSemanticsObject* object = [[FlutterSwitchSemanticsObject alloc] initWithBridge:bridge
                                                                                          uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasToggledState) |
               static_cast<int32_t>(flutter::SemanticsFlags::kIsToggled) |
               static_cast<int32_t>(flutter::SemanticsFlags::kIsEnabled);
  node.label = "foo";
  [object setSemanticsNode:&node];
  // Create ab real UISwitch to compare the FlutterSwitchSemanticsObject with.
  UISwitch* nativeSwitch = [[UISwitch alloc] init];
  nativeSwitch.on = YES;

  XCTAssertEqual(object.accessibilityTraits, nativeSwitch.accessibilityTraits);
  XCTAssertEqualObjects(object.accessibilityValue, nativeSwitch.accessibilityValue);

  // Set the toggled to false;
  flutter::SemanticsNode update;
  update.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasToggledState) |
                 static_cast<int32_t>(flutter::SemanticsFlags::kIsEnabled);
  update.label = "foo";
  [object setSemanticsNode:&update];

  nativeSwitch.on = NO;

  XCTAssertEqual(object.accessibilityTraits, nativeSwitch.accessibilityTraits);
  XCTAssertEqualObjects(object.accessibilityValue, nativeSwitch.accessibilityValue);
}

- (void)testFlutterSemanticsObjectOfRadioButton {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kIsInMutuallyExclusiveGroup) |
               static_cast<int32_t>(flutter::SemanticsFlags::kHasCheckedState) |
               static_cast<int32_t>(flutter::SemanticsFlags::kHasEnabledState) |
               static_cast<int32_t>(flutter::SemanticsFlags::kIsEnabled);
  node.label = "foo";
  [object setSemanticsNode:&node];
  XCTAssertTrue((object.accessibilityTraits & UIAccessibilityTraitButton) > 0);
  XCTAssertNil(object.accessibilityValue);
}

- (void)testFlutterSwitchSemanticsObjectMatchesUISwitchDisabled {
  fml::WeakPtrFactory<flutter::MockAccessibilityBridge> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterSwitchSemanticsObject* object = [[FlutterSwitchSemanticsObject alloc] initWithBridge:bridge
                                                                                          uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasToggledState) |
               static_cast<int32_t>(flutter::SemanticsFlags::kIsToggled);
  node.label = "foo";
  [object setSemanticsNode:&node];
  // Create ab real UISwitch to compare the FlutterSwitchSemanticsObject with.
  UISwitch* nativeSwitch = [[UISwitch alloc] init];
  nativeSwitch.on = YES;
  nativeSwitch.enabled = NO;

  XCTAssertEqual(object.accessibilityTraits, nativeSwitch.accessibilityTraits);
  XCTAssertEqualObjects(object.accessibilityValue, nativeSwitch.accessibilityValue);
}

- (void)testSemanticsObjectDeallocated {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  parent.children = @[ child ];
  // Validate SemanticsObject deallocation does not crash.
  // https://github.com/flutter/flutter/issues/66032
  __weak SemanticsObject* weakObject = parent;
  parent = nil;
  XCTAssertNil(weakObject);
}

- (void)testFlutterSemanticsObjectReturnsNilContainerWhenBridgeIsNotAlive {
  FlutterSemanticsObject* parentObject;
  FlutterScrollableSemanticsObject* scrollable;
  FlutterSemanticsObject* object2;

  flutter::SemanticsNode parent;
  parent.id = 0;
  parent.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  parent.label = "label";
  parent.value = "value";
  parent.hint = "hint";

  flutter::SemanticsNode node;
  node.id = 1;
  node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kHasImplicitScrolling);
  node.actions = flutter::kHorizontalScrollSemanticsActions;
  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.label = "label";
  node.value = "value";
  node.hint = "hint";
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;
  parent.childrenInTraversalOrder.push_back(1);

  flutter::SemanticsNode node2;
  node2.id = 2;
  node2.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node2.label = "label";
  node2.value = "value";
  node2.hint = "hint";
  node2.scrollExtentMax = 100.0;
  node2.scrollPosition = 0.0;
  parent.childrenInTraversalOrder.push_back(2);

  {
    flutter::MockAccessibilityBridge* mock = new flutter::MockAccessibilityBridge();
    mock->isVoiceOverRunningValue = true;
    fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
    fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

    parentObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
    [parentObject setSemanticsNode:&parent];

    scrollable = [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:1];
    [scrollable setSemanticsNode:&node];
    [scrollable accessibilityBridgeDidFinishUpdate];

    object2 = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:2];
    [object2 setSemanticsNode:&node2];

    parentObject.children = @[ scrollable, object2 ];
    [parentObject accessibilityBridgeDidFinishUpdate];
    [scrollable accessibilityBridgeDidFinishUpdate];
    [object2 accessibilityBridgeDidFinishUpdate];

    // Returns the correct container if the bridge is alive.
    SemanticsObjectContainer* container =
        static_cast<SemanticsObjectContainer*>(scrollable.accessibilityContainer);
    XCTAssertEqual(container.semanticsObject, parentObject);
    SemanticsObjectContainer* container2 =
        static_cast<SemanticsObjectContainer*>(object2.accessibilityContainer);
    XCTAssertEqual(container2.semanticsObject, parentObject);
  }
  // The bridge pointer went out of scope and was deallocated.

  XCTAssertNil(scrollable.accessibilityContainer);
  XCTAssertNil(object2.accessibilityContainer);
}

@end
