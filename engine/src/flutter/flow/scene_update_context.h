// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
#define FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_

#include <memory>
#include <vector>

#include "apps/mozart/lib/scene/client/resources.h"
#include "flutter/flow/compositor_context.h"
#include "lib/ftl/build_config.h"
#include "lib/ftl/logging.h"
#include "lib/ftl/macros.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flow {

class Layer;
class ExportNodeHolder;
class ExportNode;

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

    virtual mozart::client::Image* GetImage() = 0;

    virtual sk_sp<SkSurface> GetSkiaSurface() const = 0;
  };

  class SurfaceProducer {
   public:
    virtual std::unique_ptr<SurfaceProducerSurface> ProduceSurface(
        const SkISize& size) = 0;

    virtual void SubmitSurface(
        std::unique_ptr<SurfaceProducerSurface> surface) = 0;
  };

  class Entity {
   public:
    Entity(SceneUpdateContext& context);
    ~Entity();

    SceneUpdateContext& context() { return context_; }
    mozart::client::EntityNode& entity_node() { return entity_node_; }

   private:
    SceneUpdateContext& context_;
    Entity* const previous_entity_;

    mozart::client::EntityNode entity_node_;
  };

  class Clip : public Entity {
   public:
    Clip(SceneUpdateContext& context,
         mozart::client::Shape& shape,
         const SkRect& shape_bounds);
    ~Clip();
  };

  class Transform : public Entity {
   public:
    Transform(SceneUpdateContext& context, const SkMatrix& transform);
    Transform(SceneUpdateContext& context,
              float scale_x,
              float scale_y,
              float scale_z);
    ~Transform();

   private:
    float const previous_scale_x_;
    float const previous_scale_y_;
  };

  class Frame : public Entity {
   public:
    Frame(SceneUpdateContext& context,
          const SkRRect& rrect,
          SkColor color,
          float elevation);
    ~Frame();

    void AddPaintedLayer(Layer* layer);

   private:
    const SkRRect& rrect_;
    SkColor const color_;

    std::vector<Layer*> paint_layers_;
    SkRect paint_bounds_;
  };

  SceneUpdateContext(mozart::client::Session* session,
                     SurfaceProducer* surface_producer);

  ~SceneUpdateContext();

  mozart::client::Session* session() { return session_; }

  bool has_metrics() const { return !!metrics_; }
  void set_metrics(mozart2::MetricsPtr metrics) {
    metrics_ = std::move(metrics);
  }

  void AddChildScene(ExportNode* export_node,
                     SkPoint offset,
                     bool hit_testable);

  // Adds reference to |export_node| so we can call export_node->Dispose() in
  // our destructor. Caller is responsible for calling RemoveExportNode() before
  // |export_node| is destroyed.
  void AddExportNode(ExportNode* export_node);

  // Removes reference to |export_node|.
  void RemoveExportNode(ExportNode* export_node);

  // TODO(chinmaygarde): This method must submit the surfaces as soon as paint
  // tasks are done. However, given that there is no support currently for
  // Vulkan semaphores, we need to submit all the surfaces after an explicit
  // CPU wait. Once Vulkan semaphores are available, this method must return
  // void and the implementation must submit surfaces on its own as soon as the
  // specific canvas operations are done.
  FTL_WARN_UNUSED_RESULT
  std::vector<std::unique_ptr<SurfaceProducerSurface>> ExecutePaintTasks(
      CompositorContext::ScopedFrame& frame);

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

  void CreateFrame(mozart::client::EntityNode& entity_node,
                   const SkRRect& rrect,
                   SkColor color,
                   const SkRect& paint_bounds,
                   std::vector<Layer*> paint_layers);
  void SetShapeTextureOrColor(mozart::client::ShapeNode& shape_node,
                              SkColor color,
                              SkScalar scale_x,
                              SkScalar scale_y,
                              const SkRect& paint_bounds,
                              std::vector<Layer*> paint_layers);
  void SetShapeColor(mozart::client::ShapeNode& shape_node, SkColor color);
  mozart::client::Image* GenerateImageIfNeeded(
      SkColor color,
      SkScalar scale_x,
      SkScalar scale_y,
      const SkRect& paint_bounds,
      std::vector<Layer*> paint_layers);

  Entity* top_entity_ = nullptr;
  float top_scale_x_ = 1.f;
  float top_scale_y_ = 1.f;

  mozart::client::Session* const session_;
  SurfaceProducer* const surface_producer_;

  mozart2::MetricsPtr metrics_;

  std::vector<PaintTask> paint_tasks_;

  // Save ExportNodes so we can dispose them in our destructor.
  std::set<ExportNode*> export_nodes_;

  FTL_DISALLOW_COPY_AND_ASSIGN(SceneUpdateContext);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
