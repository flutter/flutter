// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <future>
#include <memory>
#include <string_view>

#include "flutter/fml/macros.h"
#include "fml/mapping.h"
#include "impeller/core/shader_types.h"

namespace impeller {

class Context;
class ShaderFunction;

class ShaderLibrary : public std::enable_shared_from_this<ShaderLibrary> {
 public:
  virtual ~ShaderLibrary();

  virtual bool IsValid() const = 0;

  virtual std::shared_ptr<const ShaderFunction> GetFunction(
      std::string_view name,
      ShaderStage stage) = 0;

  using RegistrationCallback = std::function<void(bool)>;
  virtual void RegisterFunction(std::string name,
                                ShaderStage stage,
                                std::shared_ptr<fml::Mapping> code,
                                RegistrationCallback callback);

  virtual void UnregisterFunction(std::string name, ShaderStage stage) = 0;

 protected:
  ShaderLibrary();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(ShaderLibrary);
};

}  // namespace impeller
