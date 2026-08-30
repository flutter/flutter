// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_H_

#include <iosfwd>
#include <map>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context.h"
#include "flutter/testing/testing.h"
#include "flutter/testing/thread_test.h"
#include "gtest/gtest.h"

namespace flutter::testing {

class EmbedderConfigBuilder;
class EmbedderTestContextGL;
class EmbedderTestContextMetal;
class EmbedderTestContextSoftware;
class EmbedderTestContextVulkan;

const char* EmbedderTestContextTypeToString(EmbedderTestContextType type);
bool IsBackendSupported(EmbedderTestContextType type);
std::vector<EmbedderTestContextType> GetSupportedBackends();
std::vector<EmbedderTestContextType> GetSupportedGpuBackends();

std::ostream& operator<<(std::ostream& os, const EmbedderTestContextType& type);
void PrintTo(const EmbedderTestContextType& type, std::ostream* os);

struct EmbedderTestParam {
  EmbedderTestContextType backend_type =
      EmbedderTestContextType::kSoftwareContext;
  bool enable_impeller = false;
  std::vector<std::string> extra_arguments = {};

  EmbedderTestParam() = default;
  explicit EmbedderTestParam(EmbedderTestContextType backend,
                             bool impeller = false,
                             std::vector<std::string> args = {})
      : backend_type(backend),
        enable_impeller(impeller),
        extra_arguments(std::move(args)) {}

  std::string ToString() const;
};

std::ostream& operator<<(std::ostream& os, const EmbedderTestParam& param);
void PrintTo(const EmbedderTestParam& param, std::ostream* os);

struct EmbedderTestParamName {
  std::string operator()(
      const ::testing::TestParamInfo<EmbedderTestContextType>& info) const;
  std::string operator()(
      const ::testing::TestParamInfo<EmbedderTestParam>& info) const;
};

std::vector<EmbedderTestParam> GetSupportedMatrixConfigs();
std::vector<EmbedderTestParam> GetSupportedGpuMatrixConfigs();

class EmbedderTest : public ThreadTest {
 public:
  EmbedderTest();

  std::string GetFixturesDirectory() const;

  template <typename T>
  T& GetEmbedderContext() {
    static_assert(false, "Unsupported test context type");
  }

  template <>
  EmbedderTestContextGL& GetEmbedderContext<EmbedderTestContextGL>() {
    return reinterpret_cast<EmbedderTestContextGL&>(GetGLContext());
  }

  template <>
  EmbedderTestContextMetal& GetEmbedderContext<EmbedderTestContextMetal>() {
    return reinterpret_cast<EmbedderTestContextMetal&>(GetMetalContext());
  }

  template <>
  EmbedderTestContextSoftware&
  GetEmbedderContext<EmbedderTestContextSoftware>() {
    return reinterpret_cast<EmbedderTestContextSoftware&>(GetSoftwareContext());
  }

  template <>
  EmbedderTestContextVulkan& GetEmbedderContext<EmbedderTestContextVulkan>() {
    return reinterpret_cast<EmbedderTestContextVulkan&>(GetVulkanContext());
  }

  EmbedderTestContext& GetEmbedderContext(EmbedderTestContextType type);

 protected:
  // We return the base class here and reinterpret_cast in the template
  // specializations because we're using forward declarations rather than
  // including the headers directly, and thus the relationship between the base
  // class and subclasses is unknown to the compiler here. We avoid including
  // the headers directly because the Metal headers include Objective-C types,
  // and thus cannot be included in pure C++ translation units.
  EmbedderTestContext& GetGLContext();
  EmbedderTestContext& GetMetalContext();
  EmbedderTestContext& GetSoftwareContext();
  EmbedderTestContext& GetVulkanContext();

  std::unique_ptr<EmbedderTestContext> gl_context_;
  std::unique_ptr<EmbedderTestContext> metal_context_;
  std::unique_ptr<EmbedderTestContext> software_context_;
  std::unique_ptr<EmbedderTestContext> vulkan_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTest);
};

/// Fixture for GPU-specific tests (e.g. OpenGL, Vulkan) that rely on GPU image
/// comparison fixtures. Instantiated via `EmbedderTestGlVk` in
/// `embedder_gl_unittests.cc`.
class EmbedderTestMultiBackend
    : public EmbedderTest,
      public ::testing::WithParamInterface<EmbedderTestContextType> {
 public:
  using EmbedderTest::GetEmbedderContext;
  EmbedderTestContextType GetBackendType() const { return GetParam(); }
  EmbedderTestContext& GetEmbedderContext() {
    return EmbedderTest::GetEmbedderContext(GetParam());
  }
};

/// Fixture for general engine lifecycle and embedder tests that execute across
/// all supported backends (Software, OpenGL, Vulkan, Metal) without GPU fixture
/// image comparison dependencies. This is isolated from
/// `EmbedderTestMultiBackend` to prevent GoogleTest from running GPU-only
/// fixture tests on the Software backend.
class EmbedderAllBackendsTest
    : public EmbedderTest,
      public ::testing::WithParamInterface<EmbedderTestContextType> {
 public:
  using EmbedderTest::GetEmbedderContext;
  EmbedderTestContextType GetBackendType() const { return GetParam(); }
  EmbedderTestContext& GetEmbedderContext() {
    return EmbedderTest::GetEmbedderContext(GetParam());
  }
};

class EmbedderTestMatrix
    : public EmbedderTest,
      public ::testing::WithParamInterface<EmbedderTestParam> {
 public:
  using EmbedderTest::GetEmbedderContext;
  const EmbedderTestParam& GetTestParam() const { return GetParam(); }
  EmbedderTestContextType GetBackendType() const {
    return GetParam().backend_type;
  }
  bool IsImpellerEnabled() const { return GetParam().enable_impeller; }
  EmbedderTestContext& GetEmbedderContext() {
    return EmbedderTest::GetEmbedderContext(GetParam().backend_type);
  }

  void ConfigureBuilder(EmbedderConfigBuilder& builder);
};

}  // namespace flutter::testing

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_H_
