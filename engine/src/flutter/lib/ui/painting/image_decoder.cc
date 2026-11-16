// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoder.h"

#include <utility>

#include "flutter/lib/ui/painting/image_decoder_skia.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkSamplingOptions.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "flutter/lib/ui/painting/image_decoder_impeller.h"
#endif  // IMPELLER_SUPPORTS_RENDERING

namespace flutter {

std::unique_ptr<ImageDecoder> ImageDecoder::Make(
    const Settings& settings,
    const TaskRunners& runners,
    std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
    const fml::WeakPtr<IOManager>& io_manager,
    const std::shared_ptr<fml::SyncSwitch>& gpu_disabled_switch) {
#if IMPELLER_SUPPORTS_RENDERING
  if (settings.enable_impeller) {
    return std::make_unique<ImageDecoderImpeller>(
        runners,                            //
        std::move(concurrent_task_runner),  //
        io_manager,                         //
        settings.enable_wide_gamut,         //
        gpu_disabled_switch);
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
#if !SLIMPELLER
  return std::make_unique<ImageDecoderSkia>(
      runners,                            //
      std::move(concurrent_task_runner),  //
      io_manager                          //
  );
#else   //  !SLIMPELLER
  FML_LOG(FATAL) << "Could not setup an image decoder.";
  return nullptr;
#endif  //  !SLIMPELLER
}

ImageDecoder::ImageDecoder(
    const TaskRunners& runners,
    std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
    fml::WeakPtr<IOManager> io_manager)
    : runners_(runners),
      concurrent_task_runner_(std::move(concurrent_task_runner)),
      io_manager_(std::move(io_manager)),
      weak_factory_(this) {
  FML_DCHECK(runners_.IsValid());
  FML_DCHECK(runners_.GetUITaskRunner()->RunsTasksOnCurrentThread())
      << "The image decoder must be created & collected on the UI thread.";
}

ImageDecoder::~ImageDecoder() = default;

fml::TaskRunnerAffineWeakPtr<ImageDecoder> ImageDecoder::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

// static
SkISize ImageDecoder::GetResizeStepSize(const SkISize& size,
                                        const SkISize& target_size) {
  auto halve = [](int32_t side, int32_t target_side) {
    return side / 2 >= target_side ? side / 2 : side;
  };
  const SkISize step_size =
      SkISize::Make(halve(size.width(), target_size.width()),
                    halve(size.height(), target_size.height()));
  return step_size == size ? target_size : step_size;
}

// static
bool ImageDecoder::ResizePixels(const SkPixmap& source,
                                const SkPixmap& destination) {
  const SkSamplingOptions linear(SkFilterMode::kLinear, SkMipmapMode::kNone);
  const SkISize target_size = destination.dimensions();
  SkPixmap step_source = source;
  SkBitmap step;
  SkISize step_size = GetResizeStepSize(source.dimensions(), target_size);
  while (step_size != target_size) {
    SkBitmap next_step;
    if (!next_step.tryAllocPixels(source.info().makeDimensions(step_size)) ||
        !step_source.scalePixels(next_step.pixmap(), linear)) {
      return false;
    }
    // The previous step is not needed anymore.
    step = std::move(next_step);
    step_source = step.pixmap();
    step_size = GetResizeStepSize(step_size, target_size);
  }
  return step_source.scalePixels(destination, linear);
}

}  // namespace flutter
