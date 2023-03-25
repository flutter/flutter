// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/formats.h"

#include <sstream>

#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/texture.h"

namespace impeller {

constexpr bool StoreActionNeedsResolveTexture(StoreAction action) {
  switch (action) {
    case StoreAction::kDontCare:
    case StoreAction::kStore:
      return false;
    case StoreAction::kMultisampleResolve:
    case StoreAction::kStoreAndMultisampleResolve:
      return true;
  }
}

bool Attachment::IsValid() const {
  if (!texture || !texture->IsValid()) {
    VALIDATION_LOG << "Attachment has no texture.";
    return false;
  }

  if (StoreActionNeedsResolveTexture(store_action)) {
    if (!resolve_texture || !resolve_texture->IsValid()) {
      VALIDATION_LOG << "Store action needs resolve but no valid resolve "
                        "texture specified.";
      return false;
    }
  }

  if (resolve_texture) {
    if (store_action != StoreAction::kMultisampleResolve &&
        store_action != StoreAction::kStoreAndMultisampleResolve) {
      VALIDATION_LOG << "A resolve texture was specified, but the store action "
                        "doesn't include multisample resolve.";
      return false;
    }

    if (texture->GetTextureDescriptor().storage_mode ==
            StorageMode::kDeviceTransient &&
        store_action == StoreAction::kStoreAndMultisampleResolve) {
      VALIDATION_LOG
          << "The multisample texture cannot be transient when "
             "specifying the StoreAndMultisampleResolve StoreAction.";
    }
  }

  auto storage_mode = resolve_texture
                          ? resolve_texture->GetTextureDescriptor().storage_mode
                          : texture->GetTextureDescriptor().storage_mode;

  if (storage_mode == StorageMode::kDeviceTransient) {
    if (load_action == LoadAction::kLoad) {
      VALIDATION_LOG << "The LoadAction cannot be Load when attaching a device "
                        "transient " +
                            std::string(resolve_texture ? "resolve texture."
                                                        : "texture.");
      return false;
    }
    if (store_action != StoreAction::kDontCare) {
      VALIDATION_LOG << "The StoreAction must be DontCare when attaching a "
                        "device transient " +
                            std::string(resolve_texture ? "resolve texture."
                                                        : "texture.");
      return false;
    }
  }

  return true;
}

std::string TextureUsageMaskToString(TextureUsageMask mask) {
  std::vector<TextureUsage> usages;
  if (mask & static_cast<TextureUsageMask>(TextureUsage::kShaderRead)) {
    usages.push_back(TextureUsage::kShaderRead);
  }
  if (mask & static_cast<TextureUsageMask>(TextureUsage::kShaderWrite)) {
    usages.push_back(TextureUsage::kShaderWrite);
  }
  if (mask & static_cast<TextureUsageMask>(TextureUsage::kRenderTarget)) {
    usages.push_back(TextureUsage::kRenderTarget);
  }
  std::stringstream stream;
  stream << "{ ";
  for (size_t i = 0; i < usages.size(); i++) {
    stream << TextureUsageToString(usages[i]);
    if (i != usages.size() - 1u) {
      stream << ", ";
    }
  }
  stream << " }";
  return stream.str();
}

}  // namespace impeller
