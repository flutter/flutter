// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/rasterizer.h"

#include <utility>

#include "third_party/skia/include/core/SkEncodedImageFormat.h"
#include "third_party/skia/include/core/SkImageEncoder.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkSerialProcs.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkSurfaceCharacterization.h"
#include "third_party/skia/include/utils/SkBase64.h"

namespace shell {

Rasterizer::Rasterizer(blink::TaskRunners task_runners)
    : Rasterizer(std::move(task_runners),
                 std::make_unique<flow::CompositorContext>()) {}

Rasterizer::Rasterizer(
    blink::TaskRunners task_runners,
    std::unique_ptr<flow::CompositorContext> compositor_context)
    : task_runners_(std::move(task_runners)),
      compositor_context_(std::move(compositor_context)),
      weak_factory_(this) {
  FML_DCHECK(compositor_context_);
}

Rasterizer::~Rasterizer() = default;

fml::WeakPtr<Rasterizer> Rasterizer::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

fml::WeakPtr<blink::SnapshotDelegate> Rasterizer::GetSnapshotDelegate() const {
  return weak_factory_.GetWeakPtr();
}

void Rasterizer::Setup(std::unique_ptr<Surface> surface) {
  surface_ = std::move(surface);
  compositor_context_->OnGrContextCreated();
}

void Rasterizer::Teardown() {
  compositor_context_->OnGrContextDestroyed();
  surface_.reset();
  last_layer_tree_.reset();
}

flow::TextureRegistry* Rasterizer::GetTextureRegistry() {
  return &compositor_context_->texture_registry();
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
    fml::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) {
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

sk_sp<SkImage> Rasterizer::MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                              SkISize picture_size) {
  TRACE_EVENT0("flutter", __FUNCTION__);

  sk_sp<SkSurface> surface;
  if (surface_ == nullptr || surface_->GetContext() == nullptr) {
    // Raster surface is fine if there is no on screen surface. This might
    // happen in case of software rendering.
    surface = SkSurface::MakeRaster(SkImageInfo::MakeN32Premul(picture_size));
  } else {
    // When there is an on screen surface, we need a render target SkSurface
    // because we want to access texture backed images.
    surface = SkSurface::MakeRenderTarget(
        surface_->GetContext(),                   // context
        SkBudgeted::kNo,                          // budgeted
        SkImageInfo::MakeN32Premul(picture_size)  // image info
    );
  }

  if (surface == nullptr || surface->getCanvas() == nullptr) {
    return nullptr;
  }

  surface->getCanvas()->drawPicture(picture.get());

  surface->getCanvas()->flush();

  sk_sp<SkImage> device_snapshot;
  {
    TRACE_EVENT0("flutter", "MakeDeviceSnpashot");
    device_snapshot = surface->makeImageSnapshot();
  }

  if (device_snapshot == nullptr) {
    return nullptr;
  }

  {
    TRACE_EVENT0("flutter", "DeviceHostTransfer");
    if (auto raster_image = device_snapshot->makeRasterImage()) {
      return raster_image;
    }
  }

  return nullptr;
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
  FML_DCHECK(surface_);

  auto frame = surface_->AcquireFrame(layer_tree.frame_size());

  if (frame == nullptr) {
    return false;
  }

  // There is no way for the compositor to know how long the layer tree
  // construction took. Fortunately, the layer tree does. Grab that time
  // for instrumentation.
  compositor_context_->engine_time().SetLapTime(layer_tree.construction_time());

  auto canvas = frame->SkiaCanvas();

  // External view embedding required that the gpu and platform threads are the
  // same. The dynamic merging of these threads is WIP so for now we don't
  // populate the view embedder. Once we can merge the threads, we should
  // populate the view embedded here with surface_->GetExternalViewEmbedder() if
  // the scene contains an external view (and we can probably assert that the
  // gpu and platform threads are the same).
  //
  // TODO(amirh): populate the view embedder once we dynamically merge the
  // threads for embedded platform views.
  auto external_view_embedder = nullptr;

  auto compositor_frame = compositor_context_->AcquireFrame(
      surface_->GetContext(), canvas, external_view_embedder,
      surface_->GetRootTransformation(), true);

  if (canvas) {
    canvas->clear(SK_ColorTRANSPARENT);
  }

  if (compositor_frame && compositor_frame->Raster(layer_tree, false)) {
    frame->Submit();
    FireNextFrameCallbackIfPresent();
    return true;
  }

  return false;
}

static sk_sp<SkData> SerializeTypeface(SkTypeface* typeface, void* ctx) {
  return typeface->serialize(SkTypeface::SerializeBehavior::kDoIncludeData);
}

static sk_sp<SkData> ScreenshotLayerTreeAsPicture(
    flow::LayerTree* tree,
    flow::CompositorContext& compositor_context) {
  FML_DCHECK(tree != nullptr);
  SkPictureRecorder recorder;
  recorder.beginRecording(
      SkRect::MakeWH(tree->frame_size().width(), tree->frame_size().height()));

  SkMatrix root_surface_transformation;
  root_surface_transformation.reset();

  // TODO(amirh): figure out how to take a screenshot with embedded UIView.
  // https://github.com/flutter/flutter/issues/23435
  auto frame = compositor_context.AcquireFrame(
      nullptr, recorder.getRecordingCanvas(), nullptr,
      root_surface_transformation, false);

  frame->Raster(*tree, true);

  SkSerialProcs procs = {0};
  procs.fTypefaceProc = SerializeTypeface;

  return recorder.finishRecordingAsPicture()->serialize(&procs);
}

static sk_sp<SkSurface> CreateSnapshotSurface(GrContext* surface_context,
                                              const SkISize& size) {
  const auto image_info = SkImageInfo::MakeN32Premul(size);
  if (surface_context) {
    // There is a rendering surface that may contain textures that are going to
    // be referenced in the layer tree about to be drawn.
    return SkSurface::MakeRenderTarget(surface_context,  //
                                       SkBudgeted::kNo,  //
                                       image_info        //
    );
  }

  // There is no rendering surface, assume no GPU textures are present and
  // create a raster surface.
  return SkSurface::MakeRaster(image_info);
}

static sk_sp<SkData> ScreenshotLayerTreeAsImage(
    flow::LayerTree* tree,
    flow::CompositorContext& compositor_context,
    GrContext* surface_context,
    bool compressed) {
  // Attempt to create a snapshot surface depending on whether we have access to
  // a valid GPU rendering context.
  auto snapshot_surface =
      CreateSnapshotSurface(surface_context, tree->frame_size());
  if (snapshot_surface == nullptr) {
    FML_LOG(ERROR) << "Screenshot: unable to create snapshot surface";
    return nullptr;
  }

  // Draw the current layer tree into the snapshot surface.
  auto canvas = snapshot_surface->getCanvas();

  // There is no root surface transformation for the screenshot layer. Reset the
  // matrix to identity.
  SkMatrix root_surface_transformation;
  root_surface_transformation.reset();

  auto frame = compositor_context.AcquireFrame(
      surface_context, canvas, nullptr, root_surface_transformation, false);
  canvas->clear(SK_ColorTRANSPARENT);
  frame->Raster(*tree, true);
  canvas->flush();

  // Prepare an image from the surface, this image may potentially be on th GPU.
  auto potentially_gpu_snapshot = snapshot_surface->makeImageSnapshot();
  if (!potentially_gpu_snapshot) {
    FML_LOG(ERROR) << "Screenshot: unable to make image screenshot";
    return nullptr;
  }

  // Copy the GPU image snapshot into CPU memory.
  auto cpu_snapshot = potentially_gpu_snapshot->makeRasterImage();
  if (!cpu_snapshot) {
    FML_LOG(ERROR) << "Screenshot: unable to make raster image";
    return nullptr;
  }

  // If the caller want the pixels to be compressed, there is a Skia utility to
  // compress to PNG. Use that.
  if (compressed) {
    return cpu_snapshot->encodeToData();
  }

  // Copy it into a bitmap and return the same.
  SkPixmap pixmap;
  if (!cpu_snapshot->peekPixels(&pixmap)) {
    FML_LOG(ERROR) << "Screenshot: unable to obtain bitmap pixels";
    return nullptr;
  }

  return SkData::MakeWithCopy(pixmap.addr32(), pixmap.computeByteSize());
}

Rasterizer::Screenshot Rasterizer::ScreenshotLastLayerTree(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  auto layer_tree = GetLastLayerTree();
  if (layer_tree == nullptr) {
    FML_LOG(ERROR) << "Last layer tree was null when screenshotting.";
    return {};
  }

  sk_sp<SkData> data = nullptr;

  GrContext* surface_context = surface_ ? surface_->GetContext() : nullptr;

  switch (type) {
    case ScreenshotType::SkiaPicture:
      data = ScreenshotLayerTreeAsPicture(layer_tree, *compositor_context_);
      break;
    case ScreenshotType::UncompressedImage:
      data = ScreenshotLayerTreeAsImage(layer_tree, *compositor_context_,
                                        surface_context, false);
      break;
    case ScreenshotType::CompressedImage:
      data = ScreenshotLayerTreeAsImage(layer_tree, *compositor_context_,
                                        surface_context, true);
      break;
  }

  if (data == nullptr) {
    FML_LOG(ERROR) << "Screenshot data was null.";
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

void Rasterizer::SetNextFrameCallback(fml::closure callback) {
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
