// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoding.h"

#include "flutter/flow/texture_image.h"
#include "flutter/glue/drain_data_pipe_job.h"
#include "flutter/glue/movable_wrapper.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "flutter/tonic/dart_state.h"
#include "lib/ftl/tasks/task_runner.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/mojo_converter.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "third_party/skia/include/core/SkImageGenerator.h"

using tonic::DartInvoke;
using tonic::DartPersistentValue;
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
    ftl::RefPtr<ftl::TaskRunner> task_runner,
    glue::MovableWrapper<std::unique_ptr<DartPersistentValue>> callback,
    std::vector<char> buffer) {
  sk_sp<SkImage> image = DecodeImage(std::move(buffer));
  task_runner->PostTask([callback, image]() mutable {
    InvokeImageCallback(image, callback.Unwrap());
  });
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

  DartState* dart_state = DartState::Current();
  ftl::RefPtr<ftl::TaskRunner> task_runner = dart_state->ui_task_runner();

  auto callback = glue::WrapMovable(std::unique_ptr<DartPersistentValue>(
      new DartPersistentValue(dart_state, callback_handle)));

  dart_state->io_task_runner()->PostTask(
      [task_runner, callback, consumer]() mutable {
        glue::DrainDataPipeJob* job = nullptr;
        job = new glue::DrainDataPipeJob(
            consumer.Unwrap(),
            [task_runner, callback, job](std::vector<char> buffer) {
              delete job;
              DecodeImageAndInvokeImageCallback(task_runner, callback,
                                                std::move(buffer));
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

  DartState* dart_state = DartState::Current();
  ftl::RefPtr<ftl::TaskRunner> task_runner = dart_state->ui_task_runner();

  auto callback = glue::WrapMovable(std::unique_ptr<DartPersistentValue>(
      new DartPersistentValue(dart_state, callback_handle)));

  const char* bytes = reinterpret_cast<const char*>(list.data());
  auto buffer = glue::WrapMovable(std::unique_ptr<std::vector<char>>(
      new std::vector<char>(bytes, bytes + list.num_elements())));

  dart_state->io_task_runner()->PostTask(
      [task_runner, callback, buffer]() mutable {
        DecodeImageAndInvokeImageCallback(task_runner, callback,
                                          std::move(*buffer.Unwrap()));
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
