// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
#define FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_

#include <memory>
#include <set>
#include <vector>

#include "flutter/flow/compositor_context.h"
#include "flutter/flow/raster_cache_key.h"
#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "lib/ui/scenic/cpp/resources.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

class Layer;

class SceneUpdateContext {
 public:
  class SurfaceProducerSurface {
   public:
    virtual ~SurfaceProducerSurface() = default;

    virtual size_t AdvanceAndGetAge() = 0;

    virtual bool FlushSessionAcquireAndReleaseEvents() = 0;

    virtual bool IsValid() const = 0;

    virtual SkISize GetSize() const = 0;

    virtual void SignalWritesFinished(
        std::function<void(void)> on_writes_committed) = 0;

    virtual scenic::Image* GetImage() = 0;

    virtual sk_sp<SkSurface> GetSkiaSurface() const = 0;
  };

  class SurfaceProducer {
   public:
    virtual ~SurfaceProducer() = default;

    // The produced surface owns the entity_node and has a layer_key for
    // retained rendering. The surface will only be retained if the layer_key
    // has a non-null layer pointer (layer_key.id()).
    virtual std::unique_ptr<SurfaceProducerSurface> ProduceSurface(
        const SkISize& size,
        const LayerRasterCacheKey& layer_key,
        std::unique_ptr<scenic::EntityNode> entity_node) = 0;

    // Query a retained entity node (owned by a retained surface) for retained
    // rendering.
    virtual bool HasRetainedNode(const LayerRasterCacheKey& key) const = 0;
    virtual const scenic::EntityNode& GetRetainedNode(
        const LayerRasterCacheKey& key) = 0;

    virtual void SubmitSurface(
        std::unique_ptr<SurfaceProducerSurface> surface) = 0;
  };

  class Entity {
   public:
    Entity(SceneUpdateContext& context);
    virtual ~Entity();

    SceneUpdateContext& context() { return context_; }
    scenic::EntityNode& entity_node() { return entity_node_; }
    virtual scenic::ContainerNode& embedder_node() { return entity_node_; }

   private:
    SceneUpdateContext& context_;
    Entity* const previous_entity_;

    scenic::EntityNode entity_node_;
  };

  class Transform : public Entity {
   public:
    Transform(SceneUpdateContext& context, const SkMatrix& transform);
    Transform(SceneUpdateContext& context,
              float scale_x,
              float scale_y,
              float scale_z);
    virtual ~Transform();

   private:
    float const previous_scale_x_;
    float const previous_scale_y_;
  };

  class Shape : public Entity {
   public:
    Shape(SceneUpdateContext& context);
    virtual ~Shape() = default;

    scenic::ShapeNode& shape_node() { return shape_node_; }

   private:
    scenic::ShapeNode shape_node_;
  };

  class Frame : public Shape {
   public:
    // When layer is not nullptr, the frame is associated with a layer subtree
    // rooted with that layer. The frame may then create a surface that will be
    // retained for that layer.
    Frame(SceneUpdateContext& context,
          const SkRRect& rrect,
          SkColor color,
          float local_elevation = 0.0f,
          float parent_elevation = 0.0f,
          float depth = 0.0f,
          Layer* layer = nullptr);
    virtual ~Frame();

    void AddPaintLayer(Layer* layer);

   private:
    const SkRRect& rrect_;
    SkColor const color_;

    std::vector<Layer*> paint_layers_;
    SkRect paint_bounds_;
    Layer* layer_;
  };

  class Clip : public Entity {
   public:
    Clip(SceneUpdateContext& context, const SkRect& shape_bounds);
    ~Clip() = default;
  };

  SceneUpdateContext(scenic::Session* session,
                     SurfaceProducer* surface_producer);
  ~SceneUpdateContext() = default;

  scenic::Session* session() { return session_; }

  Entity* top_entity() { return top_entity_; }

  bool has_metrics() const { return !!metrics_; }
  void set_metrics(fuchsia::ui::gfx::MetricsPtr metrics) {
    metrics_ = std::move(metrics);
  }
  const fuchsia::ui::gfx::MetricsPtr& metrics() const { return metrics_; }

  // TODO(chinmaygarde): This method must submit the surfaces as soon as paint
  // tasks are done. However, given that there is no support currently for
  // Vulkan semaphores, we need to submit all the surfaces after an explicit
  // CPU wait. Once Vulkan semaphores are available, this method must return
  // void and the implementation must submit surfaces on its own as soon as the
  // specific canvas operations are done.
  FML_WARN_UNUSED_RESULT
  std::vector<std::unique_ptr<SurfaceProducerSurface>> ExecutePaintTasks(
      CompositorContext::ScopedFrame& frame);

  float ScaleX() const { return metrics_->scale_x * top_scale_x_; }
  float ScaleY() const { return metrics_->scale_y * top_scale_y_; }

  // The transformation matrix of the current context. It's used to construct
  // the LayerRasterCacheKey for a given layer.
  SkMatrix Matrix() const { return SkMatrix::MakeScale(ScaleX(), ScaleY()); }

  bool HasRetainedNode(const LayerRasterCacheKey& key) const {
    return surface_producer_->HasRetainedNode(key);
  }
  const scenic::EntityNode& GetRetainedNode(const LayerRasterCacheKey& key) {
    return surface_producer_->GetRetainedNode(key);
  }

 private:
  struct PaintTask {
    std::unique_ptr<SurfaceProducerSurface> surface;
    SkScalar left;
    SkScalar top;
    SkScalar scale_x;
    SkScalar scale_y;
    SkColor background_color;
    std::vector<Layer*> layers;
  };

  // Setup the entity_node as a frame that materialize all the paint_layers. In
  // most cases, this creates a VulkanSurface (SurfaceProducerSurface) by
  // calling SetShapeTextureOrColor and GenerageImageIfNeeded. Such surface will
  // own the associated entity_node. If the layer pointer isn't nullptr, the
  // surface (and thus the entity_node) will be retained for that layer to
  // improve the performance.
  void CreateFrame(scenic::EntityNode entity_node,
                   scenic::ShapeNode shape_node,
                   const SkRRect& rrect,
                   SkColor color,
                   const SkRect& paint_bounds,
                   std::vector<Layer*> paint_layers,
                   Layer* layer);
  void SetShapeTextureAndColor(scenic::ShapeNode& shape_node,
                               SkColor color,
                               SkScalar scale_x,
                               SkScalar scale_y,
                               const SkRect& paint_bounds,
                               std::vector<Layer*> paint_layers,
                               Layer* layer,
                               scenic::EntityNode entity_node);
  void SetShapeColor(scenic::ShapeNode& shape_node, SkColor color);
  scenic::Image* GenerateImageIfNeeded(SkColor color,
                                       SkScalar scale_x,
                                       SkScalar scale_y,
                                       const SkRect& paint_bounds,
                                       std::vector<Layer*> paint_layers,
                                       Layer* layer,
                                       scenic::EntityNode entity_node);

  Entity* top_entity_ = nullptr;
  float top_scale_x_ = 1.f;
  float top_scale_y_ = 1.f;

  scenic::Session* const session_;
  SurfaceProducer* const surface_producer_;

  fuchsia::ui::gfx::MetricsPtr metrics_;

  std::vector<PaintTask> paint_tasks_;

  FML_DISALLOW_COPY_AND_ASSIGN(SceneUpdateContext);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
