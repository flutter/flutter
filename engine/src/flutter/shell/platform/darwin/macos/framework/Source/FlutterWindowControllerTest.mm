// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/common/isolate_scope.h"
#import "flutter/shell/platform/common/windowing.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngineTestUtils.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
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

    bool signalled = false;

    AddNativeCallback("SignalNativeTest", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                        isolate_ = Isolate::Current();
                        signalled = true;
                      }));

    while (!signalled) {
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
};

class FlutterWindowControllerRetainTest : public ::testing::Test {};

TEST_F(FlutterWindowControllerTest, CreateRegularWindow) {
  FlutterWindowCreationRequest request{
      .contentSize = {.hasSize = true, .width = 800, .height = 600},
      .on_close = [] {},
      .on_size_change = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  {
    IsolateScope isolate_scope(isolate());
    int64_t handle = FlutterCreateRegularWindow(engineId, &request);
    EXPECT_EQ(handle, 1);

    FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];
    EXPECT_NE(viewController, nil);
    CGSize size = viewController.view.frame.size;
    EXPECT_EQ(size.width, 800);
    EXPECT_EQ(size.height, 600);
  }
}

TEST_F(FlutterWindowControllerRetainTest, WindowControllerDoesNotRetainEngine) {
  FlutterWindowCreationRequest request{
      .contentSize = {.hasSize = true, .width = 800, .height = 600},
      .on_close = [] {},
      .on_size_change = [] {},
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
      int64_t handle = FlutterCreateRegularWindow(engineId, &request);
      EXPECT_EQ(handle, 1);
    }

    [engine.windowController closeAllWindows];
    [engine shutDownEngine];
  }
  EXPECT_EQ(weakEngine, nil);
}

TEST_F(FlutterWindowControllerTest, DestroyRegularWindow) {
  FlutterWindowCreationRequest request{
      .contentSize = {.hasSize = true, .width = 800, .height = 600},
      .on_close = [] {},
      .on_size_change = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engine_id = reinterpret_cast<int64_t>(engine);

  IsolateScope isolate_scope(isolate());
  int64_t handle = FlutterCreateRegularWindow(engine_id, &request);
  FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];

  FlutterDestroyWindow(engine_id, (__bridge void*)viewController.view.window);
  viewController = [engine viewControllerForIdentifier:handle];
  EXPECT_EQ(viewController, nil);
}

TEST_F(FlutterWindowControllerTest, FlutterGetWindowHandle) {
  FlutterWindowCreationRequest request{
      .contentSize = {.hasSize = true, .width = 800, .height = 600},
      .on_close = [] {},
      .on_size_change = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engine_id = reinterpret_cast<int64_t>(engine);

  IsolateScope isolate_scope(isolate());
  int64_t handle = FlutterCreateRegularWindow(engine_id, &request);
  FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];

  void* window_handle = FlutterGetWindowHandle(engine_id, handle);
  EXPECT_EQ(window_handle, (__bridge void*)viewController.view.window);
}

TEST_F(FlutterWindowControllerTest, FlutterSetWindowState) {
  FlutterWindowCreationRequest request{
      .contentSize = {.hasSize = true, .width = 800, .height = 600},
      .on_close = [] {},
      .on_size_change = [] {},
  };

  FlutterEngine* engine = GetFlutterEngine();
  int64_t engine_id = reinterpret_cast<int64_t>(engine);

  IsolateScope isolate_scope(isolate());
  int64_t handle = FlutterCreateRegularWindow(engine_id, &request);

  const std::array kWindowStates = {
      static_cast<int64_t>(WindowState::kRestored),   //
      static_cast<int64_t>(WindowState::kMaximized),  //
      static_cast<int64_t>(WindowState::kMinimized),  //
      static_cast<int64_t>(WindowState::kMaximized),  //
      static_cast<int64_t>(WindowState::kRestored),   //
  };
  FlutterViewController* viewController = [engine viewControllerForIdentifier:handle];
  void* windowHandle = (__bridge void*)viewController.view.window;

  for (const auto requestedState : kWindowStates) {
    FlutterSetWindowState(windowHandle, requestedState);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, false);
    const int64_t actualState = FlutterGetWindowState(windowHandle);
    EXPECT_EQ(actualState, requestedState);
  }
}
}  // namespace flutter::testing
