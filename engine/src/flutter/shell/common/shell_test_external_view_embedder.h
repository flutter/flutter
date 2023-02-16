// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_TEST_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_TEST_EXTERNAL_VIEW_EMBEDDER_H_

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/raster_thread_merger.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief The external view embedder used by |ShellTestPlatformViewGL|
///
class ShellTestExternalViewEmbedder final : public ExternalViewEmbedder {
 public:
  using EndFrameCallBack =
      std::function<void(bool, fml::RefPtr<fml::RasterThreadMerger>)>;

  ShellTestExternalViewEmbedder(const EndFrameCallBack& end_frame_call_back,
                                PostPrerollResult post_preroll_result,
                                bool support_thread_merging);

  ~ShellTestExternalViewEmbedder() = default;

  // Updates the post preroll result so the |PostPrerollAction| after always
  // returns the new `post_preroll_result`.
  void UpdatePostPrerollResult(PostPrerollResult post_preroll_result);

  // Gets the number of times the SubmitFrame method has been called in
  // the external view embedder.
  int GetSubmittedFrameCount();

  // Returns the size of last submitted frame surface.
  SkISize GetLastSubmittedFrameSize();

  // Returns the mutators stack for the given platform view.
  MutatorsStack GetStack(int64_t);

  // Returns the list of visited platform views.
  std::vector<int64_t> GetVisitedPlatformViews();

 private:
  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(
      SkISize frame_size,
      GrDirectContext* context,
      double device_pixel_ratio,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  PostPrerollResult PostPrerollAction(
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |ExternalViewEmbedder|
  std::vector<DisplayListBuilder*> GetCurrentBuilders() override;

  // |ExternalViewEmbedder|
  EmbedderPaintContext CompositeEmbeddedView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  void PushVisitedPlatformView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  void PushFilterToVisitedPlatformViews(
      std::shared_ptr<const DlImageFilter> filter,
      const SkRect& filter_rect) override;

  // |ExternalViewEmbedder|
  void SubmitFrame(GrDirectContext* context,
                   std::unique_ptr<SurfaceFrame> frame) override;

  // |ExternalViewEmbedder|
  void EndFrame(
      bool should_resubmit_frame,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  SkCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override;

  const EndFrameCallBack end_frame_call_back_;

  PostPrerollResult post_preroll_result_;

  bool support_thread_merging_;
  SkISize frame_size_;
  std::map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices_;
  std::map<int64_t, MutatorsStack> mutators_stacks_;
  std::map<int64_t, EmbeddedViewParams> current_composition_params_;
  std::vector<int64_t> visited_platform_views_;
  std::atomic<int> submitted_frame_count_;
  std::atomic<SkISize> last_submitted_frame_size_;

  FML_DISALLOW_COPY_AND_ASSIGN(ShellTestExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_TEST_EXTERNAL_VIEW_EMBEDDER_H_
