// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test.h"

#include <cctype>
#include <exception>
#include <iostream>
#include <utility>

#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_software.h"

namespace flutter::testing {

const char* EmbedderTestContextTypeToString(EmbedderTestContextType type) {
  switch (type) {
    case EmbedderTestContextType::kSoftwareContext:
      return "Software";
    case EmbedderTestContextType::kOpenGLContext:
      return "OpenGL";
    case EmbedderTestContextType::kMetalContext:
      return "Metal";
    case EmbedderTestContextType::kVulkanContext:
      return "Vulkan";
  }
  FML_UNREACHABLE();
}

bool IsBackendSupported(EmbedderTestContextType type) {
  switch (type) {
    case EmbedderTestContextType::kSoftwareContext:
      return true;
    case EmbedderTestContextType::kOpenGLContext:
#ifdef SHELL_ENABLE_GL
      return true;
#else
      return false;
#endif
    case EmbedderTestContextType::kMetalContext:
#ifdef SHELL_ENABLE_METAL
      return true;
#else
      return false;
#endif
    case EmbedderTestContextType::kVulkanContext:
#ifdef SHELL_ENABLE_VULKAN
      return true;
#else
      return false;
#endif
  }
  FML_UNREACHABLE();
}

std::vector<EmbedderTestContextType> GetSupportedBackends() {
  std::vector<EmbedderTestContextType> backends;
  backends.push_back(EmbedderTestContextType::kSoftwareContext);
#ifdef SHELL_ENABLE_GL
  backends.push_back(EmbedderTestContextType::kOpenGLContext);
#endif
#ifdef SHELL_ENABLE_METAL
  backends.push_back(EmbedderTestContextType::kMetalContext);
#endif
#ifdef SHELL_ENABLE_VULKAN
  backends.push_back(EmbedderTestContextType::kVulkanContext);
#endif
  return backends;
}

std::vector<EmbedderTestContextType> GetSupportedGpuBackends() {
  std::vector<EmbedderTestContextType> backends;
#ifdef SHELL_ENABLE_GL
  backends.push_back(EmbedderTestContextType::kOpenGLContext);
#endif
#ifdef SHELL_ENABLE_METAL
  backends.push_back(EmbedderTestContextType::kMetalContext);
#endif
#ifdef SHELL_ENABLE_VULKAN
  backends.push_back(EmbedderTestContextType::kVulkanContext);
#endif
  return backends;
}

std::ostream& operator<<(std::ostream& os,
                         const EmbedderTestContextType& type) {
  os << EmbedderTestContextTypeToString(type);
  return os;
}

void PrintTo(const EmbedderTestContextType& type, std::ostream* os) {
  *os << EmbedderTestContextTypeToString(type);
}

std::string EmbedderTestParam::ToString() const {
  std::string result = EmbedderTestContextTypeToString(backend_type);
  if (enable_impeller) {
    result += "_Impeller";
  }
  for (const auto& arg : extra_arguments) {
    result += "_";
    for (char c : arg) {
      if (std::isalnum(c)) {
        result += c;
      } else {
        result += '_';
      }
    }
  }
  return result;
}

std::ostream& operator<<(std::ostream& os, const EmbedderTestParam& param) {
  os << param.ToString();
  return os;
}

void PrintTo(const EmbedderTestParam& param, std::ostream* os) {
  *os << param.ToString();
}

std::string EmbedderTestParamName::operator()(
    const ::testing::TestParamInfo<EmbedderTestContextType>& info) const {
  return EmbedderTestContextTypeToString(info.param);
}

std::string EmbedderTestParamName::operator()(
    const ::testing::TestParamInfo<EmbedderTestParam>& info) const {
  return info.param.ToString();
}

std::vector<EmbedderTestParam> GetSupportedMatrixConfigs() {
  std::vector<EmbedderTestParam> configs;
  for (auto backend : GetSupportedBackends()) {
    configs.emplace_back(backend, /*impeller=*/false);
  }
  return configs;
}

std::vector<EmbedderTestParam> GetSupportedGpuMatrixConfigs() {
  std::vector<EmbedderTestParam> configs;
  for (auto backend : GetSupportedGpuBackends()) {
    configs.emplace_back(backend, /*impeller=*/false);
    configs.emplace_back(backend, /*impeller=*/true);
  }
  return configs;
}

EmbedderTest::EmbedderTest() = default;

std::string EmbedderTest::GetFixturesDirectory() const {
  return GetFixturesPath();
}

EmbedderTestContext& EmbedderTest::GetSoftwareContext() {
  if (!software_context_) {
    software_context_ =
        std::make_unique<EmbedderTestContextSoftware>(GetFixturesDirectory());
  }
  return *software_context_.get();
}

#ifndef SHELL_ENABLE_GL
// Fallback implementation.
// See: flutter/shell/platform/embedder/tests/embedder_test_gl.cc.
EmbedderTestContext& EmbedderTest::GetGLContext() {
  FML_LOG(FATAL) << "OpenGL is not supported in this build";
  std::terminate();
}
#endif

#ifndef SHELL_ENABLE_METAL
// Fallback implementation.
// See: flutter/shell/platform/embedder/tests/embedder_test_metal.mm.
EmbedderTestContext& EmbedderTest::GetMetalContext() {
  FML_LOG(FATAL) << "Metal is not supported in this build";
  std::terminate();
}
#endif

#ifndef SHELL_ENABLE_VULKAN
// Fallback implementation.
// See: flutter/shell/platform/embedder/tests/embedder_test_vulkan.cc.
EmbedderTestContext& EmbedderTest::GetVulkanContext() {
  FML_LOG(FATAL) << "Vulkan is not supported in this build";
  std::terminate();
}
#endif

EmbedderTestContext& EmbedderTest::GetEmbedderContext(
    EmbedderTestContextType type) {
  switch (type) {
    case EmbedderTestContextType::kOpenGLContext:
      return GetGLContext();
    case EmbedderTestContextType::kMetalContext:
      return GetMetalContext();
    case EmbedderTestContextType::kSoftwareContext:
      return GetSoftwareContext();
    case EmbedderTestContextType::kVulkanContext:
      return GetVulkanContext();
  }
  FML_UNREACHABLE();
}

void EmbedderTestMatrix::ConfigureBuilder(EmbedderConfigBuilder& builder) {
  TRACE_EVENT0("flutter", "EmbedderTestMatrix::ConfigureBuilder");
  if (GetParam().enable_impeller) {
    builder.AddCommandLineArgument("--enable-impeller");
  }
  for (const auto& arg : GetParam().extra_arguments) {
    builder.AddCommandLineArgument(arg);
  }
}

}  // namespace flutter::testing
