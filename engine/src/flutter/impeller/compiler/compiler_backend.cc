// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compiler/compiler_backend.h"

namespace impeller {
namespace compiler {

CompilerBackend::CompilerBackend(MSLCompiler compiler) : compiler_(compiler) {}

CompilerBackend::CompilerBackend(GLSLCompiler compiler) : compiler_(compiler) {}

CompilerBackend::CompilerBackend() = default;

CompilerBackend::CompilerBackend(Compiler compiler)
    : compiler_(std::move(compiler)){};

CompilerBackend::~CompilerBackend() = default;

const spirv_cross::Compiler* CompilerBackend::operator->() const {
  return GetCompiler();
}

uint32_t CompilerBackend::GetExtendedMSLResourceBinding(
    ExtendedResourceIndex index,
    spirv_cross::ID id) const {
  const auto kOOBIndex = static_cast<uint32_t>(-1);
  auto compiler = GetMSLCompiler();
  if (!compiler) {
    return kOOBIndex;
  }
  switch (index) {
    case ExtendedResourceIndex::kPrimary:
      return compiler->get_automatic_msl_resource_binding(id);
    case ExtendedResourceIndex::kSecondary:
      return compiler->get_automatic_msl_resource_binding_secondary(id);
      break;
  }
  return kOOBIndex;
}

const spirv_cross::Compiler* CompilerBackend::GetCompiler() const {
  if (auto compiler = GetGLSLCompiler()) {
    return compiler;
  }

  if (auto compiler = GetMSLCompiler()) {
    return compiler;
  }

  return nullptr;
}

spirv_cross::Compiler* CompilerBackend::GetCompiler() {
  if (auto* msl = std::get_if<MSLCompiler>(&compiler_)) {
    return msl->get();
  }
  if (auto* glsl = std::get_if<GLSLCompiler>(&compiler_)) {
    return glsl->get();
  }
  return nullptr;
}

const spirv_cross::CompilerMSL* CompilerBackend::GetMSLCompiler() const {
  if (auto* msl = std::get_if<MSLCompiler>(&compiler_)) {
    return msl->get();
  }
  return nullptr;
}

const spirv_cross::CompilerGLSL* CompilerBackend::GetGLSLCompiler() const {
  if (auto* glsl = std::get_if<GLSLCompiler>(&compiler_)) {
    return glsl->get();
  }
  return nullptr;
}

CompilerBackend::operator bool() const {
  return !!GetCompiler();
}

}  // namespace compiler
}  // namespace impeller
