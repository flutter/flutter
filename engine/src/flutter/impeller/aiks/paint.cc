// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/paint.h"

namespace impeller {

std::shared_ptr<Contents> Paint::CreateContentsForEntity() const {
  if (!color.IsTransparent()) {
    auto solid_color = std::make_shared<SolidColorContents>();
    solid_color->SetColor(color);
    return solid_color;
  }

  return nullptr;
}

}  // namespace impeller
