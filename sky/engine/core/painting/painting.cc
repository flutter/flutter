// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/painting.h"

#include "base/bind.h"
#include "base/logging.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"
#include "sky/engine/platform/mojo/data_pipe.h"
#include "sky/engine/tonic/dart_invoke.h"
#include "sky/engine/tonic/dart_persistent_value.h"
#include "sky/engine/tonic/mojo_converter.h"
#include "sky/engine/tonic/uint8_list.h"

namespace blink {
namespace {

void DecodeImage(scoped_ptr<DartPersistentValue> callback,
                 PassRefPtr<SharedBuffer> buffer) {
  TRACE_EVENT0("blink", "DecodeImage");

  DartState* dart_state = callback->dart_state().get();
  if (!dart_state)
    return;
  DartState::Scope scope(dart_state);

  OwnPtr<ImageDecoder> decoder =
      ImageDecoder::create(*buffer.get(), ImageSource::AlphaPremultiplied,
                           ImageSource::GammaAndColorProfileIgnored);

  // decoder can be null if the buffer was empty and we couldn't even guess
  // what type of image to decode.
  if (!decoder) {
    DartInvoke(callback->value(), {Dart_Null()});
    return;
  }
  decoder->setData(buffer.get(), true);
  if (decoder->failed() || decoder->frameCount() == 0) {
    DartInvoke(callback->value(), {Dart_Null()});
    return;
  }
  ImageFrame* imageFrame = decoder->frameBufferAtIndex(0);
  if (decoder->failed()) {
    DartInvoke(callback->value(), {Dart_Null()});
    return;
  }

  RefPtr<CanvasImage> resultImage = CanvasImage::create();
  sk_sp<SkImage> skImage = SkImage::MakeFromBitmap(imageFrame->getSkBitmap());
  resultImage->setImage(std::move(skImage));

  DartInvoke(callback->value(), {ToDart(resultImage)});
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

  DrainDataPipeInBackground(consumer.Pass(),
      base::Bind(&DecodeImage, base::Passed(&callback)));
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

  base::MessageLoop::current()->PostTask(FROM_HERE,
      base::Bind(&DecodeImage, base::Passed(&callback), buffer.release()));
}

}  // namespace

void Painting::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "decodeImageFromDataPipe", DecodeImageFromDataPipe, 2, true },
    { "decodeImageFromList", DecodeImageFromList, 2, true },
  });
}

}  // namespace blink
