// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <codecvt>
#include <locale>
#include <string>

#include "flutter/fml/macros.h"
#include "shaderc/shaderc.hpp"
#include "spirv_cross.hpp"
#include "spirv_msl.hpp"

namespace impeller {
namespace compiler {

enum class SourceType {
  kUnknown,
  kVertexShader,
  kFragmentShader,
  kTessellationControlShader,
  kTessellationEvaluationShader,
  kComputeShader,
};

enum class TargetPlatform {
  kUnknown,
  kMetalDesktop,
  kMetalIOS,
  kFlutterSPIRV,
  kOpenGLES,
  kOpenGLDesktop,
  kRuntimeStageMetal,
  kRuntimeStageGLES,
};

bool TargetPlatformIsMetal(TargetPlatform platform);

bool TargetPlatformIsOpenGL(TargetPlatform platform);

SourceType SourceTypeFromFileName(const std::string& file_name);

std::string SourceTypeToString(SourceType type);

std::string TargetPlatformToString(TargetPlatform platform);

std::string TargetPlatformSLExtension(TargetPlatform platform);

std::string EntryPointFunctionNameFromSourceName(const std::string& file_name,
                                                 SourceType type);

bool TargetPlatformNeedsSL(TargetPlatform platform);

bool TargetPlatformNeedsReflection(TargetPlatform platform);

std::string ShaderCErrorToString(shaderc_compilation_status status);

shaderc_shader_kind ToShaderCShaderKind(SourceType type);

spv::ExecutionModel ToExecutionModel(SourceType type);

spirv_cross::CompilerMSL::Options::Platform TargetPlatformToMSLPlatform(
    TargetPlatform platform);

std::string ToUtf8(const std::wstring& wstring);

std::string ToUtf8(const std::string& string);

}  // namespace compiler
}  // namespace impeller
