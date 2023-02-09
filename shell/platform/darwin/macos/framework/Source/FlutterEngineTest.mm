// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"

#include <functional>
#include <thread>

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/platform/common/accessibility_bridge.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngineTestUtils.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/testing/test_dart_native_resolver.h"

// CREATE_NATIVE_ENTRY and MOCK_ENGINE_PROC are leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

@interface FlutterEngine (Test)
/**
 * The FlutterCompositor object currently in use by the FlutterEngine.
 *
 * May be nil if the compositor has not been initialized yet.
 */
@property(nonatomic, readonly, nullable) flutter::FlutterCompositor* macOSCompositor;
@end

@interface TestPlatformViewFactory : NSObject <FlutterPlatformViewFactory>
@end

@implementation TestPlatformViewFactory
- (nonnull NSView*)createWithViewIdentifier:(int64_t)viewId arguments:(nullable id)args {
  return viewId == 42 ? [[NSView alloc] init] : nil;
}

@end

namespace flutter::testing {

TEST_F(FlutterEngineTest, CanLaunch) {
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  EXPECT_TRUE(engine.running);
}

TEST_F(FlutterEngineTest, HasNonNullExecutableName) {
  FlutterEngine* engine = GetFlutterEngine();
  std::string executable_name = [[engine executableName] UTF8String];
  ASSERT_FALSE(executable_name.empty());

  // Block until notified by the Dart test of the value of Platform.executable.
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("NotifyStringValue", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      const auto dart_string = tonic::DartConverter<std::string>::FromDart(
                          Dart_GetNativeArgument(args, 0));
                      EXPECT_EQ(executable_name, dart_string);
                      latch.Signal();
                    }));

  // Launch the test entrypoint.
  EXPECT_TRUE([engine runWithEntrypoint:@"executableNameNotNull"]);

  latch.Wait();
}

TEST_F(FlutterEngineTest, MessengerSend) {
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);

  NSData* test_message = [@"a message" dataUsingEncoding:NSUTF8StringEncoding];
  bool called = false;

  engine.embedderAPI.SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([&called, test_message](auto engine, auto message) {
        called = true;
        EXPECT_STREQ(message->channel, "test");
        EXPECT_EQ(memcmp(message->message, test_message.bytes, message->message_size), 0);
        return kSuccess;
      }));

  [engine.binaryMessenger sendOnChannel:@"test" message:test_message];
  EXPECT_TRUE(called);
}

TEST_F(FlutterEngineTest, CanLogToStdout) {
  // Block until completion of print statement.
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("SignalNativeTest",
                    CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) { latch.Signal(); }));

  // Replace stdout stream buffer with our own.
  std::stringstream buffer;
  std::streambuf* old_buffer = std::cout.rdbuf();
  std::cout.rdbuf(buffer.rdbuf());

  // Launch the test entrypoint.
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"canLogToStdout"]);
  EXPECT_TRUE(engine.running);

  latch.Wait();

  // Restore old stdout stream buffer.
  std::cout.rdbuf(old_buffer);

  // Verify hello world was written to stdout.
  std::string logs = buffer.str();
  EXPECT_TRUE(logs.find("Hello logging") != std::string::npos);
}

TEST_F(FlutterEngineTest, BackgroundIsBlack) {
  FlutterEngine* engine = GetFlutterEngine();

  // Latch to ensure the entire layer tree has been generated and presented.
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("SignalNativeTest", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      CALayer* rootLayer = engine.viewController.flutterView.layer;
                      EXPECT_TRUE(rootLayer.backgroundColor != nil);
                      if (rootLayer.backgroundColor != nil) {
                        NSColor* actualBackgroundColor =
                            [NSColor colorWithCGColor:rootLayer.backgroundColor];
                        EXPECT_EQ(actualBackgroundColor, [NSColor blackColor]);
                      }
                      latch.Signal();
                    }));

  // Launch the test entrypoint.
  EXPECT_TRUE([engine runWithEntrypoint:@"backgroundTest"]);
  EXPECT_TRUE(engine.running);

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController loadView];
  viewController.flutterView.frame = CGRectMake(0, 0, 800, 600);

  latch.Wait();
}

TEST_F(FlutterEngineTest, CanOverrideBackgroundColor) {
  FlutterEngine* engine = GetFlutterEngine();

  // Latch to ensure the entire layer tree has been generated and presented.
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("SignalNativeTest", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      CALayer* rootLayer = engine.viewController.flutterView.layer;
                      EXPECT_TRUE(rootLayer.backgroundColor != nil);
                      if (rootLayer.backgroundColor != nil) {
                        NSColor* actualBackgroundColor =
                            [NSColor colorWithCGColor:rootLayer.backgroundColor];
                        EXPECT_EQ(actualBackgroundColor, [NSColor whiteColor]);
                      }
                      latch.Signal();
                    }));

  // Launch the test entrypoint.
  EXPECT_TRUE([engine runWithEntrypoint:@"backgroundTest"]);
  EXPECT_TRUE(engine.running);

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController loadView];
  viewController.flutterView.frame = CGRectMake(0, 0, 800, 600);
  viewController.flutterView.backgroundColor = [NSColor whiteColor];

  latch.Wait();
}

TEST_F(FlutterEngineTest, CanToggleAccessibility) {
  FlutterEngine* engine = GetFlutterEngine();
  // Capture the update callbacks before the embedder API initializes.
  auto original_init = engine.embedderAPI.Initialize;
  std::function<void(const FlutterSemanticsUpdate*, void*)> update_semantics_callback;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&update_semantics_callback, &original_init](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data, auto engine_out) {
        update_semantics_callback = args->update_semantics_callback;
        return original_init(version, config, args, user_data, engine_out);
      }));
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  // Set up view controller.
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController loadView];
  // Enable the semantics.
  bool enabled_called = false;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&enabled_called](auto engine, bool enabled) {
                         enabled_called = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = YES;
  EXPECT_TRUE(enabled_called);
  // Send flutter semantics updates.
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.flags = static_cast<FlutterSemanticsFlag>(0);
  child1.actions = static_cast<FlutterSemanticsAction>(0);
  child1.text_selection_base = -1;
  child1.text_selection_extent = -1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.tooltip = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;

  FlutterSemanticsUpdate update;
  update.nodes_count = 2;
  FlutterSemanticsNode nodes[] = {root, child1};
  update.nodes = nodes;
  update.custom_actions_count = 0;
  update_semantics_callback(&update, (__bridge void*)engine);

  // Verify the accessibility tree is attached to the flutter view.
  EXPECT_EQ([engine.viewController.flutterView.accessibilityChildren count], 1u);
  NSAccessibilityElement* native_root = engine.viewController.flutterView.accessibilityChildren[0];
  std::string root_label = [native_root.accessibilityLabel UTF8String];
  EXPECT_TRUE(root_label == "root");
  EXPECT_EQ(native_root.accessibilityRole, NSAccessibilityGroupRole);
  EXPECT_EQ([native_root.accessibilityChildren count], 1u);
  NSAccessibilityElement* native_child1 = native_root.accessibilityChildren[0];
  std::string child1_value = [native_child1.accessibilityValue UTF8String];
  EXPECT_TRUE(child1_value == "child 1");
  EXPECT_EQ(native_child1.accessibilityRole, NSAccessibilityStaticTextRole);
  EXPECT_EQ([native_child1.accessibilityChildren count], 0u);
  // Disable the semantics.
  bool semanticsEnabled = true;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&semanticsEnabled](auto engine, bool enabled) {
                         semanticsEnabled = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = NO;
  EXPECT_FALSE(semanticsEnabled);
  // Verify the accessibility tree is removed from the view.
  EXPECT_EQ([engine.viewController.flutterView.accessibilityChildren count], 0u);

  [engine setViewController:nil];
}

TEST_F(FlutterEngineTest, CanToggleAccessibilityWhenHeadless) {
  FlutterEngine* engine = GetFlutterEngine();
  // Capture the update callbacks before the embedder API initializes.
  auto original_init = engine.embedderAPI.Initialize;
  std::function<void(const FlutterSemanticsUpdate*, void*)> update_semantics_callback;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&update_semantics_callback, &original_init](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data, auto engine_out) {
        update_semantics_callback = args->update_semantics_callback;
        return original_init(version, config, args, user_data, engine_out);
      }));
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);

  // Enable the semantics without attaching a view controller.
  bool enabled_called = false;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&enabled_called](auto engine, bool enabled) {
                         enabled_called = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = YES;
  EXPECT_TRUE(enabled_called);
  // Send flutter semantics updates.
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.flags = static_cast<FlutterSemanticsFlag>(0);
  child1.actions = static_cast<FlutterSemanticsAction>(0);
  child1.text_selection_base = -1;
  child1.text_selection_extent = -1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.tooltip = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;

  FlutterSemanticsUpdate update;
  update.nodes_count = 2;
  FlutterSemanticsNode nodes[] = {root, child1};
  update.nodes = nodes;
  update.custom_actions_count = 0;
  // This call updates semantics for the default view, which does not exist,
  // and therefore this call is invalid. But the engine should not crash.
  update_semantics_callback(&update, (__bridge void*)engine);

  // No crashes.
  EXPECT_EQ(engine.viewController, nil);

  // Disable the semantics.
  bool semanticsEnabled = true;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&semanticsEnabled](auto engine, bool enabled) {
                         semanticsEnabled = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = NO;
  EXPECT_FALSE(semanticsEnabled);
  // Still no crashes
  EXPECT_EQ(engine.viewController, nil);
}

TEST_F(FlutterEngineTest, ProducesAccessibilityTreeWhenAddingViews) {
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);

  // Enable the semantics without attaching a view controller.
  bool enabled_called = false;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&enabled_called](auto engine, bool enabled) {
                         enabled_called = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = YES;
  EXPECT_TRUE(enabled_called);

  EXPECT_EQ(engine.viewController, nil);

  // Assign the view controller after enabling semantics
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  engine.viewController = viewController;

  EXPECT_NE(viewController.accessibilityBridge.lock(), nullptr);
}

TEST_F(FlutterEngineTest, NativeCallbacks) {
  fml::AutoResetWaitableEvent latch;
  bool latch_called = false;
  AddNativeCallback("SignalNativeTest", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      latch_called = true;
                      latch.Signal();
                    }));

  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"nativeCallback"]);
  EXPECT_TRUE(engine.running);

  latch.Wait();
  ASSERT_TRUE(latch_called);
}

TEST(FlutterEngine, Compositor) {
  NSString* fixtures = @(flutter::testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:project];

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController loadView];
  viewController.flutterView.frame = CGRectMake(0, 0, 800, 600);

  EXPECT_TRUE([engine runWithEntrypoint:@"canCompositePlatformViews"]);

  [engine.platformViewController registerViewFactory:[[TestPlatformViewFactory alloc] init]
                                              withId:@"factory_id"];
  [engine.platformViewController
      handleMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                         arguments:@{
                                                           @"id" : @(42),
                                                           @"viewType" : @"factory_id",
                                                         }]
                result:^(id result){
                }];

  [viewController.flutterView.threadSynchronizer blockUntilFrameAvailable];

  CALayer* rootLayer = viewController.flutterView.layer;

  // There are two layers with Flutter contents and one view
  EXPECT_EQ(rootLayer.sublayers.count, 2u);
  EXPECT_EQ(viewController.flutterView.subviews.count, 1u);

  // TODO(gw280): add support for screenshot tests in this test harness

  [engine shutDownEngine];
}  // namespace flutter::testing

TEST(FlutterEngine, DartEntrypointArguments) {
  NSString* fixtures = @(flutter::testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];

  project.dartEntrypointArguments = @[ @"arg1", @"arg2" ];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:project];

  bool called = false;
  auto original_init = engine.embedderAPI.Initialize;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&called, &original_init](size_t version, const FlutterRendererConfig* config,
                                             const FlutterProjectArgs* args, void* user_data,
                                             FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
        called = true;
        EXPECT_EQ(args->dart_entrypoint_argc, 2);
        NSString* arg1 = [[NSString alloc] initWithCString:args->dart_entrypoint_argv[0]
                                                  encoding:NSUTF8StringEncoding];
        NSString* arg2 = [[NSString alloc] initWithCString:args->dart_entrypoint_argv[1]
                                                  encoding:NSUTF8StringEncoding];

        EXPECT_TRUE([arg1 isEqualToString:@"arg1"]);
        EXPECT_TRUE([arg2 isEqualToString:@"arg2"]);

        return original_init(version, config, args, user_data, engine_out);
      }));

  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  EXPECT_TRUE(called);
}

// If a channel overrides a previous channel with the same name, cleaning
// the previous channel should not affect the new channel.
//
// This is important when recreating classes that uses a channel, because the
// new instance would create the channel before the first class is deallocated
// and clears the channel.
TEST_F(FlutterEngineTest, MessengerCleanupConnectionWorks) {
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);

  NSString* channel = @"_test_";
  NSData* channel_data = [channel dataUsingEncoding:NSUTF8StringEncoding];

  // Mock SendPlatformMessage so that if a message is sent to
  // "test/send_message", act as if the framework has sent an empty message to
  // the channel marked by the `sendOnChannel:message:` call's message.
  engine.embedderAPI.SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([](auto engine_, auto message_) {
        if (strcmp(message_->channel, "test/send_message") == 0) {
          // The simplest message that is acceptable to a method channel.
          std::string message = R"|({"method": "a"})|";
          std::string channel(reinterpret_cast<const char*>(message_->message),
                              message_->message_size);
          reinterpret_cast<EmbedderEngine*>(engine_)
              ->GetShell()
              .GetPlatformView()
              ->HandlePlatformMessage(std::make_unique<PlatformMessage>(
                  channel.c_str(), fml::MallocMapping::Copy(message.c_str(), message.length()),
                  fml::RefPtr<PlatformMessageResponse>()));
        }
        return kSuccess;
      }));

  __block int record = 0;

  FlutterMethodChannel* channel1 =
      [FlutterMethodChannel methodChannelWithName:channel
                                  binaryMessenger:engine.binaryMessenger
                                            codec:[FlutterJSONMethodCodec sharedInstance]];
  [channel1 setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    record += 1;
  }];

  [engine.binaryMessenger sendOnChannel:@"test/send_message" message:channel_data];
  EXPECT_EQ(record, 1);

  FlutterMethodChannel* channel2 =
      [FlutterMethodChannel methodChannelWithName:channel
                                  binaryMessenger:engine.binaryMessenger
                                            codec:[FlutterJSONMethodCodec sharedInstance]];
  [channel2 setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    record += 10;
  }];

  [engine.binaryMessenger sendOnChannel:@"test/send_message" message:channel_data];
  EXPECT_EQ(record, 11);

  [channel1 setMethodCallHandler:nil];

  [engine.binaryMessenger sendOnChannel:@"test/send_message" message:channel_data];
  EXPECT_EQ(record, 21);
}

TEST(FlutterEngine, HasStringsWhenPasteboardEmpty) {
  id engineMock = CreateMockFlutterEngine(nil);

  // Call hasStrings and expect it to be false.
  __block bool calledAfterClear = false;
  __block bool valueAfterClear;
  FlutterResult resultAfterClear = ^(id result) {
    calledAfterClear = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    valueAfterClear = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCallAfterClear =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [engineMock handleMethodCall:methodCallAfterClear result:resultAfterClear];
  EXPECT_TRUE(calledAfterClear);
  EXPECT_FALSE(valueAfterClear);
}

TEST(FlutterEngine, HasStringsWhenPasteboardFull) {
  id engineMock = CreateMockFlutterEngine(@"some string");

  // Call hasStrings and expect it to be true.
  __block bool called = false;
  __block bool value;
  FlutterResult result = ^(id result) {
    called = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    value = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [engineMock handleMethodCall:methodCall result:result];
  EXPECT_TRUE(called);
  EXPECT_TRUE(value);
}

TEST_F(FlutterEngineTest, ResponseAfterEngineDied) {
  FlutterEngine* engine = GetFlutterEngine();
  FlutterBasicMessageChannel* channel = [[FlutterBasicMessageChannel alloc]
         initWithName:@"foo"
      binaryMessenger:engine.binaryMessenger
                codec:[FlutterStandardMessageCodec sharedInstance]];
  __block BOOL didCallCallback = NO;
  [channel setMessageHandler:^(id message, FlutterReply callback) {
    ShutDownEngine();
    callback(nil);
    didCallCallback = YES;
  }];
  EXPECT_TRUE([engine runWithEntrypoint:@"sendFooMessage"]);
  engine = nil;

  while (!didCallCallback) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
}

TEST_F(FlutterEngineTest, ResponseFromBackgroundThread) {
  FlutterEngine* engine = GetFlutterEngine();
  FlutterBasicMessageChannel* channel = [[FlutterBasicMessageChannel alloc]
         initWithName:@"foo"
      binaryMessenger:engine.binaryMessenger
                codec:[FlutterStandardMessageCodec sharedInstance]];
  __block BOOL didCallCallback = NO;
  [channel setMessageHandler:^(id message, FlutterReply callback) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      callback(nil);
      dispatch_async(dispatch_get_main_queue(), ^{
        didCallCallback = YES;
      });
    });
  }];
  EXPECT_TRUE([engine runWithEntrypoint:@"sendFooMessage"]);

  while (!didCallCallback) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
}

TEST(EngineTest, ThreadSynchronizerNotBlockingRasterThreadAfterShutdown) {
  FlutterThreadSynchronizer* threadSynchronizer = [[FlutterThreadSynchronizer alloc] init];
  [threadSynchronizer shutdown];

  std::thread rasterThread([&threadSynchronizer] {
    [threadSynchronizer performCommit:CGSizeMake(100, 100)
                               notify:^{
                               }];
  });

  rasterThread.join();
}

TEST_F(FlutterEngineTest, ManageControllersIfInitiatedByController) {
  NSString* fixtures = @(flutter::testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];

  FlutterEngine* engine;
  FlutterViewController* viewController1;

  @autoreleasepool {
    // Create FVC1.
    viewController1 = [[FlutterViewController alloc] initWithProject:project];
    EXPECT_EQ(viewController1.id, 0ull);

    engine = viewController1.engine;
    engine.viewController = nil;

    // Create FVC2 based on the same engine.
    FlutterViewController* viewController2 = [[FlutterViewController alloc] initWithEngine:engine
                                                                                   nibName:nil
                                                                                    bundle:nil];
    EXPECT_EQ(engine.viewController, viewController2);
  }
  // FVC2 is deallocated but FVC1 is retained.

  EXPECT_EQ(engine.viewController, nil);

  engine.viewController = viewController1;
  EXPECT_EQ(engine.viewController, viewController1);
  EXPECT_EQ(viewController1.id, 0ull);
}

TEST_F(FlutterEngineTest, ManageControllersIfInitiatedByEngine) {
  // Don't create the engine with `CreateMockFlutterEngine`, because it adds
  // additional references to FlutterViewControllers, which is crucial to this
  // test case.
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"io.flutter"
                                                      project:nil
                                       allowHeadlessExecution:NO];
  FlutterViewController* viewController1;

  @autoreleasepool {
    viewController1 = [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
    EXPECT_EQ(viewController1.id, 0ull);
    EXPECT_EQ(engine.viewController, viewController1);

    engine.viewController = nil;

    FlutterViewController* viewController2 = [[FlutterViewController alloc] initWithEngine:engine
                                                                                   nibName:nil
                                                                                    bundle:nil];
    EXPECT_EQ(viewController2.id, 0ull);
    EXPECT_EQ(engine.viewController, viewController2);
  }
  // FVC2 is deallocated but FVC1 is retained.

  EXPECT_EQ(engine.viewController, nil);

  engine.viewController = viewController1;
  EXPECT_EQ(engine.viewController, viewController1);
  EXPECT_EQ(viewController1.id, 0ull);
}

}  // namespace flutter::testing

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
