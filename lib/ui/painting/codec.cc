// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/codec.h"

#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/painting/frame_info.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/logging/dart_invoke.h"
#include "lib/tonic/typed_data/uint8_list.h"
#include "third_party/skia/include/codec/SkCodec.h"

using tonic::DartInvoke;
using tonic::DartPersistentValue;
using tonic::ToDart;

namespace blink {

namespace {

static constexpr const char* kInitCodecTraceTag = "InitCodec";
static constexpr const char* kCodecNextFrameTraceTag = "CodecNextFrame";

std::unique_ptr<SkCodec> InitCodec(sk_sp<SkData> buffer, size_t trace_id) {
  TRACE_FLOW_STEP("flutter", kInitCodecTraceTag, trace_id);
  TRACE_EVENT0("blink", "InitCodec");

  if (buffer == nullptr || buffer->isEmpty()) {
    return nullptr;
  }

  return SkCodec::MakeFromData(buffer);
}

void InvokeCodecCallback(std::unique_ptr<SkCodec> codec,
                         std::unique_ptr<DartPersistentValue> callback,
                         size_t trace_id) {
  tonic::DartState* dart_state = callback->dart_state().get();
  if (!dart_state) {
    TRACE_FLOW_END("flutter", kInitCodecTraceTag, trace_id);
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  if (!codec) {
    DartInvoke(callback->value(), {Dart_Null()});
  } else {
    fxl::RefPtr<Codec> resultCodec =
        fxl::MakeRefCounted<MultiFrameCodec>(std::move(codec));
    DartInvoke(callback->value(), {ToDart(resultCodec)});
  }
  TRACE_FLOW_END("flutter", kInitCodecTraceTag, trace_id);
}

void InitCodecAndInvokeCodecCallback(
    std::unique_ptr<DartPersistentValue> callback,
    sk_sp<SkData> buffer,
    size_t trace_id) {
  std::unique_ptr<SkCodec> codec = InitCodec(std::move(buffer), trace_id);
  Threads::UI()->PostTask(fxl::MakeCopyable([
    callback = std::move(callback), codec = std::move(codec), trace_id
  ]() mutable {
    InvokeCodecCallback(std::move(codec), std::move(callback), trace_id);
  }));
}

void InstantiateImageCodec(Dart_NativeArguments args) {
  static size_t trace_counter = 1;
  const size_t trace_id = trace_counter++;
  TRACE_FLOW_BEGIN("flutter", kInitCodecTraceTag, trace_id);

  Dart_Handle exception = nullptr;

  tonic::Uint8List list =
      tonic::DartConverter<tonic::Uint8List>::FromArguments(args, 0, exception);
  if (exception) {
    TRACE_FLOW_END("flutter", kInitCodecTraceTag, trace_id);
    Dart_SetReturnValue(args, exception);
    return;
  }

  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsClosure(callback_handle)) {
    TRACE_FLOW_END("flutter", kInitCodecTraceTag, trace_id);
    Dart_SetReturnValue(args, ToDart("Callback must be a function"));
    return;
  }

  auto buffer = SkData::MakeWithCopy(list.data(), list.num_elements());

  Threads::IO()->PostTask(fxl::MakeCopyable([
    callback = std::make_unique<DartPersistentValue>(
        tonic::DartState::Current(), callback_handle),
    buffer = std::move(buffer), trace_id
  ]() mutable {
    InitCodecAndInvokeCodecCallback(std::move(callback), std::move(buffer),
                                    trace_id);
  }));
}

bool copy_to(SkBitmap* dst, SkColorType dstColorType, const SkBitmap& src) {
  SkPixmap srcPM;
  if (!src.peekPixels(&srcPM)) {
    return false;
  }

  SkBitmap tmpDst;
  SkImageInfo dstInfo = srcPM.info().makeColorType(dstColorType);
  if (!tmpDst.setInfo(dstInfo)) {
    return false;
  }

  if (!tmpDst.tryAllocPixels()) {
    return false;
  }

  SkPixmap dstPM;
  if (!tmpDst.peekPixels(&dstPM)) {
    return false;
  }

  if (!srcPM.readPixels(dstPM)) {
    return false;
  }

  dst->swap(tmpDst);
  return true;
}

void InvokeNextFrameCallback(fxl::RefPtr<FrameInfo> frameInfo,
                             std::unique_ptr<DartPersistentValue> callback,
                             size_t trace_id) {
  tonic::DartState* dart_state = callback->dart_state().get();
  if (!dart_state) {
    TRACE_FLOW_END("flutter", kCodecNextFrameTraceTag, trace_id);
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  if (!frameInfo) {
    DartInvoke(callback->value(), {Dart_Null()});
  } else {
    DartInvoke(callback->value(), {ToDart(frameInfo)});
  }
  TRACE_FLOW_END("flutter", kCodecNextFrameTraceTag, trace_id);
}

}  // namespace

IMPLEMENT_WRAPPERTYPEINFO(ui, Codec);

#define FOR_EACH_BINDING(V) \
  V(Codec, getNextFrame)    \
  V(Codec, frameCount)      \
  V(Codec, repetitionCount) \
  V(Codec, dispose)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void Codec::dispose() {
  ClearDartWrapper();
}

MultiFrameCodec::MultiFrameCodec(std::unique_ptr<SkCodec> codec)
    : codec_(std::move(codec)) {
  repetitionCount_ = codec_->getRepetitionCount();
  frameInfos_ = codec_->getFrameInfo();
  frameBitmaps_.resize(frameInfos_.size());
  nextFrameIndex_ = 0;
}

sk_sp<SkImage> MultiFrameCodec::GetNextFrameImage() {
  SkBitmap& bitmap = frameBitmaps_[nextFrameIndex_];
  if (!bitmap.getPixels()) {  // We haven't decoded this frame yet
    const SkImageInfo info = codec_->getInfo().makeColorType(kN32_SkColorType);
    bitmap.allocPixels(info);

    SkCodec::Options options;
    options.fFrameIndex = nextFrameIndex_;
    const int requiredFrame = frameInfos_[nextFrameIndex_].fRequiredFrame;
    if (requiredFrame != SkCodec::kNone) {
      if (requiredFrame < 0 ||
          static_cast<size_t>(requiredFrame) >= frameBitmaps_.size()) {
        FXL_LOG(ERROR) << "Frame " << nextFrameIndex_ << " depends on frame "
                       << requiredFrame << " which out of range (0,"
                       << frameBitmaps_.size() << ").";
        return NULL;
      }
      SkBitmap& requiredBitmap = frameBitmaps_[requiredFrame];
      // For simplicity, do not try to cache old frames
      if (requiredBitmap.getPixels() &&
          copy_to(&bitmap, requiredBitmap.colorType(), requiredBitmap)) {
        options.fPriorFrame = requiredFrame;
      }
    }

    if (SkCodec::kSuccess != codec_->getPixels(info, bitmap.getPixels(),
                                               bitmap.rowBytes(), &options)) {
      FXL_LOG(ERROR) << "Could not getPixels for frame " << nextFrameIndex_;
      return NULL;
    }
  }

  return SkImage::MakeFromBitmap(bitmap);
}

void MultiFrameCodec::GetNextFrameAndInvokeCallback(
    std::unique_ptr<DartPersistentValue> callback,
    size_t trace_id) {
  fxl::RefPtr<FrameInfo> frameInfo = NULL;
  sk_sp<SkImage> skImage = GetNextFrameImage();
  if (skImage) {
    fxl::RefPtr<CanvasImage> image = CanvasImage::Create();
    image->set_image(skImage);
    frameInfo = fxl::MakeRefCounted<FrameInfo>(
        std::move(image), frameInfos_[nextFrameIndex_].fDuration);
  }
  nextFrameIndex_ = (nextFrameIndex_ + 1) % frameInfos_.size();

  Threads::UI()->PostTask(fxl::MakeCopyable(
      [ callback = std::move(callback), frameInfo, trace_id ]() mutable {
        InvokeNextFrameCallback(frameInfo, std::move(callback), trace_id);
      }));

  TRACE_FLOW_END("flutter", kCodecNextFrameTraceTag, trace_id);
}

Dart_Handle MultiFrameCodec::getNextFrame(Dart_Handle callback_handle) {
  static size_t trace_counter = 1;
  const size_t trace_id = trace_counter++;
  TRACE_FLOW_BEGIN("flutter", kCodecNextFrameTraceTag, trace_id);

  if (!Dart_IsClosure(callback_handle)) {
    TRACE_FLOW_END("flutter", kCodecNextFrameTraceTag, trace_id);
    return ToDart("Callback must be a function");
  }

  Threads::IO()->PostTask(fxl::MakeCopyable([
    callback = std::make_unique<DartPersistentValue>(
        tonic::DartState::Current(), callback_handle),
    this, trace_id
  ]() mutable {
    GetNextFrameAndInvokeCallback(std::move(callback), trace_id);
  }));

  return Dart_Null();
}

void Codec::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"instantiateImageCodec", InstantiateImageCodec, 2, true},
  });
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

}  // namespace blink
