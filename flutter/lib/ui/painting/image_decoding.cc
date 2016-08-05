// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoding.h"

#include "flow/texture_image.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/tonic/mojo_converter.h"
#include "glue/movable_wrapper.h"
#include "glue/trace_event.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "sky/engine/platform/mojo/data_pipe.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/shell/platform_view.h"
#include "third_party/skia/include/core/SkImageGenerator.h"

using tonic::DartInvoke;
using tonic::DartPersistentValue;
using tonic::ToDart;

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
                         PassOwnPtr<DartPersistentValue> callback) {
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

void DecodeImageAndInvokeImageCallback(PassOwnPtr<DartPersistentValue> callback,
                                       PassRefPtr<SharedBuffer> buffer) {
  sk_sp<SkImage> image = DecodeImage(buffer);
  Platform::current()->GetUITaskRunner()->PostTask(
      [callback, image]() { InvokeImageCallback(image, callback); });
}

void DecodeImageFromDataPipe(Dart_NativeArguments args) {
  Dart_Handle exception = nullptr;

  auto consumer = glue::WrapMovable(
      tonic::DartConverter<mojo::ScopedDataPipeConsumerHandle>::FromArguments(
          args, 0, exception));
  if (exception) {
    Dart_ThrowException(exception);
    return;
  }

  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsClosure(callback_handle)) {
    Dart_ThrowException(ToDart("Callback must be a function"));
    return;
  }

  PassOwnPtr<DartPersistentValue> callback =
      adoptPtr(new DartPersistentValue(DartState::Current(), callback_handle));

  Platform::current()->GetIOTaskRunner()->PostTask(
      [callback, consumer]() mutable {
        DrainDataPipe(consumer.Unwrap(),
                      [callback](PassRefPtr<SharedBuffer> buffer) {
                        DecodeImageAndInvokeImageCallback(callback, buffer);
                      });
      });
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
  PassOwnPtr<DartPersistentValue> callback =
      adoptPtr(new DartPersistentValue(DartState::Current(), callback_handle));

  RefPtr<SharedBuffer> buffer = SharedBuffer::create();
  buffer->append(reinterpret_cast<const char*>(list.data()),
                 list.num_elements());

  Platform::current()->GetIOTaskRunner()->PostTask([callback, buffer]() {
    DecodeImageAndInvokeImageCallback(callback, buffer);
  });
}

}  // namespace

void ImageDecoding::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"decodeImageFromDataPipe", DecodeImageFromDataPipe, 2, true},
      {"decodeImageFromList", DecodeImageFromList, 2, true},
  });
}

}  // namespace blink
