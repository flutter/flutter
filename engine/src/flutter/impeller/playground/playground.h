// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "gtest/gtest.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/renderer.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class PlaygroundImpl;

enum class PlaygroundBackend {
  kMetal,
  kOpenGLES,
};

std::string PlaygroundBackendToString(PlaygroundBackend backend);

class Playground : public ::testing::TestWithParam<PlaygroundBackend> {
 public:
  using SinglePassCallback = std::function<bool(RenderPass& pass)>;

  Playground();

  ~Playground();

  static constexpr bool is_enabled() { return is_enabled_; }

  void SetUp() override;

  void TearDown() override;

  PlaygroundBackend GetBackend() const;

  Point GetCursorPosition() const;

  ISize GetWindowSize() const;

  Point GetContentScale() const;

  std::shared_ptr<Context> GetContext() const;

  bool OpenPlaygroundHere(Renderer::RenderCallback render_callback);

  bool OpenPlaygroundHere(SinglePassCallback pass_callback);

  std::optional<DecompressedImage> LoadFixtureImageRGBA(
      const char* fixture_name) const;

  std::shared_ptr<Texture> CreateTextureForFixture(
      const char* fixture_name) const;

  std::shared_ptr<Texture> CreateTextureCubeForFixture(
      std::array<const char*, 6> fixture_names) const;

 private:
#if IMPELLER_ENABLE_PLAYGROUND
  static const bool is_enabled_ = true;
#else
  static const bool is_enabled_ = false;
#endif  // IMPELLER_ENABLE_PLAYGROUND

  struct GLFWInitializer;
  std::unique_ptr<GLFWInitializer> glfw_initializer_;
  std::unique_ptr<PlaygroundImpl> impl_;
  std::unique_ptr<Renderer> renderer_;
  Point cursor_position_;
  ISize window_size_ = ISize{1024, 768};

  void SetCursorPosition(Point pos);

  void SetWindowSize(ISize size);

  FML_DISALLOW_COPY_AND_ASSIGN(Playground);
};

#define INSTANTIATE_PLAYGROUND_SUITE(playground)                        \
  INSTANTIATE_TEST_SUITE_P(                                             \
      Play, playground,                                                 \
      ::testing::Values(PlaygroundBackend::kMetal,                      \
                        PlaygroundBackend::kOpenGLES),                  \
      [](const ::testing::TestParamInfo<Playground::ParamType>& info) { \
        return PlaygroundBackendToString(info.param);                   \
      });

}  // namespace impeller
