// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/yuv_test_textures.h"

#include <array>
#include <cmath>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "flutter/fml/status.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/geometry/size.h"
#include "impeller/geometry/vector.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/command_queue.h"
#include "third_party/abseil-cpp/absl/status/status.h"

namespace impeller {

namespace {

Vector3 RGBToYUV(Vector3 rgb, YUVColorSpace yuv_color_space) {
  Vector3 yuv;
  switch (yuv_color_space) {
    case YUVColorSpace::kBT601FullRange:
      yuv.x = rgb.x * 0.299f + rgb.y * 0.587f + rgb.z * 0.114f;
      yuv.y = rgb.x * -0.169f + rgb.y * -0.331f + rgb.z * 0.5f + 0.5f;
      yuv.z = rgb.x * 0.5f + rgb.y * -0.419f + rgb.z * -0.081f + 0.5f;
      break;
    case YUVColorSpace::kBT601LimitedRange:
      yuv.x = rgb.x * 0.257f + rgb.y * 0.516f + rgb.z * 0.100f + 0.063f;
      yuv.y = rgb.x * -0.145f + rgb.y * -0.291f + rgb.z * 0.439f + 0.5f;
      yuv.z = rgb.x * 0.429f + rgb.y * -0.368f + rgb.z * -0.071f + 0.5f;
      break;
  }
  return yuv;
}

/// Creates a host-visible texture and queues a copy of `data` into it on
/// `blit_pass`.
absl::StatusOr<std::shared_ptr<Texture>> CreateTextureWithData(
    const Context& context,
    BlitPass& blit_pass,
    PixelFormat format,
    ISize size,
    const std::vector<uint8_t>& data,
    const std::string& label) {
  TextureDescriptor descriptor;
  descriptor.storage_mode = StorageMode::kHostVisible;
  descriptor.format = format;
  descriptor.size = size;
  auto texture = context.GetResourceAllocator()->CreateTexture(descriptor);
  if (!texture) {
    return absl::InternalError("Could not allocate the " + label + " texture.");
  }
  texture->SetLabel(label);
  auto buffer = context.GetResourceAllocator()->CreateBufferWithCopy(
      data.data(), data.size());
  if (!buffer) {
    return absl::InternalError("Could not create the staging buffer for the " +
                               label + " texture.");
  }
  if (!blit_pass.AddCopy(DeviceBuffer::AsBufferView(std::move(buffer)),
                         texture)) {
    return absl::InternalError("Could not add the copy into the " + label +
                               " texture to the blit pass.");
  }
  return texture;
}

}  // namespace

absl::StatusOr<TestYUVTextures> CreateTestYUVTextures(
    const Context& context,
    YUVColorSpace yuv_color_space) {
  const Vector3 red = {244.0f / 255.0f, 67.0f / 255.0f, 54.0f / 255.0f};
  const Vector3 green = {76.0f / 255.0f, 175.0f / 255.0f, 80.0f / 255.0f};
  const Vector3 blue = {33.0f / 255.0f, 150.0f / 255.0f, 243.0f / 255.0f};
  const Vector3 white = {1.0f, 1.0f, 1.0f};
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
    uint8_t y = std::round(yuv.x * 255.0f);
    uint8_t u = std::round(yuv.y * 255.0f);
    uint8_t v = std::round(yuv.z * 255.0f);
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
    return absl::InternalError("Could not create a command buffer.");
  }
  auto blit_pass = cmd_buffer->CreateBlitPass();
  if (!blit_pass) {
    return absl::InternalError("Could not create a blit pass.");
  }

  auto y_texture =
      CreateTextureWithData(context, *blit_pass, PixelFormat::kR8UNormInt,
                            kYSize, y_data, "Test YUV Y plane");
  if (!y_texture.ok()) {
    return y_texture.status();
  }
  auto uv_texture =
      CreateTextureWithData(context, *blit_pass, PixelFormat::kR8G8UNormInt,
                            kUVSize, uv_data, "Test YUV UV plane");
  if (!uv_texture.ok()) {
    return uv_texture.status();
  }

  if (!blit_pass->EncodeCommands()) {
    return absl::InternalError("Could not encode the YUV plane uploads.");
  }
  fml::Status submit_status = context.GetCommandQueue()->Submit({cmd_buffer});
  if (!submit_status.ok()) {
    return absl::InternalError("Could not submit the YUV plane uploads: " +
                               std::string(submit_status.message()));
  }

  TestYUVTextures textures;
  textures.y = std::move(y_texture).value();
  textures.uv = std::move(uv_texture).value();
  return textures;
}

}  // namespace impeller
