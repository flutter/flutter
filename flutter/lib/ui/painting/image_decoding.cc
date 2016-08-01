// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoding.h"

#include "base/bind.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "flow/texture_image.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/tonic/dart_invoke.h"
#include "flutter/tonic/dart_persistent_value.h"
#include "flutter/tonic/mojo_converter.h"
#include "flutter/tonic/uint8_list.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"
#include "sky/engine/platform/mojo/data_pipe.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/shell/platform_view.h"
#include "third_party/skia/include/core/SkImageGenerator.h"

namespace blink {
namespace {

sk_sp<SkImage> DecodeImage(PassRefPtr<SharedBuffer> buffer) {
  TRACE_EVENT0("blink", "DecodeImage");

  const size_t data_size = buffer->size();

  if (buffer == nullptr || data_size == 0) {
    return nullptr;
  }

  sk_sp<SkData> sk_data = SkData::MakeWithoutCopy(buffer->data(), data_size);

  if (sk_data == nullptr) {
    return nullptr;
  }

  std::unique_ptr<SkImageGenerator> generator(
      SkImageGenerator::NewFromEncoded(sk_data.get()));

  if (generator == nullptr) {
    return nullptr;
  }

  auto context = reinterpret_cast<GrContext*>(
      sky::shell::PlatformView::ResourceContext.Get());

  // First, try to create a texture image from the generator.
  if (auto image = flow::TextureImageCreate(context, *generator)) {
    return image;
  }

  // The, as a fallback, try to create a regular Skia managed image. These
  // don't require a context ready.
  return flow::BitmapImageCreate(*generator);
}

void InvokeImageCallback(sk_sp<SkImage> image,
                         scoped_ptr<DartPersistentValue> callback) {
  DartState* dart_state = callback->dart_state().get();
  if (!dart_state)
    return;
  DartState::Scope scope(dart_state);
  if (!image) {
    DartInvoke(callback->value(), {Dart_Null()});
  } else {
    scoped_refptr<CanvasImage> resultImage = CanvasImage::Create();
    resultImage->set_image(std::move(image));
    DartInvoke(callback->value(), {ToDart(resultImage)});
  }
}

void DecodeImageAndInvokeImageCallback(scoped_ptr<DartPersistentValue> callback,
                                       PassRefPtr<SharedBuffer> buffer) {
  sk_sp<SkImage> image = DecodeImage(buffer);
  Platform::current()->GetUITaskRunner()->PostTask(
      FROM_HERE,
      base::Bind(InvokeImageCallback, image, base::Passed(&callback)));
}

void DecodeImageFromDataPipe(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;

  mojo::ScopedDataPipeConsumerHandle consumer =
      DartConverter<mojo::ScopedDataPipeConsumerHandle>::FromArguments(
          args, 0, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }

  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsClosure(callback_handle)) {
    Dart_ThrowException(ToDart("Callback must be a function"));
    return;
  }
  scoped_ptr<DartPersistentValue> callback(
      new DartPersistentValue(DartState::Current(), callback_handle));

  Platform::current()->GetIOTaskRunner()->PostTask(
      FROM_HERE, base::Bind(&DrainDataPipe, base::Passed(&consumer),
                            base::Bind(DecodeImageAndInvokeImageCallback,
                                       base::Passed(&callback))));
}

void DecodeImageFromList(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;

  Uint8List list = DartConverter<Uint8List>::FromArguments(args, 0, exception);
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }

  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsClosure(callback_handle)) {
    Dart_ThrowException(ToDart("Callback must be a function"));
    return;
  }
  scoped_ptr<DartPersistentValue> callback(
      new DartPersistentValue(DartState::Current(), callback_handle));

  RefPtr<SharedBuffer> buffer = SharedBuffer::create();
  buffer->append(reinterpret_cast<const char*>(list.data()),
                 list.num_elements());

  Platform::current()->GetIOTaskRunner()->PostTask(
      FROM_HERE, base::Bind(DecodeImageAndInvokeImageCallback,
                            base::Passed(&callback), buffer));
}

}  // namespace

void ImageDecoding::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
      {"decodeImageFromDataPipe", DecodeImageFromDataPipe, 2, true},
      {"decodeImageFromList", DecodeImageFromList, 2, true},
  });
}

}  // namespace blink
