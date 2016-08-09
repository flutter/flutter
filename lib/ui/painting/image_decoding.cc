// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoding.h"

#include "flutter/flow/texture_image.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "flutter/glue/drain_data_pipe_job.h"
#include "flutter/glue/movable_wrapper.h"
#include "flutter/glue/trace_event.h"
#include "lib/ftl/tasks/task_runner.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/mojo_converter.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "flutter/sky/engine/public/platform/Platform.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "third_party/skia/include/core/SkImageGenerator.h"

using tonic::DartInvoke;
using tonic::DartPersistentValue;
using tonic::DartState;
using tonic::ToDart;

namespace blink {
namespace {

sk_sp<SkImage> DecodeImage(std::vector<char> buffer) {
  TRACE_EVENT0("blink", "DecodeImage");

  if (buffer.empty()) {
    return nullptr;
  }

  sk_sp<SkData> sk_data = SkData::MakeWithoutCopy(buffer.data(), buffer.size());

  if (sk_data == nullptr) {
    return nullptr;
  }

  std::unique_ptr<SkImageGenerator> generator(
      SkImageGenerator::NewFromEncoded(sk_data.get()));

  if (generator == nullptr) {
    return nullptr;
  }

  GrContext* context = ResourceContext::Get();

  // First, try to create a texture image from the generator.
  if (sk_sp<SkImage> image = flow::TextureImageCreate(context, *generator)) {
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
                                       std::vector<char> buffer) {
  sk_sp<SkImage> image = DecodeImage(std::move(buffer));
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
        glue::DrainDataPipeJob* job = nullptr;
        job = new glue::DrainDataPipeJob(
            consumer.Unwrap(), [callback, job](std::vector<char> buffer) {
              delete job;
              DecodeImageAndInvokeImageCallback(callback, std::move(buffer));
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

  const char* bytes = reinterpret_cast<const char*>(list.data());
  PassOwnPtr<std::vector<char>> buffer =
      adoptPtr(new std::vector<char>(bytes, bytes + list.num_elements()));

  Platform::current()->GetIOTaskRunner()->PostTask([callback, buffer]() {
    DecodeImageAndInvokeImageCallback(callback, std::move(*buffer));
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
