// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_encoding.h"

#include <memory>
#include <utility>

#include "flutter/common/task_runners.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "lib/fxl/build_config.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkEncodedImageFormat.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSurface.h"

using tonic::DartInvoke;
using tonic::DartPersistentValue;
using tonic::ToDart;

#ifdef ERROR
#undef ERROR
#endif

namespace blink {
namespace {

// This must be kept in sync with the enum in painting.dart
enum ImageByteFormat {
  kRawRGBA,
  kRawUnmodified,
  kPNG,
};

void InvokeDataCallback(std::unique_ptr<DartPersistentValue> callback,
                        sk_sp<SkData> buffer) {
  tonic::DartState* dart_state = callback->dart_state().get();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  if (!buffer) {
    DartInvoke(callback->value(), {Dart_Null()});
  } else {
    Dart_Handle dart_data = tonic::DartConverter<tonic::Uint8List>::ToDart(
        buffer->bytes(), buffer->size());
    DartInvoke(callback->value(), {dart_data});
  }
}

sk_sp<SkImage> ConvertToRasterImageIfNecessary(sk_sp<SkImage> image,
                                               GrContext* context) {
  if (context == nullptr) {
    // The context was null (software rendering contexts) so the image is likely
    // already a raster image. Nothing more to do.
    return image;
  }

  TRACE_EVENT0("flutter", __FUNCTION__);

  // Create a GPU surface with the context and then do a device to host copy of
  // image contents.
  auto surface = SkSurface::MakeRenderTarget(
      context, SkBudgeted::kNo,
      SkImageInfo::MakeN32Premul(image->dimensions()));

  if (surface == nullptr || surface->getCanvas() == nullptr) {
    FXL_LOG(ERROR) << "Could not create a surface to copy the texture into.";
    return nullptr;
  }

  surface->getCanvas()->drawImage(image, 0, 0);
  surface->getCanvas()->flush();

  auto snapshot = surface->makeImageSnapshot();

  if (snapshot == nullptr) {
    FXL_LOG(ERROR) << "Could not snapshot image to encode.";
    return nullptr;
  }

  return snapshot->makeRasterImage();
}

sk_sp<SkData> CopyImageByteData(sk_sp<SkImage> raster_image,
                                SkColorType color_type) {
  FXL_DCHECK(raster_image);

  SkPixmap pixmap;

  if (!raster_image->peekPixels(&pixmap)) {
    FXL_LOG(ERROR) << "Could not copy pixels from the raster image.";
    return nullptr;
  }

  // The color types already match. No need to swizzle. Return early.
  if (pixmap.colorType() == color_type) {
    return SkData::MakeWithCopy(pixmap.addr(), pixmap.computeByteSize());
  }

  // Perform swizzle if the type doesnt match the specification.
  auto surface = SkSurface::MakeRaster(
      SkImageInfo::Make(raster_image->width(), raster_image->height(),
                        color_type, kPremul_SkAlphaType, nullptr));

  if (!surface) {
    FXL_LOG(ERROR) << "Could not setup the surface for swizzle.";
    return nullptr;
  }

  surface->writePixels(pixmap, 0, 0);

  if (!surface->peekPixels(&pixmap)) {
    FXL_LOG(ERROR) << "Pixel address is not available.";
    return nullptr;
  }

  return SkData::MakeWithCopy(pixmap.addr(), pixmap.computeByteSize());
}

sk_sp<SkData> EncodeImage(sk_sp<SkImage> p_image,
                          GrContext* context,
                          ImageByteFormat format) {
  TRACE_EVENT0("flutter", __FUNCTION__);

  // Check validity of the image.
  if (p_image == nullptr) {
    FXL_LOG(ERROR) << "Image was null.";
    return nullptr;
  }

  auto dimensions = p_image->dimensions();

  if (dimensions.isEmpty()) {
    FXL_LOG(ERROR) << "Image dimensions were empty.";
    return nullptr;
  }

  auto raster_image = ConvertToRasterImageIfNecessary(p_image, context);

  if (raster_image == nullptr) {
    FXL_LOG(ERROR) << "Could not create a raster copy of the image.";
    return nullptr;
  }

  switch (format) {
    case kPNG: {
      auto png_image =
          raster_image->encodeToData(SkEncodedImageFormat::kPNG, 0);

      if (png_image == nullptr) {
        FXL_LOG(ERROR) << "Could not convert raster image to PNG.";
        return nullptr;
      }
      return png_image;
    } break;
    case kRawRGBA: {
      return CopyImageByteData(raster_image, kRGBA_8888_SkColorType);
    } break;
    case kRawUnmodified: {
      return CopyImageByteData(raster_image, kN32_SkColorType);
    } break;
  }

  FXL_LOG(ERROR) << "Unknown error encoding image.";
  return nullptr;
}

void EncodeImageAndInvokeDataCallback(
    std::unique_ptr<DartPersistentValue> callback,
    sk_sp<SkImage> image,
    GrContext* context,
    fxl::RefPtr<fxl::TaskRunner> ui_task_runner,
    ImageByteFormat format) {
  sk_sp<SkData> encoded = EncodeImage(std::move(image), context, format);

  ui_task_runner->PostTask(
      fxl::MakeCopyable([callback = std::move(callback), encoded]() mutable {
        InvokeDataCallback(std::move(callback), std::move(encoded));
      }));
}

}  // namespace

Dart_Handle EncodeImage(CanvasImage* canvas_image,
                        int format,
                        Dart_Handle callback_handle) {
  if (!canvas_image)
    return ToDart("encode called with non-genuine Image.");

  if (!Dart_IsClosure(callback_handle))
    return ToDart("Callback must be a function.");

  ImageByteFormat image_format = static_cast<ImageByteFormat>(format);

  auto callback = std::make_unique<DartPersistentValue>(
      tonic::DartState::Current(), callback_handle);

  const auto& task_runners = UIDartState::Current()->GetTaskRunners();
  auto context = UIDartState::Current()->GetResourceContext();

  task_runners.GetIOTaskRunner()->PostTask(
      fxl::MakeCopyable([callback = std::move(callback),                   //
                         image = canvas_image->image(),                    //
                         context = std::move(context),                     //
                         ui_task_runner = task_runners.GetUITaskRunner(),  //
                         image_format                                      //
  ]() mutable {
        EncodeImageAndInvokeDataCallback(std::move(callback),        //
                                         std::move(image),           //
                                         context.get(),              //
                                         std::move(ui_task_runner),  //
                                         image_format                //
        );
      }));

  return Dart_Null();
}

}  // namespace blink
