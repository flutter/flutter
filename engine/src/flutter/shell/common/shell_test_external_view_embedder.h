// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_TEST_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_TEST_EXTERNAL_VIEW_EMBEDDER_H_

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/raster_thread_merger.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief The external view embedder used by |ShellTestPlatformViewGL|
///
class ShellTestExternalViewEmbedder final : public ExternalViewEmbedder {
 public:
  using EndFrameCallBack = std::function<void(void)>;

  ShellTestExternalViewEmbedder(const EndFrameCallBack& end_frame_call_back,
                                PostPrerollResult post_preroll_result)
      : end_frame_call_back_(end_frame_call_back),
        post_preroll_result_(post_preroll_result) {}

  ~ShellTestExternalViewEmbedder() = default;

 private:
  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(SkISize frame_size,
                  GrContext* context,
                  double device_pixel_ratio) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int view_id,
      std::unique_ptr<EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  PostPrerollResult PostPrerollAction(
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id) override;

  // |ExternalViewEmbedder|
  bool SubmitFrame(GrContext* context, SkCanvas* background_canvas) override;

  // |ExternalViewEmbedder|
  void FinishFrame() override;

  // |ExternalViewEmbedder|
  void EndFrame(
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  SkCanvas* GetRootCanvas() override;

  const EndFrameCallBack end_frame_call_back_;
  const PostPrerollResult post_preroll_result_;

  FML_DISALLOW_COPY_AND_ASSIGN(ShellTestExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_TEST_EXTERNAL_VIEW_EMBEDDER_H_
