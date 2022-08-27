// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/formats.h"

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

// TODO(110385): Enable attachment validation.
#if 0
  if (StoreActionNeedsResolveTexture(store_action)) {
    if (!resolve_texture || !resolve_texture->IsValid()) {
      VALIDATION_LOG << "Store action needs resolve but no valid resolve "
                        "texture specified.";
      return false;
    }
  }

  if (texture->GetTextureDescriptor().storage_mode ==
      StorageMode::kDeviceTransient) {
    if (load_action != LoadAction::kDontCare &&
        store_action != StoreAction::kDontCare) {
      VALIDATION_LOG
          << "Load or store actions specified on device transient textures.";
      return false;
    }
  }
#endif

  return true;
}

}  // namespace impeller
