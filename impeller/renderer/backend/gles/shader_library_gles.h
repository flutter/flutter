// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/renderer/shader_key.h"
#include "impeller/renderer/shader_library.h"

namespace impeller {

class ShaderLibraryGLES final : public ShaderLibrary {
 public:
  // |ShaderLibrary|
  ~ShaderLibraryGLES() override;

  // |ShaderLibrary|
  bool IsValid() const override;

 private:
  friend class ContextGLES;
  ShaderFunctionMap functions_;
  bool is_valid_ = false;

  ShaderLibraryGLES(
      std::vector<std::shared_ptr<fml::Mapping>> shader_libraries);

  // |ShaderLibrary|
  std::shared_ptr<const ShaderFunction> GetFunction(
      const std::string_view& name,
      ShaderStage stage) override;

  FML_DISALLOW_COPY_AND_ASSIGN(ShaderLibraryGLES);
};

}  // namespace impeller
