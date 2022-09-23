// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/compositing/scene.h"

#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/painting/display_list_deferred_image_gpu_skia.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/lib/ui/window/window.h"
#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/lib/ui/painting/display_list_deferred_image_gpu_impeller.h"
#endif  // IMPELLER_SUPPORTS_RENDERING
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, Scene);

void Scene::create(Dart_Handle scene_handle,
                   std::shared_ptr<flutter::Layer> rootLayer,
                   uint32_t rasterizerTracingThreshold,
                   bool checkerboardRasterCacheImages,
                   bool checkerboardOffscreenLayers) {
  auto scene = fml::MakeRefCounted<Scene>(
      std::move(rootLayer), rasterizerTracingThreshold,
      checkerboardRasterCacheImages, checkerboardOffscreenLayers);
  scene->AssociateWithDartWrapper(scene_handle);
}

Scene::Scene(std::shared_ptr<flutter::Layer> rootLayer,
             uint32_t rasterizerTracingThreshold,
             bool checkerboardRasterCacheImages,
             bool checkerboardOffscreenLayers) {
  // Currently only supports a single window.
  auto viewport_metrics = UIDartState::Current()
                              ->platform_configuration()
                              ->get_window(0)
                              ->viewport_metrics();

  layer_tree_ = std::make_shared<LayerTree>(
      SkISize::Make(viewport_metrics.physical_width,
                    viewport_metrics.physical_height),
      static_cast<float>(viewport_metrics.device_pixel_ratio));
  layer_tree_->set_root_layer(std::move(rootLayer));
  layer_tree_->set_rasterizer_tracing_threshold(rasterizerTracingThreshold);
  layer_tree_->set_checkerboard_raster_cache_images(
      checkerboardRasterCacheImages);
  layer_tree_->set_checkerboard_offscreen_layers(checkerboardOffscreenLayers);
}

Scene::~Scene() {}

void Scene::dispose() {
  layer_tree_.reset();
  ClearDartWrapper();
}

Dart_Handle Scene::toImageSync(uint32_t width,
                               uint32_t height,
                               Dart_Handle raw_image_handle) {
  TRACE_EVENT0("flutter", "Scene::toImageSync");

  if (!layer_tree_) {
    return tonic::ToDart("Scene did not contain a layer tree.");
  }

  Scene::RasterizeToImage(width, height, raw_image_handle);
  return Dart_Null();
}

Dart_Handle Scene::toImage(uint32_t width,
                           uint32_t height,
                           Dart_Handle raw_image_callback) {
  TRACE_EVENT0("flutter", "Scene::toImage");

  if (!layer_tree_) {
    return tonic::ToDart("Scene did not contain a layer tree.");
  }

  return Picture::RasterizeLayerTreeToImage(std::move(layer_tree_), width,
                                            height, raw_image_callback);
}

static sk_sp<DlImage> CreateDeferredImage(
    bool impeller,
    std::shared_ptr<LayerTree> layer_tree,
    uint32_t width,
    uint32_t height,
    fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
    fml::RefPtr<fml::TaskRunner> raster_task_runner,
    fml::RefPtr<SkiaUnrefQueue> unref_queue) {
#if IMPELLER_SUPPORTS_RENDERING
  if (impeller) {
    return DlDeferredImageGPUImpeller::Make(
        std::move(layer_tree), SkISize::Make(width, height),
        std::move(snapshot_delegate), std::move(raster_task_runner));
  }
#endif  // IMPELLER_SUPPORTS_RENDERING

  const SkImageInfo image_info = SkImageInfo::Make(
      width, height, kRGBA_8888_SkColorType, kPremul_SkAlphaType);
  return DlDeferredImageGPUSkia::MakeFromLayerTree(
      image_info, std::move(layer_tree), std::move(snapshot_delegate),
      std::move(raster_task_runner), std::move(unref_queue));
}

void Scene::RasterizeToImage(uint32_t width,
                             uint32_t height,
                             Dart_Handle raw_image_handle) {
  auto* dart_state = UIDartState::Current();
  if (!dart_state) {
    return;
  }
  auto unref_queue = dart_state->GetSkiaUnrefQueue();
  auto snapshot_delegate = dart_state->GetSnapshotDelegate();
  auto raster_task_runner = dart_state->GetTaskRunners().GetRasterTaskRunner();

  auto image = CanvasImage::Create();
  auto dl_image = CreateDeferredImage(
      dart_state->IsImpellerEnabled(), layer_tree_, width, height,
      std::move(snapshot_delegate), std::move(raster_task_runner),
      std::move(unref_queue));
  image->set_image(dl_image);
  image->AssociateWithDartWrapper(raw_image_handle);
}

std::shared_ptr<flutter::LayerTree> Scene::takeLayerTree() {
  return std::move(layer_tree_);
}

}  // namespace flutter
