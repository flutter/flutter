// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string_view>

#include "flutter/fml/macros.h"
#include "impeller/renderer/shader_types.h"

namespace impeller {

class Context;
class ShaderFunction;

class ShaderLibrary {
 public:
  virtual ~ShaderLibrary();

  virtual bool IsValid() const = 0;

  virtual std::shared_ptr<const ShaderFunction> GetFunction(
      const std::string_view& name,
      ShaderStage stage) = 0;

 protected:
  ShaderLibrary();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(ShaderLibrary);
};

}  // namespace impeller
