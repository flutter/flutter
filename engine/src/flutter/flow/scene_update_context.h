// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
#define FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_

#include <memory>
#include <set>
#include <vector>

#include "flutter/flow/compositor_context.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "lib/ui/scenic/cpp/resources.h"
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

    virtual scenic::Image* GetImage() = 0;

    virtual sk_sp<SkSurface> GetSkiaSurface() const = 0;
  };

  class SurfaceProducer {
   public:
    virtual ~SurfaceProducer() = default;

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
    scenic::EntityNode& entity_node() { return entity_node_; }

   private:
    SceneUpdateContext& context_;
    Entity* const previous_entity_;

    scenic::EntityNode entity_node_;
  };

  class Clip : public Entity {
   public:
    Clip(SceneUpdateContext& context,
         scenic::Shape& shape,
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

  SceneUpdateContext(scenic::Session* session,
                     SurfaceProducer* surface_producer);

  ~SceneUpdateContext();

  scenic::Session* session() { return session_; }

  bool has_metrics() const { return !!metrics_; }
  void set_metrics(fuchsia::ui::gfx::MetricsPtr metrics) {
    metrics_ = std::move(metrics);
  }
  const fuchsia::ui::gfx::MetricsPtr& metrics() const { return metrics_; }

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
  FML_WARN_UNUSED_RESULT
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

  void CreateFrame(scenic::EntityNode& entity_node,
                   const SkRRect& rrect,
                   SkColor color,
                   const SkRect& paint_bounds,
                   std::vector<Layer*> paint_layers);
  void SetShapeTextureOrColor(scenic::ShapeNode& shape_node,
                              SkColor color,
                              SkScalar scale_x,
                              SkScalar scale_y,
                              const SkRect& paint_bounds,
                              std::vector<Layer*> paint_layers);
  void SetShapeColor(scenic::ShapeNode& shape_node, SkColor color);
  scenic::Image* GenerateImageIfNeeded(SkColor color,
                                       SkScalar scale_x,
                                       SkScalar scale_y,
                                       const SkRect& paint_bounds,
                                       std::vector<Layer*> paint_layers);

  Entity* top_entity_ = nullptr;
  float top_scale_x_ = 1.f;
  float top_scale_y_ = 1.f;

  scenic::Session* const session_;
  SurfaceProducer* const surface_producer_;

  fuchsia::ui::gfx::MetricsPtr metrics_;

  std::vector<PaintTask> paint_tasks_;

  // Save ExportNodes so we can dispose them in our destructor.
  std::set<ExportNode*> export_nodes_;

  FML_DISALLOW_COPY_AND_ASSIGN(SceneUpdateContext);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_SCENE_UPDATE_CONTEXT_H_
