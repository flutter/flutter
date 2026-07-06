// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_PLAYGROUND_PLAYGROUND_H_
#define FLUTTER_IMPELLER_PLAYGROUND_PLAYGROUND_H_

#include <chrono>
#include <memory>

#include "flutter/fml/status.h"
#include "flutter/fml/time/time_delta.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/runtime_types.h"
#include "impeller/core/texture.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/point.h"
#include "impeller/playground/image/compressed_image.h"
#include "impeller/playground/image/decompressed_image.h"
#include "impeller/playground/switches.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class PlaygroundImpl;

namespace testing {
class GoldenDigestManager;
}

enum class PlaygroundBackend {
  kMetal,
  kMetalSDF,
  kOpenGLES,
  kOpenGLESSDF,
  kVulkan,
};

std::string PlaygroundBackendToString(PlaygroundBackend backend);

class Playground {
 public:
  using SinglePassCallback = std::function<bool(RenderPass& pass)>;

  explicit Playground(PlaygroundBackend backend,
                      const PlaygroundSwitches& switches);

  virtual ~Playground();

  static bool ShouldOpenNewPlaygrounds();

  bool IsPlaygroundEnabled() const;

  Point GetCursorPosition() const;

  ISize GetWindowSize() const;

  IRect GetWindowBounds() const;

  Point GetContentScale() const;

  /// @brief Get the amount of time elapsed from the start of the playground's
  /// execution.
  Scalar GetSecondsElapsed() const;

  std::shared_ptr<Context> GetContext() const;

  std::shared_ptr<Context> MakeContext() const;

  ContentContext& GetContentContext() const;

  std::shared_ptr<TypographerContext>& GetTypographerContext() const;

  using RenderCallback = std::function<bool(RenderTarget& render_target)>;

  /// @brief Whether this instance will write a golden image of the output
  ///        from |OpenPlaygroundHere|.
  bool ShouldWriteGoldenImage();

  /// @brief Sets a particular test to either write a golden or not, false
  ///        by default.
  void SetEnableWriteGolden(bool write_golden);

  bool OpenPlaygroundHere(const RenderCallback& render_callback);

  bool OpenPlaygroundHere(const SinglePassCallback& pass_callback);

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

  [[nodiscard]] fml::Status SetCapabilities(
      const std::shared_ptr<Capabilities>& capabilities);

  using GLProcAddressResolver = std::function<void*(const char* proc_name)>;
  GLProcAddressResolver CreateGLProcAddressResolver() const;

  using VKProcAddressResolver =
      std::function<void*(void* instance, const char* proc_name)>;
  VKProcAddressResolver CreateVKProcAddressResolver() const;

  /// @brief Mark the GPU as unavilable.
  ///
  /// Only supported on the Metal backend.
  void SetGPUDisabled(bool disabled) const;

  RuntimeStageBackend GetRuntimeStageBackend() const;

 protected:
  // This method could override testing::Test::TearDown() directly, but
  // since we don't inherit from that Test class the override would not
  // be recognized. Instead we make this method available to subclasses
  // that do inherit from testing::Test so that they can redirect to
  // it during test teardown.
  void TearDownContextData();

  virtual bool ShouldKeepRendering() const;

  /// @brief Make sure that when the context is later created that it
  ///        will not be shared with any other playgrounds.
  ///
  /// Must be called before any other method except for the Ensure family
  /// of methods.
  virtual void EnsureContextIsUnique();

  /// @brief Returns true if the platform can support wide gamuts.
  bool PlatformSupportsWideGamutTests() const;

  /// @brief Make sure that when the context is later created that it
  ///        will support wide gamuts if the platform supports it.
  ///        Returns whether the platform supports wide gamut.
  ///
  /// Must be called before any other method except for the Ensure family
  /// of methods.
  ///
  /// Callers should abort (such as via GTEST_SKIP) if the method returns
  /// false if their behavior depends on the wide gamut support.
  ///
  /// @see PlatformSupportsWideGamut()
  [[nodiscard]] virtual bool EnsureContextSupportsWideGamut();

  /// @brief Returns true if the platform can support experimental AA lines.
  bool PlatformSupportsAtialiasLines() const;

  /// @brief Make sure that when the context is later created that it
  ///        will support the experimental AA lines flag.
  ///
  /// Must be called before any other method except for the Ensure family
  /// of methods.
  ///
  /// Callers should abort (such as via GTEST_SKIP) if the method returns
  /// false if their behavior depends on the experimental AA lines.
  [[nodiscard]] virtual bool EnsureContextSupportsAntialiasLines();

  /// @brief  Return an unmodifiable reference to the current switches.
  ///         The switches might change at the start of a test as it
  ///         has a brief opportunity to call any of the Ensure* methods
  ///         that define the environment it expects, but should be
  ///         stable by the time any subsequent methods that might perform
  ///         work are called.
  const PlaygroundSwitches& GetSwitches() const { return switches_; }

  void SetTypographerContext(
      std::shared_ptr<TypographerContext> typographer_context);

  void SetWindowSize(ISize size);

  virtual testing::GoldenDigestManager* GetGoldenDigestManager() const;

 private:
  const PlaygroundBackend backend_;
  PlaygroundSwitches switches_;

  fml::TimeDelta start_time_;

  // The following state variables are created lazily because not every
  // playground instance uses them. Most, if not all, do use the |impl_|
  // and |context_| implicitly, especially when running with the playground
  // window enabled, but the content and typographer contexts are only used
  // by a small portion of the unit tests.
  //
  // Since they are created lazily upon first reference, they are triggered
  // by const getter methods and so need to be mutable for the first call
  // when they get initialized.
  mutable std::unique_ptr<PlaygroundImpl> impl_;
  mutable std::shared_ptr<Context> context_;
  mutable std::unique_ptr<ContentContext> content_context_;
  mutable std::shared_ptr<TypographerContext> typographer_context_;

  Point cursor_position_;
  ISize window_size_ = ISize{1024, 768};
  std::shared_ptr<HostBuffer> host_buffer_;
  bool should_write_golden_ = false;

  std::unique_ptr<PlaygroundImpl>& GetImpl() const;

  void SetupContext() const;

  void SetupWindow();

  void SetCursorPosition(Point pos);

  [[nodiscard]]
  bool RenderImage(const RenderCallback& render_callback, bool write_image);

  [[nodiscard]]
  bool WriteGoldenImage(const RenderTarget& render_target,
                        const std::string& postfix = "");

  Playground(const Playground&) = delete;

  Playground& operator=(const Playground&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_PLAYGROUND_PLAYGROUND_H_
