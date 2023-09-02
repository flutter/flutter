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
#include "gtest/gtest.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/lib/ui/painting/image_encoding_impeller.h"
#include "impeller/renderer/testing/mocks.h"
#endif  // IMPELLER_SUPPORTS_RENDERING

// CREATE_NATIVE_ENTRY is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

namespace flutter {
namespace testing {

namespace {
fml::AutoResetWaitableEvent message_latch;

class MockDlImage : public DlImage {
 public:
  MOCK_METHOD(sk_sp<SkImage>, skia_image, (), (const, override));
  MOCK_METHOD(std::shared_ptr<impeller::Texture>,
              impeller_texture,
              (),
              (const, override));
  MOCK_METHOD(bool, isOpaque, (), (const, override));
  MOCK_METHOD(bool, isTextureBacked, (), (const, override));
  MOCK_METHOD(bool, isUIThreadSafe, (), (const, override));
  MOCK_METHOD(SkISize, dimensions, (), (const, override));
  MOCK_METHOD(size_t, GetApproximateByteSize, (), (const, override));
};

}  // namespace

class MockSyncSwitch {
 public:
  struct Handlers {
    Handlers& SetIfTrue(const std::function<void()>& handler) {
      true_handler = handler;
      return *this;
    }
    Handlers& SetIfFalse(const std::function<void()>& handler) {
      false_handler = handler;
      return *this;
    }
    std::function<void()> true_handler = [] {};
    std::function<void()> false_handler = [] {};
  };

  MOCK_METHOD(void, Execute, (const Handlers& handlers), (const));
  MOCK_METHOD(void, SetSwitch, (bool value));
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

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("encodeImageProducesExternalUint8List");

  shell->RunEngine(std::move(configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch.Wait();
  DestroyShell(std::move(shell), task_runners);
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

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("encodeImageProducesExternalUint8List");

  shell->RunEngine(std::move(configuration), [&](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch.Wait();
  DestroyShell(std::move(shell), task_runners);
}

#if IMPELLER_SUPPORTS_RENDERING
using ::impeller::testing::MockAllocator;
using ::impeller::testing::MockBlitPass;
using ::impeller::testing::MockCommandBuffer;
using ::impeller::testing::MockDeviceBuffer;
using ::impeller::testing::MockImpellerContext;
using ::impeller::testing::MockTexture;
using ::testing::_;
using ::testing::DoAll;
using ::testing::InvokeArgument;
using ::testing::Return;

namespace {
std::shared_ptr<impeller::Context> MakeConvertDlImageToSkImageContext(
    std::vector<uint8_t>& buffer) {
  auto context = std::make_shared<MockImpellerContext>();
  auto command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto allocator = std::make_shared<MockAllocator>();
  auto blit_pass = std::make_shared<MockBlitPass>();
  impeller::DeviceBufferDescriptor device_buffer_desc;
  device_buffer_desc.size = buffer.size();
  auto device_buffer = std::make_shared<MockDeviceBuffer>(device_buffer_desc);
  EXPECT_CALL(*allocator, OnCreateBuffer).WillOnce(Return(device_buffer));
  EXPECT_CALL(*blit_pass, IsValid).WillRepeatedly(Return(true));
  EXPECT_CALL(*command_buffer, IsValid).WillRepeatedly(Return(true));
  EXPECT_CALL(*command_buffer, OnCreateBlitPass).WillOnce(Return(blit_pass));
  EXPECT_CALL(*command_buffer, OnSubmitCommands(_))
      .WillOnce(
          DoAll(InvokeArgument<0>(impeller::CommandBuffer::Status::kCompleted),
                Return(true)));
  EXPECT_CALL(*context, GetResourceAllocator).WillRepeatedly(Return(allocator));
  EXPECT_CALL(*context, CreateCommandBuffer).WillOnce(Return(command_buffer));
  EXPECT_CALL(*device_buffer, OnGetContents).WillOnce(Return(buffer.data()));
  return context;
}
}  // namespace

TEST(ImageEncodingImpellerTest, ConvertDlImageToSkImage16Float) {
  sk_sp<MockDlImage> image(new MockDlImage());
  EXPECT_CALL(*image, dimensions)
      .WillRepeatedly(Return(SkISize::Make(100, 100)));
  impeller::TextureDescriptor desc;
  desc.format = impeller::PixelFormat::kR16G16B16A16Float;
  auto texture = std::make_shared<MockTexture>(desc);
  EXPECT_CALL(*image, impeller_texture).WillOnce(Return(texture));
  std::vector<uint8_t> buffer;
  buffer.reserve(100 * 100 * 8);
  auto context = MakeConvertDlImageToSkImageContext(buffer);
  bool did_call = false;
  ImageEncodingImpeller::ConvertDlImageToSkImage(
      image,
      [&did_call](const sk_sp<SkImage>& image) {
        did_call = true;
        ASSERT_TRUE(image);
        EXPECT_EQ(100, image->width());
        EXPECT_EQ(100, image->height());
        EXPECT_EQ(kRGBA_F16_SkColorType, image->colorType());
        EXPECT_EQ(nullptr, image->colorSpace());
      },
      context);
  EXPECT_TRUE(did_call);
}

TEST(ImageEncodingImpellerTest, ConvertDlImageToSkImage10XR) {
  sk_sp<MockDlImage> image(new MockDlImage());
  EXPECT_CALL(*image, dimensions)
      .WillRepeatedly(Return(SkISize::Make(100, 100)));
  impeller::TextureDescriptor desc;
  desc.format = impeller::PixelFormat::kB10G10R10XR;
  auto texture = std::make_shared<MockTexture>(desc);
  EXPECT_CALL(*image, impeller_texture).WillOnce(Return(texture));
  std::vector<uint8_t> buffer;
  buffer.reserve(100 * 100 * 4);
  auto context = MakeConvertDlImageToSkImageContext(buffer);
  bool did_call = false;
  ImageEncodingImpeller::ConvertDlImageToSkImage(
      image,
      [&did_call](const sk_sp<SkImage>& image) {
        did_call = true;
        ASSERT_TRUE(image);
        EXPECT_EQ(100, image->width());
        EXPECT_EQ(100, image->height());
        EXPECT_EQ(kBGR_101010x_XR_SkColorType, image->colorType());
        EXPECT_EQ(nullptr, image->colorSpace());
      },
      context);
  EXPECT_TRUE(did_call);
}
#endif  // IMPELLER_SUPPORTS_RENDERING

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
