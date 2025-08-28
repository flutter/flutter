// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_WRAPPER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_WRAPPER_H_

#include "flutter/common/task_runners.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder_2.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/surface/android_surface.h"

namespace flutter {

//------------------------------------------------------------------------------
/// A wrapper for the android external view embedder classes that dynamically
/// selects the implementation to use.
///
/// This wrapper is used to defer external view embedder construction until the
/// impeller context setup has completed on the raster thread.
class AndroidExternalViewEmbedderWrapper final : public ExternalViewEmbedder {
 public:
  AndroidExternalViewEmbedderWrapper(
      bool meets_hcpp_criteria,
      const AndroidContext& android_context,
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      std::shared_ptr<AndroidSurfaceFactory> surface_factory,
      const TaskRunners& task_runners);

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  DlCanvas* CompositeEmbeddedView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  void SubmitFlutterView(
      int64_t flutter_view_id,
      GrDirectContext* context,
      const std::shared_ptr<impeller::AiksContext>& aiks_context,
      std::unique_ptr<SurfaceFrame> frame) override;

  // |ExternalViewEmbedder|
  PostPrerollResult PostPrerollAction(
      const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger)
      override;

  // |ExternalViewEmbedder|
  DlCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void BeginFrame(GrDirectContext* context,
                  const fml::RefPtr<fml::RasterThreadMerger>&
                      raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void PrepareFlutterView(DlISize frame_size,
                          double device_pixel_ratio) override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void EndFrame(bool should_resubmit_frame,
                const fml::RefPtr<fml::RasterThreadMerger>&
                    raster_thread_merger) override;

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override;

  // |ExternalViewEmbedder|
  void Teardown() override;

 private:
  void EnsureInitialized();

  // Whether the device has hcpp mode initialized and is at least API 34.
  const bool meets_hcpp_criteria_;
  const AndroidContext& android_context_;
  const TaskRunners& task_runners_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  std::shared_ptr<AndroidSurfaceFactory> surface_factory_;
  std::unique_ptr<AndroidExternalViewEmbedder> non_hcpp_view_embedder_;
  std::unique_ptr<AndroidExternalViewEmbedder2> hcpp_view_embedder_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_WRAPPER_H_
