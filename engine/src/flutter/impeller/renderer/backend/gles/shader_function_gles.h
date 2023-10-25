// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/shader_function.h"

namespace impeller {

class ShaderLibraryGLES;

class ShaderFunctionGLES final
    : public ShaderFunction,
      public BackendCast<ShaderFunctionGLES, ShaderFunction> {
 public:
  // |ShaderFunction|
  ~ShaderFunctionGLES() override;

  const std::shared_ptr<const fml::Mapping>& GetSourceMapping() const;

 private:
  friend ShaderLibraryGLES;

  std::shared_ptr<const fml::Mapping> mapping_;

  ShaderFunctionGLES(UniqueID library_id,
                     ShaderStage stage,
                     std::string name,
                     std::shared_ptr<const fml::Mapping> mapping);

  ShaderFunctionGLES(const ShaderFunctionGLES&) = delete;

  ShaderFunctionGLES& operator=(const ShaderFunctionGLES&) = delete;
};

}  // namespace impeller
