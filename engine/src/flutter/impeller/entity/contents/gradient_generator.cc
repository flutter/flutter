// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/gradient_generator.h"

#include "flutter/fml/logging.h"
#include "impeller/base/strings.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/texture_util.h"

namespace impeller {

namespace {

std::vector<uint8_t> ToR32G32B32A32FloatBytes(
    const std::vector<Color>& colors) {
  static_assert(sizeof(Color) == sizeof(float) * 4,
                "Color must be exactly 4 floats with no padding.");
  static_assert(std::is_standard_layout_v<Color>,
                "Color must be standard layout.");
  // `Color` is a standard-layout struct of 4 contiguous 32-bit floats (RGBA),
  // directly matching the `kR32G32B32A32Float` pixel format layout.
  const auto* bytes = reinterpret_cast<const uint8_t*>(colors.data());
  return std::vector<uint8_t>(bytes, bytes + colors.size() * sizeof(Color));
}

std::vector<uint8_t> ToR8G8B8A8Bytes(const std::vector<Color>& colors) {
  std::vector<uint8_t> bytes;
  bytes.reserve(colors.size() * 4);
  for (const auto& color : colors) {
    auto converted = color.ToR8G8B8A8();
    bytes.push_back(converted[0]);
    bytes.push_back(converted[1]);
    bytes.push_back(converted[2]);
    bytes.push_back(converted[3]);
  }
  return bytes;
}

}  // namespace

std::shared_ptr<Texture> CreateGradientTexture(
    const GradientData& gradient_data,
    const std::shared_ptr<impeller::Context>& context) {
  if (gradient_data.colors.empty()) {
    FML_DLOG(ERROR) << "Invalid gradient data.";
    return nullptr;
  }

  impeller::TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  texture_descriptor.size = ISize(gradient_data.colors.size(), 1);

  bool is_wide_gamut =
      std::any_of(gradient_data.colors.begin(), gradient_data.colors.end(),
                  [](const Color& c) { return c.IsWideGamut(); });

  std::vector<uint8_t> bytes;
  if (is_wide_gamut) {
    texture_descriptor.format = PixelFormat::kR32G32B32A32Float;
    bytes = ToR32G32B32A32FloatBytes(gradient_data.colors);
  } else {
    texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
    bytes = ToR8G8B8A8Bytes(gradient_data.colors);
  }

  return CreateTexture(texture_descriptor, bytes, context, "Gradient");
}

std::vector<StopData> CreateGradientColors(const std::vector<Color>& colors,
                                           const std::vector<Scalar>& stops) {
  FML_DCHECK(stops.size() == colors.size());

  std::vector<StopData> result;
  result.reserve(stops.size());
  Scalar last_stop = 0;
  for (auto i = 0u; i < stops.size(); i++) {
    Scalar delta = stops[i] - last_stop;
    Scalar inverse_delta = delta == 0.0f ? 0.0 : 1.0 / delta;
    result.emplace_back(StopData{
        .color = colors[i], .stop = stops[i], .inverse_delta = inverse_delta});
    last_stop = stops[i];
  }
  return result;
}

int PopulateUniformGradientColors(
    const std::vector<Color>& colors,
    const std::vector<Scalar>& stops,
    Vector4 frag_info_colors[kMaxUniformGradientStops],
    Vector4 frag_info_stop_pairs[kMaxUniformGradientStops / 2]) {
  FML_DCHECK(stops.size() == colors.size());

  Scalar last_stop = 0;
  int index = 0;
  for (auto i = 0u; i < stops.size() && i < kMaxUniformGradientStops; i++) {
    Scalar cur_stop = stops[i];
    Scalar delta = cur_stop - last_stop;
    Scalar inverse_delta = delta == 0.0f ? 0.0 : 1.0 / delta;
    frag_info_colors[index] = colors[i];
    if ((i & 1) == 0) {
      frag_info_stop_pairs[index / 2].x = cur_stop;
      frag_info_stop_pairs[index / 2].y = inverse_delta;
    } else {
      frag_info_stop_pairs[index / 2].z = cur_stop;
      frag_info_stop_pairs[index / 2].w = inverse_delta;
    }
    last_stop = cur_stop;
    index++;
  }
  return index;
}

}  // namespace impeller
