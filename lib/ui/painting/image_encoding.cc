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

sk_sp<SkData> EncodeImage(sk_sp<SkImage> image, ImageByteFormat format) {
  TRACE_EVENT0("flutter", __FUNCTION__);

  if (image == nullptr) {
    return nullptr;
  }

  if (format == kPNG) {
    return image->encodeToData(SkEncodedImageFormat::kPNG, 0);
  }

  // Copy the GPU image snapshot into CPU memory.
  auto cpu_snapshot = image->makeRasterImage();
  if (!cpu_snapshot) {
    FXL_LOG(ERROR) << "Pixel copy failed.";
    return nullptr;
  }

  SkPixmap pixmap;
  if (!cpu_snapshot->peekPixels(&pixmap)) {
    FXL_LOG(ERROR) << "Pixel address is not available.";
    return nullptr;
  }

  if (format == kRawUnmodified) {
    return SkData::MakeWithCopy(pixmap.addr(), pixmap.computeByteSize());
  }

  ASSERT(format == kRawRGBA);
  if (pixmap.colorType() != kRGBA_8888_SkColorType) {
    TRACE_EVENT0("flutter", "ConvertToRGBA");

    // Convert the pixel data to N32 to adhere to our API contract.
    const auto image_info = SkImageInfo::MakeN32Premul(image->width(),
                                                       image->height());
    auto surface = SkSurface::MakeRaster(image_info);
    surface->writePixels(pixmap, 0, 0);
    if (!surface->peekPixels(&pixmap)) {
      FXL_LOG(ERROR) << "Pixel address is not available.";
      return nullptr;
    }

    return SkData::MakeWithCopy(pixmap.addr32(), pixmap.computeByteSize());
  } else {
    return SkData::MakeWithCopy(pixmap.addr32(), pixmap.computeByteSize());
  }
}

void EncodeImageAndInvokeDataCallback(
    std::unique_ptr<DartPersistentValue> callback,
    sk_sp<SkImage> image,
    fxl::RefPtr<fxl::TaskRunner> ui_task_runner,
    ImageByteFormat format) {
  sk_sp<SkData> encoded = EncodeImage(std::move(image), format);

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
  sk_sp<SkImage> image = canvas_image->image();

  const auto& task_runners = UIDartState::Current()->GetTaskRunners();

  task_runners.GetIOTaskRunner()->PostTask(fxl::MakeCopyable(
      [callback = std::move(callback), image,
       ui_task_runner = task_runners.GetUITaskRunner(),
       image_format]() mutable {
        EncodeImageAndInvokeDataCallback(std::move(callback),
                                         std::move(image),
                                         std::move(ui_task_runner),
                                         image_format);
      }));

  return Dart_Null();
}

}  // namespace blink
