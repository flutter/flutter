// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoding.h"

#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "lib/ftl/functional/make_copyable.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "third_party/skia/include/core/SkImageGenerator.h"

using tonic::DartInvoke;
using tonic::DartPersistentValue;
using tonic::ToDart;

namespace blink {
namespace {

sk_sp<SkImage> DecodeImage(sk_sp<SkData> buffer) {
  TRACE_EVENT0("blink", "DecodeImage");

  if (buffer == nullptr || buffer->isEmpty()) {
    return nullptr;
  }

  auto raster_image = SkImage::MakeFromEncoded(std::move(buffer));

  if (raster_image == nullptr) {
    return nullptr;
  }

  if (auto context = ResourceContext::Get()) {
    auto colorspace = SkColorSpace::MakeSRGB();
    if (auto texture_image =
            raster_image->makeTextureImage(context, colorspace.get())) {
      return texture_image;
    }
  }

  return raster_image;
}

void InvokeImageCallback(sk_sp<SkImage> image,
                         std::unique_ptr<DartPersistentValue> callback) {
  tonic::DartState* dart_state = callback->dart_state().get();
  if (!dart_state)
    return;
  tonic::DartState::Scope scope(dart_state);
  if (!image) {
    DartInvoke(callback->value(), {Dart_Null()});
  } else {
    ftl::RefPtr<CanvasImage> resultImage = CanvasImage::Create();
    resultImage->set_image(std::move(image));
    DartInvoke(callback->value(), {ToDart(resultImage)});
  }
}

void DecodeImageAndInvokeImageCallback(
    std::unique_ptr<DartPersistentValue> callback,
    sk_sp<SkData> buffer) {
  sk_sp<SkImage> image = DecodeImage(std::move(buffer));
  Threads::UI()->PostTask(
      ftl::MakeCopyable([ callback = std::move(callback), image ]() mutable {
        InvokeImageCallback(image, std::move(callback));
      }));
}

void DecodeImageFromList(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;

  tonic::Uint8List list =
      tonic::DartConverter<tonic::Uint8List>::FromArguments(args, 0, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }

  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsClosure(callback_handle)) {
    Dart_ThrowException(ToDart("Callback must be a function"));
    return;
  }

  auto buffer = SkData::MakeWithCopy(list.data(), list.num_elements());

  Threads::IO()->PostTask(ftl::MakeCopyable([
    callback = std::make_unique<DartPersistentValue>(
        tonic::DartState::Current(), callback_handle),
    buffer = std::move(buffer)
  ]() mutable {
    DecodeImageAndInvokeImageCallback(std::move(callback), std::move(buffer));
  }));
}

}  // namespace

void ImageDecoding::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"decodeImageFromList", DecodeImageFromList, 2, true},
  });
}

}  // namespace blink
