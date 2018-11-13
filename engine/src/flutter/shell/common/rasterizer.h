// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_RASTERIZER_H_
#define SHELL_COMMON_RASTERIZER_H_

#include <memory>

#include "flutter/common/task_runners.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "flutter/shell/common/surface.h"
#include "flutter/synchronization/pipeline.h"

namespace shell {

class Rasterizer final : public blink::SnapshotDelegate {
 public:
  Rasterizer(blink::TaskRunners task_runners);

  Rasterizer(blink::TaskRunners task_runners,
             std::unique_ptr<flow::CompositorContext> compositor_context);

  ~Rasterizer();

  void Setup(std::unique_ptr<Surface> surface);

  void Teardown();

  fml::WeakPtr<Rasterizer> GetWeakPtr() const;

  fml::WeakPtr<blink::SnapshotDelegate> GetSnapshotDelegate() const;

  flow::LayerTree* GetLastLayerTree();

  void DrawLastLayerTree();

  flow::TextureRegistry* GetTextureRegistry();

  void Draw(fml::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline);

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

  flow::CompositorContext* compositor_context() {
    return compositor_context_.get();
  }

 private:
  blink::TaskRunners task_runners_;
  std::unique_ptr<Surface> surface_;
  std::unique_ptr<flow::CompositorContext> compositor_context_;
  std::unique_ptr<flow::LayerTree> last_layer_tree_;
  fml::closure next_frame_callback_;
  fml::WeakPtrFactory<Rasterizer> weak_factory_;

  // |blink::SnapshotDelegate|
  sk_sp<SkImage> MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                    SkISize picture_size) override;

  void DoDraw(std::unique_ptr<flow::LayerTree> layer_tree);

  bool DrawToSurface(flow::LayerTree& layer_tree);

  void FireNextFrameCallbackIfPresent();

  FML_DISALLOW_COPY_AND_ASSIGN(Rasterizer);
};

}  // namespace shell

#endif  // SHELL_COMMON_RASTERIZER_H_
