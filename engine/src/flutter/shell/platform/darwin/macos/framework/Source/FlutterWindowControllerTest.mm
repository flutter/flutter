// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/common/isolate_scope.h"
#import "flutter/shell/platform/common/windowing.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngineTestUtils.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterWindowController.h"
#import "flutter/testing/testing.h"
#import "third_party/googletest/googletest/include/gtest/gtest.h"

namespace flutter::testing {

class FlutterWindowControllerTest : public FlutterEngineTest {
 public:
  FlutterWindowControllerTest() = default;

  void SetUp() {
    FlutterEngineTest::SetUp();

    [GetFlutterEngine() runWithEntrypoint:@"testWindowController"];

    signalled_ = false;

    AddNativeCallback("SignalNativeTest", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                        isolate_ = Isolate::Current();
                        signalled_ = true;
                      }));

    while (!signalled_) {
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }
  }

  void TearDown() {
    [GetFlutterEngine().windowController closeAllWindows];
    FlutterEngineTest::TearDown();
  }

 protected:
  flutter::Isolate& isolate() {
    if (isolate_) {
      return *isolate_;
    } else {
      FML_LOG(ERROR) << "Isolate is not set.";
      FML_UNREACHABLE();
    }
  }

  std::optional<flutter::Isolate> isolate_;
  bool signalled_;
};

class FlutterWindowControllerRetainTest : public ::testing::Test {};

TEST_F(FlutterWindowControllerTest, CreateRegularWindow) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  {
    IsolateScope isolate_scope(isolate());
    int64_t handle = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
    EXPECT_EQ(handle, 1);

    FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];
    EXPECT_NE(viewController, nil);
    CGSize size = viewController.view.frame.size;
    EXPECT_EQ(size.width, 800);
    EXPECT_EQ(size.height, 600);
  }
}

TEST_F(FlutterWindowControllerTest, CreateTooltipWindow) {
  IsolateScope isolate_scope(isolate());
  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  auto request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };
  int64_t parentViewId = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
  EXPECT_EQ(parentViewId, 1);

  auto position_callback = [](const FlutterWindowSize& child_size,
                              const FlutterWindowRect& parent_rect,
                              const FlutterWindowRect& output_rect) -> FlutterWindowRect* {
    FlutterWindowRect* rect = static_cast<FlutterWindowRect*>(malloc(sizeof(FlutterWindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  request = FlutterWindowCreationRequest{
      .has_constraints = true,
      .constraints{
          .max_width = 1000,
          .max_height = 1000,
      },
      .parent_view_id = parentViewId,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
      .on_get_window_position = position_callback,
  };

  const int64_t tooltipViewId =
      InternalFlutter_WindowController_CreateTooltipWindow(engineId, &request);
  EXPECT_NE(tooltipViewId, 0);
}

TEST_F(FlutterWindowControllerRetainTest, WindowControllerDoesNotRetainEngine) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  __weak FlutterEngine* weakEngine = nil;
  @autoreleasepool {
    NSString* fixtures = @(flutter::testing::GetFixturesPath());
    NSLog(@"Fixtures path: %@", fixtures);
    FlutterDartProject* project = [[FlutterDartProject alloc]
        initWithAssetsPath:fixtures
               ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];

    static std::optional<flutter::Isolate> isolate;
    isolate = std::nullopt;

    project.rootIsolateCreateCallback = [](void*) { isolate = flutter::Isolate::Current(); };
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test"
                                                        project:project
                                         allowHeadlessExecution:YES];
    weakEngine = engine;
    [engine runWithEntrypoint:@"testWindowControllerRetainCycle"];

    int64_t engineId = reinterpret_cast<int64_t>(engine);

    {
      FML_DCHECK(isolate.has_value());
      // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
      IsolateScope isolateScope(*isolate);
      int64_t handle = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
      EXPECT_EQ(handle, 1);
    }

    [engine.windowController closeAllWindows];
    [engine shutDownEngine];
  }
  EXPECT_EQ(weakEngine, nil);
}

TEST_F(FlutterWindowControllerTest, DestroyRegularWindow) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engine_id = reinterpret_cast<int64_t>(engine);

  IsolateScope isolate_scope(isolate());
  int64_t handle = InternalFlutter_WindowController_CreateRegularWindow(engine_id, &request);
  FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];

  InternalFlutter_Window_Destroy(engine_id, (__bridge void*)viewController.view.window);
  viewController = [engine viewControllerForIdentifier:handle];
  EXPECT_EQ(viewController, nil);
}

TEST_F(FlutterWindowControllerTest, InternalFlutterWindowGetHandle) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engine_id = reinterpret_cast<int64_t>(engine);

  IsolateScope isolate_scope(isolate());
  int64_t handle = InternalFlutter_WindowController_CreateRegularWindow(engine_id, &request);
  FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];

  void* window_handle = InternalFlutter_Window_GetHandle(engine_id, handle);
  EXPECT_EQ(window_handle, (__bridge void*)viewController.view.window);
}

TEST_F(FlutterWindowControllerTest, WindowStates) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engine_id = reinterpret_cast<int64_t>(engine);

  IsolateScope isolate_scope(isolate());
  int64_t handle = InternalFlutter_WindowController_CreateRegularWindow(engine_id, &request);

  FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];
  NSWindow* window = viewController.view.window;
  void* windowHandle = (__bridge void*)window;

  EXPECT_EQ(window.zoomed, NO);
  EXPECT_EQ(window.miniaturized, NO);
  EXPECT_EQ(window.styleMask & NSWindowStyleMaskFullScreen, 0u);

  InternalFlutter_Window_SetMaximized(windowHandle, true);
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);
  EXPECT_EQ(window.zoomed, YES);

  InternalFlutter_Window_SetMaximized(windowHandle, false);
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);
  EXPECT_EQ(window.zoomed, NO);

  // FullScreen toggle does not seem to work when the application is not run from a bundle.

  InternalFlutter_Window_Minimize(windowHandle);
  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, false);
  EXPECT_EQ(window.miniaturized, YES);
}

TEST_F(FlutterWindowControllerTest, ClosesAllWindowsOnEngineRestart) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };
  FlutterEngine* engine = GetFlutterEngine();
  int64_t engine_id = reinterpret_cast<int64_t>(engine);

  IsolateScope isolate_scope(isolate());

  // Create multiple windows
  int64_t handle1 = InternalFlutter_WindowController_CreateRegularWindow(engine_id, &request);
  int64_t handle2 = InternalFlutter_WindowController_CreateRegularWindow(engine_id, &request);
  int64_t handle3 = InternalFlutter_WindowController_CreateRegularWindow(engine_id, &request);

  // Verify windows are created
  FlutterViewController* viewController1 = [engine viewControllerForIdentifier:handle1];
  FlutterViewController* viewController2 = [engine viewControllerForIdentifier:handle2];
  FlutterViewController* viewController3 = [engine viewControllerForIdentifier:handle3];
  EXPECT_NE(viewController1, nil);
  EXPECT_NE(viewController2, nil);
  EXPECT_NE(viewController3, nil);

  // Close all windows on engine restart
  [engine engineCallbackOnPreEngineRestart];

  // Verify all windows are closed and view controllers are disposed
  viewController1 = [engine viewControllerForIdentifier:handle1];
  viewController2 = [engine viewControllerForIdentifier:handle2];
  viewController3 = [engine viewControllerForIdentifier:handle3];
  EXPECT_EQ(viewController1, nil);
  EXPECT_EQ(viewController2, nil);
  EXPECT_EQ(viewController3, nil);
};

TEST_F(FlutterWindowControllerTest, ViewMetricsRespectPositionCallbackConstraints) {
  IsolateScope isolate_scope(isolate());
  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  // Create parent window.
  auto parentRequest = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };
  int64_t parentViewId =
      InternalFlutter_WindowController_CreateRegularWindow(engineId, &parentRequest);
  EXPECT_EQ(parentViewId, 1);

  auto position_callback = [](const FlutterWindowSize& child_size,
                              const FlutterWindowRect& parent_rect,
                              const FlutterWindowRect& output_rect) -> FlutterWindowRect* {
    FlutterWindowRect* rect = static_cast<FlutterWindowRect*>(malloc(sizeof(FlutterWindowRect)));
    rect->left = parent_rect.left;
    rect->top = parent_rect.top;
    rect->width = 500;
    rect->height = 400;
    return rect;
  };

  auto tooltipRequest = FlutterWindowCreationRequest{
      .has_constraints = true,
      .constraints{
          .min_width = 0,
          .min_height = 0,
          .max_width = 1000,
          .max_height = 1000,
      },
      .parent_view_id = parentViewId,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
      .on_get_window_position = position_callback,
  };

  const int64_t tooltipViewId =
      InternalFlutter_WindowController_CreateTooltipWindow(engineId, &tooltipRequest);
  EXPECT_NE(tooltipViewId, 0);

  FlutterViewController* viewController = [engine viewControllerForIdentifier:tooltipViewId];
  FlutterView* flutterView = viewController.flutterView;

  EXPECT_EQ(flutterView.sizedToContents, YES);

  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);

  [flutterView.sizingDelegate viewDidUpdateContents:flutterView withSize:NSMakeSize(1000, 1000)];

  // The constraints from request are 1000x1000, but additional constraints came from the positioner
  // and must be respected.
  CGSize maxSize = flutterView.maximumContentSize;
  EXPECT_LE(maxSize.width, 500);
  EXPECT_LE(maxSize.height, 400);
}
}  // namespace flutter::testing
