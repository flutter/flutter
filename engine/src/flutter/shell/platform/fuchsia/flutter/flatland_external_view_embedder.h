// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_EXTERNAL_VIEW_EMBEDDER_H_

#include <fuchsia/ui/composition/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/fit/function.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>

#include <cstdint>  // For uint32_t & uint64_t
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/common/canvas_spy.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

#include "flatland_connection.h"
#include "surface_producer.h"

namespace flutter_runner {

using ViewCallback = std::function<void()>;
using FlatlandViewCreatedCallback = std::function<void(
    fuchsia::ui::composition::ContentId,
    fuchsia::ui::composition::ChildViewWatcherPtr child_view_watcher)>;
using FlatlandViewIdCallback =
    std::function<void(fuchsia::ui::composition::ContentId)>;

// This class orchestrates interaction with the Scenic's Flatland compositor on
// Fuchsia. It ensures that flutter content and platform view content are both
// rendered correctly in a unified scene.
class FlatlandExternalViewEmbedder final
    : public flutter::ExternalViewEmbedder {
 public:
  constexpr static uint32_t kFlatlandDefaultViewportSize = 32;

  FlatlandExternalViewEmbedder(
      fuchsia::ui::views::ViewCreationToken view_creation_token,
      fuchsia::ui::views::ViewIdentityOnCreation view_identity,
      fuchsia::ui::composition::ViewBoundProtocols endpoints,
      fidl::InterfaceRequest<fuchsia::ui::composition::ParentViewportWatcher>
          parent_viewport_watcher_request,
      std::shared_ptr<FlatlandConnection> flatland,
      std::shared_ptr<SurfaceProducer> surface_producer,
      bool intercept_all_input = false);
  ~FlatlandExternalViewEmbedder();

  // |ExternalViewEmbedder|
  SkCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id) override;

  // |ExternalViewEmbedder|
  flutter::PostPrerollResult PostPrerollAction(
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void BeginFrame(
      SkISize frame_size,
      GrDirectContext* context,
      double device_pixel_ratio,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void EndFrame(
      bool should_resubmit_frame,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void SubmitFrame(GrDirectContext* context,
                   std::unique_ptr<flutter::SurfaceFrame> frame) override;

  // |ExternalViewEmbedder|
  void CancelFrame() override { Reset(); }

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override { return false; }

  // View manipulation.
  // |SetViewProperties| doesn't manipulate the view directly -- it sets pending
  // properties for the next |UpdateView| call.
  void CreateView(int64_t view_id,
                  ViewCallback on_view_created,
                  FlatlandViewCreatedCallback on_view_bound);
  void DestroyView(int64_t view_id, FlatlandViewIdCallback on_view_unbound);
  void SetViewProperties(int64_t view_id,
                         const SkRect& occlusion_hint,
                         bool hit_testable,
                         bool focusable);

 private:
  void Reset();  // Reset state for a new frame.

  // This struct represents a transformed clip rect.
  struct TransformedClip {
    SkMatrix transform = SkMatrix::I();
    SkRect rect = SkRect::MakeEmpty();

    bool operator==(const TransformedClip& other) const {
      return transform == other.transform && rect == other.rect;
    }
  };

  // This struct represents all the mutators that can be applied to a
  // PlatformView, unpacked from the `MutatorStack`.
  struct ViewMutators {
    std::vector<TransformedClip> clips;
    SkMatrix total_transform = SkMatrix::I();
    SkMatrix transform = SkMatrix::I();
    SkScalar opacity = 1.f;

    bool operator==(const ViewMutators& other) const {
      return clips == other.clips && total_transform == other.total_transform &&
             transform == other.transform && opacity == other.opacity;
    }
  };

  ViewMutators ParseMutatorStack(const flutter::MutatorsStack& mutators_stack);

  struct EmbedderLayer {
    EmbedderLayer(const SkISize& frame_size,
                  std::optional<flutter::EmbeddedViewParams> view_params)
        : embedded_view_params(std::move(view_params)),
          recorder(std::make_unique<SkPictureRecorder>()),
          canvas_spy(std::make_unique<flutter::CanvasSpy>(
              recorder->beginRecording(frame_size.width(),
                                       frame_size.height()))),
          surface_size(frame_size) {}

    std::optional<flutter::EmbeddedViewParams> embedded_view_params;
    std::unique_ptr<SkPictureRecorder> recorder;
    std::unique_ptr<flutter::CanvasSpy> canvas_spy;
    SkISize surface_size;
  };
  using EmbedderLayerId = std::optional<uint32_t>;
  constexpr static EmbedderLayerId kRootLayerId = EmbedderLayerId{};

  struct FlatlandView {
    fuchsia::ui::composition::TransformId transform_id;
    fuchsia::ui::composition::ContentId viewport_id;
    ViewMutators mutators;
    SkSize size = SkSize::MakeEmpty();
    fit::callback<void(const SkSize&)> pending_create_viewport_callback;
  };

  struct FlatlandLayer {
    // Transform on which Images are set.
    fuchsia::ui::composition::TransformId transform_id;
  };

  std::shared_ptr<FlatlandConnection> flatland_;
  std::shared_ptr<SurfaceProducer> surface_producer_;

  fuchsia::ui::composition::ParentViewportWatcherPtr parent_viewport_watcher_;

  fuchsia::ui::composition::TransformId root_transform_id_;

  std::unordered_map<int64_t, FlatlandView> flatland_views_;
  std::vector<FlatlandLayer> flatland_layers_;

  std::unordered_map<EmbedderLayerId, EmbedderLayer> frame_layers_;
  std::vector<EmbedderLayerId> frame_composition_order_;
  std::vector<fuchsia::ui::composition::TransformId> child_transforms_;
  SkISize frame_size_ = SkISize::Make(0, 0);

  FML_DISALLOW_COPY_AND_ASSIGN(FlatlandExternalViewEmbedder);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FLATLAND_EXTERNAL_VIEW_EMBEDDER_H_
