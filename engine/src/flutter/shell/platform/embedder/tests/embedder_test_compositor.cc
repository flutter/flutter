// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_compositor.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

EmbedderTestCompositor::EmbedderTestCompositor(SkISize surface_size,
                                               sk_sp<GrDirectContext> context)
    : surface_size_(surface_size), context_(context) {
  FML_CHECK(!surface_size_.isEmpty()) << "Surface size must not be empty";
  FML_CHECK(context_);
}

EmbedderTestCompositor::~EmbedderTestCompositor() = default;

void EmbedderTestCompositor::SetRenderTargetType(RenderTargetType type) {
  type_ = type;
}

static void InvokeAllCallbacks(const std::vector<fml::closure>& callbacks) {
  for (const auto& callback : callbacks) {
    if (callback) {
      callback();
    }
  }
}

bool EmbedderTestCompositor::CreateBackingStore(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  bool success = false;
  switch (type_) {
    case RenderTargetType::kOpenGLFramebuffer:
      success = CreateFramebufferRenderSurface(config, backing_store_out);
      break;
    case RenderTargetType::kOpenGLTexture:
      success = CreateTextureRenderSurface(config, backing_store_out);
      break;
    case RenderTargetType::kSoftwareBuffer:
      success = CreateSoftwareRenderSurface(config, backing_store_out);
      break;
    default:
      FML_CHECK(false);
      return false;
  }
  if (success) {
    backing_stores_created_++;
    InvokeAllCallbacks(on_create_render_target_callbacks_);
  }
  return success;
}

bool EmbedderTestCompositor::CollectBackingStore(
    const FlutterBackingStore* backing_store) {
  // We have already set the destruction callback for the various backing
  // stores. Our user_data is just the canvas from that backing store and does
  // not need to be explicitly collected. Embedders might have some other state
  // they want to collect though.
  backing_stores_collected_++;
  InvokeAllCallbacks(on_collect_render_target_callbacks_);
  return true;
}

bool EmbedderTestCompositor::UpdateOffscrenComposition(
    const FlutterLayer** layers,
    size_t layers_count) {
  last_composition_ = nullptr;

  const auto image_info = SkImageInfo::MakeN32Premul(surface_size_);

  auto surface = type_ == RenderTargetType::kSoftwareBuffer
                     ? SkSurface::MakeRaster(image_info)
                     : SkSurface::MakeRenderTarget(
                           context_.get(),            // context
                           SkBudgeted::kNo,           // budgeted
                           image_info,                // image info
                           1,                         // sample count
                           kTopLeft_GrSurfaceOrigin,  // surface origin
                           nullptr,                   // surface properties
                           false                      // create mipmaps
                       );

  if (!surface) {
    FML_LOG(ERROR) << "Could not update the off-screen composition.";
    return false;
  }

  auto canvas = surface->getCanvas();

  // This has to be transparent because we are going to be compositing this
  // sub-hierarchy onto the on-screen surface.
  canvas->clear(SK_ColorTRANSPARENT);

  for (size_t i = 0; i < layers_count; ++i) {
    const auto* layer = layers[i];

    sk_sp<SkImage> platform_renderered_contents;

    sk_sp<SkImage> layer_image;
    SkIPoint canvas_offset = SkIPoint::Make(0, 0);

    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore:
        layer_image =
            reinterpret_cast<SkSurface*>(layer->backing_store->user_data)
                ->makeImageSnapshot();

        break;
      case kFlutterLayerContentTypePlatformView:
        layer_image =
            platform_view_renderer_callback_
                ? platform_view_renderer_callback_(*layer, context_.get())
                : nullptr;
        canvas_offset = SkIPoint::Make(layer->offset.x, layer->offset.y);
        break;
    };

    // If the layer is not a platform view but the engine did not specify an
    // image for the backing store, it is an error.
    if (!layer_image && layer->type != kFlutterLayerContentTypePlatformView) {
      FML_LOG(ERROR) << "Could not snapshot layer in test compositor: "
                     << *layer;
      return false;
    }

    // The test could have just specified no contents to be rendered in place of
    // a platform view. This is not an error.
    if (layer_image) {
      // The image rendered by Flutter already has the correct offset and
      // transformation applied. The layers offset is meant for the platform.
      canvas->drawImage(layer_image.get(), canvas_offset.x(),
                        canvas_offset.y());
    }
  }

  last_composition_ = surface->makeImageSnapshot();

  if (!last_composition_) {
    FML_LOG(ERROR) << "Could not update the contents of the sub-composition.";
    return false;
  }

  if (next_scene_callback_) {
    auto last_composition_snapshot = last_composition_->makeRasterImage();
    FML_CHECK(last_composition_snapshot);
    auto callback = next_scene_callback_;
    next_scene_callback_ = nullptr;
    callback(std::move(last_composition_snapshot));
  }

  return true;
}

sk_sp<SkImage> EmbedderTestCompositor::GetLastComposition() {
  return last_composition_;
}

bool EmbedderTestCompositor::Present(const FlutterLayer** layers,
                                     size_t layers_count) {
  if (!UpdateOffscrenComposition(layers, layers_count)) {
    FML_LOG(ERROR)
        << "Could not update the off-screen composition in the test compositor";
    return false;
  }

  // If the test has asked to access the layers and renderers being presented.
  // Access the same and present it to the test for its test assertions.
  if (present_callback_) {
    auto callback = present_callback_;
    if (present_callback_is_one_shot_) {
      present_callback_ = nullptr;
    }
    callback(layers, layers_count);
  }

  InvokeAllCallbacks(on_present_callbacks_);
  return true;
}

bool EmbedderTestCompositor::CreateFramebufferRenderSurface(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  const auto image_info =
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height);

  auto surface = SkSurface::MakeRenderTarget(
      context_.get(),               // context
      SkBudgeted::kNo,              // budgeted
      image_info,                   // image info
      1,                            // sample count
      kBottomLeft_GrSurfaceOrigin,  // surface origin
      nullptr,                      // surface properties
      false                         // mipmaps
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create render target for compositor layer.";
    return false;
  }

  GrBackendRenderTarget render_target = surface->getBackendRenderTarget(
      SkSurface::BackendHandleAccess::kDiscardWrite_BackendHandleAccess);

  if (!render_target.isValid()) {
    FML_LOG(ERROR) << "Backend render target was invalid.";
    return false;
  }

  GrGLFramebufferInfo framebuffer_info = {};
  if (!render_target.getGLFramebufferInfo(&framebuffer_info)) {
    FML_LOG(ERROR) << "Could not access backend framebuffer info.";
    return false;
  }

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = surface.get();
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = framebuffer_info.fFormat;
  backing_store_out->open_gl.framebuffer.name = framebuffer_info.fFBOID;
  // The balancing unref is in the destruction callback.
  surface->ref();
  backing_store_out->open_gl.framebuffer.user_data = surface.get();
  backing_store_out->open_gl.framebuffer.destruction_callback =
      [](void* user_data) { reinterpret_cast<SkSurface*>(user_data)->unref(); };

  return true;
}

bool EmbedderTestCompositor::CreateTextureRenderSurface(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  const auto image_info =
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height);

  auto surface = SkSurface::MakeRenderTarget(
      context_.get(),               // context
      SkBudgeted::kNo,              // budgeted
      image_info,                   // image info
      1,                            // sample count
      kBottomLeft_GrSurfaceOrigin,  // surface origin
      nullptr,                      // surface properties
      false                         // mipmaps

  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create render target for compositor layer.";
    return false;
  }

  GrBackendTexture render_texture = surface->getBackendTexture(
      SkSurface::BackendHandleAccess::kDiscardWrite_BackendHandleAccess);

  if (!render_texture.isValid()) {
    FML_LOG(ERROR) << "Backend render texture was invalid.";
    return false;
  }

  GrGLTextureInfo texture_info = {};
  if (!render_texture.getGLTextureInfo(&texture_info)) {
    FML_LOG(ERROR) << "Could not access backend texture info.";
    return false;
  }

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = surface.get();
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeTexture;
  backing_store_out->open_gl.texture.target = texture_info.fTarget;
  backing_store_out->open_gl.texture.name = texture_info.fID;
  backing_store_out->open_gl.texture.format = texture_info.fFormat;
  // The balancing unref is in the destruction callback.
  surface->ref();
  backing_store_out->open_gl.texture.user_data = surface.get();
  backing_store_out->open_gl.texture.destruction_callback =
      [](void* user_data) { reinterpret_cast<SkSurface*>(user_data)->unref(); };

  return true;
}

bool EmbedderTestCompositor::CreateSoftwareRenderSurface(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  auto surface = SkSurface::MakeRaster(
      SkImageInfo::MakeN32Premul(config->size.width, config->size.height));

  if (!surface) {
    FML_LOG(ERROR)
        << "Could not create the render target for compositor layer.";
    return false;
  }

  SkPixmap pixmap;
  if (!surface->peekPixels(&pixmap)) {
    FML_LOG(ERROR) << "Could not peek pixels of pixmap.";
    return false;
  }

  backing_store_out->type = kFlutterBackingStoreTypeSoftware;
  backing_store_out->user_data = surface.get();
  backing_store_out->software.allocation = pixmap.addr();
  backing_store_out->software.row_bytes = pixmap.rowBytes();
  backing_store_out->software.height = pixmap.height();
  // The balancing unref is in the destruction callback.
  surface->ref();
  backing_store_out->software.user_data = surface.get();
  backing_store_out->software.destruction_callback = [](void* user_data) {
    reinterpret_cast<SkSurface*>(user_data)->unref();
  };

  return true;
}

void EmbedderTestCompositor::SetNextPresentCallback(
    const PresentCallback& next_present_callback) {
  SetPresentCallback(next_present_callback, true);
}

void EmbedderTestCompositor::SetPresentCallback(
    const PresentCallback& present_callback,
    bool one_shot) {
  FML_CHECK(!present_callback_);
  present_callback_ = present_callback;
  present_callback_is_one_shot_ = one_shot;
}

void EmbedderTestCompositor::SetNextSceneCallback(
    const NextSceneCallback& next_scene_callback) {
  FML_CHECK(!next_scene_callback_);
  next_scene_callback_ = next_scene_callback;
}

void EmbedderTestCompositor::SetPlatformViewRendererCallback(
    const PlatformViewRendererCallback& callback) {
  platform_view_renderer_callback_ = callback;
}

size_t EmbedderTestCompositor::GetPendingBackingStoresCount() const {
  FML_CHECK(backing_stores_created_ >= backing_stores_collected_);
  return backing_stores_created_ - backing_stores_collected_;
}

size_t EmbedderTestCompositor::GetBackingStoresCreatedCount() const {
  return backing_stores_created_;
}

size_t EmbedderTestCompositor::GetBackingStoresCollectedCount() const {
  return backing_stores_collected_;
}

void EmbedderTestCompositor::AddOnCreateRenderTargetCallback(
    fml::closure callback) {
  on_create_render_target_callbacks_.push_back(callback);
}

void EmbedderTestCompositor::AddOnCollectRenderTargetCallback(
    fml::closure callback) {
  on_collect_render_target_callbacks_.push_back(callback);
}

void EmbedderTestCompositor::AddOnPresentCallback(fml::closure callback) {
  on_present_callbacks_.push_back(callback);
}

}  // namespace testing
}  // namespace flutter
