// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoder_no_gl_unittests.h"
#include <memory>
#include <utility>
#include <vector>

#include "flutter/fml/endianness.h"
#include "impeller/renderer/capabilities.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/renderer/command_buffer_scheduling_receipt.h"
#include "impeller/renderer/testing/mocks.h"
#endif  // IMPELLER_SUPPORTS_RENDERING

#include "include/core/SkColorType.h"
#include "third_party/skia/include/codec/SkPngDecoder.h"

namespace flutter {
namespace testing {

// Tests are disabled for fuchsia.
#if defined(OS_FUCHSIA)
#pragma GCC diagnostic ignored "-Wunreachable-code"
#endif

namespace {

bool IsPngWithPLTE(const uint8_t* bytes, size_t size) {
  constexpr std::string_view kPngMagic = "\x89PNG\x0d\x0a\x1a\x0a";
  constexpr std::string_view kPngPlte = "PLTE";
  constexpr uint32_t kLengthBytes = 4;
  constexpr uint32_t kTypeBytes = 4;
  constexpr uint32_t kCrcBytes = 4;

  if (size < kPngMagic.size()) {
    return false;
  }

  if (memcmp(bytes, kPngMagic.data(), kPngMagic.size()) != 0) {
    return false;
  }

  const uint8_t* end = bytes + size;
  const uint8_t* loc = bytes + kPngMagic.size();
  while (loc + kLengthBytes + kTypeBytes <= end) {
    uint32_t chunk_length =
        fml::BigEndianToArch(*reinterpret_cast<const uint32_t*>(loc));

    if (memcmp(loc + kLengthBytes, kPngPlte.data(), kPngPlte.size()) == 0) {
      return true;
    }

    loc += kLengthBytes + kTypeBytes + chunk_length + kCrcBytes;
  }

  return false;
}

}  // namespace

float HalfToFloat(uint16_t half) {
  switch (half) {
    case 0x7c00:
      return std::numeric_limits<float>::infinity();
    case 0xfc00:
      return -std::numeric_limits<float>::infinity();
  }
  bool negative = half >> 15;
  uint16_t exponent = (half >> 10) & 0x1f;
  uint16_t fraction = half & 0x3ff;
  float fExponent = exponent - 15.0f;
  float fFraction = static_cast<float>(fraction) / 1024.f;
  float pow_value = powf(2.0f, fExponent);
  return (negative ? -1.f : 1.f) * pow_value * (1.0f + fFraction);
}

float DecodeBGR10(uint32_t x) {
  const float max = 1.25098f;
  const float min = -0.752941f;
  const float intercept = min;
  const float slope = (max - min) / 1024.0f;
  return (x * slope) + intercept;
}

SkBitmap MakeThinStripesBitmap(int size) {
  SkBitmap bitmap;
  bitmap.allocPixels(SkImageInfo::Make(size, size, kRGBA_8888_SkColorType,
                                       kOpaque_SkAlphaType));
  bitmap.eraseColor(SK_ColorBLACK);
  for (int x = 1; x < size; x += 2) {
    bitmap.erase(SK_ColorWHITE, SkIRect::MakeXYWH(x, 0, 1, size));
  }
  return bitmap;
}

TEST(ImageDecoderNoGLTest, ImpellerUploadTracksSchedulingReceipt) {
#if !IMPELLER_SUPPORTS_RENDERING
  GTEST_SKIP() << "Test only supported with Impeller rendering.";
#else
  using ::impeller::testing::MockBlitPass;
  using ::impeller::testing::MockCommandBuffer;
  using ::impeller::testing::MockCommandQueue;
  using ::impeller::testing::MockImpellerContext;
  using ::testing::_;
  using ::testing::Return;

  auto context = std::make_shared<MockImpellerContext>();
  auto allocator = std::make_shared<impeller::TestImpellerAllocator>();
  auto command_buffer = std::make_shared<MockCommandBuffer>(context);
  const std::shared_ptr<impeller::CommandBuffer> submitted_command_buffer =
      command_buffer;
  auto blit_pass = std::make_shared<MockBlitPass>();
  auto command_queue = std::make_shared<MockCommandQueue>();
  std::shared_ptr<impeller::CommandBufferSchedulingReceipt> receipt =
      std::make_shared<impeller::CommandBufferSchedulingReceiptState>();

  EXPECT_CALL(*context, GetResourceAllocator).WillOnce(Return(allocator));
  EXPECT_CALL(*context, CreateCommandBuffer).WillOnce(Return(command_buffer));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*context, TrackPendingImageUpload(receipt));
  EXPECT_CALL(*command_buffer, SetLabel(_));
  EXPECT_CALL(*command_buffer, OnCreateBlitPass).WillOnce(Return(blit_pass));
  EXPECT_CALL(*command_buffer, OnWaitUntilCompleted);
  EXPECT_CALL(*blit_pass, IsValid).WillOnce(Return(true));
  EXPECT_CALL(*blit_pass, OnSetLabel(_)).Times(2);
  EXPECT_CALL(*blit_pass, OnCopyBufferToTextureCommand(_, _, _, _, _, _, _))
      .WillOnce(Return(true));
  EXPECT_CALL(*blit_pass, EncodeCommands).WillOnce(Return(true));
  EXPECT_CALL(*command_queue, SubmitWithReceipt(submitted_command_buffer, _))
      .WillOnce([receipt](const std::shared_ptr<impeller::CommandBuffer>&,
                          const impeller::CommandQueue::CompletionCallback&) {
        return impeller::CommandQueue::SubmitResult{
            .status = absl::OkStatus(),
            .scheduling_receipt = receipt,
        };
      });

  impeller::DeviceBufferDescriptor buffer_descriptor;
  buffer_descriptor.size = 4u;
  auto buffer =
      std::make_shared<impeller::TestImpellerDeviceBuffer>(buffer_descriptor);
  auto gpu_disabled_switch = std::make_shared<fml::SyncSwitch>(false);
  sk_sp<DlImage> image;
  std::string decode_error;
  bool callback_called = false;

  ImageDecoderImpeller::UploadTextureToPrivate(
      [&](const sk_sp<DlImage>& result, const std::string& error) {
        image = result;
        decode_error = error;
        callback_called = true;
      },
      context, buffer,
      {.size = impeller::ISize(1, 1),
       .format = impeller::PixelFormat::kR8G8B8A8UNormInt},
      std::nullopt, gpu_disabled_switch);

  EXPECT_TRUE(callback_called);
  EXPECT_NE(image, nullptr);
  EXPECT_TRUE(decode_error.empty());
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerWideGamutDisplayP3) {
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Fuchsia can't load the test fixtures.";
#endif
  SkCodecs::Register(SkPngDecoder::Decoder());
  auto data = flutter::testing::OpenFixtureAsSkData("DisplayP3Logo.png");
  auto image = SkImages::DeferredFromEncodedData(data);
  std::shared_ptr<impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetSupportsTextureToTextureBlits(true)
          .Build();
  ASSERT_TRUE(image != nullptr);
  ASSERT_EQ(SkISize::Make(100, 100), image->dimensions());

  ImageGeneratorRegistry registry;
  std::shared_ptr<ImageGenerator> generator =
      registry.CreateCompatibleGenerator(data);
  ASSERT_TRUE(generator);

  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(std::move(data),
                                                         std::move(generator));

  ASSERT_FALSE(
      IsPngWithPLTE(descriptor->data()->bytes(), descriptor->data()->size()));

#if IMPELLER_SUPPORTS_RENDERING
  std::shared_ptr<impeller::Allocator> allocator =
      std::make_shared<impeller::TestImpellerAllocator>();
  absl::StatusOr<ImageDecoderImpeller::DecompressResult> wide_result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(), {.target_width = 100, .target_height = 100},
          {100, 100},
          /*supports_wide_gamut=*/true, capabilities, allocator);
  ASSERT_TRUE(wide_result.ok());
  ASSERT_EQ(wide_result->image_info.format,
            impeller::PixelFormat::kR16G16B16A16Float);

  const uint16_t* half_ptr = reinterpret_cast<const uint16_t*>(
      wide_result->device_buffer->OnGetContents());
  bool found_deep_red = false;
  for (int i = 0; i < wide_result->image_info.size.width *
                          wide_result->image_info.size.height;
       ++i) {
    float red = HalfToFloat(*half_ptr++);
    float green = HalfToFloat(*half_ptr++);
    float blue = HalfToFloat(*half_ptr++);
    half_ptr++;  // alpha
    if (fabsf(red - 1.0931f) < 0.01f && fabsf(green - -0.2268f) < 0.01f &&
        fabsf(blue - -0.1501f) < 0.01f) {
      found_deep_red = true;
      break;
    }
  }

  ASSERT_TRUE(found_deep_red);
  absl::StatusOr<ImageDecoderImpeller::DecompressResult> narrow_result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(), {.target_width = 100, .target_height = 100},
          {100, 100},
          /*supports_wide_gamut=*/false, capabilities, allocator);

  ASSERT_TRUE(narrow_result.ok());
  ASSERT_EQ(narrow_result->image_info.format,
            impeller::PixelFormat::kR8G8B8A8UNormInt);
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerWideGamutIndexedPng) {
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Fuchsia can't load the test fixtures.";
#endif
  SkCodecs::Register(SkPngDecoder::Decoder());
  auto data = flutter::testing::OpenFixtureAsSkData("WideGamutIndexed.png");
  auto image = SkImages::DeferredFromEncodedData(data);
  std::shared_ptr<impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetSupportsTextureToTextureBlits(true)
          .Build();
  ASSERT_TRUE(image != nullptr);
  ASSERT_EQ(SkISize::Make(100, 100), image->dimensions());

  ImageGeneratorRegistry registry;
  std::shared_ptr<ImageGenerator> generator =
      registry.CreateCompatibleGenerator(data);
  ASSERT_TRUE(generator);

  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(std::move(data),
                                                         std::move(generator));

  ASSERT_TRUE(
      IsPngWithPLTE(descriptor->data()->bytes(), descriptor->data()->size()));

#if IMPELLER_SUPPORTS_RENDERING
  std::shared_ptr<impeller::Allocator> allocator =
      std::make_shared<impeller::TestImpellerAllocator>();
  absl::StatusOr<ImageDecoderImpeller::DecompressResult> wide_result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(), {.target_width = 100, .target_height = 100},
          {100, 100},
          /*supports_wide_gamut=*/true, capabilities, allocator);
  ASSERT_TRUE(wide_result.ok());
  ASSERT_EQ(wide_result->image_info.format,
            impeller::PixelFormat::kB10G10R10XR);

  const uint32_t* pixel_ptr = reinterpret_cast<const uint32_t*>(
      wide_result->device_buffer->OnGetContents());
  bool found_deep_red = false;
  for (int i = 0; i < wide_result->image_info.size.width *
                          wide_result->image_info.size.height;
       ++i) {
    uint32_t pixel = *pixel_ptr++;
    float blue = DecodeBGR10((pixel >> 0) & 0x3ff);
    float green = DecodeBGR10((pixel >> 10) & 0x3ff);
    float red = DecodeBGR10((pixel >> 20) & 0x3ff);
    if (fabsf(red - 1.0931f) < 0.01f && fabsf(green - -0.2268f) < 0.01f &&
        fabsf(blue - -0.1501f) < 0.01f) {
      found_deep_red = true;
      break;
    }
  }

  ASSERT_TRUE(found_deep_red);
  absl::StatusOr<ImageDecoderImpeller::DecompressResult> narrow_result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(), {.target_width = 100, .target_height = 100},
          {100, 100},
          /*supports_wide_gamut=*/false, capabilities, allocator);

  ASSERT_TRUE(narrow_result.ok());
  ASSERT_EQ(narrow_result->image_info.format,
            impeller::PixelFormat::kR8G8B8A8UNormInt);
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerRGBA32FDecode) {
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Fuchsia can't load the test fixtures.";
#endif

#if IMPELLER_SUPPORTS_RENDERING
  // 1. Create a 1x1 pixel with float RGBA values.
  float pixel_data[] = {1.0f, 0.5f, 0.25f, 1.0f};  // R, G, B, A
  sk_sp<SkData> sk_data = SkData::MakeWithCopy(pixel_data, sizeof(pixel_data));
  auto immutable_buffer =
      fml::MakeRefCounted<ImmutableBuffer>(std::move(sk_data));

  // 2. Create an ImageDescriptor using the private constructor.
  ImageDescriptor::ImageInfo image_info = {
      .width = 1,
      .height = 1,
      .format = ImageDescriptor::PixelFormat::kRGBAFloat32,
      .alpha_type = kUnpremul_SkAlphaType,
  };
  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(
      immutable_buffer->data(), image_info, sizeof(pixel_data));

  // Set up Impeller capabilities and allocator.
  std::shared_ptr<impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetSupportsTextureToTextureBlits(true)
          .Build();
  std::shared_ptr<impeller::Allocator> allocator =
      std::make_shared<impeller::TestImpellerAllocator>();

  // 3. Call ImageDecoderImpeller::DecompressTexture with this ImageDescriptor.
  absl::StatusOr<ImageDecoderImpeller::DecompressResult> result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(),
          /*options=*/
          {.target_width = 1,
           .target_height = 1,
           .target_format =
               ImageDecoder::TargetPixelFormat::kR32G32B32A32Float},
          /*max_texture_size=*/{1, 1},
          /*supports_wide_gamut=*/true, capabilities, allocator);

  // 4. Assert that wide_result->image_info.format is
  // impeller::PixelFormat::kR32G32B32A32Float.
  ASSERT_TRUE(result.ok());
  ASSERT_EQ(result->image_info.format,
            impeller::PixelFormat::kR32G32B32A32Float);

  // Optionally, verify the pixel data if needed.
  const float* decompressed_pixel_ptr =
      reinterpret_cast<const float*>(result->device_buffer->OnGetContents());
  ASSERT_NE(decompressed_pixel_ptr, nullptr);
  EXPECT_EQ(decompressed_pixel_ptr[0], 1.0f);   // R
  EXPECT_EQ(decompressed_pixel_ptr[1], 0.5f);   // G
  EXPECT_EQ(decompressed_pixel_ptr[2], 0.25f);  // B
  EXPECT_EQ(decompressed_pixel_ptr[3], 1.0f);   // A

#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerR32FDecode) {
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Fuchsia can't load the test fixtures.";
#endif

#if !IMPELLER_SUPPORTS_RENDERING
  GTEST_SKIP() << "test only supported on impeller";
#else
  // 1. Create a 1x1 pixel with float RGBA values.
  float pixel_data[] = {1.0f};
  sk_sp<SkData> sk_data = SkData::MakeWithCopy(pixel_data, sizeof(pixel_data));
  auto immutable_buffer =
      fml::MakeRefCounted<ImmutableBuffer>(std::move(sk_data));

  // 2. Create an ImageDescriptor using the private constructor.
  ImageDescriptor::ImageInfo image_info = {
      .width = 1,
      .height = 1,
      .format = ImageDescriptor::PixelFormat::kR32Float,
      .alpha_type = kUnpremul_SkAlphaType,
  };
  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(
      immutable_buffer->data(), image_info, sizeof(pixel_data));

  // Set up Impeller capabilities and allocator.
  std::shared_ptr<impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetSupportsTextureToTextureBlits(true)
          .Build();
  std::shared_ptr<impeller::Allocator> allocator =
      std::make_shared<impeller::TestImpellerAllocator>();

  // 3. Call ImageDecoderImpeller::DecompressTexture with this ImageDescriptor.
  absl::StatusOr<ImageDecoderImpeller::DecompressResult> result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(),
          /*options=*/
          {.target_width = 1,
           .target_height = 1,
           .target_format = ImageDecoder::TargetPixelFormat::kR32Float},
          /*max_texture_size=*/{1, 1},
          /*supports_wide_gamut=*/true, capabilities, allocator);

  // 4. Assert that wide_result->image_info.format is
  // impeller::PixelFormat::kR32G32B32A32Float.
  ASSERT_TRUE(result.ok());
  ASSERT_EQ(result->image_info.format, impeller::PixelFormat::kR32Float);

  // Optionally, verify the pixel data if needed.
  const float* decompressed_pixel_ptr =
      reinterpret_cast<const float*>(result->device_buffer->OnGetContents());
  ASSERT_NE(decompressed_pixel_ptr, nullptr);
  EXPECT_EQ(decompressed_pixel_ptr[0], 1.0f);

#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerUnmultipliedAlphaPng) {
#if defined(OS_FUCHSIA)
  GTEST_SKIP() << "Fuchsia can't load the test fixtures.";
#endif
  SkCodecs::Register(SkPngDecoder::Decoder());
  auto data = flutter::testing::OpenFixtureAsSkData("unmultiplied_alpha.png");
  auto image = SkImages::DeferredFromEncodedData(data);
  std::shared_ptr<impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetSupportsTextureToTextureBlits(true)
          .Build();
  ASSERT_TRUE(image != nullptr);
  ASSERT_EQ(SkISize::Make(11, 11), image->dimensions());

  ImageGeneratorRegistry registry;
  std::shared_ptr<ImageGenerator> generator =
      registry.CreateCompatibleGenerator(data);
  ASSERT_TRUE(generator);

  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(std::move(data),
                                                         std::move(generator));

#if IMPELLER_SUPPORTS_RENDERING
  std::shared_ptr<impeller::Allocator> allocator =
      std::make_shared<impeller::TestImpellerAllocator>();
  absl::StatusOr<ImageDecoderImpeller::DecompressResult> result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(), {.target_width = 11, .target_height = 11}, {11, 11},
          /*supports_wide_gamut=*/true, capabilities, allocator);
  ASSERT_TRUE(result.ok());
  ASSERT_EQ(result->image_info.format,
            impeller::PixelFormat::kR8G8B8A8UNormInt);

  const uint32_t* pixel_ptr =
      reinterpret_cast<const uint32_t*>(result->device_buffer->OnGetContents());
  // Test the upper left pixel is premultiplied and not solid red.
  ASSERT_EQ(*pixel_ptr, (uint32_t)0x1000001);
  // Test a pixel in the green box is still green.
  ASSERT_EQ(*(pixel_ptr + 11 * 4 + 4), (uint32_t)0xFF00FF00);

#endif  // IMPELLER_SUPPORTS_RENDERING
}

#if IMPELLER_SUPPORTS_RENDERING
void ExpectDecodedFormat(sk_sp<SkColorSpace> color_space,
                         bool supports_wide_gamut,
                         impeller::PixelFormat expected_format) {
  uint8_t pixel_data[] = {255, 255, 255, 255};
  sk_sp<SkData> sk_data = SkData::MakeWithCopy(pixel_data, sizeof(pixel_data));
  auto immutable_buffer =
      fml::MakeRefCounted<ImmutableBuffer>(std::move(sk_data));

  ImageDescriptor::ImageInfo image_info = {
      .width = 1,
      .height = 1,
      .format = ImageDescriptor::PixelFormat::kRGBA8888,
      .alpha_type = kOpaque_SkAlphaType,
      .color_space = std::move(color_space),
  };
  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(
      immutable_buffer->data(), image_info, sizeof(pixel_data));

  std::shared_ptr<impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetSupportsTextureToTextureBlits(true)
          .Build();
  std::shared_ptr<impeller::Allocator> allocator =
      std::make_shared<impeller::TestImpellerAllocator>();

  absl::StatusOr<ImageDecoderImpeller::DecompressResult> result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(), {.target_width = 1, .target_height = 1}, {1, 1},
          supports_wide_gamut, capabilities, allocator);

  ASSERT_TRUE(result.ok());
  EXPECT_EQ(result->image_info.format, expected_format);
}
#endif  // IMPELLER_SUPPORTS_RENDERING

TEST(ImageDecoderNoGLTest, ImpellerHdrPqImageDecodesToF16) {
#if IMPELLER_SUPPORTS_RENDERING
  ExpectDecodedFormat(
      SkColorSpace::MakeRGB(SkNamedTransferFn::kPQ, SkNamedGamut::kRec2020),
      /*supports_wide_gamut=*/true, impeller::PixelFormat::kR16G16B16A16Float);
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerHdrHlgImageDecodesToF16) {
#if IMPELLER_SUPPORTS_RENDERING
  ExpectDecodedFormat(
      SkColorSpace::MakeRGB(SkNamedTransferFn::kHLG, SkNamedGamut::kRec2020),
      /*supports_wide_gamut=*/true, impeller::PixelFormat::kR16G16B16A16Float);
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerOpaqueSdrWideGamutDecodesToB10XR) {
#if IMPELLER_SUPPORTS_RENDERING
  ExpectDecodedFormat(
      SkColorSpace::MakeRGB(SkNamedTransferFn::kSRGB, SkNamedGamut::kDisplayP3),
      /*supports_wide_gamut=*/true, impeller::PixelFormat::kB10G10R10XR);
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, ImpellerHdrImageWithoutWideGamutDecodesToF16) {
#if IMPELLER_SUPPORTS_RENDERING
  ExpectDecodedFormat(
      SkColorSpace::MakeRGB(SkNamedTransferFn::kPQ, SkNamedGamut::kSRGB),
      /*supports_wide_gamut=*/true, impeller::PixelFormat::kR16G16B16A16Float);
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest,
     ImpellerHdrImageWithoutWideGamutSupportDecodesToRGBA8888) {
#if IMPELLER_SUPPORTS_RENDERING
  ExpectDecodedFormat(
      SkColorSpace::MakeRGB(SkNamedTransferFn::kPQ, SkNamedGamut::kRec2020),
      /*supports_wide_gamut=*/false, impeller::PixelFormat::kR8G8B8A8UNormInt);
#endif  // IMPELLER_SUPPORTS_RENDERING
}

TEST(ImageDecoderNoGLTest, GetResizeStepSizeHalvesTowardsTargetSize) {
  // Sides that are at least twice as long as the target are halved.
  EXPECT_EQ(ImageDecoder::GetResizeStepSize(SkISize::Make(1024, 1024),
                                            SkISize::Make(120, 120)),
            SkISize::Make(512, 512));
  EXPECT_EQ(ImageDecoder::GetResizeStepSize(SkISize::Make(256, 256),
                                            SkISize::Make(120, 120)),
            SkISize::Make(128, 128));
  // Each side is halved on its own.
  EXPECT_EQ(ImageDecoder::GetResizeStepSize(SkISize::Make(1024, 1024),
                                            SkISize::Make(600, 100)),
            SkISize::Make(1024, 512));
  // Halving to exactly the target size is the final step.
  EXPECT_EQ(ImageDecoder::GetResizeStepSize(SkISize::Make(240, 240),
                                            SkISize::Make(120, 120)),
            SkISize::Make(120, 120));
  // Less than 2x left: the final step scales to the target size.
  EXPECT_EQ(ImageDecoder::GetResizeStepSize(SkISize::Make(128, 128),
                                            SkISize::Make(120, 120)),
            SkISize::Make(120, 120));
  // Images are scaled up in a single step.
  EXPECT_EQ(ImageDecoder::GetResizeStepSize(SkISize::Make(100, 100),
                                            SkISize::Make(300, 300)),
            SkISize::Make(300, 300));
}

// Regression test for https://github.com/flutter/flutter/issues/193779.
TEST(ImageDecoderNoGLTest, ResizePixelsDoesNotAliasThinLines) {
  const SkBitmap stripes = MakeThinStripesBitmap(256);
  SkBitmap resized;
  ASSERT_TRUE(resized.tryAllocPixels(stripes.info().makeWH(30, 30)));

  ASSERT_TRUE(ImageDecoder::ResizePixels(stripes.pixmap(), resized.pixmap()));

  // A single linear step would only read 2 of the ~8.5 columns covered by each
  // pixel, which gives anything from almost black to almost white.
  for (int y = 0; y < resized.height(); y++) {
    for (int x = 0; x < resized.width(); x++) {
      EXPECT_NEAR(SkColorGetR(resized.getColor(x, y)), 128, 2)
          << "at (" << x << ", " << y << ")";
    }
  }
}

// Regression test for https://github.com/flutter/flutter/issues/193779.
TEST(ImageDecoderNoGLTest, ImpellerCpuResizeDoesNotAliasThinLines) {
#if !IMPELLER_SUPPORTS_RENDERING
  GTEST_SKIP() << "Test only supported with Impeller rendering.";
#else
  const SkBitmap stripes = MakeThinStripesBitmap(256);
  auto descriptor = fml::MakeRefCounted<ImageDescriptor>(
      SkData::MakeWithCopy(stripes.getPixels(), stripes.computeByteSize()),
      ImageDescriptor::CreateImageInfo(stripes.info()), stripes.rowBytes());
  // Without texture to texture blits, images are resized on the CPU.
  std::shared_ptr<impeller::Capabilities> capabilities =
      impeller::CapabilitiesBuilder()
          .SetSupportsTextureToTextureBlits(false)
          .Build();
  std::shared_ptr<impeller::Allocator> allocator =
      std::make_shared<impeller::TestImpellerAllocator>();

  absl::StatusOr<ImageDecoderImpeller::DecompressResult> result =
      ImageDecoderImpeller::DecompressTexture(
          descriptor.get(), {.target_width = 30, .target_height = 30},
          {1000, 1000}, /*supports_wide_gamut=*/false, capabilities, allocator);

  ASSERT_TRUE(result.ok());
  ASSERT_FALSE(result->resize_info.has_value());
  ASSERT_EQ(result->image_info.size, impeller::ISize(30, 30));
  ASSERT_EQ(result->image_info.format,
            impeller::PixelFormat::kR8G8B8A8UNormInt);
  const uint8_t* pixels = result->device_buffer->OnGetContents();
  for (int i = 0; i < 30 * 30; i++) {
    EXPECT_NEAR(pixels[i * 4], 128, 2) << "at pixel " << i;
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
}

// Regression test for https://github.com/flutter/flutter/issues/193779.
TEST(ImageDecoderNoGLTest, ImpellerGpuResizeHalvesTowardsTargetSize) {
#if !IMPELLER_SUPPORTS_RENDERING
  GTEST_SKIP() << "Test only supported with Impeller rendering.";
#else
  using ::impeller::testing::MockBlitPass;
  using ::impeller::testing::MockCommandBuffer;
  using ::impeller::testing::MockCommandQueue;
  using ::impeller::testing::MockImpellerContext;
  using ::testing::_;
  using ::testing::Return;

  auto context = std::make_shared<MockImpellerContext>();
  auto allocator = std::make_shared<impeller::TestImpellerAllocator>();
  auto command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto blit_pass = std::make_shared<MockBlitPass>();
  auto command_queue = std::make_shared<MockCommandQueue>();

  EXPECT_CALL(*context, GetBackendType)
      .WillRepeatedly(Return(impeller::Context::BackendType::kVulkan));
  EXPECT_CALL(*context, GetResourceAllocator).WillRepeatedly(Return(allocator));
  EXPECT_CALL(*context, CreateCommandBuffer).WillOnce(Return(command_buffer));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_buffer, SetLabel(_));
  EXPECT_CALL(*command_buffer, OnCreateBlitPass).WillOnce(Return(blit_pass));
  EXPECT_CALL(*command_buffer, OnWaitUntilCompleted);
  EXPECT_CALL(*blit_pass, IsValid).WillOnce(Return(true));
  EXPECT_CALL(*blit_pass, OnSetLabel(_)).Times(2);
  EXPECT_CALL(*blit_pass, OnCopyBufferToTextureCommand(_, _, _, _, _, _, _))
      .WillOnce(Return(true));
  // The (source, destination) sizes of each resize blit.
  using Resizes = std::vector<std::pair<impeller::ISize, impeller::ISize>>;
  Resizes resizes;
  EXPECT_CALL(*blit_pass, ResizeTexture(_, _))
      .WillRepeatedly(
          [&resizes](const std::shared_ptr<impeller::Texture>& source,
                     const std::shared_ptr<impeller::Texture>& destination) {
            resizes.emplace_back(source->GetSize(), destination->GetSize());
            return true;
          });
  // Only the resized texture gets mipmaps.
  EXPECT_CALL(*blit_pass, OnGenerateMipmapCommand(_, _)).WillOnce(Return(true));
  EXPECT_CALL(*blit_pass, EncodeCommands).WillOnce(Return(true));
  EXPECT_CALL(*command_queue, SubmitWithReceipt(_, _))
      .WillOnce([](const std::shared_ptr<impeller::CommandBuffer>&,
                   const impeller::CommandQueue::CompletionCallback&) {
        return impeller::CommandQueue::SubmitResult{
            .status = absl::OkStatus(),
        };
      });

  impeller::DeviceBufferDescriptor buffer_descriptor;
  buffer_descriptor.size = 256u * 256u * 4u;
  auto buffer =
      std::make_shared<impeller::TestImpellerDeviceBuffer>(buffer_descriptor);
  auto gpu_disabled_switch = std::make_shared<fml::SyncSwitch>(false);
  sk_sp<DlImage> image;
  std::string decode_error;

  ImageDecoderImpeller::UploadTextureToPrivate(
      [&](const sk_sp<DlImage>& result, const std::string& error) {
        image = result;
        decode_error = error;
      },
      context, buffer,
      {.size = impeller::ISize(256, 256),
       .format = impeller::PixelFormat::kR8G8B8A8UNormInt},
      SkImageInfo::Make(30, 30, kRGBA_8888_SkColorType, kPremul_SkAlphaType),
      gpu_disabled_switch);

  EXPECT_NE(image, nullptr);
  EXPECT_TRUE(decode_error.empty());
  // A single 256x256 to 30x30 blit would only read 2x2 of the ~8x8 source
  // pixels covered by each destination pixel.
  const Resizes expected_resizes = {
      {impeller::ISize(256, 256), impeller::ISize(128, 128)},
      {impeller::ISize(128, 128), impeller::ISize(64, 64)},
      {impeller::ISize(64, 64), impeller::ISize(32, 32)},
      {impeller::ISize(32, 32), impeller::ISize(30, 30)},
  };
  EXPECT_EQ(resizes, expected_resizes);
  // The full size texture is only read by the first blit, so it has no
  // mipmaps.
  ASSERT_EQ(allocator->created_textures().size(), 5u);
  EXPECT_EQ(allocator->created_textures().front()->GetSize(),
            impeller::ISize(256, 256));
  EXPECT_EQ(
      allocator->created_textures().front()->GetTextureDescriptor().mip_count,
      1u);
  EXPECT_EQ(allocator->last_created_texture()->GetTextureDescriptor().mip_count,
            impeller::ISize(30, 30).MipCount());
#endif  // IMPELLER_SUPPORTS_RENDERING
}

}  // namespace testing
}  // namespace flutter
