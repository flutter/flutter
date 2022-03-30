// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_encoding.h"
#include "flutter/lib/ui/painting/image_encoding_impl.h"

#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"

// CREATE_NATIVE_ENTRY is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

namespace flutter {
namespace testing {

namespace {
fml::AutoResetWaitableEvent message_latch;
};

class MockSyncSwitch {
 public:
  struct Handlers {
    Handlers& SetIfTrue(const std::function<void()>& handler) {
      true_handler = std::move(handler);
      return *this;
    }
    Handlers& SetIfFalse(const std::function<void()>& handler) {
      false_handler = std::move(handler);
      return *this;
    }
    std::function<void()> true_handler = [] {};
    std::function<void()> false_handler = [] {};
  };

  MOCK_CONST_METHOD1(Execute, void(const Handlers& handlers));
  MOCK_METHOD1(SetSwitch, void(bool value));
};

TEST_F(ShellTest, EncodeImageGivesExternalTypedData) {
  auto native_encode_image = [&](Dart_NativeArguments args) {
    auto image_handle = Dart_GetNativeArgument(args, 0);
    image_handle =
        Dart_GetField(image_handle, Dart_NewStringFromCString("_image"));
    ASSERT_FALSE(Dart_IsError(image_handle)) << Dart_GetError(image_handle);
    ASSERT_FALSE(Dart_IsNull(image_handle));
    auto format_handle = Dart_GetNativeArgument(args, 1);
    auto callback_handle = Dart_GetNativeArgument(args, 2);

    intptr_t peer = 0;
    Dart_Handle result = Dart_GetNativeInstanceField(
        image_handle, tonic::DartWrappable::kPeerIndex, &peer);
    ASSERT_FALSE(Dart_IsError(result));
    CanvasImage* canvas_image = reinterpret_cast<CanvasImage*>(peer);

    int64_t format = -1;
    result = Dart_IntegerToInt64(format_handle, &format);
    ASSERT_FALSE(Dart_IsError(result));

    result = EncodeImage(canvas_image, format, callback_handle);
    ASSERT_TRUE(Dart_IsNull(result));
  };

  auto nativeValidateExternal = [&](Dart_NativeArguments args) {
    auto handle = Dart_GetNativeArgument(args, 0);

    auto typed_data_type = Dart_GetTypeOfExternalTypedData(handle);
    EXPECT_EQ(typed_data_type, Dart_TypedData_kUint8);

    message_latch.Signal();
  };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("EncodeImage", CREATE_NATIVE_ENTRY(native_encode_image));
  AddNativeCallback("ValidateExternal",
                    CREATE_NATIVE_ENTRY(nativeValidateExternal));

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("encodeImageProducesExternalUint8List");

  shell->RunEngine(std::move(configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch.Wait();
  DestroyShell(std::move(shell), std::move(task_runners));
}

TEST_F(ShellTest, EncodeImageAccessesSyncSwitch) {
  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  auto native_encode_image = [&](Dart_NativeArguments args) {
    auto image_handle = Dart_GetNativeArgument(args, 0);
    image_handle =
        Dart_GetField(image_handle, Dart_NewStringFromCString("_image"));
    ASSERT_FALSE(Dart_IsError(image_handle)) << Dart_GetError(image_handle);
    ASSERT_FALSE(Dart_IsNull(image_handle));
    auto format_handle = Dart_GetNativeArgument(args, 1);

    intptr_t peer = 0;
    Dart_Handle result = Dart_GetNativeInstanceField(
        image_handle, tonic::DartWrappable::kPeerIndex, &peer);
    ASSERT_FALSE(Dart_IsError(result));
    CanvasImage* canvas_image = reinterpret_cast<CanvasImage*>(peer);

    int64_t format = -1;
    result = Dart_IntegerToInt64(format_handle, &format);
    ASSERT_FALSE(Dart_IsError(result));

    auto io_manager = UIDartState::Current()->GetIOManager();
    fml::AutoResetWaitableEvent latch;

    task_runners.GetIOTaskRunner()->PostTask([&]() {
      auto is_gpu_disabled_sync_switch =
          std::make_shared<const MockSyncSwitch>();
      EXPECT_CALL(*is_gpu_disabled_sync_switch, Execute)
          .WillOnce([](const MockSyncSwitch::Handlers& handlers) {
            handlers.true_handler();
          });
      ConvertToRasterUsingResourceContext(canvas_image->image()->skia_image(),
                                          io_manager->GetResourceContext(),
                                          is_gpu_disabled_sync_switch);
      latch.Signal();
    });

    latch.Wait();

    message_latch.Signal();
  };

  AddNativeCallback("EncodeImage", CREATE_NATIVE_ENTRY(native_encode_image));

  std::unique_ptr<Shell> shell =
      CreateShell(std::move(settings), std::move(task_runners));

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("encodeImageProducesExternalUint8List");

  shell->RunEngine(std::move(configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch.Wait();
  DestroyShell(std::move(shell), std::move(task_runners));
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
