// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/shader_library.h"

namespace impeller {

class ShaderLibraryMTL final : public ShaderLibrary {
 public:
  ShaderLibraryMTL();

  ~ShaderLibraryMTL() override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(ShaderLibraryMTL);
};

}  // namespace impeller
