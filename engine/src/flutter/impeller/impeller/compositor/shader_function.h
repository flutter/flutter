// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "impeller/compositor/comparable.h"
#include "impeller/shader_glue/shader_types.h"

namespace impeller {

class ShaderFunction : public Comparable<ShaderFunction> {
 public:
  virtual ~ShaderFunction();

  ShaderStage GetStage() const;

  id<MTLFunction> GetMTLFunction() const;

  // Comparable<ShaderFunction>
  std::size_t GetHash() const override;

  // Comparable<ShaderFunction>
  bool IsEqual(const ShaderFunction& other) const override;

 private:
  friend class ShaderLibrary;

  id<MTLFunction> function_ = nullptr;
  ShaderStage stage_;

  ShaderFunction(id<MTLFunction> function, ShaderStage stage);

  FML_DISALLOW_COPY_AND_ASSIGN(ShaderFunction);
};

}  // namespace impeller
