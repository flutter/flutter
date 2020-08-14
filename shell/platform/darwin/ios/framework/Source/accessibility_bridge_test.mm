// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#import "third_party/ocmock/Source/OCMock/OCMock.h"

FLUTTER_ASSERT_NOT_ARC
@class MockPlatformView;
static MockPlatformView* gMockPlatformView = nil;

@interface MockPlatformView : UIView
@end
@implementation MockPlatformView

- (instancetype)init {
  self = [super init];
  if (self) {
    gMockPlatformView = self;
  }
  return self;
}

- (void)dealloc {
  gMockPlatformView = nil;
  [super dealloc];
}

@end

@interface MockFlutterPlatformView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView* view;
@end

@implementation MockFlutterPlatformView

- (instancetype)init {
  if (self = [super init]) {
    _view = [[MockPlatformView alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_view release];
  _view = nil;
  [super dealloc];
}

@end

@interface MockFlutterPlatformFactory : NSObject <FlutterPlatformViewFactory>
@end

@implementation MockFlutterPlatformFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[[MockFlutterPlatformView alloc] init] autorelease];
}

@end

namespace flutter {
namespace {
class MockDelegate : public PlatformView::Delegate {
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override {}
  void OnPlatformViewDestroyed() override {}
  void OnPlatformViewSetNextFrameCallback(const fml::closure& closure) override {}
  void OnPlatformViewSetViewportMetrics(const ViewportMetrics& metrics) override {}
  void OnPlatformViewDispatchPlatformMessage(fml::RefPtr<PlatformMessage> message) override {}
  void OnPlatformViewDispatchPointerDataPacket(std::unique_ptr<PointerDataPacket> packet) override {
  }
  void OnPlatformViewDispatchSemanticsAction(int32_t id,
                                             SemanticsAction action,
                                             std::vector<uint8_t> args) override {}
  void OnPlatformViewSetSemanticsEnabled(bool enabled) override {}
  void OnPlatformViewSetAccessibilityFeatures(int32_t flags) override {}
  void OnPlatformViewRegisterTexture(std::shared_ptr<Texture> texture) override {}
  void OnPlatformViewUnregisterTexture(int64_t texture_id) override {}
  void OnPlatformViewMarkTextureFrameAvailable(int64_t texture_id) override {}

  std::unique_ptr<std::vector<std::string>> ComputePlatformViewResolvedLocale(
      const std::vector<std::string>& supported_locale_data) override {
    std::unique_ptr<std::vector<std::string>> out = std::make_unique<std::vector<std::string>>();
    return out;
  }
};

class MockIosDelegate : public AccessibilityBridge::IosDelegate {
 public:
  bool IsFlutterViewControllerPresentingModalViewController(
      FlutterViewController* view_controller) override {
    return result_IsFlutterViewControllerPresentingModalViewController_;
  };

  void PostAccessibilityNotification(UIAccessibilityNotifications notification,
                                     id argument) override {
    if (on_PostAccessibilityNotification_) {
      on_PostAccessibilityNotification_(notification, argument);
    }
  }
  std::function<void(UIAccessibilityNotifications, id)> on_PostAccessibilityNotification_;
  bool result_IsFlutterViewControllerPresentingModalViewController_ = false;
};
}  // namespace
}  // namespace flutter

namespace {
fml::RefPtr<fml::TaskRunner> CreateNewThread(std::string name) {
  auto thread = std::make_unique<fml::Thread>(name);
  auto runner = thread->GetTaskRunner();
  return runner;
}
}  // namespace

@interface AccessibilityBridgeTest : XCTestCase
@end

@implementation AccessibilityBridgeTest

- (void)testCreate {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/nil,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil);
  XCTAssertTrue(bridge.get());
}

- (void)testUpdateSemanticsEmpty {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterView = OCMClassMock([FlutterView class]);
  id mockFlutterViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([mockFlutterViewController view]).andReturn(mockFlutterView);
  OCMExpect([mockFlutterView setAccessibilityElements:[OCMArg isNil]]);
  auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view_controller=*/mockFlutterViewController,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil);
  flutter::SemanticsNodeUpdates nodes;
  flutter::CustomAccessibilityActionUpdates actions;
  bridge->UpdateSemantics(/*nodes=*/nodes, /*actions=*/actions);
  OCMVerifyAll(mockFlutterView);
}

- (void)testUpdateSemanticsOneNode {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterView = OCMClassMock([FlutterView class]);
  id mockFlutterViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([mockFlutterViewController view]).andReturn(mockFlutterView);
  std::string label = "some label";

  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view_controller=*/mockFlutterViewController,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil);

  OCMExpect([mockFlutterView setAccessibilityElements:[OCMArg checkWithBlock:^BOOL(NSArray* value) {
                               if ([value count] != 1) {
                                 return NO;
                               } else {
                                 SemanticsObjectContainer* container = value[0];
                                 SemanticsObject* object = container.semanticsObject;
                                 return object.uid == kRootNodeId &&
                                        object.bridge.get() == bridge.get() &&
                                        object.node.label == label;
                               }
                             }]]);

  flutter::SemanticsNodeUpdates nodes;
  flutter::SemanticsNode semantics_node;
  semantics_node.id = kRootNodeId;
  semantics_node.label = label;
  nodes[kRootNodeId] = semantics_node;
  flutter::CustomAccessibilityActionUpdates actions;
  bridge->UpdateSemantics(/*nodes=*/nodes, /*actions=*/actions);
  OCMVerifyAll(mockFlutterView);
}

- (void)testSemanticsDeallocated {
  @autoreleasepool {
    flutter::MockDelegate mock_delegate;
    auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
    flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                                 /*platform=*/thread_task_runner,
                                 /*raster=*/thread_task_runner,
                                 /*ui=*/thread_task_runner,
                                 /*io=*/thread_task_runner);
    auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
        /*delegate=*/mock_delegate,
        /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
        /*task_runners=*/runners);
    id mockFlutterView = OCMClassMock([FlutterView class]);
    id mockFlutterViewController = OCMClassMock([FlutterViewController class]);
    OCMStub([mockFlutterViewController view]).andReturn(mockFlutterView);
    std::string label = "some label";

    auto flutterPlatformViewsController =
        std::make_unique<flutter::FlutterPlatformViewsController>();
    flutterPlatformViewsController->SetFlutterView(mockFlutterView);

    MockFlutterPlatformFactory* factory = [[MockFlutterPlatformFactory new] autorelease];
    flutterPlatformViewsController->RegisterViewFactory(
        factory, @"MockFlutterPlatformView",
        FlutterPlatformViewGestureRecognizersBlockingPolicyEager);
    FlutterResult result = ^(id result) {
    };
    flutterPlatformViewsController->OnMethodCall(
        [FlutterMethodCall
            methodCallWithMethodName:@"create"
                           arguments:@{@"id" : @2, @"viewType" : @"MockFlutterPlatformView"}],
        result);

    auto bridge = std::make_unique<flutter::AccessibilityBridge>(
        /*view_controller=*/mockFlutterViewController,
        /*platform_view=*/platform_view.get(),
        /*platform_views_controller=*/flutterPlatformViewsController.get());

    flutter::SemanticsNodeUpdates nodes;
    flutter::SemanticsNode semantics_node;
    semantics_node.id = 2;
    semantics_node.platformViewId = 2;
    semantics_node.label = label;
    nodes[kRootNodeId] = semantics_node;
    flutter::CustomAccessibilityActionUpdates actions;
    bridge->UpdateSemantics(/*nodes=*/nodes, /*actions=*/actions);
    XCTAssertNotNil(gMockPlatformView);
    flutterPlatformViewsController->Reset();
  }
  XCTAssertNil(gMockPlatformView);
}

- (void)testAnnouncesRouteChanges {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterView = OCMClassMock([FlutterView class]);
  id mockFlutterViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([mockFlutterViewController view]).andReturn(mockFlutterView);
  std::string label = "some label";

  NSMutableArray<NSDictionary<NSString*, id>*>* accessibility_notifications =
      [[[NSMutableArray alloc] init] autorelease];
  auto ios_delegate = std::make_unique<flutter::MockIosDelegate>();
  ios_delegate->on_PostAccessibilityNotification_ =
      [accessibility_notifications](UIAccessibilityNotifications notification, id argument) {
        [accessibility_notifications addObject:@{
          @"notification" : @(notification),
          @"argument" : argument ? argument : [NSNull null],
        }];
      };
  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view_controller=*/mockFlutterViewController,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil,
                                                     /*ios_delegate=*/std::move(ios_delegate));

  flutter::CustomAccessibilityActionUpdates actions;
  flutter::SemanticsNodeUpdates nodes;

  flutter::SemanticsNode route_node;
  route_node.id = 1;
  route_node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kScopesRoute) |
                     static_cast<int32_t>(flutter::SemanticsFlags::kNamesRoute);
  route_node.label = "route";
  nodes[route_node.id] = route_node;
  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = label;
  root_node.childrenInTraversalOrder = {1};
  root_node.childrenInHitTestOrder = {1};
  nodes[root_node.id] = root_node;
  bridge->UpdateSemantics(/*nodes=*/nodes, /*actions=*/actions);

  XCTAssertEqual([accessibility_notifications count], 1ul);
  SemanticsObject* focusObject = accessibility_notifications[0][@"argument"];
  XCTAssertEqual([focusObject uid], 1);
  XCTAssertEqualObjects([focusObject accessibilityLabel], @"route");
  XCTAssertEqual([accessibility_notifications[0][@"notification"] unsignedIntValue],
                 UIAccessibilityScreenChangedNotification);
}

- (void)testAnnouncesLayoutChangeWithNilIfLastFocusIsRemoved {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterViewController = OCMClassMock([FlutterViewController class]);

  NSMutableArray<NSDictionary<NSString*, id>*>* accessibility_notifications =
      [[[NSMutableArray alloc] init] autorelease];
  auto ios_delegate = std::make_unique<flutter::MockIosDelegate>();
  ios_delegate->on_PostAccessibilityNotification_ =
      [accessibility_notifications](UIAccessibilityNotifications notification, id argument) {
        [accessibility_notifications addObject:@{
          @"notification" : @(notification),
          @"argument" : argument ? argument : [NSNull null],
        }];
      };
  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view_controller=*/mockFlutterViewController,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil,
                                                     /*ios_delegate=*/std::move(ios_delegate));

  flutter::CustomAccessibilityActionUpdates actions;
  flutter::SemanticsNodeUpdates first_update;

  flutter::SemanticsNode route_node;
  route_node.id = 1;
  route_node.label = "route";
  first_update[route_node.id] = route_node;
  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = "root";
  root_node.childrenInTraversalOrder = {1};
  root_node.childrenInHitTestOrder = {1};
  first_update[root_node.id] = root_node;
  bridge->UpdateSemantics(/*nodes=*/first_update, /*actions=*/actions);

  XCTAssertEqual([accessibility_notifications count], 0ul);
  // Simulates the focusing on the node 1.
  bridge->AccessibilityFocusDidChange(1);

  flutter::SemanticsNodeUpdates second_update;
  // Simulates the removal of the node 1
  flutter::SemanticsNode new_root_node;
  new_root_node.id = kRootNodeId;
  new_root_node.label = "root";
  second_update[root_node.id] = new_root_node;
  bridge->UpdateSemantics(/*nodes=*/second_update, /*actions=*/actions);
  NSNull* focusObject = accessibility_notifications[0][@"argument"];
  // The node 1 was removed, so the bridge will set the focus object to nil.
  XCTAssertEqual(focusObject, [NSNull null]);
  XCTAssertEqual([accessibility_notifications[0][@"notification"] unsignedIntValue],
                 UIAccessibilityLayoutChangedNotification);
}

- (void)testAnnouncesLayoutChangeWithLastFocused {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterViewController = OCMClassMock([FlutterViewController class]);

  NSMutableArray<NSDictionary<NSString*, id>*>* accessibility_notifications =
      [[[NSMutableArray alloc] init] autorelease];
  auto ios_delegate = std::make_unique<flutter::MockIosDelegate>();
  ios_delegate->on_PostAccessibilityNotification_ =
      [accessibility_notifications](UIAccessibilityNotifications notification, id argument) {
        [accessibility_notifications addObject:@{
          @"notification" : @(notification),
          @"argument" : argument ? argument : [NSNull null],
        }];
      };
  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view_controller=*/mockFlutterViewController,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil,
                                                     /*ios_delegate=*/std::move(ios_delegate));

  flutter::CustomAccessibilityActionUpdates actions;
  flutter::SemanticsNodeUpdates first_update;

  flutter::SemanticsNode node_one;
  node_one.id = 1;
  node_one.label = "route1";
  first_update[node_one.id] = node_one;
  flutter::SemanticsNode node_two;
  node_two.id = 2;
  node_two.label = "route2";
  first_update[node_two.id] = node_two;
  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = "root";
  root_node.childrenInTraversalOrder = {1, 2};
  root_node.childrenInHitTestOrder = {1, 2};
  first_update[root_node.id] = root_node;
  bridge->UpdateSemantics(/*nodes=*/first_update, /*actions=*/actions);

  XCTAssertEqual([accessibility_notifications count], 0ul);
  // Simulates the focusing on the node 1.
  bridge->AccessibilityFocusDidChange(1);

  flutter::SemanticsNodeUpdates second_update;
  // Simulates the removal of the node 2.
  flutter::SemanticsNode new_root_node;
  new_root_node.id = kRootNodeId;
  new_root_node.label = "root";
  new_root_node.childrenInTraversalOrder = {1};
  new_root_node.childrenInHitTestOrder = {1};
  second_update[root_node.id] = new_root_node;
  bridge->UpdateSemantics(/*nodes=*/second_update, /*actions=*/actions);
  SemanticsObject* focusObject = accessibility_notifications[0][@"argument"];
  // Since we have focused on the node 1 right before the layout changed, the bridge should refocus
  // the node 1.
  XCTAssertEqual([focusObject uid], 1);
  XCTAssertEqual([accessibility_notifications[0][@"notification"] unsignedIntValue],
                 UIAccessibilityLayoutChangedNotification);
}

- (void)testAnnouncesScrollChangeWithLastFocused {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterViewController = OCMClassMock([FlutterViewController class]);

  NSMutableArray<NSDictionary<NSString*, id>*>* accessibility_notifications =
      [[[NSMutableArray alloc] init] autorelease];
  auto ios_delegate = std::make_unique<flutter::MockIosDelegate>();
  ios_delegate->on_PostAccessibilityNotification_ =
      [accessibility_notifications](UIAccessibilityNotifications notification, id argument) {
        [accessibility_notifications addObject:@{
          @"notification" : @(notification),
          @"argument" : argument ? argument : [NSNull null],
        }];
      };
  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view_controller=*/mockFlutterViewController,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil,
                                                     /*ios_delegate=*/std::move(ios_delegate));

  flutter::CustomAccessibilityActionUpdates actions;
  flutter::SemanticsNodeUpdates first_update;

  flutter::SemanticsNode node_one;
  node_one.id = 1;
  node_one.label = "route1";
  node_one.scrollPosition = 0.0;
  first_update[node_one.id] = node_one;
  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = "root";
  root_node.childrenInTraversalOrder = {1};
  root_node.childrenInHitTestOrder = {1};
  first_update[root_node.id] = root_node;
  bridge->UpdateSemantics(/*nodes=*/first_update, /*actions=*/actions);

  // The first update will trigger a scroll announcement, but we are not interested in it.
  [accessibility_notifications removeAllObjects];

  // Simulates the focusing on the node 1.
  bridge->AccessibilityFocusDidChange(1);

  flutter::SemanticsNodeUpdates second_update;
  // Simulates the scrolling on the node 1.
  flutter::SemanticsNode new_node_one;
  new_node_one.id = 1;
  new_node_one.label = "route1";
  new_node_one.scrollPosition = 1.0;
  second_update[new_node_one.id] = new_node_one;
  bridge->UpdateSemantics(/*nodes=*/second_update, /*actions=*/actions);
  SemanticsObject* focusObject = accessibility_notifications[0][@"argument"];
  // Since we have focused on the node 1 right before the scrolling, the bridge should refocus the
  // node 1.
  XCTAssertEqual([focusObject uid], 1);
  XCTAssertEqual([accessibility_notifications[0][@"notification"] unsignedIntValue],
                 UIAccessibilityPageScrolledNotification);
}

- (void)testAnnouncesIgnoresRouteChangesWhenModal {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterView = OCMClassMock([FlutterView class]);
  id mockFlutterViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([mockFlutterViewController view]).andReturn(mockFlutterView);
  std::string label = "some label";

  NSMutableArray<NSDictionary<NSString*, id>*>* accessibility_notifications =
      [[[NSMutableArray alloc] init] autorelease];
  auto ios_delegate = std::make_unique<flutter::MockIosDelegate>();
  ios_delegate->on_PostAccessibilityNotification_ =
      [accessibility_notifications](UIAccessibilityNotifications notification, id argument) {
        [accessibility_notifications addObject:@{
          @"notification" : @(notification),
          @"argument" : argument ? argument : [NSNull null],
        }];
      };
  ios_delegate->result_IsFlutterViewControllerPresentingModalViewController_ = true;
  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view_controller=*/mockFlutterViewController,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil,
                                                     /*ios_delegate=*/std::move(ios_delegate));

  flutter::CustomAccessibilityActionUpdates actions;
  flutter::SemanticsNodeUpdates nodes;

  flutter::SemanticsNode route_node;
  route_node.id = 1;
  route_node.label = label;
  route_node.flags = static_cast<int32_t>(flutter::SemanticsFlags::kScopesRoute) |
                     static_cast<int32_t>(flutter::SemanticsFlags::kNamesRoute);
  route_node.label = "route";
  nodes[route_node.id] = route_node;
  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = label;
  root_node.childrenInTraversalOrder = {1};
  root_node.childrenInHitTestOrder = {1};
  nodes[root_node.id] = root_node;
  bridge->UpdateSemantics(/*nodes=*/nodes, /*actions=*/actions);

  XCTAssertEqual([accessibility_notifications count], 0ul);
}

- (void)testAccessibilityMessageAfterDeletion {
  flutter::MockDelegate mock_delegate;
  auto thread = std::make_unique<fml::Thread>("AccessibilityBridgeTest");
  auto thread_task_runner = thread->GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id engine = OCMClassMock([FlutterEngine class]);
  id flutterViewController = OCMClassMock([FlutterViewController class]);

  OCMStub([flutterViewController engine]).andReturn(engine);
  OCMStub([engine binaryMessenger]).andReturn(messenger);
  FlutterBinaryMessengerConnection connection = 123;
  OCMStub([messenger setMessageHandlerOnChannel:@"flutter/accessibility"
                           binaryMessageHandler:[OCMArg any]])
      .andReturn(connection);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    auto weakFactory =
        std::make_unique<fml::WeakPtrFactory<FlutterViewController>>(flutterViewController);
    platform_view->SetOwnerViewController(weakFactory->GetWeakPtr());
    auto bridge =
        std::make_unique<flutter::AccessibilityBridge>(/*view=*/nil,
                                                       /*platform_view=*/platform_view.get(),
                                                       /*platform_views_controller=*/nil);
    XCTAssertTrue(bridge.get());
    OCMVerify([messenger setMessageHandlerOnChannel:@"flutter/accessibility"
                               binaryMessageHandler:[OCMArg isNotNil]]);
    bridge.reset();
    latch.Signal();
  });
  latch.Wait();
  OCMVerify([messenger cleanupConnection:connection]);
}
@end
