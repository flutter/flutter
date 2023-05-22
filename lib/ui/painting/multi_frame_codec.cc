// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/multi_frame_codec.h"

#include <utility>

#include "flutter/fml/make_copyable.h"
#include "flutter/lib/ui/painting/display_list_image_gpu.h"
#include "flutter/lib/ui/painting/image.h"
#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/lib/ui/painting/image_decoder_impeller.h"
#endif  // IMPELLER_SUPPORTS_RENDERING
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/skia/include/codec/SkCodecAnimation.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPixelRef.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
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
      is_impeller_enabled_(UIDartState::Current()->IsImpellerEnabled()),
      nextFrameIndex_(0) {}

static void InvokeNextFrameCallback(
    const fml::RefPtr<CanvasImage>& image,
    int duration,
    const std::string& decode_error,
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
                    {tonic::ToDart(image), tonic::ToDart(duration),
                     tonic::ToDart(decode_error)});
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

std::pair<sk_sp<DlImage>, std::string>
MultiFrameCodec::State::GetNextFrameImage(
    fml::WeakPtr<GrDirectContext> resourceContext,
    const std::shared_ptr<const fml::SyncSwitch>& gpu_disable_sync_switch,
    const std::shared_ptr<impeller::Context>& impeller_context,
    fml::RefPtr<flutter::SkiaUnrefQueue> unref_queue) {
  SkBitmap bitmap = SkBitmap();
  SkImageInfo info = generator_->GetInfo().makeColorType(kN32_SkColorType);
  if (info.alphaType() == kUnpremul_SkAlphaType) {
    SkImageInfo updated = info.makeAlphaType(kPremul_SkAlphaType);
    info = updated;
  }
  if (!bitmap.tryAllocPixels(info)) {
    std::ostringstream ostr;
    ostr << "Failed to allocate memory for bitmap of size "
         << info.computeMinByteSize() << "B";
    std::string decode_error = ostr.str();
    FML_LOG(ERROR) << decode_error;
    return std::make_pair(nullptr, decode_error);
  }

  ImageGenerator::FrameInfo frameInfo =
      generator_->GetFrameInfo(nextFrameIndex_);

  const int requiredFrameIndex =
      frameInfo.required_frame.value_or(SkCodec::kNoFrame);
  std::optional<unsigned int> prior_frame_index = std::nullopt;

  if (requiredFrameIndex != SkCodec::kNoFrame) {
    // We currently assume that frames can only ever depend on the immediately
    // previous frame, if any. This means that
    // `DisposalMethod::kRestorePrevious` is not supported.
    if (lastRequiredFrame_ == nullptr) {
      FML_DLOG(INFO)
          << "Frame " << nextFrameIndex_ << " depends on frame "
          << requiredFrameIndex
          << " and no required frames are cached. Using blank slate instead.";
    } else {
      // Copy the previous frame's output buffer into the current frame as the
      // starting point.
      if (lastRequiredFrame_->getPixels() &&
          CopyToBitmap(&bitmap, lastRequiredFrame_->colorType(),
                       *lastRequiredFrame_)) {
        prior_frame_index = requiredFrameIndex;
      }
    }
  }

  // Write the new frame to the output buffer. The bitmap pixels as supplied
  // are already set in accordance with the previous frame's disposal policy.
  if (!generator_->GetPixels(info, bitmap.getPixels(), bitmap.rowBytes(),
                             nextFrameIndex_, requiredFrameIndex)) {
    std::ostringstream ostr;
    ostr << "Could not getPixels for frame " << nextFrameIndex_;
    std::string decode_error = ostr.str();
    FML_LOG(ERROR) << decode_error;
    return std::make_pair(nullptr, decode_error);
  }

  // Hold onto this if we need it to decode future frames.
  if (frameInfo.disposal_method == SkCodecAnimation::DisposalMethod::kKeep ||
      lastRequiredFrame_) {
    lastRequiredFrame_ = std::make_unique<SkBitmap>(bitmap);
    lastRequiredFrameIndex_ = nextFrameIndex_;
  }

#if IMPELLER_SUPPORTS_RENDERING
  if (is_impeller_enabled_) {
    // This is safe regardless of whether the GPU is available or not because
    // without mipmap creation there is no command buffer encoding done.
    return ImageDecoderImpeller::UploadTextureToShared(
        impeller_context, std::make_shared<SkBitmap>(bitmap),
        /*create_mips=*/false);
  }
#endif  // IMPELLER_SUPPORTS_RENDERING

  sk_sp<SkImage> skImage;
  gpu_disable_sync_switch->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&skImage, &bitmap] {
            // Defer decoding until time of draw later on the raster thread.
            // Can happen when GL operations are currently forbidden such as
            // in the background on iOS.
            skImage = SkImages::RasterFromBitmap(bitmap);
          })
          .SetIfFalse([&skImage, &resourceContext, &bitmap] {
            if (resourceContext) {
              SkPixmap pixmap(bitmap.info(), bitmap.pixelRef()->pixels(),
                              bitmap.pixelRef()->rowBytes());
              skImage = SkImages::CrossContextTextureFromPixmap(
                  resourceContext.get(), pixmap, true);
            } else {
              // Defer decoding until time of draw later on the raster thread.
              // Can happen when GL operations are currently forbidden such as
              // in the background on iOS.
              skImage = SkImages::RasterFromBitmap(bitmap);
            }
          }));

  return std::make_pair(DlImageGPU::Make({skImage, std::move(unref_queue)}),
                        std::string());
}

void MultiFrameCodec::State::GetNextFrameAndInvokeCallback(
    std::unique_ptr<DartPersistentValue> callback,
    const fml::RefPtr<fml::TaskRunner>& ui_task_runner,
    fml::WeakPtr<GrDirectContext> resourceContext,
    fml::RefPtr<flutter::SkiaUnrefQueue> unref_queue,
    const std::shared_ptr<const fml::SyncSwitch>& gpu_disable_sync_switch,
    size_t trace_id,
    const std::shared_ptr<impeller::Context>& impeller_context) {
  fml::RefPtr<CanvasImage> image = nullptr;
  int duration = 0;
  sk_sp<DlImage> dlImage;
  std::string decode_error;
  std::tie(dlImage, decode_error) =
      GetNextFrameImage(std::move(resourceContext), gpu_disable_sync_switch,
                        impeller_context, std::move(unref_queue));
  if (dlImage) {
    image = CanvasImage::Create();
    image->set_image(dlImage);
    ImageGenerator::FrameInfo frameInfo =
        generator_->GetFrameInfo(nextFrameIndex_);
    duration = frameInfo.duration;
  }
  nextFrameIndex_ = (nextFrameIndex_ + 1) % frameCount_;

  // The static leak checker gets confused by the use of fml::MakeCopyable.
  // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks)
  ui_task_runner->PostTask(fml::MakeCopyable(
      [callback = std::move(callback), image = std::move(image),
       decode_error = std::move(decode_error), duration, trace_id]() mutable {
        InvokeNextFrameCallback(image, duration, decode_error,
                                std::move(callback), trace_id);
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
    std::string decode_error("Could not provide any frame.");
    FML_LOG(ERROR) << decode_error;
    task_runners.GetUITaskRunner()->PostTask(fml::MakeCopyable(
        [trace_id, decode_error = std::move(decode_error),
         callback = std::make_unique<DartPersistentValue>(
             tonic::DartState::Current(), callback_handle)]() mutable {
          InvokeNextFrameCallback(nullptr, 0, decode_error, std::move(callback),
                                  trace_id);
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
            std::move(callback), ui_task_runner,
            io_manager->GetResourceContext(), io_manager->GetSkiaUnrefQueue(),
            io_manager->GetIsGpuDisabledSyncSwitch(), trace_id,
            io_manager->GetImpellerContext());
      }));

  return Dart_Null();
  // The static leak checker gets confused by the control flow, unique
  // pointers and closures in this function.
  // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks)
}

int MultiFrameCodec::frameCount() const {
  return state_->frameCount_;
}

int MultiFrameCodec::repetitionCount() const {
  return state_->repetitionCount_;
}

}  // namespace flutter
