// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/yuv_test_textures.h"

#include <array>
#include <cmath>
#include <cstdint>
#include <string_view>
#include <vector>

#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/geometry/size.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/command_queue.h"

namespace impeller {

namespace {

Vector3 RGBToYUV(Vector3 rgb, YUVColorSpace yuv_color_space) {
  Vector3 yuv;
  switch (yuv_color_space) {
    case YUVColorSpace::kBT601FullRange:
      yuv.x = rgb.x * 0.299 + rgb.y * 0.587 + rgb.z * 0.114;
      yuv.y = rgb.x * -0.169 + rgb.y * -0.331 + rgb.z * 0.5 + 0.5;
      yuv.z = rgb.x * 0.5 + rgb.y * -0.419 + rgb.z * -0.081 + 0.5;
      break;
    case YUVColorSpace::kBT601LimitedRange:
      yuv.x = rgb.x * 0.257 + rgb.y * 0.516 + rgb.z * 0.100 + 0.063;
      yuv.y = rgb.x * -0.145 + rgb.y * -0.291 + rgb.z * 0.439 + 0.5;
      yuv.z = rgb.x * 0.429 + rgb.y * -0.368 + rgb.z * -0.071 + 0.5;
      break;
  }
  return yuv;
}

/// Creates a host-visible texture and queues a copy of `data` into it on
/// `blit_pass`. Returns nullptr on failure.
std::shared_ptr<Texture> CreateTextureWithData(const Context& context,
                                               BlitPass& blit_pass,
                                               PixelFormat format,
                                               ISize size,
                                               const std::vector<uint8_t>& data,
                                               std::string_view label) {
  TextureDescriptor descriptor;
  descriptor.storage_mode = StorageMode::kHostVisible;
  descriptor.format = format;
  descriptor.size = size;
  auto texture = context.GetResourceAllocator()->CreateTexture(descriptor);
  if (!texture) {
    return nullptr;
  }
  texture->SetLabel(label);
  auto buffer = context.GetResourceAllocator()->CreateBufferWithCopy(
      data.data(), data.size());
  if (!buffer) {
    return nullptr;
  }
  if (!blit_pass.AddCopy(DeviceBuffer::AsBufferView(std::move(buffer)),
                         texture)) {
    return nullptr;
  }
  return texture;
}

}  // namespace

std::optional<TestYUVTextures> CreateTestYUVTextures(
    const Context& context,
    YUVColorSpace yuv_color_space) {
  const Vector3 red = {244.0 / 255.0, 67.0 / 255.0, 54.0 / 255.0};
  const Vector3 green = {76.0 / 255.0, 175.0 / 255.0, 80.0 / 255.0};
  const Vector3 blue = {33.0 / 255.0, 150.0 / 255.0, 243.0 / 255.0};
  const Vector3 white = {1.0, 1.0, 1.0};
  const std::array<Vector3, 4> yuvs = {
      RGBToYUV(red, yuv_color_space), RGBToYUV(green, yuv_color_space),
      RGBToYUV(blue, yuv_color_space), RGBToYUV(white, yuv_color_space)};

  // Each band covers two rows of the 8x8 luma plane and one row of the 4x4
  // chroma plane.
  constexpr ISize kYSize = {8, 8};
  constexpr ISize kUVSize = {4, 4};
  std::vector<uint8_t> y_data;
  std::vector<uint8_t> uv_data;
  y_data.reserve(kYSize.Area());
  uv_data.reserve(kUVSize.Area() * 2);
  for (const Vector3& yuv : yuvs) {
    uint8_t y = std::round(yuv.x * 255.0);
    uint8_t u = std::round(yuv.y * 255.0);
    uint8_t v = std::round(yuv.z * 255.0);
    for (int j = 0; j < kYSize.width * 2; j++) {
      y_data.push_back(y);
    }
    for (int j = 0; j < kUVSize.width; j++) {
      uv_data.push_back(u);
      uv_data.push_back(v);
    }
  }

  auto cmd_buffer = context.CreateCommandBuffer();
  if (!cmd_buffer) {
    return std::nullopt;
  }
  auto blit_pass = cmd_buffer->CreateBlitPass();
  if (!blit_pass) {
    return std::nullopt;
  }

  TestYUVTextures textures;
  textures.y =
      CreateTextureWithData(context, *blit_pass, PixelFormat::kR8UNormInt,
                            kYSize, y_data, "Test YUV Y plane");
  textures.uv =
      CreateTextureWithData(context, *blit_pass, PixelFormat::kR8G8UNormInt,
                            kUVSize, uv_data, "Test YUV UV plane");
  if (!textures.y || !textures.uv) {
    return std::nullopt;
  }

  if (!blit_pass->EncodeCommands() ||
      !context.GetCommandQueue()->Submit({cmd_buffer}).ok()) {
    return std::nullopt;
  }
  return textures;
}

}  // namespace impeller
