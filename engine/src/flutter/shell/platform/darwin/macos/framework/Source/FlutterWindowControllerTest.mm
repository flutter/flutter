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

// CREATE_NATIVE_ENTRY is leaky.
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

// Test category declaring the internal method used to simulate the first frame
// presentation. The implementation lives in FlutterView.mm.
@interface FlutterView (TestingOnPresent)
- (void)onPresent:(CGSize)frameSize withBlock:(dispatch_block_t)block delay:(NSTimeInterval)delay;
@end

namespace flutter::testing {

class FlutterWindowControllerTest : public FlutterEngineTest {
 public:
  FlutterWindowControllerTest() = default;

  void SetUp() {
    FlutterEngineTest::SetUp();

    [GetFlutterEngine() runWithEntrypoint:@"testWindowController"];

    signalled_ = false;

    AddFfiNativeCallback("SignalNativeTest", CREATE_FFI_LAMBDA([&]() {
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
  bool signalled_ = false;
};

class FlutterWindowControllerRetainTest : public ::testing::Test {};

class FlutterWindowControllerSizeTest : public FlutterEngineTest {};

const CFAbsoluteTime kTestTimeout = 30.0;

// Runs the macOS run loop until the predicate evaluates to true or the given
// timeout is exceeded. The predicate is checked after each run loop source has
// been handled. ADD_FAILURE is called on timeout.
static void RunLoopUntilPredicate(NSTimeInterval timeout, BOOL (^predicate)(void)) {
  CFAbsoluteTime const deadline = CFAbsoluteTimeGetCurrent() + timeout;
  while (!predicate()) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, true);
    if (CFAbsoluteTimeGetCurrent() > deadline) {
      ADD_FAILURE() << "Timed out waiting for run loop predicate.";
      return;
    }
  }
}

TEST_F(FlutterWindowControllerTest, FixMoveRunLoopMode) {
  FlutterEngine* engine = GetFlutterEngine();
  [engine.windowController fixMoveRunLoopModeIfNeeded];

  // Make sure that after fixMoveRunLoopMode _NSMoveTimerRunLoopMode becomes
  // common run loop mode.
  __block BOOL signalled = NO;
  CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopCommonModes, ^{
    signalled = YES;
  });
  CFRunLoopRunInMode(CFSTR("_NSMoveTimerRunLoopMode"), 1.0, YES);
  EXPECT_TRUE(signalled);
}

TEST_F(FlutterWindowControllerTest, CreateRegularWindow) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .resizable = true,
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
      .resizable = true,
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
      .resizable = true,
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

TEST_F(FlutterWindowControllerTest, CreatePopupWindow) {
  IsolateScope isolate_scope(isolate());
  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  auto request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .resizable = true,
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
      .resizable = true,
      .parent_view_id = parentViewId,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
      .on_get_window_position = position_callback,
  };

  const int64_t tooltipViewId =
      InternalFlutter_WindowController_CreatePopupWindow(engineId, &request);
  EXPECT_NE(tooltipViewId, 0);
}

TEST_F(FlutterWindowControllerTest, CreateSatelliteWindow) {
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

  auto request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .resizable = true,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  IsolateScope isolate_scope(isolate());
  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  int64_t parentViewId = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
  EXPECT_EQ(parentViewId, 1);

  request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 200, .height = 100},
      .resizable = true,
      .parent_view_id = parentViewId,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
      .on_get_window_position = position_callback,
  };

  const int64_t satelliteViewId =
      InternalFlutter_WindowController_CreateSatelliteWindow(engineId, &request);
  EXPECT_NE(satelliteViewId, 0);

  FlutterViewController* viewController = [engine viewControllerForIdentifier:satelliteViewId];
  EXPECT_NE(viewController, nil);

  NSPanel* satelliteWindow = (NSPanel*)viewController.view.window;
  EXPECT_TRUE([satelliteWindow isKindOfClass:[NSPanel class]]);
  EXPECT_TRUE(satelliteWindow.becomesKeyOnlyIfNeeded);
  EXPECT_EQ(satelliteWindow.styleMask,
            NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskUtilityWindow |
                NSWindowStyleMaskNonactivatingPanel | NSWindowStyleMaskResizable);

  NSWindow* parentWindow = [engine viewControllerForIdentifier:parentViewId].view.window;
  EXPECT_EQ(satelliteWindow.parentWindow, parentWindow);
}

static int position_callback_calls = 0;

TEST_F(FlutterWindowControllerTest, SatelliteWindowRunsPositionCallbackOnce) {
  position_callback_calls = 0;
  auto position_callback = [](const FlutterWindowSize& child_size,
                              const FlutterWindowRect& parent_rect,
                              const FlutterWindowRect& output_rect) -> FlutterWindowRect* {
    position_callback_calls++;
    FlutterWindowRect* rect = static_cast<FlutterWindowRect*>(malloc(sizeof(FlutterWindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  auto request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .resizable = true,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  IsolateScope isolate_scope(isolate());
  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  int64_t parentViewId = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
  EXPECT_EQ(parentViewId, 1);

  request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 200, .height = 100},
      .resizable = false,
      .parent_view_id = parentViewId,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
      .on_get_window_position = position_callback,
  };

  const int64_t satelliteViewId =
      InternalFlutter_WindowController_CreateSatelliteWindow(engineId, &request);
  EXPECT_NE(satelliteViewId, 0);

  ASSERT_NE([engine viewControllerForIdentifier:satelliteViewId], nil);
  NSWindow* satelliteWindow = [engine viewControllerForIdentifier:satelliteViewId].view.window;
  NSWindow* parentWindow = [engine viewControllerForIdentifier:parentViewId].view.window;
  FlutterView* satelliteView = [engine viewControllerForIdentifier:satelliteViewId].flutterView;

  NSRect parentContentRect = [parentWindow contentRectForFrameRect:parentWindow.frame];

  // The satellite is hidden until it has been placed.
  EXPECT_EQ(satelliteWindow.alphaValue, 0.0);
  EXPECT_EQ(position_callback_calls, 0);

  // Simulate the first frame: present the view content the same way the
  // compositor does. The positioner is invoked and the window is revealed.
  CGSize const frameSize = [satelliteView convertSizeToBacking:satelliteView.bounds.size];
  [satelliteView onPresent:frameSize
                 withBlock:^{
                 }
                     delay:0];
  RunLoopUntilPredicate(1.0, ^{
    return satelliteWindow.alphaValue == 1.0;
  });

  NSRect frame = satelliteWindow.frame;
  EXPECT_EQ(position_callback_calls, 1);
  EXPECT_EQ(satelliteWindow.alphaValue, 1.0);
  EXPECT_NEAR(frame.origin.x, parentContentRect.origin.x + 10, 1);
  EXPECT_NEAR(frame.origin.y + frame.size.height,
              parentContentRect.origin.y + parentContentRect.size.height - 10, 1);

  // After the initial placement, the position callback is not invoked again.
  // User driven movement is retained.
  NSRect userMovedFrame =
      NSMakeRect(frame.origin.x + 5, frame.origin.y - 5, frame.size.width, frame.size.height);
  [satelliteWindow setFrame:userMovedFrame display:NO];
  [satelliteView onPresent:frameSize
                 withBlock:^{
                 }
                     delay:0];
  RunLoopUntilPredicate(1.0, ^{
    return NSEqualRects(satelliteWindow.frame, userMovedFrame);
  });

  EXPECT_EQ(position_callback_calls, 1);
  EXPECT_TRUE(NSEqualRects(satelliteWindow.frame, userMovedFrame));
}

TEST_F(FlutterWindowControllerTest, ReparentSatelliteWindow) {
  auto request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .resizable = true,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  IsolateScope isolate_scope(isolate());
  FlutterEngine* engine = GetFlutterEngine();
  int64_t engineId = reinterpret_cast<int64_t>(engine);

  int64_t parentViewId1 = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
  EXPECT_EQ(parentViewId1, 1);
  int64_t parentViewId2 = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
  EXPECT_EQ(parentViewId2, 2);

  request = FlutterWindowCreationRequest{
      .has_size = true,
      .size = {.width = 200, .height = 100},
      .resizable = false,
      .parent_view_id = parentViewId1,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  const int64_t satelliteViewId =
      InternalFlutter_WindowController_CreateSatelliteWindow(engineId, &request);
  EXPECT_NE(satelliteViewId, 0);

  NSWindow* parentWindow1 = [engine viewControllerForIdentifier:parentViewId1].view.window;
  NSWindow* parentWindow2 = [engine viewControllerForIdentifier:parentViewId2].view.window;
  NSWindow* satelliteWindow = [engine viewControllerForIdentifier:satelliteViewId].view.window;

  EXPECT_EQ(satelliteWindow.parentWindow, parentWindow1);

  InternalFlutter_Window_Reparent(engineId, (__bridge void*)satelliteWindow, parentViewId2);

  EXPECT_EQ(satelliteWindow.parentWindow, parentWindow2);
}

TEST_F(FlutterWindowControllerRetainTest, WindowControllerDoesNotRetainEngine) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .resizable = true,
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

    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);

    int64_t engineId = reinterpret_cast<int64_t>(engine);

    {
      FML_DCHECK(isolate.has_value());
      // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
      IsolateScope isolateScope(*isolate);
      int64_t handle = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
      EXPECT_EQ(handle, 1);
    }

    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);

    [engine.windowController closeAllWindows];
    [engine shutDownEngine];
  }
  EXPECT_EQ(weakEngine, nil);
}

TEST_F(FlutterWindowControllerTest, DestroyRegularWindow) {
  FlutterWindowCreationRequest request{
      .has_size = true,
      .size = {.width = 800, .height = 600},
      .resizable = true,
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
      .resizable = true,
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
      .resizable = true,
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
      .resizable = true,
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
      .resizable = true,
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

  [flutterView.contentDelegate viewDidUpdateContents:flutterView withSize:NSMakeSize(1000, 1000)];

  // The constraints from request are 1000x1000, but additional constraints came from the positioner
  // and must be respected.
  CGSize maxSize = flutterView.maximumContentSize;
  EXPECT_LE(maxSize.width, 500);
  EXPECT_LE(maxSize.height, 400);
}

TEST_F(FlutterWindowControllerTest, GetOffsetInParent) {
  NSWindow* parentWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                       styleMask:NSWindowStyleMaskTitled
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
  [parentWindow setReleasedWhenClosed:NO];
  NSWindow* childWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                      styleMask:NSWindowStyleMaskBorderless
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];
  [childWindow setReleasedWhenClosed:NO];

  // Bottom left origin.
  [parentWindow setFrame:NSMakeRect(100, 100, 800, 600) display:NO];
  [childWindow setFrame:NSMakeRect(150, 150, 100, 100) display:NO];

  // Establish the parent-child relationship required by GetOffsetInParent.
  [parentWindow addChildWindow:childWindow ordered:NSWindowAbove];

  FlutterWindowOffset offset =
      InternalFlutter_Window_GetOffsetInParent((__bridge void*)childWindow);

  // GetOffsetInParent has relative coordinates with top left origin.
  NSRect parentContentRect = [parentWindow contentRectForFrameRect:parentWindow.frame];

  double expectedX = 150 - parentContentRect.origin.x;
  double expectedY = (parentContentRect.origin.y + parentContentRect.size.height) - (150 + 100);

  EXPECT_NEAR(offset.x, expectedX, 0.001);
  EXPECT_NEAR(offset.y, expectedY, 0.001);

  [parentWindow removeChildWindow:childWindow];
  [childWindow close];
  [parentWindow close];
}

TEST_F(FlutterWindowControllerSizeTest, SizedToContentResizable) {
  FlutterWindowCreationRequest request{
      .has_size = false,
      .has_constraints = true,
      .constraints{
          .min_width = 0,
          .min_height = 0,
          .max_width = 1000,
          .max_height = 1000,
      },
      .resizable = true,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  std::optional<Isolate> isolate;

  bool signaled = false;
  AddFfiNativeCallback("SignalNativeTest", CREATE_FFI_LAMBDA([&](Dart_NativeArguments args) {
                         signaled = true;
                         isolate = Isolate::Current();
                       }));

  auto engine = GetFlutterEngine();
  [engine runWithEntrypoint:@"testRenderSizedToContentResizable"];

  auto engineId = reinterpret_cast<int64_t>(GetFlutterEngine());

  while (!signaled) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
  }

  int64_t viewId = 0;
  {
    IsolateScope isolate_scope(*isolate);
    viewId = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
  }

  auto controller = [engine viewControllerForIdentifier:viewId];
  auto window = controller.view.window;
  CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
  double pixelRatio = [window backingScaleFactor];
  while (window.frame.size.width != 300 / pixelRatio &&
         CFAbsoluteTimeGetCurrent() - startTime < kTestTimeout) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
  }

  NSRect contentRect = [window contentRectForFrameRect:window.frame];
  EXPECT_EQ(contentRect.size.width, 300 / pixelRatio);
  EXPECT_EQ(contentRect.size.height, 300 / pixelRatio);
  EXPECT_TRUE((window.styleMask & NSWindowStyleMaskResizable) != 0);

  [engine.windowController closeAllWindows];
  [engine shutDownEngine];
}

TEST_F(FlutterWindowControllerSizeTest, SizedToContentNotResizable) {
  FlutterWindowCreationRequest request{
      .has_size = false,
      .has_constraints = true,
      .constraints{
          .min_width = 0,
          .min_height = 0,
          .max_width = 1000,
          .max_height = 1000,
      },
      .resizable = false,
      .on_should_close = [] {},
      .on_will_close = [] {},
      .notify_listeners = [] {},
  };

  std::optional<Isolate> isolate;

  bool signaled = false;
  AddFfiNativeCallback("SignalNativeTest", CREATE_FFI_LAMBDA([&](Dart_NativeArguments args) {
                         signaled = true;
                         isolate = Isolate::Current();
                       }));

  auto engine = GetFlutterEngine();
  [engine runWithEntrypoint:@"testRenderSizedToContent"];

  auto engineId = reinterpret_cast<int64_t>(GetFlutterEngine());

  while (!signaled) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
  }

  int64_t viewId = 0;
  {
    IsolateScope isolate_scope(*isolate);
    viewId = InternalFlutter_WindowController_CreateRegularWindow(engineId, &request);
  }

  auto controller = [engine viewControllerForIdentifier:viewId];
  auto window = controller.view.window;

  CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
  double pixelRatio = [window backingScaleFactor];
  while (window.frame.size.width != 300 / pixelRatio &&
         CFAbsoluteTimeGetCurrent() - startTime < kTestTimeout) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
  }

  NSRect contentRect = [window contentRectForFrameRect:window.frame];
  EXPECT_EQ(contentRect.size.width, 300 / pixelRatio);
  EXPECT_EQ(contentRect.size.height, 300 / pixelRatio);
  EXPECT_TRUE((window.styleMask & NSWindowStyleMaskResizable) == 0);

  // Wait until the second frame is rendered, which should resize the window based
  // on new content.
  startTime = CFAbsoluteTimeGetCurrent();
  while (window.frame.size.width == 300 / pixelRatio &&
         CFAbsoluteTimeGetCurrent() - startTime < kTestTimeout) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
  }

  contentRect = [window contentRectForFrameRect:window.frame];
  EXPECT_EQ(contentRect.size.width, 200 / pixelRatio);
  EXPECT_EQ(contentRect.size.height, 200 / pixelRatio);

  [engine.windowController closeAllWindows];
  [engine shutDownEngine];
}

}  // namespace flutter::testing

// NOLINTEND(clang-analyzer-core.StackAddressEscape)