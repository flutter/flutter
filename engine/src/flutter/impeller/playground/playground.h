// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <chrono>
#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_delta.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/point.h"
#include "impeller/image/compressed_image.h"
#include "impeller/image/decompressed_image.h"
#include "impeller/playground/switches.h"
#include "impeller/renderer/renderer.h"
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

  explicit Playground(PlaygroundSwitches switches);

  virtual ~Playground();

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

  static std::shared_ptr<CompressedImage> LoadFixtureImageCompressed(
      std::shared_ptr<fml::Mapping> mapping);

  static std::optional<DecompressedImage> DecodeImageRGBA(
      const std::shared_ptr<CompressedImage>& compressed);

  static std::shared_ptr<Texture> CreateTextureForMapping(
      const std::shared_ptr<Context>& context,
      std::shared_ptr<fml::Mapping> mapping,
      bool enable_mipmapping = false);

  std::shared_ptr<Texture> CreateTextureForFixture(
      const char* fixture_name,
      bool enable_mipmapping = false) const;

  std::shared_ptr<Texture> CreateTextureCubeForFixture(
      std::array<const char*, 6> fixture_names) const;

  static bool SupportsBackend(PlaygroundBackend backend);

  virtual std::unique_ptr<fml::Mapping> OpenAssetAsMapping(
      std::string asset_name) const = 0;

  virtual std::string GetWindowTitle() const = 0;

 protected:
  const PlaygroundSwitches switches_;

  virtual bool ShouldKeepRendering() const;

  void SetWindowSize(ISize size);

 private:
  struct GLFWInitializer;

  fml::TimeDelta start_time_;
  std::unique_ptr<GLFWInitializer> glfw_initializer_;
  std::unique_ptr<PlaygroundImpl> impl_;
  std::shared_ptr<Context> context_;
  std::unique_ptr<Renderer> renderer_;
  Point cursor_position_;
  ISize window_size_ = ISize{1024, 768};

  void SetCursorPosition(Point pos);

  Playground(const Playground&) = delete;

  Playground& operator=(const Playground&) = delete;
};

}  // namespace impeller
