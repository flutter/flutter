// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/multi_frame_codec.h"

#include "flutter/fml/make_copyable.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/skia/include/core/SkPixelRef.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {

MultiFrameCodec::MultiFrameCodec(std::unique_ptr<SkCodec> codec)
    : state_(new State(std::move(codec))) {}

MultiFrameCodec::~MultiFrameCodec() = default;

MultiFrameCodec::State::State(std::unique_ptr<SkCodec> codec)
    : codec_(std::move(codec)),
      frameCount_(codec_->getFrameCount()),
      repetitionCount_(codec_->getRepetitionCount()),
      nextFrameIndex_(0) {}

static void InvokeNextFrameCallback(
    fml::RefPtr<FrameInfo> frameInfo,
    std::unique_ptr<DartPersistentValue> callback,
    size_t trace_id) {
  std::shared_ptr<tonic::DartState> dart_state = callback->dart_state().lock();
  if (!dart_state) {
    FML_DLOG(ERROR) << "Could not acquire Dart state while attempting to fire "
                       "next frame callback.";
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  if (!frameInfo) {
    tonic::DartInvoke(callback->value(), {Dart_Null()});
  } else {
    tonic::DartInvoke(callback->value(), {ToDart(frameInfo)});
  }
}

// Copied the source bitmap to the destination. If this cannot occur due to
// running out of memory or the image info not being compatible, returns false.
static bool CopyToBitmap(SkBitmap* dst,
                         SkColorType dstColorType,
                         const SkBitmap& src) {
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

sk_sp<SkImage> MultiFrameCodec::State::GetNextFrameImage(
    fml::WeakPtr<GrContext> resourceContext) {
  SkBitmap bitmap = SkBitmap();
  SkImageInfo info = codec_->getInfo().makeColorType(kN32_SkColorType);
  if (info.alphaType() == kUnpremul_SkAlphaType) {
    info = info.makeAlphaType(kPremul_SkAlphaType);
  }
  bitmap.allocPixels(info);

  SkCodec::Options options;
  options.fFrameIndex = nextFrameIndex_;
  SkCodec::FrameInfo frameInfo;
  codec_->getFrameInfo(nextFrameIndex_, &frameInfo);
  const int requiredFrameIndex = frameInfo.fRequiredFrame;
  if (requiredFrameIndex != SkCodec::kNoFrame) {
    if (lastRequiredFrame_ == nullptr) {
      FML_LOG(ERROR) << "Frame " << nextFrameIndex_ << " depends on frame "
                     << requiredFrameIndex
                     << " and no required frames are cached.";
      return nullptr;
    } else if (lastRequiredFrameIndex_ != requiredFrameIndex) {
      FML_DLOG(INFO) << "Required frame " << requiredFrameIndex
                     << " is not cached. Using " << lastRequiredFrameIndex_
                     << " instead";
    }

    if (lastRequiredFrame_->getPixels() &&
        CopyToBitmap(&bitmap, lastRequiredFrame_->colorType(),
                     *lastRequiredFrame_)) {
      options.fPriorFrame = requiredFrameIndex;
    }
  }

  if (SkCodec::kSuccess != codec_->getPixels(info, bitmap.getPixels(),
                                             bitmap.rowBytes(), &options)) {
    FML_LOG(ERROR) << "Could not getPixels for frame " << nextFrameIndex_;
    return nullptr;
  }

  // Hold onto this if we need it to decode future frames.
  if (frameInfo.fDisposalMethod == SkCodecAnimation::DisposalMethod::kKeep) {
    lastRequiredFrame_ = std::make_unique<SkBitmap>(bitmap);
    lastRequiredFrameIndex_ = nextFrameIndex_;
  }

  if (resourceContext) {
    SkPixmap pixmap(bitmap.info(), bitmap.pixelRef()->pixels(),
                    bitmap.pixelRef()->rowBytes());
    return SkImage::MakeCrossContextFromPixmap(resourceContext.get(), pixmap,
                                               true);
  } else {
    // Defer decoding until time of draw later on the raster thread. Can happen
    // when GL operations are currently forbidden such as in the background
    // on iOS.
    return SkImage::MakeFromBitmap(bitmap);
  }
}

void MultiFrameCodec::State::GetNextFrameAndInvokeCallback(
    std::unique_ptr<DartPersistentValue> callback,
    fml::RefPtr<fml::TaskRunner> ui_task_runner,
    fml::WeakPtr<GrContext> resourceContext,
    fml::RefPtr<flutter::SkiaUnrefQueue> unref_queue,
    size_t trace_id) {
  fml::RefPtr<FrameInfo> frameInfo = NULL;
  sk_sp<SkImage> skImage = GetNextFrameImage(resourceContext);
  if (skImage) {
    fml::RefPtr<CanvasImage> image = CanvasImage::Create();
    image->set_image({skImage, std::move(unref_queue)});
    SkCodec::FrameInfo skFrameInfo;
    codec_->getFrameInfo(nextFrameIndex_, &skFrameInfo);
    frameInfo =
        fml::MakeRefCounted<FrameInfo>(std::move(image), skFrameInfo.fDuration);
  }
  nextFrameIndex_ = (nextFrameIndex_ + 1) % frameCount_;

  ui_task_runner->PostTask(fml::MakeCopyable(
      [callback = std::move(callback), frameInfo, trace_id]() mutable {
        InvokeNextFrameCallback(frameInfo, std::move(callback), trace_id);
      }));
}

Dart_Handle MultiFrameCodec::getNextFrame(Dart_Handle callback_handle) {
  static size_t trace_counter = 1;
  const size_t trace_id = trace_counter++;

  if (!Dart_IsClosure(callback_handle)) {
    return tonic::ToDart("Callback must be a function");
  }

  auto* dart_state = UIDartState::Current();

  const auto& task_runners = dart_state->GetTaskRunners();

  task_runners.GetIOTaskRunner()->PostTask(fml::MakeCopyable(
      [callback = std::make_unique<DartPersistentValue>(
           tonic::DartState::Current(), callback_handle),
       weak_state = std::weak_ptr<MultiFrameCodec::State>(state_), trace_id,
       ui_task_runner = task_runners.GetUITaskRunner(),
       io_manager = dart_state->GetIOManager()]() mutable {
        auto state = weak_state.lock();
        if (!state) {
          ui_task_runner->PostTask(fml::MakeCopyable(
              [callback = std::move(callback)]() { callback->Clear(); }));
          return;
        }
        state->GetNextFrameAndInvokeCallback(
            std::move(callback), std::move(ui_task_runner),
            io_manager->GetResourceContext(), io_manager->GetSkiaUnrefQueue(),
            trace_id);
      }));

  return Dart_Null();
}

int MultiFrameCodec::frameCount() const {
  return state_->frameCount_;
}

int MultiFrameCodec::repetitionCount() const {
  return state_->repetitionCount_;
}

}  // namespace flutter
