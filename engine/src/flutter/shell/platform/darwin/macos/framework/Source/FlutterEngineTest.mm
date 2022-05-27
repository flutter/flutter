// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"

#include <functional>

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
 * The FlutterCompositor object currently in use by the FlutterEngine. This is
 * either a FlutterOpenGLCompositor or a FlutterMetalCompositor.
 *
 * May be nil if the compositor has not been initialized yet.
 */
@property(nonatomic, readonly, nullable) flutter::FlutterCompositor* macOSCompositor;
@end

namespace flutter::testing {

TEST_F(FlutterEngineTest, CanLaunch) {
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  EXPECT_TRUE(engine.running);
}

TEST_F(FlutterEngineTest, HasNonNullExecutableName) {
  // Launch the test entrypoint.
  FlutterEngine* engine = GetFlutterEngine();
  std::string executable_name = [[engine executableName] UTF8String];
  ASSERT_FALSE(executable_name.empty());
  EXPECT_TRUE([engine runWithEntrypoint:@"executableNameNotNull"]);

  // Block until notified by the Dart test of the value of Platform.executable.
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("NotifyStringValue", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      const auto dart_string = tonic::DartConverter<std::string>::FromDart(
                          Dart_GetNativeArgument(args, 0));
                      EXPECT_EQ(executable_name, dart_string);
                      latch.Signal();
                    }));
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
  // Replace stdout stream buffer with our own.
  std::stringstream buffer;
  std::streambuf* old_buffer = std::cout.rdbuf();
  std::cout.rdbuf(buffer.rdbuf());

  // Launch the test entrypoint.
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"canLogToStdout"]);
  EXPECT_TRUE(engine.running);

  // Block until completion of print statement.
  fml::AutoResetWaitableEvent latch;
  AddNativeCallback("SignalNativeTest",
                    CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) { latch.Signal(); }));
  latch.Wait();

  // Restore old stdout stream buffer.
  std::cout.rdbuf(old_buffer);

  // Verify hello world was written to stdout.
  std::string logs = buffer.str();
  EXPECT_TRUE(logs.find("Hello logging") != std::string::npos);
}

TEST_F(FlutterEngineTest, CanToggleAccessibility) {
  FlutterEngine* engine = GetFlutterEngine();
  // Capture the update callbacks before the embedder API initializes.
  auto original_init = engine.embedderAPI.Initialize;
  std::function<void(const FlutterSemanticsNode*, void*)> update_node_callback;
  std::function<void(const FlutterSemanticsCustomAction*, void*)> update_action_callback;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&update_action_callback, &update_node_callback, &original_init](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data, auto engine_out) {
        update_node_callback = args->update_semantics_node_callback;
        update_action_callback = args->update_semantics_custom_action_callback;
        return original_init(version, config, args, user_data, engine_out);
      }));
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  // Set up view controller.
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];
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
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  update_node_callback(&root, (void*)CFBridgingRetain(engine));

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
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  update_node_callback(&child1, (void*)CFBridgingRetain(engine));

  FlutterSemanticsNode node_batch_end;
  node_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_node_callback(&node_batch_end, (void*)CFBridgingRetain(engine));

  FlutterSemanticsCustomAction action_batch_end;
  action_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_action_callback(&action_batch_end, (void*)CFBridgingRetain(engine));

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
  std::function<void(const FlutterSemanticsNode*, void*)> update_node_callback;
  std::function<void(const FlutterSemanticsCustomAction*, void*)> update_action_callback;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&update_action_callback, &update_node_callback, &original_init](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data, auto engine_out) {
        update_node_callback = args->update_semantics_node_callback;
        update_action_callback = args->update_semantics_custom_action_callback;
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
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  update_node_callback(&root, (void*)CFBridgingRetain(engine));

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
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  update_node_callback(&child1, (void*)CFBridgingRetain(engine));

  FlutterSemanticsNode node_batch_end;
  node_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_node_callback(&node_batch_end, (void*)CFBridgingRetain(engine));

  FlutterSemanticsCustomAction action_batch_end;
  action_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_action_callback(&action_batch_end, (void*)CFBridgingRetain(engine));

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

TEST_F(FlutterEngineTest, ResetsAccessibilityBridgeWhenSetsNewViewController) {
  FlutterEngine* engine = GetFlutterEngine();
  // Capture the update callbacks before the embedder API initializes.
  auto original_init = engine.embedderAPI.Initialize;
  std::function<void(const FlutterSemanticsNode*, void*)> update_node_callback;
  std::function<void(const FlutterSemanticsCustomAction*, void*)> update_action_callback;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&update_action_callback, &update_node_callback, &original_init](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data, auto engine_out) {
        update_node_callback = args->update_semantics_node_callback;
        update_action_callback = args->update_semantics_custom_action_callback;
        return original_init(version, config, args, user_data, engine_out);
      }));
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  // Set up view controller.
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];
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
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  update_node_callback(&root, (void*)CFBridgingRetain(engine));

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
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  update_node_callback(&child1, (void*)CFBridgingRetain(engine));

  FlutterSemanticsNode node_batch_end;
  node_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_node_callback(&node_batch_end, (void*)CFBridgingRetain(engine));

  FlutterSemanticsCustomAction action_batch_end;
  action_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_action_callback(&action_batch_end, (void*)CFBridgingRetain(engine));

  auto native_root = engine.accessibilityBridge.lock()->GetFlutterPlatformNodeDelegateFromID(0);
  EXPECT_FALSE(native_root.expired());

  // Set up a new view controller.
  FlutterViewController* newViewController =
      [[FlutterViewController alloc] initWithProject:project];
  [newViewController loadView];
  [engine setViewController:newViewController];

  auto new_native_root = engine.accessibilityBridge.lock()->GetFlutterPlatformNodeDelegateFromID(0);
  // The tree is recreated and the old tree will be destroyed.
  EXPECT_FALSE(new_native_root.expired());
  EXPECT_TRUE(native_root.expired());

  [engine setViewController:nil];
}

TEST_F(FlutterEngineTest, NativeCallbacks) {
  FlutterEngine* engine = GetFlutterEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"nativeCallback"]);
  EXPECT_TRUE(engine.running);

  fml::AutoResetWaitableEvent latch;
  bool latch_called = false;

  AddNativeCallback("SignalNativeTest", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
                      latch_called = true;
                      latch.Signal();
                    }));
  latch.Wait();
  ASSERT_TRUE(latch_called);
}

// TODO(iskakaushik): Enable after https://github.com/flutter/flutter/issues/96668 is fixed.
TEST(FlutterEngine, DISABLED_Compositor) {
  NSString* fixtures = @(flutter::testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:project];

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  viewController.flutterView.frame = CGRectMake(0, 0, 800, 600);
  [engine setViewController:viewController];

  EXPECT_TRUE([engine runWithEntrypoint:@"canCompositePlatformViews"]);

  // Latch to ensure the entire layer tree has been generated and presented.
  fml::AutoResetWaitableEvent latch;
  auto compositor = engine.macOSCompositor;
  compositor->SetPresentCallback([&](bool has_flutter_content) {
    latch.Signal();
    return true;
  });
  latch.Wait();

  CALayer* rootLayer = viewController.flutterView.layer;

  // There are three layers total - the root layer and two sublayers.
  // This test will need to be updated when PlatformViews are supported, as
  // there are two PlatformView layers in this test.
  EXPECT_EQ(rootLayer.sublayers.count, 2u);

  // TODO(gw280): add support for screenshot tests in this test harness

  [engine shutDownEngine];
}

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

}  // namespace flutter::testing

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
