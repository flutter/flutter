// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "impeller/entity/contents/gradient_generator.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/gradient.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/texture.h"

namespace impeller {

std::shared_ptr<Texture> CreateGradientTexture(
    const std::vector<Color>& colors,
    const std::vector<Scalar>& stops,
    std::shared_ptr<impeller::Context> context) {
  // If the computed scale is nearly the same as the color length, then the
  // stops are evenly spaced and we can lerp entirely in the gradient shader.
  // Thus we only need to populate a texture with all of the colors in order.
  // For other cases, we may have more colors than we can fit in the texture,
  // or we may have very small stop values. For these gradients the lerped
  // values are computed here and then populated in a texture.
  uint32_t texture_size;
  auto color_stop_channels = CreateGradientBuffer(colors, stops, &texture_size);
  impeller::TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = {texture_size, 1};
  auto texture =
      context->GetResourceAllocator()->CreateTexture(texture_descriptor);
  if (!texture) {
    FML_DLOG(ERROR) << "Could not create Impeller texture.";
    return nullptr;
  }

  auto mapping = std::make_shared<fml::DataMapping>(color_stop_channels);
  if (!texture->SetContents(mapping)) {
    FML_DLOG(ERROR) << "Could not copy contents into Impeller texture.";
    return nullptr;
  }
  texture->SetLabel(impeller::SPrintF("Gradient(%p)", texture.get()).c_str());
  return texture;
}

}  // namespace impeller
