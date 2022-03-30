// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoder.h"

#include "flutter/lib/ui/painting/image_decoder_skia.h"

#if IMPELLER_SUPPORTS_PLATFORM
#include "flutter/lib/ui/painting/image_decoder_impeller.h"
#endif  // IMPELLER_SUPPORTS_PLATFORM

namespace flutter {

std::unique_ptr<ImageDecoder> ImageDecoder::Make(
    const Settings& settings,
    TaskRunners runners,
    std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
    fml::WeakPtr<IOManager> io_manager) {
#if IMPELLER_SUPPORTS_PLATFORM
  if (settings.enable_impeller) {
    return std::make_unique<ImageDecoderImpeller>(
        std::move(runners),                 //
        std::move(concurrent_task_runner),  //
        std::move(io_manager)               //
    );
  }
#endif  // IMPELLER_SUPPORTS_PLATFORM
  return std::make_unique<ImageDecoderSkia>(
      std::move(runners),                 //
      std::move(concurrent_task_runner),  //
      std::move(io_manager)               //
  );
}

ImageDecoder::ImageDecoder(
    TaskRunners runners,
    std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
    fml::WeakPtr<IOManager> io_manager)
    : runners_(std::move(runners)),
      concurrent_task_runner_(std::move(concurrent_task_runner)),
      io_manager_(std::move(io_manager)),
      weak_factory_(this) {
  FML_DCHECK(runners_.IsValid());
  FML_DCHECK(runners_.GetUITaskRunner()->RunsTasksOnCurrentThread())
      << "The image decoder must be created & collected on the UI thread.";
}

ImageDecoder::~ImageDecoder() = default;

fml::WeakPtr<ImageDecoder> ImageDecoder::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

}  // namespace flutter
