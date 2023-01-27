// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "impeller/entity/contents/gradient_generator.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/texture.h"

namespace impeller {

std::shared_ptr<Texture> CreateGradientTexture(
    const GradientData& gradient_data,
    const std::shared_ptr<impeller::Context>& context) {
  if (gradient_data.texture_size == 0) {
    FML_DLOG(ERROR) << "Invalid gradient data.";
    return nullptr;
  }

  impeller::TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = {gradient_data.texture_size, 1};
  auto texture =
      context->GetResourceAllocator()->CreateTexture(texture_descriptor);
  if (!texture) {
    FML_DLOG(ERROR) << "Could not create Impeller texture.";
    return nullptr;
  }

  auto mapping = std::make_shared<fml::DataMapping>(gradient_data.color_bytes);
  if (!texture->SetContents(mapping)) {
    FML_DLOG(ERROR) << "Could not copy contents into Impeller texture.";
    return nullptr;
  }
  texture->SetLabel(impeller::SPrintF("Gradient(%p)", texture.get()).c_str());
  return texture;
}

std::vector<StopData> CreateGradientColors(const std::vector<Color>& colors,
                                           const std::vector<Scalar>& stops) {
  FML_DCHECK(stops.size() == colors.size());

  std::vector<StopData> result(stops.size());
  for (auto i = 0u; i < stops.size(); i++) {
    result[i] = {.color = colors[i], .stop = stops[i]};
  }
  return result;
}

}  // namespace impeller
