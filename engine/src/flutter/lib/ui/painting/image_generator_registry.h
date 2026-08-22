// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_H_

#include <functional>
#include <memory>
#include <set>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/painting/image_generator.h"

namespace flutter {

/// @brief  `ImageGeneratorFactory` is the top level primitive for specifying an
///         image decoder in Flutter. When called, it should return an
///         `ImageGenerator` that typically compatible with the given input
///         data.
using ImageGeneratorFactory =
    std::function<std::shared_ptr<ImageGenerator>(sk_sp<SkData> buffer)>;

/// @brief  Controls where an image generator factory is invoked when resolving
///         a generator asynchronously.
enum class ImageGeneratorFactoryExecution {
  /// Invoke the factory on the callback task runner used to resolve the
  /// registry.
  kCallbackTaskRunner,

  /// Invoke the factory on the engine's concurrent task runner.
  kConcurrentTaskRunner,
};

/// @brief Keeps a priority-ordered registry of image generator builders to be
///        used when decoding images. This object must be created, accessed, and
///        collected on the UI thread (typically the engine or its runtime
///        controller).
class ImageGeneratorRegistry {
 public:
  ImageGeneratorRegistry();

  ~ImageGeneratorRegistry();

  /// @brief      Install a new factory for image generators
  /// @param[in]  factory   Callback that produces `ImageGenerator`s for
  ///                       compatible input data.
  /// @param[in]  priority  The priority used to determine the order in which
  ///                       factories are tried. Higher values mean higher
  ///                       priority. The built-in Skia decoders are installed
  ///                       at priority 0, and so a priority > 0 takes precedent
  ///                       over the builtin decoders. When multiple decoders
  ///                       are added with the same priority, those which are
  ///                       added earlier take precedent.
  /// @param[in]  execution  Where the factory is invoked when using
  ///                        `CreateCompatibleGeneratorAsync`. This setting is
  ///                        ignored by `CreateCompatibleGenerator`.
  /// @see        `CreateCompatibleGenerator`, `CreateCompatibleGeneratorAsync`
  void AddFactory(ImageGeneratorFactory factory,
                  int32_t priority,
                  ImageGeneratorFactoryExecution execution =
                      ImageGeneratorFactoryExecution::kCallbackTaskRunner);

  /// @brief      Walks the list of image generator builders in descending
  ///             priority order until a compatible `ImageGenerator` is able to
  ///             be built. This method invokes every factory synchronously on
  ///             the calling thread, regardless of its execution setting. Use
  ///             `CreateCompatibleGeneratorAsync` when calling from the UI
  ///             thread. The returned `ImageGenerator` can then be used to
  ///             fully decode the image on e.g. the IO thread.
  /// @param[in]  buffer  The raw encoded image data.
  /// @return     An `ImageGenerator` that is compatible with the input buffer.
  ///             If no compatible `ImageGenerator` type was found, then
  ///             `std::shared_ptr<ImageGenerator>(nullptr)` is returned.
  /// @see        `ImageGenerator`
  std::shared_ptr<ImageGenerator> CreateCompatibleGenerator(
      const sk_sp<SkData>& buffer);

  /// @brief      Asynchronously walks the list of image generator factories in
  ///             priority order. Factories registered for concurrent execution
  ///             are invoked on `concurrent_task_runner`; all other factories
  ///             are invoked on `callback_task_runner`. This method must be
  ///             called from `callback_task_runner`, where the registry is
  ///             accessed. The callback is always posted to that runner.
  /// @param[in]  buffer                  The raw encoded image data.
  /// @param[in]  concurrent_task_runner  Runner for factories that may perform
  ///                                     expensive compatibility checks.
  /// @param[in]  callback_task_runner    Runner on which `callback` is invoked.
  /// @param[in]  callback                Receives a compatible generator, or
  ///                                     `nullptr` if none was found.
  void CreateCompatibleGeneratorAsync(
      const sk_sp<SkData>& buffer,
      const std::shared_ptr<fml::ConcurrentTaskRunner>& concurrent_task_runner,
      const fml::RefPtr<fml::TaskRunner>& callback_task_runner,
      std::function<void(std::shared_ptr<ImageGenerator>)> callback);

  fml::TaskRunnerAffineWeakPtr<ImageGeneratorRegistry> GetWeakPtr() const;

 private:
  struct PrioritizedFactory {
    ImageGeneratorFactory callback;

    int32_t priority = 0;
    // Used as a fallback priority comparison when equal.
    size_t ascending_nonce = 0;
    ImageGeneratorFactoryExecution execution =
        ImageGeneratorFactoryExecution::kCallbackTaskRunner;
  };

  struct Compare {
    constexpr bool operator()(const PrioritizedFactory& lhs,
                              const PrioritizedFactory& rhs) const {
      // When priorities are equal, factories registered earlier take
      // precedent.
      if (lhs.priority == rhs.priority) {
        return lhs.ascending_nonce < rhs.ascending_nonce;
      }
      // Order by descending priority.
      return lhs.priority > rhs.priority;
    }
  };

  using FactorySet = std::set<PrioritizedFactory, Compare>;
  FactorySet image_generator_factories_;
  size_t nonce_;
  fml::TaskRunnerAffineWeakPtrFactory<ImageGeneratorRegistry> weak_factory_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_H_
