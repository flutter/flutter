// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <variant>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "spirv_glsl.hpp"
#include "spirv_msl.hpp"

namespace impeller {
namespace compiler {

struct CompilerBackend {
  using MSLCompiler = std::shared_ptr<spirv_cross::CompilerMSL>;
  using GLSLCompiler = std::shared_ptr<spirv_cross::CompilerGLSL>;
  using Compiler = std::variant<MSLCompiler, GLSLCompiler>;

  enum class Type {
    kMSL,
    kGLSL,
  };

  CompilerBackend(MSLCompiler compiler);

  CompilerBackend(GLSLCompiler compiler);

  CompilerBackend(Type type, Compiler compiler);

  CompilerBackend();

  ~CompilerBackend();

  Type GetType() const;

  const spirv_cross::Compiler* operator->() const;

  operator bool() const;

  enum class ExtendedResourceIndex {
    kPrimary,
    kSecondary,
  };
  uint32_t GetExtendedMSLResourceBinding(ExtendedResourceIndex index,
                                         spirv_cross::ID id) const;

  const spirv_cross::Compiler* GetCompiler() const;

  spirv_cross::Compiler* GetCompiler();

 private:
  Type type_ = Type::kMSL;
  Compiler compiler_;

  const spirv_cross::CompilerMSL* GetMSLCompiler() const;

  const spirv_cross::CompilerGLSL* GetGLSLCompiler() const;
};

}  // namespace compiler
}  // namespace impeller
