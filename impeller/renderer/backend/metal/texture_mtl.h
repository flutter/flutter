// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class TextureMTL final : public Texture {
 public:
  TextureMTL();

  ~TextureMTL() override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(TextureMTL);
};

}  // namespace impeller
