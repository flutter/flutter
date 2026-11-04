// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSemanticsScrollView.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTouchInterceptingView+Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObjectTestMocks.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/TextInputSemanticsObject.h"

FLUTTER_ASSERT_ARC

const float kFloatCompareEpsilon = 0.001;

@interface SemanticsObject (UIFocusSystem) <UIFocusItem, UIFocusItemContainer>
@end

@interface FlutterScrollableSemanticsObject (UIFocusItemScrollableContainer) <
    UIFocusItemScrollableContainer>
@end

@interface TextInputSemanticsObject (Test)
- (UIView<UITextInput>*)textInputSurrogate;
@end

@interface SemanticsObjectTest : XCTestCase
@end

@implementation SemanticsObjectTest

- (void)testCreate {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  XCTAssertNotNil(object);
}

- (void)testUIFocusSystemMethodsDoNotCrashWhenBridgeIsDead {
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge;
  SemanticsObject* object;
  {
    auto mock_bridge = std::make_unique<flutter::testing::MockAccessibilityBridge>();
    fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock_bridge.get());
    bridge = factory.GetWeakPtr();
    object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  }
  // Now bridge is nullptr.

  XCTAssertNil([object parentFocusEnvironment]);
  XCTAssertNil([object coordinateSpace]);
  XCTAssertTrue(CGRectEqualToRect([object frame], CGRectZero));
  id context = OCMClassMock([UIFocusUpdateContext class]);
  OCMStub([context nextFocusedItem]).andReturn(object);
  [object didUpdateFocusInContext:context
         withAnimationCoordinator:OCMClassMock([UIFocusAnimationCoordinator class])];
}

- (void)testSetChildren {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  parent.children = @[ child ];
  XCTAssertEqual(parent, child.parent);
  parent.children = @[];
  XCTAssertNil(child.parent);
}

- (void)testOldParentDoesNotDetachReparentedChild {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* oldParent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* newParent = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:2];

  oldParent.children = @[ child ];
  oldParent.childrenInHitTestOrder = @[ child ];
  newParent.children = @[ child ];
  newParent.childrenInHitTestOrder = @[ child ];

  oldParent.children = @[];
  oldParent.childrenInHitTestOrder = @[];

  XCTAssertEqual(child.parent, newParent);
}

- (void)testSetChildrenInHitTestOrderDoesNotModifyParent {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* traversalParent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* hitTestParent = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:2];

  traversalParent.children = @[ child ];
  XCTAssertEqual(child.parent, traversalParent);

  hitTestParent.childrenInHitTestOrder = @[ child ];
  XCTAssertEqual(child.parent, traversalParent);

  hitTestParent.childrenInHitTestOrder = @[];
  XCTAssertEqual(child.parent, traversalParent);
}

- (void)testAccessibilityHitTestFocusAtLeaf {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
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
      new flutter::testing::MockAccessibilityBridge());
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
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
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

- (void)testFlutterScrollableSemanticsObjectIsNotAccessibilityElementWhenVoiceOverIsRunning {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags.hasImplicitScrolling = true;

  node.actions = flutter::kHorizontalScrollSemanticsActions |
                 static_cast<int32_t>(flutter::SemanticsAction::kCustomAction);

  node.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  node.scrollExtentMax = 100.0;
  node.scrollPosition = 0.0;

  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  [scrollable setSemanticsNode:&node];
  [scrollable accessibilityBridgeDidFinishUpdate];

  UIScrollView* scrollView = [scrollable nativeAccessibility];

  XCTAssertFalse(scrollView.isAccessibilityElement);
}

- (void)testAccessibilityScrollToVisibleWithChild {
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
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
      new flutter::testing::MockAccessibilityBridge());
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
      new flutter::testing::MockAccessibilityBridge());
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
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitStaticText);
}

- (void)testPlainSemanticsObjectWithHeadingLevelHasHeaderTrait {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.headingLevel = 2;
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertTrue(([object accessibilityTraits] & UIAccessibilityTraitHeader) > 0);
}

- (void)testNodeWithImplicitScrollIsAnAccessibilityElementWhenItisHidden {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;

  node.flags.hasImplicitScrolling = true;
  node.flags.isHidden = true;
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual(object.isAccessibilityElement, YES);
}

- (void)testNodeWithImplicitScrollIsNotAnAccessibilityElementWhenItisNotHidden {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.flags.hasImplicitScrolling = true;
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual(object.isAccessibilityElement, NO);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
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
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags.isTextField = true;
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitNone);
}

- (void)testIntresetingSemanticsObjectWithLabelHasStaticTextTrait2 {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  flutter::SemanticsNode node;
  node.label = "foo";

  node.flags.isButton = true;
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitButton);
}

- (void)testVerticalFlutterScrollableSemanticsObject {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
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
  node.flags.hasImplicitScrolling = true;
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

  XCTAssertEqualWithAccuracy(scrollView.frame.origin.x, x * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.origin.y, y * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.width, w * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.height, h * effectivelyScale,
                             kFloatCompareEpsilon);

  XCTAssertEqualWithAccuracy(scrollView.contentSize.width, w * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.contentSize.height,
                             (h + scrollExtentMax) * effectivelyScale, kFloatCompareEpsilon);

  XCTAssertEqual(scrollView.contentOffset.x, 0);
  XCTAssertEqualWithAccuracy(scrollView.contentOffset.y, scrollPosition * effectivelyScale,
                             kFloatCompareEpsilon);
}

- (void)testVerticalFlutterScrollableSemanticsObjectNoWindowDoesNotCrash {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridgeNoWindow());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  float transformScale = 0.5f;
  float x = 10;
  float y = 10;
  float w = 100;
  float h = 200;
  float scrollExtentMax = 500.0;
  float scrollPosition = 150.0;

  flutter::SemanticsNode node;
  node.flags.hasImplicitScrolling = true;
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
      new flutter::testing::MockAccessibilityBridge());
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
  node.flags.hasImplicitScrolling = true;
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

  XCTAssertEqualWithAccuracy(scrollView.frame.origin.x, x * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.origin.y, y * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.width, w * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.height, h * effectivelyScale,
                             kFloatCompareEpsilon);

  XCTAssertEqualWithAccuracy(scrollView.contentSize.width, (w + scrollExtentMax) * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.contentSize.height, h * effectivelyScale,
                             kFloatCompareEpsilon);

  XCTAssertEqualWithAccuracy(scrollView.contentOffset.x, scrollPosition * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqual(scrollView.contentOffset.y, 0);
}

- (void)testCanHandleInfiniteScrollExtent {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
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
  node.flags.hasImplicitScrolling = true;
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
  XCTAssertEqualWithAccuracy(scrollView.frame.origin.x, x * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.origin.y, y * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.width, w * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.height, h * effectivelyScale,
                             kFloatCompareEpsilon);

  XCTAssertEqualWithAccuracy(scrollView.contentSize.width, w * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.contentSize.height,
                             (h + kScrollExtentMaxForInf + scrollPosition) * effectivelyScale,
                             kFloatCompareEpsilon);

  XCTAssertEqual(scrollView.contentOffset.x, 0);
  XCTAssertEqualWithAccuracy(scrollView.contentOffset.y, scrollPosition * effectivelyScale,
                             kFloatCompareEpsilon);
}

- (void)testCanHandleNaNScrollExtentAndScrollPoisition {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
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
  node.flags.hasImplicitScrolling = true;
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

  XCTAssertEqualWithAccuracy(scrollView.frame.origin.x, x * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.origin.y, y * effectivelyScale, kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.width, w * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.frame.size.height, h * effectivelyScale,
                             kFloatCompareEpsilon);

  // Content size equal to the scrollable size.
  XCTAssertEqualWithAccuracy(scrollView.contentSize.width, w * effectivelyScale,
                             kFloatCompareEpsilon);
  XCTAssertEqualWithAccuracy(scrollView.contentSize.height, h * effectivelyScale,
                             kFloatCompareEpsilon);

  XCTAssertEqual(scrollView.contentOffset.x, 0);
  XCTAssertEqual(scrollView.contentOffset.y, 0);
}

- (void)testFlutterScrollableSemanticsObjectIsNotHittestable {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags.hasImplicitScrolling = true;
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
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = false;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags.hasImplicitScrolling = true;
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

- (void)testFlutterSemanticsObjectHasIdentifier {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.identifier = "identifier";

  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertTrue([object.accessibilityIdentifier isEqualToString:@"identifier"]);
}

- (void)testFlutterSemanticsObjectHasLocale {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.locale = "es-MX";

  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertTrue([object.accessibilityLanguage isEqualToString:@"es-MX"]);
}

- (void)testFlutterSemanticsObjectUseDefaultLocale {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  mock->mockedLocale = @"es-MX";

  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertTrue([object.accessibilityLanguage isEqualToString:@"es-MX"]);
}

- (void)testFlutterSemanticsObjectPrioritizedSectionLocale {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  // Set both locales.
  mock->mockedLocale = @"es-MX";
  node.locale = "zh-TW";

  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  // node.locale takes priority.
  XCTAssertTrue([object.accessibilityLanguage isEqualToString:@"zh-TW"]);
}

- (void)testFlutterSemanticsObjectLocaleNil {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;

  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  XCTAssertTrue(object.accessibilityLanguage == nil);
}

- (void)testFlutterScrollableSemanticsObjectWithLabelValueHintIsNotHiddenWhenVoiceOverIsRunning {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags.hasImplicitScrolling = true;
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
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
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

- (void)testSemanticsObjectContainerAccessibilityFrameCoversEntireScreen {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode parent;
  parent.id = 0;
  parent.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);

  flutter::SemanticsNode child;
  child.id = 1;
  child.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  child.rect = SkRect::MakeXYWH(0, 0, 100, 100);
  parent.childrenInTraversalOrder.push_back(1);

  FlutterSemanticsObject* parentObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                    uid:0];
  [parentObject setSemanticsNode:&parent];

  FlutterSemanticsObject* childObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                   uid:1];
  [childObject setSemanticsNode:&child];

  parentObject.children = @[ childObject ];
  [parentObject accessibilityBridgeDidFinishUpdate];
  [childObject accessibilityBridgeDidFinishUpdate];

  SemanticsObjectContainer* container =
      static_cast<SemanticsObjectContainer*>(parentObject.accessibilityContainer);

  XCTAssertTrue(childObject.accessibilityRespondsToUserInteraction);
  XCTAssertTrue(CGRectEqualToRect(container.accessibilityFrame, UIScreen.mainScreen.bounds));
}

- (void)testSemanticsObjectContainerAccessibilityFrameUsesScreenOfBridgeViewWindow {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode parent;
  parent.id = 0;

  flutter::SemanticsNode child;
  child.id = 1;
  child.rect = SkRect::MakeXYWH(0, 0, 100, 100);
  parent.childrenInTraversalOrder.push_back(1);

  FlutterSemanticsObject* parentObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                    uid:0];
  [parentObject setSemanticsNode:&parent];
  FlutterSemanticsObject* childObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                   uid:1];
  [childObject setSemanticsNode:&child];
  parentObject.children = @[ childObject ];

  // Put the bridge view's window on a screen that is not `UIScreen.mainScreen` (e.g. the inner
  // display of a device with multiple built-in displays).
  CGRect screenBounds = CGRectMake(0, 0, 951, 669);
  UIScreen* mockScreen = OCMClassMock([UIScreen class]);
  OCMStub([mockScreen bounds]).andDo(^(NSInvocation* invocation) {
    CGRect bounds = screenBounds;
    [invocation setReturnValue:&bounds];
  });
  UIWindowScene* mockWindowScene = OCMClassMock([UIWindowScene class]);
  OCMStub([mockWindowScene screen]).andReturn(mockScreen);
  UIWindow* mockWindow = OCMPartialMock(mock->view().window);
  OCMStub([mockWindow windowScene]).andReturn(mockWindowScene);

  SemanticsObjectContainer* container =
      static_cast<SemanticsObjectContainer*>(parentObject.accessibilityContainer);
  XCTAssertTrue(CGRectEqualToRect(container.accessibilityFrame, screenBounds));

  [(id)mockWindow stopMocking];
}

- (void)testRootSemanticsObjectContainerAccessibilityContainerIsBridgeView {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode root;
  root.id = kRootNodeId;

  FlutterSemanticsObject* rootObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                  uid:kRootNodeId];
  [rootObject setSemanticsNode:&root];

  SemanticsObjectContainer* container =
      static_cast<SemanticsObjectContainer*>(rootObject.accessibilityContainer);

  XCTAssertEqual(container.accessibilityContainer, mock->view());
}

- (void)testBridgeViewIsNilWhileBridgeIsAliveAndViewIsNotLoaded {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isViewLoaded = false;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode root;
  root.id = kRootNodeId;
  root.rect = SkRect::MakeXYWH(0, 0, 100, 100);

  FlutterSemanticsObject* rootObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                  uid:kRootNodeId];
  [rootObject setSemanticsNode:&root];

  XCTAssertNotNil(mock->view());
  XCTAssertTrue(rootObject.bridge != nullptr);
  XCTAssertNil(rootObject.bridgeView);
  XCTAssertTrue(CGRectEqualToRect(rootObject.accessibilityFrame, CGRectZero));

  SemanticsObjectContainer* container =
      static_cast<SemanticsObjectContainer*>(rootObject.accessibilityContainer);
  XCTAssertNotNil(container);
  XCTAssertNil(container.accessibilityContainer);
}

- (void)testChildSemanticsObjectContainerAccessibilityContainerIsParentContainer {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode root;
  root.id = kRootNodeId;
  root.childrenInTraversalOrder.push_back(1);

  flutter::SemanticsNode child;
  child.id = 1;
  child.childrenInTraversalOrder.push_back(2);

  flutter::SemanticsNode grandchild;
  grandchild.id = 2;

  FlutterSemanticsObject* rootObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                  uid:kRootNodeId];
  [rootObject setSemanticsNode:&root];

  FlutterSemanticsObject* childObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                   uid:1];
  [childObject setSemanticsNode:&child];

  FlutterSemanticsObject* grandchildObject = [[FlutterSemanticsObject alloc] initWithBridge:bridge
                                                                                        uid:2];
  [grandchildObject setSemanticsNode:&grandchild];

  rootObject.children = @[ childObject ];
  childObject.children = @[ grandchildObject ];

  SemanticsObjectContainer* rootContainer =
      static_cast<SemanticsObjectContainer*>(rootObject.accessibilityContainer);
  SemanticsObjectContainer* childContainer =
      static_cast<SemanticsObjectContainer*>(childObject.accessibilityContainer);

  XCTAssertEqual(childContainer.accessibilityContainer, rootContainer);
}

- (void)testFlutterSemanticsObjectAttributedStringsDoNotCrashWhenEmpty {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
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
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
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
  node.flags.hasImplicitScrolling = true;
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

- (void)testFlutterScrollableSemanticsObjectNoScrollBarOrContentInsets {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags.hasImplicitScrolling = true;
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
  XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior,
                 UIScrollViewContentInsetAdjustmentNever);
  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(scrollView.contentInset, UIEdgeInsetsZero));
}

- (void)testSemanticsObjectBuildsAttributedString {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
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
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];

  // Handle nil with no node set.
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:nil]);

  // Handle initial setting of node with liveRegion
  flutter::SemanticsNode node;
  node.flags.isLiveRegion = true;
  node.label = "foo";
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&node]);

  // Handle nil with node set.
  [object setSemanticsNode:&node];
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:nil]);

  // Handle new node, still has live region, same label.
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:&node]);

  // Handle update node with new label, still has live region.
  flutter::SemanticsNode updatedNode;
  updatedNode.flags.isLiveRegion = true;
  updatedNode.label = "bar";
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&updatedNode]);

  // Handle dropping the live region flag.
  updatedNode.flags = flutter::SemanticsFlags{};
  XCTAssertFalse([object nodeShouldTriggerAnnouncement:&updatedNode]);

  // Handle adding the flag when the label has not changed.
  updatedNode.label = "foo";
  [object setSemanticsNode:&updatedNode];
  XCTAssertTrue([object nodeShouldTriggerAnnouncement:&node]);
}

- (void)testShouldDispatchShowOnScreenActionForHeader {
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags.isHeader = true;
  node.label = "foo";

  [object setSemanticsNode:&node];

  // Simulate accessibility focus.
  [object accessibilityElementDidBecomeFocused];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 1);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testShouldDispatchShowOnScreenActionForHidden {
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:1];

  // Handle initial setting of node with hidden.
  flutter::SemanticsNode node;
  node.flags.isHidden = true;
  node.label = "foo";

  [object setSemanticsNode:&node];

  // Simulate accessibility focus.
  [object accessibilityElementDidBecomeFocused];

  XCTAssertTrue(bridge->observations.size() == 1);
  XCTAssertTrue(bridge->observations[0].id == 1);
  XCTAssertTrue(bridge->observations[0].action == flutter::SemanticsAction::kShowOnScreen);
}

- (void)testFlutterSwitchSemanticsObjectMatchesUISwitch {
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterSwitchSemanticsObject* object = [[FlutterSwitchSemanticsObject alloc] initWithBridge:bridge
                                                                                          uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags.isToggled = flutter::SemanticsTristate::kTrue;
  node.flags.isEnabled = flutter::SemanticsTristate::kTrue;
  node.label = "foo";
  [object setSemanticsNode:&node];
  // Create ab real UISwitch to compare the FlutterSwitchSemanticsObject with.
  UISwitch* nativeSwitch = [[UISwitch alloc] init];
  nativeSwitch.on = YES;

  XCTAssertEqual(object.accessibilityTraits, nativeSwitch.accessibilityTraits);
  XCTAssertEqualObjects(object.accessibilityValue, nativeSwitch.accessibilityValue);

  // Set the toggled to false;
  flutter::SemanticsNode update;
  update.flags.isToggled = flutter::SemanticsTristate::kFalse;
  update.flags.isEnabled = flutter::SemanticsTristate::kTrue;

  update.label = "foo";
  [object setSemanticsNode:&update];

  nativeSwitch.on = NO;

  XCTAssertEqual(object.accessibilityTraits, nativeSwitch.accessibilityTraits);
  XCTAssertEqualObjects(object.accessibilityValue, nativeSwitch.accessibilityValue);
}

- (void)testFlutterSemanticsObjectOfRadioButton {
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags.isInMutuallyExclusiveGroup = true;
  node.flags.isChecked = flutter::SemanticsCheckState::kFalse;
  node.flags.isEnabled = flutter::SemanticsTristate::kTrue;
  node.label = "foo";
  [object setSemanticsNode:&node];
  XCTAssertTrue((object.accessibilityTraits & UIAccessibilityTraitButton) > 0);
  XCTAssertNil(object.accessibilityValue);
}

- (void)testFlutterSwitchSemanticsObjectMatchesUISwitchDisabled {
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterSwitchSemanticsObject* object = [[FlutterSwitchSemanticsObject alloc] initWithBridge:bridge
                                                                                          uid:1];

  // Handle initial setting of node with header.
  flutter::SemanticsNode node;
  node.flags.isToggled = flutter::SemanticsTristate::kTrue;
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
      new flutter::testing::MockAccessibilityBridge());
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
  node.flags.hasImplicitScrolling = true;
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
    flutter::testing::MockAccessibilityBridge* mock =
        new flutter::testing::MockAccessibilityBridge();
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

- (void)testAccessibilityHitTestSearchCanReturnPlatformView {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object0 = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* object1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* object3 = [[SemanticsObject alloc] initWithBridge:bridge uid:3];
  FlutterTouchInterceptingView* platformView =
      [[FlutterTouchInterceptingView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  FlutterPlatformViewSemanticsContainer* platformViewSemanticsContainer =
      [[FlutterPlatformViewSemanticsContainer alloc] initWithBridge:bridge
                                                                uid:1
                                                       platformView:platformView];

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
  fml::WeakPtrFactory<flutter::testing::MockAccessibilityBridge> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  __weak FlutterTouchInterceptingView* weakPlatformView;
  __weak FlutterPlatformViewSemanticsContainer* weakContainer;
  @autoreleasepool {
    FlutterTouchInterceptingView* platformView = [[FlutterTouchInterceptingView alloc] init];
    weakPlatformView = platformView;

    @autoreleasepool {
      FlutterPlatformViewSemanticsContainer* container =
          [[FlutterPlatformViewSemanticsContainer alloc] initWithBridge:bridge
                                                                    uid:1
                                                           platformView:platformView];
      weakContainer = container;
      XCTAssertEqualObjects(platformView.accessibilityContainer, container);
      XCTAssertNotNil(weakPlatformView);
      XCTAssertNotNil(weakContainer);
    }
    // Check the variables are still lived.
    // `container` is `retain` in `platformView`, so it will not be nil here.
    XCTAssertNotNil(weakPlatformView);
    XCTAssertNotNil(weakContainer);
  }
  // Check if there's no more strong references to `platformView` after container and platformView
  // are released.
  XCTAssertNil(weakPlatformView);
  XCTAssertNil(weakContainer);
}

- (void)testTextInputSemanticsObject {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags.isTextField = true;
  node.flags.isReadOnly = true;
  TextInputSemanticsObject* object = [[TextInputSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  [object accessibilityBridgeDidFinishUpdate];
  XCTAssertEqual([object accessibilityTraits], UIAccessibilityTraitNone);
}

- (void)testTextInputSemanticsObject_isSecureTextEntry {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags.isTextField = true;
  node.flags.isObscured = true;

  TextInputSemanticsObject* object = [[TextInputSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  [object accessibilityBridgeDidFinishUpdate];

  XCTAssertTrue([object isSecureTextEntry]);

  node.flags.isObscured = false;
  [object setSemanticsNode:&node];
  [object accessibilityBridgeDidFinishUpdate];

  XCTAssertFalse([object isSecureTextEntry]);
}

- (void)testTextInputSemanticsObject_canPerformAction {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.label = "foo";
  node.flags.isTextField = true;
  node.flags.isReadOnly = true;
  TextInputSemanticsObject* object = [[TextInputSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  [object accessibilityBridgeDidFinishUpdate];

  id textInputSurrogate = OCMClassMock([UIResponder class]);
  id partialSemanticsObject = OCMPartialMock(object);
  OCMStub([partialSemanticsObject textInputSurrogate]).andReturn(textInputSurrogate);

  OCMExpect([textInputSurrogate canPerformAction:[OCMArg anySelector] withSender:OCMOCK_ANY])
      .andReturn(YES);
  XCTAssertTrue([partialSemanticsObject canPerformAction:@selector(copy:) withSender:nil]);

  OCMExpect([textInputSurrogate canPerformAction:[OCMArg anySelector] withSender:OCMOCK_ANY])
      .andReturn(NO);
  XCTAssertFalse([partialSemanticsObject canPerformAction:@selector(copy:) withSender:nil]);
}

- (void)testTextInputSemanticsObject_editActions {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.label = "foo";

  node.flags.isTextField = true;
  node.flags.isReadOnly = true;
  TextInputSemanticsObject* object = [[TextInputSemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  [object accessibilityBridgeDidFinishUpdate];

  id textInputSurrogate = OCMClassMock([UIResponder class]);
  id partialSemanticsObject = OCMPartialMock(object);
  OCMStub([partialSemanticsObject textInputSurrogate]).andReturn(textInputSurrogate);

  XCTestExpectation* copyExpectation =
      [self expectationWithDescription:@"Surrogate's copy method is called."];
  XCTestExpectation* cutExpectation =
      [self expectationWithDescription:@"Surrogate's cut method is called."];
  XCTestExpectation* pasteExpectation =
      [self expectationWithDescription:@"Surrogate's paste method is called."];
  XCTestExpectation* selectAllExpectation =
      [self expectationWithDescription:@"Surrogate's selectAll method is called."];
  XCTestExpectation* deleteExpectation =
      [self expectationWithDescription:@"Surrogate's delete method is called."];

  OCMStub([textInputSurrogate copy:OCMOCK_ANY]).andDo(^(NSInvocation* invocation) {
    [copyExpectation fulfill];
  });
  OCMStub([textInputSurrogate cut:OCMOCK_ANY]).andDo(^(NSInvocation* invocation) {
    [cutExpectation fulfill];
  });
  OCMStub([textInputSurrogate paste:OCMOCK_ANY]).andDo(^(NSInvocation* invocation) {
    [pasteExpectation fulfill];
  });
  OCMStub([textInputSurrogate selectAll:OCMOCK_ANY]).andDo(^(NSInvocation* invocation) {
    [selectAllExpectation fulfill];
  });
  OCMStub([textInputSurrogate delete:OCMOCK_ANY]).andDo(^(NSInvocation* invocation) {
    [deleteExpectation fulfill];
  });

  [partialSemanticsObject copy:nil];
  [partialSemanticsObject cut:nil];
  [partialSemanticsObject paste:nil];
  [partialSemanticsObject selectAll:nil];
  [partialSemanticsObject delete:nil];

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSliderSemanticsObject {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();

  flutter::SemanticsNode node;
  node.flags.isSlider = true;
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  [object setSemanticsNode:&node];
  [object accessibilityBridgeDidFinishUpdate];
  XCTAssertEqual([object accessibilityActivate], YES);
}

- (void)testUIFocusItemConformance {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  parent.children = @[ child ];

  // parentFocusEnvironment
  XCTAssertTrue([parent.parentFocusEnvironment isKindOfClass:[UIView class]]);
  XCTAssertEqual(child.parentFocusEnvironment, child.parent);

  // canBecomeFocused
  flutter::SemanticsNode childNode;
  childNode.flags.isHidden = true;
  childNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [child setSemanticsNode:&childNode];
  XCTAssertFalse(child.canBecomeFocused);
  childNode.flags = flutter::SemanticsFlags{};
  [child setSemanticsNode:&childNode];
  XCTAssertTrue(child.canBecomeFocused);
  childNode.actions = 0;
  [child setSemanticsNode:&childNode];
  XCTAssertFalse(child.canBecomeFocused);

  CGFloat scale = ((bridge->view().window.screen ?: UIScreen.mainScreen)).scale;

  childNode.rect = SkRect::MakeXYWH(0, 0, 100 * scale, 100 * scale);
  [child setSemanticsNode:&childNode];
  flutter::SemanticsNode parentNode;
  parentNode.rect = SkRect::MakeXYWH(0, 0, 200, 200);
  [parent setSemanticsNode:&parentNode];

  XCTAssertTrue(CGRectEqualToRect(child.frame, CGRectMake(0, 0, 100, 100)));
}

- (void)testHiddenChildOfImplicitlyScrollingContainerCanBecomeFocused {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* container = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  scrollable.children = @[ container ];
  container.children = @[ child ];

  flutter::SemanticsNode scrollableNode;
  scrollableNode.flags.hasImplicitScrolling = true;
  scrollableNode.scrollPosition = 0;
  [scrollable setSemanticsNode:&scrollableNode];

  // An offscreen item, nested below the scrollable, that can be tapped.
  flutter::SemanticsNode childNode;
  childNode.flags.isHidden = true;
  childNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [child setSemanticsNode:&childNode];
  XCTAssertTrue(child.canBecomeFocused);

  // An offscreen item with no tap or focus action is not focusable.
  childNode.actions = 0;
  [child setSemanticsNode:&childNode];
  XCTAssertFalse(child.canBecomeFocused);
}

- (void)testHiddenChildOutsideScrollContainerCannotBecomeFocused {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  parent.children = @[ child ];

  flutter::SemanticsNode childNode;
  childNode.flags.isHidden = true;
  childNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [child setSemanticsNode:&childNode];
  XCTAssertFalse(child.canBecomeFocused);

  childNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kFocus);
  [child setSemanticsNode:&childNode];
  XCTAssertFalse(child.canBecomeFocused);
}

- (void)testHiddenChildOfNonImplicitlyScrollingContainerCannotBecomeFocused {
  // Models a PageView (which disallows implicit scrolling) nested in a
  // ListView (which allows it). Offscreen pages must not be focusable.
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  FlutterScrollableSemanticsObject* outer =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* inner = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  outer.children = @[ inner ];
  inner.children = @[ child ];

  flutter::SemanticsNode outerNode;
  outerNode.flags.hasImplicitScrolling = true;
  outerNode.scrollPosition = 0;
  [outer setSemanticsNode:&outerNode];

  flutter::SemanticsNode innerNode;
  innerNode.scrollPosition = 0;
  [inner setSemanticsNode:&innerNode];

  flutter::SemanticsNode childNode;
  childNode.flags.isHidden = true;
  childNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [child setSemanticsNode:&childNode];
  XCTAssertFalse(child.canBecomeFocused);
}

- (void)testNodeWithOnlyFocusActionCanBecomeFocused {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];

  flutter::SemanticsNode node;
  node.actions = static_cast<int32_t>(flutter::SemanticsAction::kFocus);
  [object setSemanticsNode:&node];
  XCTAssertTrue(object.canBecomeFocused);
}

- (void)testDidUpdateFocusDispatchesFocusActionsToNextFocusedItem {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  scrollable.children = @[ child ];

  flutter::SemanticsNode scrollableNode;
  scrollableNode.flags.hasImplicitScrolling = true;
  scrollableNode.scrollPosition = 0;
  [scrollable setSemanticsNode:&scrollableNode];

  flutter::SemanticsNode childNode;
  childNode.flags.isHidden = true;
  childNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap) |
                      static_cast<int32_t>(flutter::SemanticsAction::kFocus) |
                      static_cast<int32_t>(flutter::SemanticsAction::kDidGainAccessibilityFocus);
  [child setSemanticsNode:&childNode];

  id context = OCMClassMock([UIFocusUpdateContext class]);
  OCMStub([context nextFocusedItem]).andReturn(child);
  OCMStub([context previouslyFocusedItem]).andReturn(nil);
  id coordinator = OCMClassMock([UIFocusAnimationCoordinator class]);

  // The scrollable is in the focus chain but is not the focused item.
  [scrollable didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
  XCTAssertEqual(mock->observations.size(), (size_t)0);

  // The framework scrolls the focused item into view.
  [child didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
  XCTAssertEqual(mock->observations.size(), (size_t)3);
  XCTAssertEqual(mock->observations[0].id, 1);
  XCTAssertEqual(mock->observations[0].action, flutter::SemanticsAction::kShowOnScreen);
  XCTAssertEqual(mock->observations[1].id, 1);
  XCTAssertEqual(mock->observations[1].action, flutter::SemanticsAction::kFocus);
  XCTAssertEqual(mock->observations[2].id, 1);
  XCTAssertEqual(mock->observations[2].action,
                 flutter::SemanticsAction::kDidGainAccessibilityFocus);
}

// Builds root(0) -> scrollable(1) -> buttons 2, 3, 4, where button 4 is
// scrolled offscreen. Used by the Tab navigation tests.
static SemanticsObject* BuildTabNavigationTree(fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge,
                                               NSArray<SemanticsObject*>** buttons) {
  SemanticsObject* root = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:1];
  root.children = @[ scrollable ];

  flutter::SemanticsNode scrollableNode;
  scrollableNode.id = 1;
  scrollableNode.flags.hasImplicitScrolling = true;
  scrollableNode.scrollPosition = 0;
  [scrollable setSemanticsNode:&scrollableNode];

  NSMutableArray<SemanticsObject*>* result = [NSMutableArray array];
  for (int32_t uid = 2; uid <= 4; uid++) {
    SemanticsObject* button = [[SemanticsObject alloc] initWithBridge:bridge uid:uid];
    flutter::SemanticsNode node;
    node.id = uid;
    node.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
    node.flags.isHidden = uid == 4;
    [button setSemanticsNode:&node];
    [result addObject:button];
  }
  scrollable.children = result;
  *buttons = result;
  return root;
}

static id MockFocusContext(id previous, id next, UIFocusHeading heading) {
  id context = OCMClassMock([UIFocusUpdateContext class]);
  OCMStub([context previouslyFocusedItem]).andReturn(previous);
  OCMStub([context nextFocusedItem]).andReturn(next);
  OCMStub([context focusHeading]).andReturn(heading);
  return context;
}

- (void)testTabAllowsFocusUpdateThatMatchesTraversalOrder {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  id context = MockFocusContext(buttons[0], buttons[1], UIFocusHeadingNext);
  XCTAssertTrue([buttons[0] shouldUpdateFocusInContext:context]);
  XCTAssertEqual(mock->observations.size(), (size_t)0);
  XCTAssertNil(root.preferredFocusEnvironments);
}

- (void)testTabRedirectsEarlyWrapToOffscreenItem {
  // The focus engine wraps around from the last visible item (button 3)
  // because the next item (button 4) is offscreen.
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  id context = MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst);
  XCTAssertFalse([buttons[1] shouldUpdateFocusInContext:context]);
  XCTAssertEqual(mock->observations.size(), (size_t)1);
  XCTAssertEqual(mock->observations[0].id, 4);
  XCTAssertEqual(mock->observations[0].action, flutter::SemanticsAction::kShowOnScreen);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[2] ]);
  // Only the root redirects.
  XCTAssertNil(buttons[0].preferredFocusEnvironments);

  // Once the target receives focus, the redirect is cleared.
  id gained = MockFocusContext(buttons[1], buttons[2], UIFocusHeadingNone);
  [buttons[2] didUpdateFocusInContext:gained
             withAnimationCoordinator:OCMClassMock([UIFocusAnimationCoordinator class])];
  XCTAssertNil(root.preferredFocusEnvironments);
}

- (void)testTabContinuesFromPendingTargetAndWrapsAtTheEnd {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  // First Tab from button 3 targets button 4, which is still offscreen.
  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[2] ]);

  // A second Tab before focus moves continues from button 4, the last item,
  // and wraps around to button 2, even though the focus engine proposes it.
  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingNext)]);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[0] ]);
}

- (void)testShiftTabWrapsToLastItem {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  // The focus engine wraps to the last visible item (button 3), but the last
  // item in traversal order is the offscreen button 4.
  id context = MockFocusContext(buttons[0], buttons[1], UIFocusHeadingLast);
  XCTAssertFalse([buttons[0] shouldUpdateFocusInContext:context]);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[2] ]);
}

- (void)testTabFollowsTraversalOrderWhenFocusEngineOrderDiffers {
  // The focus engine picks items geometrically, and its picks are unreliable
  // while the framework is scrolling, so the traversal order wins.
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  XCTAssertFalse([buttons[0]
      shouldUpdateFocusInContext:MockFocusContext(buttons[0], buttons[2], UIFocusHeadingNext)]);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[1] ]);
}

- (void)testTabRedirectsToOffscreenItemWhenFocusEngineFindsNoCandidate {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], nil, UIFocusHeadingNext)]);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[2] ]);
}

- (void)testTabAllowsFocusToLeaveTheFlutterView {
  // For example, to a native view in an add-to-app screen.
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);
  UIView* nativeView = [[UIView alloc] init];

  XCTAssertTrue([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], nativeView, UIFocusHeadingFirst)]);
  XCTAssertEqual(mock->observations.size(), (size_t)0);
  XCTAssertNil(root.preferredFocusEnvironments);
}

- (void)testPendingTabTargetIsClearedWhenFocusMovesElsewhere {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[2] ]);

  // The user clicks button 2 before the redirect completes.
  id clicked = MockFocusContext(buttons[1], buttons[0], UIFocusHeadingNone);
  [buttons[1] didUpdateFocusInContext:clicked
             withAnimationCoordinator:OCMClassMock([UIFocusAnimationCoordinator class])];
  XCTAssertNil(root.preferredFocusEnvironments);
}

- (void)testPendingTabTargetIsClearedWhenRemovedFromTree {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);
  buttons[2].parent.children = @[ buttons[0], buttons[1] ];
  XCTAssertNil(root.preferredFocusEnvironments);
}

- (void)testSemanticsUpdateRequestsFocusOnceTabTargetIsVisible {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);
  id focusSystem = OCMClassMock([UIFocusSystem class]);
  OCMStub(ClassMethod([focusSystem focusSystemForEnvironment:root])).andReturn(focusSystem);
  __block int requests = 0;
  OCMStub([focusSystem requestFocusUpdateToEnvironment:root]).andDo(^(NSInvocation* invocation) {
    requests++;
  });

  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);

  // The framework has not scrolled yet.
  [root focusSystemDidFinishSemanticsUpdate];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
  XCTAssertEqual(requests, 0);

  // The framework scrolled button 4 into view.
  flutter::SemanticsNode node;
  node.id = 4;
  node.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [buttons[2] setSemanticsNode:&node];
  [root focusSystemDidFinishSemanticsUpdate];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
  XCTAssertEqual(requests, 1);
  OCMVerify([focusSystem updateFocusIfNeeded]);
  XCTAssertNil(root.preferredFocusEnvironments);
  [focusSystem stopMocking];
}

- (void)testTabSkipsFocusableScrollableNode {
  // A scrollable is represented by its scroll view in the focus system, which
  // cannot be focused, so it must not become a Tab target.
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);
  SemanticsObject* scrollable = buttons[0].parent;
  flutter::SemanticsNode scrollableNode;
  scrollableNode.id = 1;
  scrollableNode.flags.hasImplicitScrolling = true;
  scrollableNode.scrollPosition = 0;
  scrollableNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [scrollable setSemanticsNode:&scrollableNode];

  // Shift+Tab from button 2 wraps to button 4, not to the scrollable.
  XCTAssertFalse([buttons[0]
      shouldUpdateFocusInContext:MockFocusContext(buttons[0], buttons[1], UIFocusHeadingLast)]);
  XCTAssertEqualObjects(root.preferredFocusEnvironments, @[ buttons[2] ]);
}

- (void)testTabRequestsFocusAfterTimeoutWithoutSemanticsUpdate {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);
  id focusSystem = OCMClassMock([UIFocusSystem class]);
  OCMStub(ClassMethod([focusSystem focusSystemForEnvironment:root])).andReturn(focusSystem);
  __block int requests = 0;
  OCMStub([focusSystem requestFocusUpdateToEnvironment:root]).andDo(^(NSInvocation* invocation) {
    requests++;
  });

  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  XCTAssertEqual(requests, 0);
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];
  XCTAssertEqual(requests, 1);
  XCTAssertNil(root.preferredFocusEnvironments);
  [focusSystem stopMocking];
}

- (void)testTabRequestsFocusAfterMaxSemanticsUpdates {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);
  id focusSystem = OCMClassMock([UIFocusSystem class]);
  OCMStub(ClassMethod([focusSystem focusSystemForEnvironment:root])).andReturn(focusSystem);
  __block int requests = 0;
  OCMStub([focusSystem requestFocusUpdateToEnvironment:root]).andDo(^(NSInvocation* invocation) {
    requests++;
  });

  XCTAssertFalse([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);
  // Button 4 stays hidden, e.g. clipped by something other than the list.
  for (int i = 0; i < 3; i++) {
    [root focusSystemDidFinishSemanticsUpdate];
  }
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
  XCTAssertEqual(requests, 1);
  [focusSystem stopMocking];
}

- (void)testTabRequestsFocusImmediatelyForVisibleTarget {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);
  id focusSystem = OCMClassMock([UIFocusSystem class]);
  OCMStub(ClassMethod([focusSystem focusSystemForEnvironment:root])).andReturn(focusSystem);
  __block int requests = 0;
  OCMStub([focusSystem requestFocusUpdateToEnvironment:root]).andDo(^(NSInvocation* invocation) {
    requests++;
  });

  // The focus engine proposes button 4, but button 3 is next.
  XCTAssertFalse([buttons[0]
      shouldUpdateFocusInContext:MockFocusContext(buttons[0], buttons[2], UIFocusHeadingNext)]);
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
  XCTAssertEqual(requests, 1);
  [focusSystem stopMocking];
}

- (void)testShouldUpdateFocusIgnoresNonTabHeadings {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  XCTAssertTrue([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingDown)]);
  XCTAssertTrue([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingNone)]);
  // Only the item losing focus decides.
  XCTAssertTrue([buttons[0]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);
  XCTAssertEqual(mock->observations.size(), (size_t)0);
  XCTAssertNil(root.preferredFocusEnvironments);
}

- (void)testShouldUpdateFocusDoesNothingWhenVoiceOverIsRunning {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  NSArray<SemanticsObject*>* buttons;
  SemanticsObject* root = BuildTabNavigationTree(factory.GetWeakPtr(), &buttons);

  XCTAssertTrue([buttons[1]
      shouldUpdateFocusInContext:MockFocusContext(buttons[1], buttons[0], UIFocusHeadingFirst)]);
  XCTAssertEqual(mock->observations.size(), (size_t)0);
  XCTAssertNil(root.preferredFocusEnvironments);
}

- (void)testDidUpdateFocusDispatchesDidLoseFocusToPreviouslyFocusedItem {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:3];

  flutter::SemanticsNode node;
  node.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap) |
                 static_cast<int32_t>(flutter::SemanticsAction::kDidLoseAccessibilityFocus);
  [object setSemanticsNode:&node];

  id context = OCMClassMock([UIFocusUpdateContext class]);
  OCMStub([context nextFocusedItem]).andReturn(nil);
  OCMStub([context previouslyFocusedItem]).andReturn(object);

  [object didUpdateFocusInContext:context
         withAnimationCoordinator:OCMClassMock([UIFocusAnimationCoordinator class])];
  XCTAssertEqual(mock->observations.size(), (size_t)1);
  XCTAssertEqual(mock->observations[0].id, 3);
  XCTAssertEqual(mock->observations[0].action,
                 flutter::SemanticsAction::kDidLoseAccessibilityFocus);
}

- (void)testDidUpdateFocusWithoutFocusActionsDispatchesNothing {
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];

  flutter::SemanticsNode node;
  node.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [object setSemanticsNode:&node];

  id context = OCMClassMock([UIFocusUpdateContext class]);
  OCMStub([context nextFocusedItem]).andReturn(object);
  OCMStub([context previouslyFocusedItem]).andReturn(nil);

  [object didUpdateFocusInContext:context
         withAnimationCoordinator:OCMClassMock([UIFocusAnimationCoordinator class])];
  XCTAssertEqual(mock->observations.size(), (size_t)0);
}

- (void)testDidUpdateFocusDispatchesNothingWhenVoiceOverIsRunning {
  // VoiceOver's own focus callbacks already dispatch these actions.
  flutter::testing::MockAccessibilityBridge* mock = new flutter::testing::MockAccessibilityBridge();
  mock->isVoiceOverRunningValue = true;
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(mock);
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* object = [[SemanticsObject alloc] initWithBridge:bridge uid:0];

  flutter::SemanticsNode node;
  node.actions = static_cast<int32_t>(flutter::SemanticsAction::kFocus) |
                 static_cast<int32_t>(flutter::SemanticsAction::kDidGainAccessibilityFocus) |
                 static_cast<int32_t>(flutter::SemanticsAction::kDidLoseAccessibilityFocus);
  [object setSemanticsNode:&node];

  id gainContext = OCMClassMock([UIFocusUpdateContext class]);
  OCMStub([gainContext nextFocusedItem]).andReturn(object);
  [object didUpdateFocusInContext:gainContext
         withAnimationCoordinator:OCMClassMock([UIFocusAnimationCoordinator class])];

  id loseContext = OCMClassMock([UIFocusUpdateContext class]);
  OCMStub([loseContext previouslyFocusedItem]).andReturn(object);
  [object didUpdateFocusInContext:loseContext
         withAnimationCoordinator:OCMClassMock([UIFocusAnimationCoordinator class])];

  XCTAssertEqual(mock->observations.size(), (size_t)0);
}

- (void)testUIFocusItemContainerConformance {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  SemanticsObject* parent = [[SemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child1 = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  SemanticsObject* child2 = [[SemanticsObject alloc] initWithBridge:bridge uid:2];
  parent.childrenInHitTestOrder = @[ child1, child2 ];

  // focusItemsInRect
  NSArray<id<UIFocusItem>>* itemsInRect = [parent focusItemsInRect:CGRectMake(0, 0, 100, 100)];
  XCTAssertEqual(itemsInRect.count, (unsigned long)2);
  XCTAssertTrue([itemsInRect containsObject:child1]);
  XCTAssertTrue([itemsInRect containsObject:child2]);
}

- (void)testFocusEngineScrollingIsCancelled {
  // The framework scrolls focused items into view, so the focus engine's own
  // scrolling of the mirror UIScrollView is cancelled and not forwarded.
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::testing::MockAccessibilityBridge> bridge = factory.GetWeakPtr();
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:5];
  scrollable.scrollView.contentOffset = CGPointMake(0, 100);
  bridge->observations.clear();

  CGPoint target = CGPointMake(0, 456);
  [scrollable.scrollView scrollViewWillEndDragging:scrollable.scrollView
                                      withVelocity:CGPointZero
                               targetContentOffset:&target];
  XCTAssertTrue(CGPointEqualToPoint(target, CGPointMake(0, 100)));

  scrollable.scrollView.contentOffset = CGPointMake(0, 200);
  XCTAssertEqual(bridge->observations.size(), (size_t)0);
}

- (void)testFocusItemFrameIgnoresUnforwardedScrollViewOffset {
  // Item frames follow the framework, which positions the items, even if
  // UIKit moves the mirror UIScrollView before the next semantics update.
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  FlutterScrollableSemanticsObject* scrollable =
      [[FlutterScrollableSemanticsObject alloc] initWithBridge:bridge uid:0];
  SemanticsObject* child = [[SemanticsObject alloc] initWithBridge:bridge uid:1];
  scrollable.children = @[ child ];

  flutter::SemanticsNode scrollableNode;
  scrollableNode.flags.hasImplicitScrolling = true;
  scrollableNode.actions = flutter::kVerticalScrollSemanticsActions;
  scrollableNode.rect = SkRect::MakeXYWH(0, 0, 100, 200);
  scrollableNode.scrollExtentMax = 1000;
  scrollableNode.scrollPosition = 300;
  [scrollable setSemanticsNode:&scrollableNode];
  [scrollable accessibilityBridgeDidFinishUpdate];

  flutter::SemanticsNode childNode;
  childNode.flags.isHidden = true;
  childNode.actions = static_cast<int32_t>(flutter::SemanticsAction::kTap);
  childNode.rect = SkRect::MakeXYWH(0, 500, 100, 50);
  [child setSemanticsNode:&childNode];

  // After a framework update, the frame is in content coordinates.
  const CGFloat frameworkOffsetY = scrollable.scrollView.contentOffset.y;
  XCTAssertEqualWithAccuracy(child.frame.origin.y, 500 + frameworkOffsetY, kFloatCompareEpsilon);
  const CGRect frameBefore = child.frame;

  // The focus engine scrolls the scroll view, without a framework update.
  scrollable.scrollView.contentOffset = CGPointMake(0, frameworkOffsetY + 200);
  XCTAssertTrue(CGRectEqualToRect(child.frame, frameBefore));
}

- (void)testAccessibilityRespondsToUserInteraction {
  fml::WeakPtrFactory<flutter::AccessibilityBridgeIos> factory(
      new flutter::testing::MockAccessibilityBridge());
  fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge = factory.GetWeakPtr();
  FlutterSemanticsObject* object = [[FlutterSemanticsObject alloc] initWithBridge:bridge uid:0];

  flutter::SemanticsNode node;
  node.id = 0;
  node.actions = flutter::kSystemActions | flutter::kScrollableSemanticsActions |
                 static_cast<int32_t>(flutter::SemanticsAction::kDismiss);
  [object setSemanticsNode:&node];
  XCTAssertFalse(object.accessibilityRespondsToUserInteraction);

  node.actions |= static_cast<int32_t>(flutter::SemanticsAction::kTap);
  [object setSemanticsNode:&node];
  XCTAssertTrue(object.accessibilityRespondsToUserInteraction);
}
@end
