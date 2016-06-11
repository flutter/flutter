// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/painting.h"

#include "base/bind.h"
#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "flutter/tonic/dart_invoke.h"
#include "flutter/tonic/dart_persistent_value.h"
#include "flutter/tonic/mojo_converter.h"
#include "flutter/tonic/uint8_list.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"
#include "sky/engine/platform/mojo/data_pipe.h"

namespace blink {
namespace {

sk_sp<SkImage> DecodeImage(PassRefPtr<SharedBuffer> buffer) {
  TRACE_EVENT0("blink", "DecodeImage");
  OwnPtr<ImageDecoder> decoder =
      ImageDecoder::create(*buffer.get(), ImageSource::AlphaPremultiplied,
                           ImageSource::GammaAndColorProfileIgnored);
  // decoder can be null if the buffer was empty and we couldn't even guess
  // what type of image to decode.
  if (!decoder)
    return nullptr;
  decoder->setData(buffer.get(), true);
  if (decoder->failed() || decoder->frameCount() == 0)
    return nullptr;
  ImageFrame* imageFrame = decoder->frameBufferAtIndex(0);
  if (decoder->failed())
    return nullptr;
  return SkImage::MakeFromBitmap(imageFrame->getSkBitmap());
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
    scoped_refptr<CanvasImage> resultImage = CanvasImage::create();
    resultImage->setImage(std::move(image));
    DartInvoke(callback->value(), {ToDart(resultImage)});
  }
}

void DecodeImageAndInvokeImageCallback(
    scoped_ptr<DartPersistentValue> callback, PassRefPtr<SharedBuffer> buffer) {
  sk_sp<SkImage> image = DecodeImage(buffer);
  Platform::current()->GetUITaskRunner()->PostTask(FROM_HERE,
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

  Platform::current()->GetIOTaskRunner()->PostTask(FROM_HERE,
    base::Bind(&DrainDataPipe,
               base::Passed(&consumer),
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

  Platform::current()->GetIOTaskRunner()->PostTask(FROM_HERE,
      base::Bind(DecodeImageAndInvokeImageCallback,
                 base::Passed(&callback), buffer));
}

}  // namespace

void Painting::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "decodeImageFromDataPipe", DecodeImageFromDataPipe, 2, true },
    { "decodeImageFromList", DecodeImageFromList, 2, true },
  });
}

}  // namespace blink
