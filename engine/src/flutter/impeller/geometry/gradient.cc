// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "impeller/geometry/gradient.h"

namespace impeller {

static void AppendColor(const Color& color, std::vector<uint8_t>* colors) {
  auto converted = color.Premultiply().ToR8G8B8A8();
  colors->push_back(converted[0]);
  colors->push_back(converted[1]);
  colors->push_back(converted[2]);
  colors->push_back(converted[3]);
}

std::vector<uint8_t> CreateGradientBuffer(const std::vector<Color>& colors,
                                          const std::vector<Scalar>& stops,
                                          uint32_t* out_texture_size) {
  uint32_t texture_size;
  // TODO(jonahwilliams): we should add a display list flag to check if the
  // stops were provided or not, then we can skip this step.
  // TODO(jonahwilliams): Skia has a check for stop sizes below a certain
  // threshold, we should make sure that we behave reasonably with them.
  if (stops.size() == 2) {
    texture_size = 2;
  } else {
    auto minimum_delta = 1.0;
    for (size_t i = 1; i < stops.size(); i++) {
      auto value = stops[i] - stops[i - 1];
      if (value < minimum_delta) {
        minimum_delta = value;
      }
    }
    // Avoid creating textures that are absurdly large due to stops that are
    // very close together.
    // TODO(jonahwilliams): this should use a platform specific max texture
    // size.
    texture_size =
        std::min((uint32_t)std::round(1.0 / minimum_delta) + 1, 1024u);
  }

  *out_texture_size = texture_size;
  std::vector<uint8_t> color_stop_channels;
  color_stop_channels.reserve(texture_size * 4);

  if (texture_size == colors.size() && colors.size() <= 1024) {
    for (auto i = 0u; i < colors.size(); i++) {
      AppendColor(colors[i], &color_stop_channels);
    }
  } else {
    Color previous_color = colors[0];
    auto previous_stop = 0.0;
    auto previous_color_index = 0;

    // The first index is always equal to the first color, exactly.
    AppendColor(previous_color, &color_stop_channels);

    for (auto i = 1u; i < texture_size - 1; i++) {
      auto scaled_i = i / texture_size;
      Color next_color = colors[previous_color_index + 1];
      auto next_stop = stops[previous_color_index + 1];

      // We're almost exactly equal to the next stop.
      if (ScalarNearlyEqual(scaled_i, next_stop)) {
        AppendColor(next_color, &color_stop_channels);

        previous_color = next_color;
        previous_stop = next_stop;
        previous_color_index += 1;
      } else if (scaled_i < next_stop) {
        // We're still between the current stop and the next stop.
        auto t = (scaled_i - previous_stop) / (next_stop - previous_stop);
        auto mixed_color = Color::lerp(previous_color, next_color, t);

        AppendColor(mixed_color, &color_stop_channels);
      } else {
        // We've slightly overshot the next stop. In theory this only happens if
        // we have scaled our texture such that not every stop gets their own
        // index. For now I am simply ignoring the inbetween colors. Currently
        // this requires a gradient with either an absurd number of textures
        // or very small stops.
        AppendColor(next_color, &color_stop_channels);

        previous_color = next_color;
        previous_stop = next_stop;
        previous_color_index += 1;
      }
    }
    // The last index is always equal to the last color, exactly.
    AppendColor(colors.back(), &color_stop_channels);
  }
  return color_stop_channels;
}

}  // namespace impeller
