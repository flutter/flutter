// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/multi_frame_codec.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/lib/ui/painting/image.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/skia/include/core/SkPixelRef.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {

MultiFrameCodec::MultiFrameCodec(std::shared_ptr<ImageGenerator> generator)
    : state_(new State(std::move(generator))) {}

MultiFrameCodec::~MultiFrameCodec() = default;

MultiFrameCodec::State::State(std::shared_ptr<ImageGenerator> generator)
    : generator_(std::move(generator)),
      frameCount_(generator_->GetFrameCount()),
      repetitionCount_(generator_->GetPlayCount() ==
                               ImageGenerator::kInfinitePlayCount
                           ? -1
                           : generator_->GetPlayCount() - 1),
      nextFrameIndex_(0) {}

static void InvokeNextFrameCallback(
    fml::RefPtr<CanvasImage> image,
    int duration,
    std::unique_ptr<DartPersistentValue> callback,
    size_t trace_id) {
  std::shared_ptr<tonic::DartState> dart_state = callback->dart_state().lock();
  if (!dart_state) {
    FML_DLOG(ERROR) << "Could not acquire Dart state while attempting to fire "
                       "next frame callback.";
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  tonic::DartInvoke(callback->value(),
                    {tonic::ToDart(image), tonic::ToDart(duration)});
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
    fml::WeakPtr<GrDirectContext> resourceContext,
    const std::shared_ptr<const fml::SyncSwitch>& gpu_disable_sync_switch) {
  SkBitmap bitmap = SkBitmap();
  SkImageInfo info = generator_->GetInfo().makeColorType(kN32_SkColorType);
  if (info.alphaType() == kUnpremul_SkAlphaType) {
    SkImageInfo updated = info.makeAlphaType(kPremul_SkAlphaType);
    info = updated;
  }
  bitmap.allocPixels(info);

  ImageGenerator::FrameInfo frameInfo =
      generator_->GetFrameInfo(nextFrameIndex_);

  const int requiredFrameIndex =
      frameInfo.required_frame.value_or(SkCodec::kNoFrame);
  std::optional<unsigned int> prior_frame_index = std::nullopt;

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
      prior_frame_index = requiredFrameIndex;
    }
  }

  if (!generator_->GetPixels(info, bitmap.getPixels(), bitmap.rowBytes(),
                             nextFrameIndex_, requiredFrameIndex)) {
    FML_LOG(ERROR) << "Could not getPixels for frame " << nextFrameIndex_;
    return nullptr;
  }

  // Hold onto this if we need it to decode future frames.
  if (frameInfo.disposal_method == SkCodecAnimation::DisposalMethod::kKeep) {
    lastRequiredFrame_ = std::make_unique<SkBitmap>(bitmap);
    lastRequiredFrameIndex_ = nextFrameIndex_;
  }
  sk_sp<SkImage> result;

  gpu_disable_sync_switch->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&result, &bitmap] {
            // Defer decoding until time of draw later on the raster thread. Can
            // happen when GL operations are currently forbidden such as in the
            // background on iOS.
            result = SkImage::MakeFromBitmap(bitmap);
          })
          .SetIfFalse([&result, &resourceContext, &bitmap] {
            if (resourceContext) {
              SkPixmap pixmap(bitmap.info(), bitmap.pixelRef()->pixels(),
                              bitmap.pixelRef()->rowBytes());
              result = SkImage::MakeCrossContextFromPixmap(
                  resourceContext.get(), pixmap, true);
            } else {
              // Defer decoding until time of draw later on the raster thread.
              // Can happen when GL operations are currently forbidden such as
              // in the background on iOS.
              result = SkImage::MakeFromBitmap(bitmap);
            }
          }));
  return result;
}

void MultiFrameCodec::State::GetNextFrameAndInvokeCallback(
    std::unique_ptr<DartPersistentValue> callback,
    fml::RefPtr<fml::TaskRunner> ui_task_runner,
    fml::WeakPtr<GrDirectContext> resourceContext,
    fml::RefPtr<flutter::SkiaUnrefQueue> unref_queue,
    const std::shared_ptr<const fml::SyncSwitch>& gpu_disable_sync_switch,
    size_t trace_id) {
  fml::RefPtr<CanvasImage> image = nullptr;
  int duration = 0;
  sk_sp<SkImage> skImage =
      GetNextFrameImage(resourceContext, gpu_disable_sync_switch);
  if (skImage) {
    image = CanvasImage::Create();
    image->set_image(DlImageGPU::Make({skImage, std::move(unref_queue)}));
    ImageGenerator::FrameInfo frameInfo =
        generator_->GetFrameInfo(nextFrameIndex_);
    duration = frameInfo.duration;
  }
  nextFrameIndex_ = (nextFrameIndex_ + 1) % frameCount_;

  ui_task_runner->PostTask(fml::MakeCopyable([callback = std::move(callback),
                                              image = std::move(image),
                                              duration, trace_id]() mutable {
    InvokeNextFrameCallback(std::move(image), duration, std::move(callback),
                            trace_id);
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

  if (state_->frameCount_ == 0) {
    FML_LOG(ERROR) << "Could not provide any frame.";
    task_runners.GetUITaskRunner()->PostTask(fml::MakeCopyable(
        [trace_id,
         callback = std::make_unique<DartPersistentValue>(
             tonic::DartState::Current(), callback_handle)]() mutable {
          InvokeNextFrameCallback(nullptr, 0, std::move(callback), trace_id);
        }));
    return Dart_Null();
  }

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
            io_manager->GetIsGpuDisabledSyncSwitch(), trace_id);
      }));

  return Dart_Null();
  // The static leak checker gets confused by the control flow, unique pointers
  // and closures in this function.
  // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks)
}

int MultiFrameCodec::frameCount() const {
  return state_->frameCount_;
}

int MultiFrameCodec::repetitionCount() const {
  return state_->repetitionCount_;
}

}  // namespace flutter
