// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_COMPOSITOR_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_COMPOSITOR_H_

#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace flutter {
namespace testing {

class EmbedderTestCompositor {
 public:
  enum class RenderTargetType {
    kOpenGLFramebuffer,
    kOpenGLTexture,
    kSoftwareBuffer,
  };

  EmbedderTestCompositor(sk_sp<GrContext> context);

  ~EmbedderTestCompositor();

  void SetRenderTargetType(RenderTargetType type);

  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out);

  bool CollectBackingStore(const FlutterBackingStore* backing_store);

  bool Present(const FlutterLayer** layers, size_t layers_count);

  using PlatformViewRendererCallback =
      std::function<sk_sp<SkImage>(const FlutterLayer& layer,
                                   GrContext* context)>;
  void SetPlatformViewRendererCallback(PlatformViewRendererCallback callback);

  using PresentCallback =
      std::function<void(const FlutterLayer** layers, size_t layers_count)>;
  //----------------------------------------------------------------------------
  /// @brief      Allows tests to install a callback to notify them when the
  ///             entire render tree has been finalized so they can run their
  ///             assertions.
  ///
  /// @param[in]  next_present_callback  The next present callback
  ///
  void SetNextPresentCallback(PresentCallback next_present_callback);

  using NextSceneCallback = std::function<void(sk_sp<SkImage> image)>;
  void SetNextSceneCallback(NextSceneCallback next_scene_callback);

  sk_sp<SkImage> GetLastComposition();

  size_t GetBackingStoresCount() const;

 private:
  sk_sp<GrContext> context_;
  RenderTargetType type_ = RenderTargetType::kOpenGLFramebuffer;
  PlatformViewRendererCallback platform_view_renderer_callback_;
  PresentCallback next_present_callback_;
  NextSceneCallback next_scene_callback_;
  sk_sp<SkImage> last_composition_;
  // The number of currently allocated backing stores (created - collected).
  size_t backing_stores_count_ = 0;

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
