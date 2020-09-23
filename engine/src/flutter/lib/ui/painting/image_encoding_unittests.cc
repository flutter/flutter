// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_encoding.h"

#include "flutter/common/task_runners.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

namespace {
fml::AutoResetWaitableEvent message_latch;
};

TEST_F(ShellTest, EncodeImageGivesExternalTypedData) {
  auto nativeEncodeImage = [&](Dart_NativeArguments args) {
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

  AddNativeCallback("EncodeImage", CREATE_NATIVE_ENTRY(nativeEncodeImage));
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

}  // namespace testing
}  // namespace flutter
