// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/picture.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_persistent_value.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {
namespace {

sk_sp<SkSurface> MakeSnapshotSurface(const SkISize& picture_size,
                                     fml::WeakPtr<GrContext> resource_context) {
  SkImageInfo image_info = SkImageInfo::MakeN32Premul(
      picture_size.width(), picture_size.height(), SkColorSpace::MakeSRGB());
  if (resource_context) {
    return SkSurface::MakeRenderTarget(resource_context.get(),  // context
                                       SkBudgeted::kNo,         // budgeted
                                       image_info               // image info
    );
  } else {
    return SkSurface::MakeRaster(image_info);
  }
}

/// Makes a RAM backed (Raster) image of a picture.
/// @param[in] picture The picture that will get converted to an image.
/// @param[in] surface The surface tha will be used to render the picture.  This
///                    will be CPU or GPU based.
/// @todo Currently this creates a RAM backed image regardless of what type of
///       surface is used.  In certain instances we may want a GPU backed image
///       from a GPU surface to avoid the conversion.
sk_sp<SkImage> MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                  sk_sp<SkSurface> surface) {
  TRACE_EVENT0("flutter", __FUNCTION__);

  if (surface == nullptr || surface->getCanvas() == nullptr) {
    return nullptr;
  }

  surface->getCanvas()->drawPicture(picture.get());

  surface->getCanvas()->flush();

  // Here device could mean GPU or CPU (depending on the supplied surface) and
  // host means CPU; this is different from use cases like Flutter driver tests
  // where device means mobile devices and host means laptops/desktops.
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
}  // namespace

IMPLEMENT_WRAPPERTYPEINFO(ui, Picture);

#define FOR_EACH_BINDING(V) \
  V(Picture, toImage)       \
  V(Picture, dispose)       \
  V(Picture, GetAllocationSize)

DART_BIND_ALL(Picture, FOR_EACH_BINDING)

fml::RefPtr<Picture> Picture::Create(
    flutter::SkiaGPUObject<SkPicture> picture) {
  return fml::MakeRefCounted<Picture>(std::move(picture));
}

Picture::Picture(flutter::SkiaGPUObject<SkPicture> picture)
    : picture_(std::move(picture)) {}

Picture::~Picture() = default;

Dart_Handle Picture::toImage(uint32_t width,
                             uint32_t height,
                             Dart_Handle raw_image_callback) {
  if (!picture_.get()) {
    return tonic::ToDart("Picture is null");
  }

  return RasterizeToImage(picture_.get(), width, height, raw_image_callback);
}

void Picture::dispose() {
  ClearDartWrapper();
}

size_t Picture::GetAllocationSize() {
  if (auto picture = picture_.get()) {
    return picture->approximateBytesUsed();
  } else {
    return sizeof(Picture);
  }
}

Dart_Handle Picture::RasterizeToImage(sk_sp<SkPicture> picture,
                                      uint32_t width,
                                      uint32_t height,
                                      Dart_Handle raw_image_callback) {
  if (Dart_IsNull(raw_image_callback) || !Dart_IsClosure(raw_image_callback)) {
    return tonic::ToDart("Image callback was invalid");
  }

  if (width == 0 || height == 0) {
    return tonic::ToDart("Image dimensions for scene were invalid.");
  }

  auto* dart_state = UIDartState::Current();
  tonic::DartPersistentValue* image_callback =
      new tonic::DartPersistentValue(dart_state, raw_image_callback);
  auto unref_queue = dart_state->GetSkiaUnrefQueue();
  auto ui_task_runner = dart_state->GetTaskRunners().GetUITaskRunner();
  auto io_task_runner = dart_state->GetTaskRunners().GetIOTaskRunner();
  fml::WeakPtr<GrContext> resource_context = dart_state->GetResourceContext();

  // We can't create an image on this task runner because we don't have a
  // graphics context. Even if we did, it would be slow anyway. Also, this
  // thread owns the sole reference to the layer tree. So we flatten the layer
  // tree into a picture and use that as the thread transport mechanism.

  auto picture_bounds = SkISize::Make(width, height);

  auto ui_task = fml::MakeCopyable([image_callback, unref_queue](
                                       sk_sp<SkImage> raster_image) mutable {
    auto dart_state = image_callback->dart_state().lock();
    if (!dart_state) {
      // The root isolate could have died in the meantime.
      return;
    }
    tonic::DartState::Scope scope(dart_state);

    if (!raster_image) {
      tonic::DartInvoke(image_callback->Get(), {Dart_Null()});
      return;
    }

    auto dart_image = CanvasImage::Create();
    dart_image->set_image({std::move(raster_image), std::move(unref_queue)});
    auto* raw_dart_image = tonic::ToDart(std::move(dart_image));

    // All done!
    tonic::DartInvoke(image_callback->Get(), {raw_dart_image});

    // image_callback is associated with the Dart isolate and must be deleted
    // on the UI thread
    delete image_callback;
  });

  fml::TaskRunner::RunNowOrPostTask(io_task_runner, [ui_task_runner, picture,
                                                     picture_bounds, ui_task,
                                                     resource_context] {
    sk_sp<SkSurface> surface =
        MakeSnapshotSurface(picture_bounds, resource_context);
    sk_sp<SkImage> raster_image = MakeRasterSnapshot(picture, surface);

    fml::TaskRunner::RunNowOrPostTask(
        ui_task_runner, [ui_task, raster_image]() { ui_task(raster_image); });
  });

  return Dart_Null();
}

}  // namespace flutter
