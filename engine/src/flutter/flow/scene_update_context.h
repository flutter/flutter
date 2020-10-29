// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
#define FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_

#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/ui/scenic/cpp/resources.h>
#include <lib/ui/scenic/cpp/session.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>

#include <cfloat>
#include <memory>
#include <set>
#include <vector>

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

class Layer;

// Scenic currently lacks an API to enable rendering of alpha channel; this only
// happens if there is a OpacityNode higher in the tree with opacity != 1. For
// now, clamp to a infinitesimally smaller value than 1, which does not cause
// visual problems in practice.
constexpr float kOneMinusEpsilon = 1 - FLT_EPSILON;

// How much layers are separated in Scenic z elevation.
constexpr float kScenicZElevationBetweenLayers = 10.f;

class SessionWrapper {
 public:
  virtual ~SessionWrapper() {}

  virtual scenic::Session* get() = 0;
  virtual void Present() = 0;
};

class SceneUpdateContext : public flutter::ExternalViewEmbedder {
 public:
  class Entity {
   public:
    Entity(std::shared_ptr<SceneUpdateContext> context);
    virtual ~Entity();

    std::shared_ptr<SceneUpdateContext> context() { return context_; }
    scenic::EntityNode& entity_node() { return entity_node_; }
    virtual scenic::ContainerNode& embedder_node() { return entity_node_; }

   private:
    std::shared_ptr<SceneUpdateContext> context_;
    Entity* const previous_entity_;

    scenic::EntityNode entity_node_;
  };

  class Transform : public Entity {
   public:
    Transform(std::shared_ptr<SceneUpdateContext> context,
              const SkMatrix& transform);
    Transform(std::shared_ptr<SceneUpdateContext> context,
              float scale_x,
              float scale_y,
              float scale_z);
    virtual ~Transform();

   private:
    float const previous_scale_x_;
    float const previous_scale_y_;
  };

  class Frame : public Entity {
   public:
    // When layer is not nullptr, the frame is associated with a layer subtree
    // rooted with that layer. The frame may then create a surface that will be
    // retained for that layer.
    Frame(std::shared_ptr<SceneUpdateContext> context,
          const SkRRect& rrect,
          SkColor color,
          SkAlpha opacity,
          std::string label);
    virtual ~Frame();

    scenic::ContainerNode& embedder_node() override { return opacity_node_; }

    void AddPaintLayer(Layer* layer);

   private:
    const float previous_elevation_;

    const SkRRect rrect_;
    SkColor const color_;
    SkAlpha const opacity_;

    scenic::OpacityNodeHACK opacity_node_;
    std::vector<Layer*> paint_layers_;
    SkRect paint_bounds_;
  };

  class Clip : public Entity {
   public:
    Clip(std::shared_ptr<SceneUpdateContext> context,
         const SkRect& shape_bounds);
    ~Clip() = default;
  };

  struct PaintTask {
    SkRect paint_bounds;
    SkScalar scale_x;
    SkScalar scale_y;
    SkColor background_color;
    scenic::Material material;
    std::vector<Layer*> layers;
  };

  SceneUpdateContext(std::string debug_label,
                     fuchsia::ui::views::ViewToken view_token,
                     scenic::ViewRefPair view_ref_pair,
                     SessionWrapper& session,
                     bool intercept_all_input = false);
  ~SceneUpdateContext() = default;

  scenic::ContainerNode& root_node() { return root_node_; }

  // The cumulative alpha value based on all the parent OpacityLayers.
  void set_alphaf(float alpha) { alpha_ = alpha; }
  float alphaf() { return alpha_; }

  // Returns all `PaintTask`s generated for the current frame.
  std::vector<PaintTask> GetPaintTasks();

  // Enable/disable wireframe rendering around the root view bounds.
  void EnableWireframe(bool enable);

  // Reset state for a new frame.
  void Reset();

  // |ExternalViewEmbedder|
  SkCanvas* GetRootCanvas() override { return nullptr; }

  // |ExternalViewEmbedder|
  void CancelFrame() override {}

  // |ExternalViewEmbedder|
  void BeginFrame(
      SkISize frame_size,
      GrDirectContext* context,
      double device_pixel_ratio,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override {}

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int view_id,
      std::unique_ptr<EmbeddedViewParams> params) override {}

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override {
    return std::vector<SkCanvas*>();
  }

  // |ExternalViewEmbedder|
  virtual SkCanvas* CompositeEmbeddedView(int view_id) override {
    return nullptr;
  }

  void CreateView(int64_t view_id, bool hit_testable, bool focusable);
  void UpdateView(int64_t view_id, bool hit_testable, bool focusable);
  void DestroyView(int64_t view_id);
  void UpdateView(int64_t view_id,
                  const SkPoint& offset,
                  const SkSize& size,
                  std::optional<bool> override_hit_testable = std::nullopt);

 private:
  // Helper class for setting up an invisible rectangle to catch all input.
  // Rejected input will then be re-injected into a suitable platform view
  // controlled by this Engine instance.
  class InputInterceptor {
   public:
    InputInterceptor(scenic::Session* session)
        : opacity_node_(session), shape_node_(session) {
      opacity_node_.SetLabel("Flutter::InputInterceptor");
      opacity_node_.SetOpacity(0.f);

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

  void CreateFrame(scenic::EntityNode& entity_node,
                   const SkRRect& rrect,
                   SkColor color,
                   SkAlpha opacity,
                   const SkRect& paint_bounds,
                   std::vector<Layer*> paint_layers);

  SessionWrapper& session_;

  scenic::View root_view_;
  scenic::EntityNode root_node_;

  std::vector<PaintTask> paint_tasks_;

  Entity* top_entity_ = nullptr;
  float top_scale_x_ = 1.f;
  float top_scale_y_ = 1.f;
  float top_elevation_ = 0.f;

  float next_elevation_ = 0.f;
  float alpha_ = 1.f;

  std::optional<InputInterceptor> input_interceptor_;
  bool intercept_all_input_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(SceneUpdateContext);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
