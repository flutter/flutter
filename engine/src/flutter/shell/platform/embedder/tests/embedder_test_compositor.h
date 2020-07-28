// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_COMPOSITOR_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_COMPOSITOR_H_

#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {
namespace testing {

class EmbedderTestCompositor {
 public:
  enum class RenderTargetType {
    kOpenGLFramebuffer,
    kOpenGLTexture,
    kSoftwareBuffer,
  };

  EmbedderTestCompositor(SkISize surface_size, sk_sp<GrDirectContext> context);

  ~EmbedderTestCompositor();

  void SetRenderTargetType(RenderTargetType type);

  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out);

  bool CollectBackingStore(const FlutterBackingStore* backing_store);

  bool Present(const FlutterLayer** layers, size_t layers_count);

  using PlatformViewRendererCallback =
      std::function<sk_sp<SkImage>(const FlutterLayer& layer,
                                   GrDirectContext* context)>;
  void SetPlatformViewRendererCallback(
      const PlatformViewRendererCallback& callback);

  using PresentCallback =
      std::function<void(const FlutterLayer** layers, size_t layers_count)>;
  //----------------------------------------------------------------------------
  /// @brief      Allows tests to install a callback to notify them when the
  ///             entire render tree has been finalized so they can run their
  ///             assertions.
  ///
  /// @param[in]  next_present_callback  The next present callback
  ///
  void SetNextPresentCallback(const PresentCallback& next_present_callback);

  void SetPresentCallback(const PresentCallback& present_callback,
                          bool one_shot);

  using NextSceneCallback = std::function<void(sk_sp<SkImage> image)>;
  void SetNextSceneCallback(const NextSceneCallback& next_scene_callback);

  sk_sp<SkImage> GetLastComposition();

  size_t GetPendingBackingStoresCount() const;

  size_t GetBackingStoresCreatedCount() const;

  size_t GetBackingStoresCollectedCount() const;

  void AddOnCreateRenderTargetCallback(fml::closure callback);

  void AddOnCollectRenderTargetCallback(fml::closure callback);

  void AddOnPresentCallback(fml::closure callback);

 private:
  const SkISize surface_size_;
  sk_sp<GrDirectContext> context_;
  RenderTargetType type_ = RenderTargetType::kOpenGLFramebuffer;
  PlatformViewRendererCallback platform_view_renderer_callback_;
  bool present_callback_is_one_shot_ = false;
  PresentCallback present_callback_;
  NextSceneCallback next_scene_callback_;
  sk_sp<SkImage> last_composition_;
  size_t backing_stores_created_ = 0;
  size_t backing_stores_collected_ = 0;
  std::vector<fml::closure> on_create_render_target_callbacks_;
  std::vector<fml::closure> on_collect_render_target_callbacks_;
  std::vector<fml::closure> on_present_callbacks_;

  bool UpdateOffscrenComposition(const FlutterLayer** layers,
                                 size_t layers_count);

  bool CreateFramebufferRenderSurface(const FlutterBackingStoreConfig* config,
                                      FlutterBackingStore* renderer_out);

  bool CreateTextureRenderSurface(const FlutterBackingStoreConfig* config,
                                  FlutterBackingStore* renderer_out);

  bool CreateSoftwareRenderSurface(const FlutterBackingStoreConfig* config,
                                   FlutterBackingStore* renderer_out);

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestCompositor);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_COMPOSITOR_H_
