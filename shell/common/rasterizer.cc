// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/rasterizer.h"

#include <utility>

#include "third_party/skia/include/core/SkEncodedImageFormat.h"
#include "third_party/skia/include/core/SkImageEncoder.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/src/utils/SkBase64.h"

namespace shell {

Rasterizer::Rasterizer(blink::TaskRunners task_runners)
    : task_runners_(std::move(task_runners)), weak_factory_(this) {
  weak_prototype_ = weak_factory_.GetWeakPtr();
}

Rasterizer::~Rasterizer() = default;

fml::WeakPtr<Rasterizer> Rasterizer::GetWeakPtr() const {
  return weak_prototype_;
}

void Rasterizer::Setup(std::unique_ptr<Surface> surface) {
  surface_ = std::move(surface);
}

void Rasterizer::Teardown() {
  surface_.reset();
  last_layer_tree_.reset();
}

flow::TextureRegistry* Rasterizer::GetTextureRegistry() {
  if (!surface_) {
    return nullptr;
  }

  return &(surface_->GetCompositorContext().texture_registry());
}

flow::LayerTree* Rasterizer::GetLastLayerTree() {
  return last_layer_tree_.get();
}

void Rasterizer::DrawLastLayerTree() {
  if (!last_layer_tree_ || !surface_) {
    return;
  }
  DrawToSurface(*last_layer_tree_);
}

void Rasterizer::Draw(
    fxl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) {
  TRACE_EVENT0("flutter", "GPURasterizer::Draw");

  flutter::Pipeline<flow::LayerTree>::Consumer consumer =
      std::bind(&Rasterizer::DoDraw, this, std::placeholders::_1);

  // Consume as many pipeline items as possible. But yield the event loop
  // between successive tries.
  switch (pipeline->Consume(consumer)) {
    case flutter::PipelineConsumeResult::MoreAvailable: {
      task_runners_.GetGPUTaskRunner()->PostTask(
          [weak_this = weak_factory_.GetWeakPtr(), pipeline]() {
            if (weak_this) {
              weak_this->Draw(pipeline);
            }
          });
      break;
    }
    default:
      break;
  }
}

void Rasterizer::DoDraw(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!layer_tree || !surface_) {
    return;
  }

  if (DrawToSurface(*layer_tree)) {
    last_layer_tree_ = std::move(layer_tree);
  }
}

bool Rasterizer::DrawToSurface(flow::LayerTree& layer_tree) {
  FXL_DCHECK(surface_);

  auto frame = surface_->AcquireFrame(layer_tree.frame_size());

  if (frame == nullptr) {
    return false;
  }

  auto& compositor_context = surface_->GetCompositorContext();

  // There is no way for the compositor to know how long the layer tree
  // construction took. Fortunately, the layer tree does. Grab that time
  // for instrumentation.
  compositor_context.engine_time().SetLapTime(layer_tree.construction_time());

  auto compositor_frame = compositor_context.AcquireFrame(
      surface_->GetContext(), frame->SkiaCanvas(), true);

  if (compositor_frame && compositor_frame->Raster(layer_tree, false)) {
    frame->Submit();
    FireNextFrameCallbackIfPresent();
    return true;
  }

  return false;
}

static sk_sp<SkPicture> ScreenshotLayerTreeAsPicture(flow::LayerTree* tree) {
  FXL_DCHECK(tree != nullptr);
  SkPictureRecorder recorder;
  recorder.beginRecording(
      SkRect::MakeWH(tree->frame_size().width(), tree->frame_size().height()));

  flow::CompositorContext compositor_context;
  auto frame = compositor_context.AcquireFrame(
      nullptr, recorder.getRecordingCanvas(), false);

  frame->Raster(*tree, true);

  return recorder.finishRecordingAsPicture();
}

static sk_sp<SkData> ScreenshotLayerTreeAsImage(flow::LayerTree* tree,
                                                bool compressed) {
  const SkISize& frame_size = tree->frame_size();
  SkBitmap bitmap;
  if (!bitmap.tryAllocN32Pixels(frame_size.width(), frame_size.height())) {
    return nullptr;
  }
  auto bitmap_surface = SkSurface::MakeRasterDirect(
      bitmap.info(), bitmap.getPixels(), bitmap.rowBytes());
  flow::CompositorContext compositor_context;
  auto canvas = bitmap_surface->getCanvas();
  auto frame = compositor_context.AcquireFrame(nullptr, canvas, false);
  canvas->clear(SK_ColorBLACK);
  frame->Raster(*tree, true);
  canvas->flush();
  if (compressed) {
    return SkEncodeBitmap(bitmap, SkEncodedImageFormat::kPNG, 100);
  } else {
    return SkData::MakeWithCopy(bitmap.getPixels(), bitmap.computeByteSize());
  }
  return nullptr;
}

Rasterizer::Screenshot Rasterizer::ScreenshotLastLayerTree(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  auto layer_tree = GetLastLayerTree();
  if (layer_tree == nullptr) {
    FXL_DLOG(INFO) << "Last layer tree was null when screenshotting.";
    return {};
  }

  sk_sp<SkData> data = nullptr;

  switch (type) {
    case ScreenshotType::SkiaPicture:
      data = ScreenshotLayerTreeAsPicture(layer_tree)->serialize();
      break;
    case ScreenshotType::UncompressedImage:
      data = ScreenshotLayerTreeAsImage(layer_tree, false);
      break;
    case ScreenshotType::CompressedImage:
      data = ScreenshotLayerTreeAsImage(layer_tree, true);
      break;
  }

  if (data == nullptr) {
    FXL_DLOG(INFO) << "Sceenshot data was null.";
    return {};
  }

  if (base64_encode) {
    size_t b64_size = SkBase64::Encode(data->data(), data->size(), nullptr);
    auto b64_data = SkData::MakeUninitialized(b64_size);
    SkBase64::Encode(data->data(), data->size(), b64_data->writable_data());
    return Rasterizer::Screenshot{b64_data, layer_tree->frame_size()};
  }

  return Rasterizer::Screenshot{data, layer_tree->frame_size()};
}

void Rasterizer::SetNextFrameCallback(fxl::Closure callback) {
  next_frame_callback_ = callback;
}

void Rasterizer::FireNextFrameCallbackIfPresent() {
  if (!next_frame_callback_) {
    return;
  }
  // It is safe for the callback to set a new callback.
  auto callback = next_frame_callback_;
  next_frame_callback_ = nullptr;
  callback();
}

}  // namespace shell
