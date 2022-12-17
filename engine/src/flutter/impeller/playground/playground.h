// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_delta.h"

#include "impeller/geometry/point.h"
#include "impeller/renderer/renderer.h"
#include "impeller/renderer/texture.h"
#include "impeller/runtime_stage/runtime_stage.h"

namespace impeller {

class PlaygroundImpl;

enum class PlaygroundBackend {
  kMetal,
  kOpenGLES,
  kVulkan,
};

std::string PlaygroundBackendToString(PlaygroundBackend backend);

class Playground {
 public:
  using SinglePassCallback = std::function<bool(RenderPass& pass)>;

  explicit Playground();

  virtual ~Playground();

  static constexpr bool is_enabled() { return is_enabled_; }

  static bool ShouldOpenNewPlaygrounds();

  void SetupContext(PlaygroundBackend backend);

  void SetupWindow();

  void TeardownWindow();

  Point GetCursorPosition() const;

  ISize GetWindowSize() const;

  Point GetContentScale() const;

  /// @brief Get the amount of time elapsed from the start of the playground's
  /// execution.
  Scalar GetSecondsElapsed() const;

  std::shared_ptr<Context> GetContext() const;

  bool OpenPlaygroundHere(const Renderer::RenderCallback& render_callback);

  bool OpenPlaygroundHere(SinglePassCallback pass_callback);

  std::optional<DecompressedImage> LoadFixtureImageRGBA(
      const char* fixture_name) const;

  std::shared_ptr<Texture> CreateTextureForFixture(
      const char* fixture_name,
      bool enable_mipmapping = false) const;

  std::shared_ptr<Texture> CreateTextureCubeForFixture(
      std::array<const char*, 6> fixture_names) const;

  static bool SupportsBackend(PlaygroundBackend backend);

  virtual std::unique_ptr<fml::Mapping> OpenAssetAsMapping(
      std::string asset_name) const = 0;

  virtual std::string GetWindowTitle() const = 0;

 private:
#if IMPELLER_ENABLE_PLAYGROUND
  static const bool is_enabled_ = true;
#else
  static const bool is_enabled_ = false;
#endif  // IMPELLER_ENABLE_PLAYGROUND

  fml::TimeDelta start_time_;

  struct GLFWInitializer;
  std::unique_ptr<GLFWInitializer> glfw_initializer_;
  std::unique_ptr<PlaygroundImpl> impl_;
  std::shared_ptr<Context> context_;
  std::unique_ptr<Renderer> renderer_;
  Point cursor_position_;
  ISize window_size_ = ISize{1024, 768};

  void SetCursorPosition(Point pos);

  void SetWindowSize(ISize size);

  FML_DISALLOW_COPY_AND_ASSIGN(Playground);
};

}  // namespace impeller
