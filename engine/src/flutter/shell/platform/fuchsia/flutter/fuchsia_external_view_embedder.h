// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FUCHSIA_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FUCHSIA_EXTERNAL_VIEW_EMBEDDER_H_

#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/ui/scenic/cpp/resources.h>
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
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

#include "session_connection.h"
#include "vulkan_surface_producer.h"

namespace flutter_runner {

// This class orchestrates interaction with the Scenic compositor on Fuchsia. It
// ensures that flutter content and platform view content are both rendered
// correctly in a unified scene.
class FuchsiaExternalViewEmbedder final : public flutter::ExternalViewEmbedder {
 public:
  FuchsiaExternalViewEmbedder(std::string debug_label,
                              fuchsia::ui::views::ViewToken view_token,
                              scenic::ViewRefPair view_ref_pair,
                              SessionConnection& session,
                              VulkanSurfaceProducer& surface_producer,
                              bool intercept_all_input = false);
  ~FuchsiaExternalViewEmbedder();

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
  void SubmitFrame(
      GrDirectContext* context,
      std::unique_ptr<flutter::SurfaceFrame> frame,
      const std::shared_ptr<fml::SyncSwitch>& gpu_disable_sync_switch) override;

  // |ExternalViewEmbedder|
  void CancelFrame() override { Reset(); }

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override { return false; }

  // View manipulation.
  // |SetViewProperties| doesn't manipulate the view directly -- it sets
  // prending properties for the next |UpdateView| call.
  void EnableWireframe(bool enable);
  void CreateView(int64_t view_id);
  void DestroyView(int64_t view_id);
  void SetViewProperties(int64_t view_id, bool hit_testable, bool focusable);

 private:
  // Reset state for a new frame.
  void Reset();

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

  struct ScenicView {
    scenic::OpacityNodeHACK opacity_node;
    scenic::EntityNode entity_node;
    scenic::ViewHolder view_holder;

    SkPoint offset = SkPoint::Make(0.f, 0.f);
    SkSize size = SkSize::MakeEmpty();
    float elevation = 0.f;
    float opacity = 1.f;
    bool hit_testable = false;
    bool focusable = false;

    bool pending_hit_testable = false;
    bool pending_focusable = false;
  };

  struct ScenicLayer {
    scenic::ShapeNode shape_node;
    scenic::Material material;
  };

  // Helper class for setting up an invisible rectangle to catch all input.
  // Rejected input will then be re-injected into a suitable platform view
  // controlled by this Engine instance.
  class InputInterceptor {
   public:
    InputInterceptor(scenic::Session* session)
        : opacity_node_(session), shape_node_(session) {
      opacity_node_.SetLabel("Flutter::InputInterceptor");
      opacity_node_.SetOpacity(0.5f);

      // Set the shape node to capture all input. Any unwanted input will be
      // reinjected.
      shape_node_.SetHitTestBehavior(
          fuchsia::ui::gfx::HitTestBehavior::kDefault);
      shape_node_.SetSemanticVisibility(false);

      opacity_node_.AddChild(shape_node_);
    }

    void UpdateDimensions(scenic::Session* session,
                          float width,
                          float height,
                          float elevation) {
      opacity_node_.SetTranslation(width * 0.5f, height * 0.5f, elevation);
      shape_node_.SetShape(scenic::Rectangle(session, width, height));
    }

    const scenic::Node& node() { return opacity_node_; }

   private:
    scenic::OpacityNodeHACK opacity_node_;
    scenic::ShapeNode shape_node_;
  };

  using EmbedderLayerId = std::optional<uint32_t>;
  constexpr static EmbedderLayerId kRootLayerId = EmbedderLayerId{};

  SessionConnection& session_;
  VulkanSurfaceProducer& surface_producer_;

  scenic::View root_view_;
  scenic::EntityNode metrics_node_;
  scenic::EntityNode root_node_;

  std::unordered_map<uint64_t, std::vector<scenic::Rectangle>> scenic_rects_;
  std::unordered_map<int64_t, ScenicView> scenic_views_;
  std::vector<ScenicLayer> scenic_layers_;

  std::optional<InputInterceptor> input_interceptor_;

  std::unordered_map<EmbedderLayerId, EmbedderLayer> frame_layers_;
  std::vector<EmbedderLayerId> frame_composition_order_;
  SkISize frame_size_ = SkISize::Make(0, 0);
  float frame_dpr_ = 1.f;

  bool intercept_all_input_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(FuchsiaExternalViewEmbedder);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_FUCHSIA_EXTERNAL_VIEW_EMBEDDER_H_
