// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/reflector.h"

#include "flutter/fml/logging.h"

namespace impeller {
namespace compiler {

std::string SPIRVTypeToString(const spirv_cross::CompilerMSL& compiler,
                              const spirv_cross::SPIRType& type,
                              size_t indent = 0) {
  std::string pad(indent, '-');

  std::stringstream stream;
  stream << std::endl;

  // stream << pad << "Type ID: " << type.identifier << std::endl;

  if (auto identifier = compiler.get_name(type.basetype); !identifier.empty()) {
    stream << pad << "OpName: " << identifier << std::endl;
  }

  for (const auto& member : type.member_types) {
    stream << SPIRVTypeToString(compiler, compiler.get_type(member),
                                indent += 2);
  }

  return stream.str();
}

Reflector::Reflector(const spirv_cross::CompilerMSL& compiler) {
  auto resources = compiler.get_shader_resources();

  for (const auto& stage_input : resources.stage_inputs) {
    FML_LOG(ERROR) << stage_input.name;
  }

  for (const auto& stage_output : resources.stage_outputs) {
    FML_LOG(ERROR) << stage_output.name;
  }

  for (const auto& uniform_buffer : resources.uniform_buffers) {
    FML_LOG(ERROR) << uniform_buffer.name;
    auto type = compiler.get_type(uniform_buffer.type_id);

    FML_LOG(ERROR) << SPIRVTypeToString(compiler, type);
  }

  is_valid_ = true;
}

Reflector::~Reflector() = default;

bool Reflector::IsValid() const {
  return is_valid_;
}

}  // namespace compiler
}  // namespace impeller
