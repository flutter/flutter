// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <utility>
#include <vector>

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
namespace {

struct AsyncImageGeneratorFactory {
  ImageGeneratorFactory callback;
  ImageGeneratorFactoryExecution execution;
};

void LogNoImageDecoders() {
  FML_LOG(WARNING)
      << "There are currently no image decoders installed. If you're writing "
         "your own platform embedding, you can register new image decoders "
         "via `ImageGeneratorRegistry::AddFactory` on the "
         "`ImageGeneratorRegistry` provided by the engine. Otherwise, please "
         "file a bug on https://github.com/flutter/flutter/issues.";
}

// Resolves an ordered snapshot of factories while returning to the callback
// task runner after invoking a factory concurrently.
class AsyncImageGeneratorResolver
    : public std::enable_shared_from_this<AsyncImageGeneratorResolver> {
 public:
  static void Resolve(
      std::vector<AsyncImageGeneratorFactory> factories,
      sk_sp<SkData> buffer,
      std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
      fml::RefPtr<fml::TaskRunner> callback_task_runner,
      std::function<void(std::shared_ptr<ImageGenerator>)> callback) {
    auto resolver = std::shared_ptr<AsyncImageGeneratorResolver>(
        new AsyncImageGeneratorResolver(std::move(factories), std::move(buffer),
                                        std::move(concurrent_task_runner),
                                        std::move(callback_task_runner),
                                        std::move(callback)));
    resolver->ResolveFrom(0u);
  }

 private:
  AsyncImageGeneratorResolver(
      std::vector<AsyncImageGeneratorFactory> factories,
      sk_sp<SkData> buffer,
      std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
      fml::RefPtr<fml::TaskRunner> callback_task_runner,
      std::function<void(std::shared_ptr<ImageGenerator>)> callback)
      : factories_(std::move(factories)),
        buffer_(std::move(buffer)),
        concurrent_task_runner_(std::move(concurrent_task_runner)),
        callback_task_runner_(std::move(callback_task_runner)),
        callback_(std::move(callback)) {}

  void ResolveFrom(size_t index) {
    while (index < factories_.size()) {
      const AsyncImageGeneratorFactory& factory = factories_[index];
      if (factory.execution ==
          ImageGeneratorFactoryExecution::kConcurrentTaskRunner) {
        auto self = shared_from_this();
        concurrent_task_runner_->PostTask([self, index]() {
          std::shared_ptr<ImageGenerator> result =
              self->factories_[index].callback(self->buffer_);
          self->callback_task_runner_->PostTask(
              [self, index, result = std::move(result)]() mutable {
                if (result) {
                  self->Complete(std::move(result));
                } else {
                  self->ResolveFrom(index + 1u);
                }
              });
        });
        return;
      }

      std::shared_ptr<ImageGenerator> result = factory.callback(buffer_);
      if (result) {
        Complete(std::move(result));
        return;
      }
      index++;
    }
    Complete(nullptr);
  }

  void Complete(std::shared_ptr<ImageGenerator> generator) {
    auto callback = std::move(callback_);
    callback_task_runner_->PostTask(
        [callback = std::move(callback),
         generator = std::move(generator)]() mutable {
          callback(std::move(generator));
        });
  }

  const std::vector<AsyncImageGeneratorFactory> factories_;
  const sk_sp<SkData> buffer_;
  const std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner_;
  const fml::RefPtr<fml::TaskRunner> callback_task_runner_;
  std::function<void(std::shared_ptr<ImageGenerator>)> callback_;
};

}  // namespace

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
  // SkImageGeneratorCG copies the complete ImageIO property dictionary while
  // constructing a generator. Images with rich metadata can make that
  // operation too expensive for the UI thread.
  AddFactory(
      [](sk_sp<SkData> buffer) {
        auto generator =
            SkImageGeneratorCG::MakeFromEncodedCG(std::move(buffer));
        return BuiltinSkiaImageGenerator::MakeFromGenerator(
            std::move(generator));
      },
      0, ImageGeneratorFactoryExecution::kConcurrentTaskRunner);
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

void ImageGeneratorRegistry::AddFactory(
    ImageGeneratorFactory factory,
    int32_t priority,
    ImageGeneratorFactoryExecution execution) {
  image_generator_factories_.insert(
      {std::move(factory), priority, ++nonce_, execution});
}

std::shared_ptr<ImageGenerator>
ImageGeneratorRegistry::CreateCompatibleGenerator(const sk_sp<SkData>& buffer) {
  if (image_generator_factories_.empty()) {
    LogNoImageDecoders();
  }

  for (auto& factory : image_generator_factories_) {
    std::shared_ptr<ImageGenerator> result = factory.callback(buffer);
    if (result) {
      return result;
    }
  }
  return nullptr;
}

void ImageGeneratorRegistry::CreateCompatibleGeneratorAsync(
    const sk_sp<SkData>& buffer,
    const std::shared_ptr<fml::ConcurrentTaskRunner>& concurrent_task_runner,
    const fml::RefPtr<fml::TaskRunner>& callback_task_runner,
    std::function<void(std::shared_ptr<ImageGenerator>)> callback) {
  FML_DCHECK(callback_task_runner->RunsTasksOnCurrentThread());

  if (image_generator_factories_.empty()) {
    LogNoImageDecoders();
  }

  std::vector<AsyncImageGeneratorFactory> factories;
  factories.reserve(image_generator_factories_.size());
  for (const auto& factory : image_generator_factories_) {
    factories.push_back({factory.callback, factory.execution});
  }

  AsyncImageGeneratorResolver::Resolve(
      std::move(factories), buffer, concurrent_task_runner,
      callback_task_runner, std::move(callback));
}

fml::TaskRunnerAffineWeakPtr<ImageGeneratorRegistry>
ImageGeneratorRegistry::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

}  // namespace flutter
