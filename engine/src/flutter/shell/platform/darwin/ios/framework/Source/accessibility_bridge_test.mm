// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

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
  bool IsFlutterViewControllerPresentingModalViewController(UIView* view) override {
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
  OCMExpect([mockFlutterView setAccessibilityElements:[OCMArg isNil]]);
  auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/mockFlutterView,
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
  std::string label = "some label";

  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/mockFlutterView,
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
        /*view=*/mockFlutterView,
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
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/mockFlutterView,
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

  XCTAssertEqual([accessibility_notifications count], 1ul);
  XCTAssertEqualObjects(accessibility_notifications[0][@"argument"], @"route");
  XCTAssertEqual([accessibility_notifications[0][@"notification"] unsignedIntValue],
                 UIAccessibilityScreenChangedNotification);
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
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/mockFlutterView,
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

@end
