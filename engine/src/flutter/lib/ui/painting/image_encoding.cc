// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_encoding.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "lib/fxl/build_config.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "third_party/skia/include/core/SkEncodedImageFormat.h"
#include "third_party/skia/include/core/SkImage.h"

using tonic::DartInvoke;
using tonic::DartPersistentValue;
using tonic::ToDart;

namespace blink {
namespace {

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

sk_sp<SkData> EncodeImage(sk_sp<SkImage> image,
                          SkEncodedImageFormat format,
                          int quality) {
  if (image == nullptr) {
    return nullptr;
  }
  return image->encodeToData(format, quality);
}

void EncodeImageAndInvokeDataCallback(
    std::unique_ptr<DartPersistentValue> callback,
    sk_sp<SkImage> image,
    SkEncodedImageFormat format,
    int quality) {
  sk_sp<SkData> encoded = EncodeImage(std::move(image), format, quality);

  Threads::UI()->PostTask(
      fxl::MakeCopyable([callback = std::move(callback), encoded]() mutable {
        InvokeDataCallback(std::move(callback), std::move(encoded));
      }));
}

SkEncodedImageFormat ToSkEncodedImageFormat(int format) {
  // Map the formats exposed in flutter to formats supported in Skia.
  // See:
  // https://github.com/google/skia/blob/master/include/core/SkEncodedImageFormat.h
  switch (format) {
    case 0:
      return SkEncodedImageFormat::kJPEG;
    case 1:
      return SkEncodedImageFormat::kPNG;
    case 2:
      return SkEncodedImageFormat::kWEBP;
    default:
      /* NOTREACHED */
      return SkEncodedImageFormat::kWEBP;
  }
}

}  // namespace

Dart_Handle EncodeImage(CanvasImage* canvas_image,
                        int format,
                        int quality,
                        Dart_Handle callback_handle) {
  if (!canvas_image)
    return ToDart("encode called with non-genuine Image.");

  if (!Dart_IsClosure(callback_handle))
    return ToDart("Callback must be a function.");

  SkEncodedImageFormat image_format = ToSkEncodedImageFormat(format);

  if (quality > 100)
    quality = 100;
  if (quality < 0)
    quality = 0;

  auto callback = std::make_unique<DartPersistentValue>(
      tonic::DartState::Current(), callback_handle);
  sk_sp<SkImage> image = canvas_image->image();

  Threads::IO()->PostTask(fxl::MakeCopyable(
      [callback = std::move(callback), image, image_format, quality]() mutable {
        EncodeImageAndInvokeDataCallback(std::move(callback), std::move(image),
                                         image_format, quality);
      }));

  return Dart_Null();
}

}  // namespace blink
