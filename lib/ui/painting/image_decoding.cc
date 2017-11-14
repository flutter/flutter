// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoding.h"

#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/resource_context.h"
#include "lib/fxl/build_config.h"
#include "lib/fxl/functional/make_copyable.h"
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

static constexpr const char* kDecodeImageTraceTag = "DecodeImage";

sk_sp<SkImage> DecodeImage(sk_sp<SkData> buffer, size_t trace_id) {
  TRACE_FLOW_STEP("flutter", kDecodeImageTraceTag, trace_id);
  TRACE_EVENT0("blink", "DecodeImage");

  if (buffer == nullptr || buffer->isEmpty()) {
    return nullptr;
  }

  GrContext* context = ResourceContext::Get();
  if (context) {
    // This indicates that we do not want a "linear blending" decode.
    sk_sp<SkColorSpace> dstColorSpace = nullptr;
    return SkImage::MakeCrossContextFromEncoded(context, std::move(buffer),
                                                false, dstColorSpace.get());
  } else {
    return SkImage::MakeFromEncoded(std::move(buffer));
  }
}

void InvokeImageCallback(sk_sp<SkImage> image,
                         std::unique_ptr<DartPersistentValue> callback,
                         size_t trace_id) {
  tonic::DartState* dart_state = callback->dart_state().get();
  if (!dart_state) {
    TRACE_FLOW_END("flutter", kDecodeImageTraceTag, trace_id);
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  if (!image) {
    DartInvoke(callback->value(), {Dart_Null()});
  } else {
    fxl::RefPtr<CanvasImage> resultImage = CanvasImage::Create();
    resultImage->set_image(std::move(image));
    DartInvoke(callback->value(), {ToDart(resultImage)});
  }
  TRACE_FLOW_END("flutter", kDecodeImageTraceTag, trace_id);
}

void DecodeImageAndInvokeImageCallback(
    std::unique_ptr<DartPersistentValue> callback,
    sk_sp<SkData> buffer,
    size_t trace_id) {
  sk_sp<SkImage> image = DecodeImage(std::move(buffer), trace_id);
  Threads::UI()->PostTask(fxl::MakeCopyable([
    callback = std::move(callback), image, trace_id
  ]() mutable { InvokeImageCallback(image, std::move(callback), trace_id); }));
}

void DecodeImageFromList(Dart_NativeArguments args) {
  static size_t trace_counter = 1;
  const size_t trace_id = trace_counter++;
  TRACE_FLOW_BEGIN("flutter", kDecodeImageTraceTag, trace_id);

  Dart_Handle exception = nullptr;

  tonic::Uint8List list =
      tonic::DartConverter<tonic::Uint8List>::FromArguments(args, 0, exception);
  if (exception) {
    TRACE_FLOW_END("flutter", kDecodeImageTraceTag, trace_id);
    Dart_ThrowException(exception);
    return;
  }

  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsClosure(callback_handle)) {
    TRACE_FLOW_END("flutter", kDecodeImageTraceTag, trace_id);
    Dart_ThrowException(ToDart("Callback must be a function"));
    return;
  }

  auto buffer = SkData::MakeWithCopy(list.data(), list.num_elements());

  Threads::IO()->PostTask(fxl::MakeCopyable([
    callback = std::make_unique<DartPersistentValue>(
        tonic::DartState::Current(), callback_handle),
    buffer = std::move(buffer), trace_id
  ]() mutable {
    DecodeImageAndInvokeImageCallback(std::move(callback), std::move(buffer),
                                      trace_id);
  }));
}

}  // namespace

void ImageDecoding::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"decodeImageFromList", DecodeImageFromList, 2, true},
  });
}

}  // namespace blink
