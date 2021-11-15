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
#include "impeller/renderer/comparable.h"
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

  struct ShaderKey {
    std::string name;
    ShaderStage stage = ShaderStage::kUnknown;

    ShaderKey(const std::string_view& p_name, ShaderStage p_stage)
        : name({p_name.data(), p_name.size()}), stage(p_stage) {}

    struct Hash {
      size_t operator()(const ShaderKey& key) const {
        return fml::HashCombine(key.name, key.stage);
      }
    };

    struct Equal {
      constexpr bool operator()(const ShaderKey& k1,
                                const ShaderKey& k2) const {
        return k1.stage == k2.stage && k1.name == k2.name;
      }
    };
  };

  using Functions = std::unordered_map<ShaderKey,
                                       std::shared_ptr<const ShaderFunction>,
                                       ShaderKey::Hash,
                                       ShaderKey::Equal>;

  UniqueID library_id_;
  NSArray<id<MTLLibrary>>* libraries_ = nullptr;
  Functions functions_;
  bool is_valid_ = false;

  ShaderLibraryMTL(NSArray<id<MTLLibrary>>* libraries);

  // |ShaderLibrary|
  std::shared_ptr<const ShaderFunction> GetFunction(
      const std::string_view& name,
      ShaderStage stage) override;

  FML_DISALLOW_COPY_AND_ASSIGN(ShaderLibraryMTL);
};

}  // namespace impeller
