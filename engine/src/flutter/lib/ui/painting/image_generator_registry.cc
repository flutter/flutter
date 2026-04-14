// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <utility>

#include "flutter/lib/ui/painting/image_generator_registry.h"
#include "third_party/skia/include/codec/SkBmpDecoder.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/include/codec/SkGifDecoder.h"
#include "third_party/skia/include/codec/SkIcoDecoder.h"
#include "third_party/skia/include/codec/SkJpegDecoder.h"
#include "third_party/skia/include/codec/SkPngDecoder.h"
#include "third_party/skia/include/codec/SkWbmpDecoder.h"
#include "third_party/skia/include/codec/SkWebpDecoder.h"
#include "third_party/skia/include/core/SkImageGenerator.h"
#ifdef FML_OS_MACOSX
#include "third_party/skia/include/ports/SkImageGeneratorCG.h"
#elif FML_OS_WIN
#include "third_party/skia/include/ports/SkImageGeneratorWIC.h"
#endif

#include "image_generator_apng.h"

#include <mutex>

namespace {
void RegisterSkiaCodecs() {
  // These are in the order they will be attempted to be decoded from.
  // If we have data to back it up, we can order these by "frequency used in
  // the wild" for a very small performance bump, but for now we mirror the
  // order Skia had them in.
  SkCodecs::Register(SkPngDecoder::Decoder());
  SkCodecs::Register(SkJpegDecoder::Decoder());
  SkCodecs::Register(SkWebpDecoder::Decoder());
  SkCodecs::Register(SkGifDecoder::Decoder());
  SkCodecs::Register(SkBmpDecoder::Decoder());
  SkCodecs::Register(SkWbmpDecoder::Decoder());
  SkCodecs::Register(SkIcoDecoder::Decoder());
}

}  // namespace

namespace flutter {

ImageGeneratorRegistry::ImageGeneratorRegistry() : weak_factory_(this) {
  AddFactory(
      [](sk_sp<SkData> buffer) {
        return APNGImageGenerator::MakeFromData(std::move(buffer));
      },
      0);

  static std::once_flag register_skia_codecs;
  std::call_once(register_skia_codecs, RegisterSkiaCodecs);
  AddFactory(
      [](sk_sp<SkData> buffer) {
        return BuiltinSkiaCodecImageGenerator::MakeFromData(std::move(buffer));
      },
      0);

  // todo(bdero): https://github.com/flutter/flutter/issues/82603
#ifdef FML_OS_MACOSX
  AddFactory(
      [](sk_sp<SkData> buffer) {
        auto generator =
            SkImageGeneratorCG::MakeFromEncodedCG(std::move(buffer));
        return BuiltinSkiaImageGenerator::MakeFromGenerator(
            std::move(generator));
      },
      0);
#elif FML_OS_WIN
  AddFactory(
      [](sk_sp<SkData> buffer) {
        auto generator = SkImageGeneratorWIC::MakeFromEncodedWIC(buffer);
        return BuiltinSkiaImageGenerator::MakeFromGenerator(
            std::move(generator));
      },
      0);
#endif
}

ImageGeneratorRegistry::~ImageGeneratorRegistry() = default;

void ImageGeneratorRegistry::AddFactory(ImageGeneratorFactory factory,
                                        int32_t priority) {
  image_generator_factories_.insert({std::move(factory), priority, ++nonce_});
}

std::shared_ptr<ImageGenerator>
ImageGeneratorRegistry::CreateCompatibleGenerator(const sk_sp<SkData>& buffer) {
  if (!image_generator_factories_.size()) {
    FML_LOG(WARNING)
        << "There are currently no image decoders installed. If you're writing "
           "your own platform embedding, you can register new image decoders "
           "via `ImageGeneratorRegistry::AddFactory` on the "
           "`ImageGeneratorRegistry` provided by the engine. Otherwise, please "
           "file a bug on https://github.com/flutter/flutter/issues.";
  }

  for (auto& factory : image_generator_factories_) {
    std::shared_ptr<ImageGenerator> result = factory.callback(buffer);
    if (result) {
      return result;
    }
  }
  return nullptr;
}

fml::TaskRunnerAffineWeakPtr<ImageGeneratorRegistry>
ImageGeneratorRegistry::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

}  // namespace flutter
