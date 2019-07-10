// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_RASTERIZER_H_
#define SHELL_COMMON_RASTERIZER_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "flutter/shell/common/pipeline.h"
#include "flutter/shell/common/surface.h"

namespace flutter {

/// Takes |LayerTree|s and draws its contents.
class Rasterizer final : public SnapshotDelegate {
 public:
  class Delegate {
   public:
    virtual void OnFrameRasterized(const FrameTiming&) = 0;
  };
  // TODO(dnfield): remove once embedders have caught up.
  class DummyDelegate : public Delegate {
    void OnFrameRasterized(const FrameTiming&) override {}
  };
  Rasterizer(TaskRunners task_runners,
             std::unique_ptr<flutter::CompositorContext> compositor_context);

  Rasterizer(Delegate& delegate, TaskRunners task_runners);

  Rasterizer(Delegate& delegate,
             TaskRunners task_runners,
             std::unique_ptr<flutter::CompositorContext> compositor_context);

  ~Rasterizer();

  void Setup(std::unique_ptr<Surface> surface);

  void Teardown();

  // Frees up Skia GPU resources.
  //
  // This method must be called from the GPU task runner.
  void NotifyLowMemoryWarning() const;

  fml::WeakPtr<Rasterizer> GetWeakPtr() const;

  fml::WeakPtr<SnapshotDelegate> GetSnapshotDelegate() const;

  flutter::LayerTree* GetLastLayerTree();

  void DrawLastLayerTree();

  flutter::TextureRegistry* GetTextureRegistry();

  void Draw(fml::RefPtr<Pipeline<flutter::LayerTree>> pipeline);

  enum class ScreenshotType {
    SkiaPicture,
    UncompressedImage,  // In kN32_SkColorType format
    CompressedImage,
  };

  struct Screenshot {
    sk_sp<SkData> data;
    SkISize frame_size = SkISize::MakeEmpty();

    Screenshot();

    Screenshot(sk_sp<SkData> p_data, SkISize p_size);

    Screenshot(const Screenshot& other);

    ~Screenshot();
  };

  Screenshot ScreenshotLastLayerTree(ScreenshotType type, bool base64_encode);

  // Sets a callback that will be executed after the next frame is submitted to
  // the surface on the GPU task runner.
  void SetNextFrameCallback(fml::closure callback);

  flutter::CompositorContext* compositor_context() {
    return compositor_context_.get();
  }

  void SetResourceCacheMaxBytes(int max_bytes);

 private:
  Delegate& delegate_;
  TaskRunners task_runners_;
  std::unique_ptr<Surface> surface_;
  std::unique_ptr<flutter::CompositorContext> compositor_context_;
  std::unique_ptr<flutter::LayerTree> last_layer_tree_;
  fml::closure next_frame_callback_;
  fml::WeakPtrFactory<Rasterizer> weak_factory_;

  // |SnapshotDelegate|
  sk_sp<SkImage> MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                    SkISize picture_size) override;

  void DoDraw(std::unique_ptr<flutter::LayerTree> layer_tree);

  RasterStatus DrawToSurface(flutter::LayerTree& layer_tree);

  void FireNextFrameCallbackIfPresent();

  FML_DISALLOW_COPY_AND_ASSIGN(Rasterizer);
};

}  // namespace flutter

#endif  // SHELL_COMMON_RASTERIZER_H_
