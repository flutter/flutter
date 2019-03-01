// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Allow access to fml::MessageLoop::GetCurrent() in order to flush platform
// thread tasks.
#define FML_USED_ON_EMBEDDER

#include <functional>
#include "embedder.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"
#include "flutter/testing/testing.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_library_natives.h"

#define REGISTER_FUNCTION(name, count) {"" #name, name, count, true},
#define DECLARE_FUNCTION(name, count) \
  extern void name(Dart_NativeArguments args);
#define BUILTIN_NATIVE_LIST(V) \
  V(SignalNativeTest, 0)       \
  V(NotifyTestData1, 1)        \
  V(NotifyTestData3, 3)

BUILTIN_NATIVE_LIST(DECLARE_FUNCTION);

static tonic::DartLibraryNatives* g_natives;

Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                      int argument_count,
                                      bool* auto_setup_scope) {
  return g_natives->GetNativeFunction(name, argument_count, auto_setup_scope);
}

const uint8_t* GetSymbol(Dart_NativeFunction native_function) {
  return g_natives->GetSymbol(native_function);
}

using OnTestDataCallback = std::function<void(Dart_NativeArguments)>;

fml::AutoResetWaitableEvent g_latch;
OnTestDataCallback g_test_data_callback = [](Dart_NativeArguments) {};

// Called by the Dart text fixture on the UI thread to signal that the C++
// unittest should resume.
void SignalNativeTest(Dart_NativeArguments args) {
  g_latch.Signal();
}

// Called by test fixture on UI thread to pass data back to this test.
// 1 parameter version.
void NotifyTestData1(Dart_NativeArguments args) {
  g_test_data_callback(args);
}

// Called by test fixture on UI thread to pass data back to this test.
// 3 parameter version.
void NotifyTestData3(Dart_NativeArguments args) {
  g_test_data_callback(args);
}

TEST(EmbedderTest, CanLaunchAndShutdownWithValidProjectArgs) {
  FlutterSoftwareRendererConfig renderer;
  renderer.struct_size = sizeof(FlutterSoftwareRendererConfig);
  renderer.surface_present_callback = [](void*, const void*, size_t, size_t) {
    return false;
  };

  FlutterRendererConfig config = {};
  config.type = FlutterRendererType::kSoftware;
  config.software = renderer;

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = testing::GetFixturesPath();

  // Register native functions to be called from test fixture.
  g_natives = new tonic::DartLibraryNatives();
  g_natives->Register({BUILTIN_NATIVE_LIST(REGISTER_FUNCTION)});
  args.root_isolate_create_callback = [](void*) {
    Dart_SetNativeResolver(Dart_RootLibrary(), GetNativeFunction, GetSymbol);
  };

  typedef struct {
    std::function<void(const FlutterSemanticsNode*)> on_semantics_update;
    std::function<void(const FlutterSemanticsCustomAction*)>
        on_custom_action_update;
  } TestData;
  auto test_data = TestData{};
  args.update_semantics_node_callback = [](const FlutterSemanticsNode* node,
                                           void* data) {
    auto test_data = reinterpret_cast<TestData*>(data);
    test_data->on_semantics_update(node);
  };
  args.update_semantics_custom_action_callback =
      [](const FlutterSemanticsCustomAction* action, void* data) {
        auto test_data = reinterpret_cast<TestData*>(data);
        test_data->on_custom_action_update(action);
      };

  // Start the engine, run text fixture.
  FlutterEngine engine = nullptr;
  FlutterEngineResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config,
                                                &args, &test_data, &engine);
  ASSERT_EQ(result, FlutterEngineResult::kSuccess);

  // Wait for initial NotifySemanticsEnabled(false).
  g_test_data_callback = [](Dart_NativeArguments args) {
    bool enabled;
    Dart_GetNativeBooleanArgument(args, 0, &enabled);
    ASSERT_FALSE(enabled);
    g_latch.Signal();
  };
  g_latch.Wait();

  // Enable semantics. Wait for NotifySemanticsEnabled(true).
  g_test_data_callback = [](Dart_NativeArguments args) {
    bool enabled;
    Dart_GetNativeBooleanArgument(args, 0, &enabled);
    ASSERT_TRUE(enabled);
    g_latch.Signal();
  };
  result = FlutterEngineUpdateSemanticsEnabled(engine, true);
  ASSERT_EQ(result, FlutterEngineResult::kSuccess);
  g_latch.Wait();

  // Wait for initial accessibility features (reduce_motion == false)
  g_test_data_callback = [](Dart_NativeArguments args) {
    bool enabled;
    Dart_GetNativeBooleanArgument(args, 0, &enabled);
    ASSERT_FALSE(enabled);
    g_latch.Signal();
  };
  g_latch.Wait();

  // Set accessibility features: (reduce_motion == true)
  g_test_data_callback = [](Dart_NativeArguments args) {
    bool enabled;
    Dart_GetNativeBooleanArgument(args, 0, &enabled);
    ASSERT_TRUE(enabled);
    g_latch.Signal();
  };
  result = FlutterEngineUpdateAccessibilityFeatures(
      engine, kFlutterAccessibilityFeatureReduceMotion);
  ASSERT_EQ(result, FlutterEngineResult::kSuccess);
  g_latch.Wait();

  // Wait for UpdateSemantics callback on platform (current) thread.
  int node_count = 0;
  int node_batch_end_count = 0;
  test_data.on_semantics_update =
      [&node_count, &node_batch_end_count](const FlutterSemanticsNode* node) {
        if (node->id == kFlutterSemanticsNodeIdBatchEnd) {
          ++node_batch_end_count;
        } else {
          ++node_count;
          ASSERT_EQ(1.0, node->transform.scaleX);
          ASSERT_EQ(2.0, node->transform.skewX);
          ASSERT_EQ(3.0, node->transform.transX);
          ASSERT_EQ(4.0, node->transform.skewY);
          ASSERT_EQ(5.0, node->transform.scaleY);
          ASSERT_EQ(6.0, node->transform.transY);
          ASSERT_EQ(7.0, node->transform.pers0);
          ASSERT_EQ(8.0, node->transform.pers1);
          ASSERT_EQ(9.0, node->transform.pers2);
        }
      };
  int action_count = 0;
  int action_batch_end_count = 0;
  test_data.on_custom_action_update =
      [&action_count,
       &action_batch_end_count](const FlutterSemanticsCustomAction* action) {
        if (action->id == kFlutterSemanticsCustomActionIdBatchEnd) {
          ++action_batch_end_count;
        } else {
          ++action_count;
        }
      };
  g_latch.Wait();
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  ASSERT_EQ(4, node_count);
  ASSERT_EQ(1, node_batch_end_count);
  ASSERT_EQ(1, action_count);
  ASSERT_EQ(1, action_batch_end_count);

  // Dispatch a tap to semantics node 42. Wait for NotifySemanticsAction.
  g_test_data_callback = [](Dart_NativeArguments args) {
    int64_t node_id;
    Dart_GetNativeIntegerArgument(args, 0, &node_id);
    ASSERT_EQ(42, node_id);

    int64_t action_id;
    Dart_GetNativeIntegerArgument(args, 1, &action_id);
    ASSERT_EQ(static_cast<int32_t>(blink::SemanticsAction::kTap), action_id);

    Dart_Handle semantic_args = Dart_GetNativeArgument(args, 2);
    int64_t data;
    Dart_Handle dart_int = Dart_ListGetAt(semantic_args, 0);
    Dart_IntegerToInt64(dart_int, &data);
    ASSERT_EQ(2, data);

    dart_int = Dart_ListGetAt(semantic_args, 1);
    Dart_IntegerToInt64(dart_int, &data);
    ASSERT_EQ(1, data);
    g_latch.Signal();
  };
  std::vector<uint8_t> bytes({2, 1});
  result = FlutterEngineDispatchSemanticsAction(
      engine, 42, kFlutterSemanticsActionTap, &bytes[0], bytes.size());
  g_latch.Wait();

  // Disable semantics. Wait for NotifySemanticsEnabled(false).
  g_test_data_callback = [](Dart_NativeArguments args) {
    bool enabled;
    Dart_GetNativeBooleanArgument(args, 0, &enabled);
    ASSERT_FALSE(enabled);
    g_latch.Signal();
  };
  result = FlutterEngineUpdateSemanticsEnabled(engine, false);
  ASSERT_EQ(result, FlutterEngineResult::kSuccess);
  g_latch.Wait();

  result = FlutterEngineShutdown(engine);
  ASSERT_EQ(result, FlutterEngineResult::kSuccess);
}
