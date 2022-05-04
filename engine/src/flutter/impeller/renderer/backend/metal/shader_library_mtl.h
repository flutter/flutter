// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>

#include <memory>
#include <string>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/base/comparable.h"
#include "impeller/renderer/shader_key.h"
#include "impeller/renderer/shader_library.h"

namespace impeller {

class ShaderLibraryMTL final : public ShaderLibrary {
 public:
  ShaderLibraryMTL();

  // |ShaderLibrary|
  ~ShaderLibraryMTL() override;

  // |ShaderLibrary|
  bool IsValid() const override;

 private:
  friend class ContextMTL;

  UniqueID library_id_;
  NSArray<id<MTLLibrary>>* libraries_ = nullptr;
  ShaderFunctionMap functions_;
  bool is_valid_ = false;

  ShaderLibraryMTL(NSArray<id<MTLLibrary>>* libraries);

  // |ShaderLibrary|
  std::shared_ptr<const ShaderFunction> GetFunction(
      const std::string_view& name,
      ShaderStage stage) override;

  FML_DISALLOW_COPY_AND_ASSIGN(ShaderLibraryMTL);
};

}  // namespace impeller
