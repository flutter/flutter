// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/shader_library.h"

namespace impeller {

class ShaderLibraryGLES final : public ShaderLibrary {
 public:
  ShaderLibraryGLES();

  // |ShaderLibrary|
  ~ShaderLibraryGLES() override;

  // |ShaderLibrary|
  bool IsValid() const override;

 private:
  friend class ContextGLES;

  // |ShaderLibrary|
  std::shared_ptr<const ShaderFunction> GetFunction(
      const std::string_view& name,
      ShaderStage stage) override;

  FML_DISALLOW_COPY_AND_ASSIGN(ShaderLibraryGLES);
};

}  // namespace impeller
