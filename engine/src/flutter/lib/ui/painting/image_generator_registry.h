// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_H_

#include <functional>
#include <memory>
#include <set>
#include <vector>

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
  /// Invoke the factory on the UI task runner.
  kUITaskRunner,

  /// Invoke the factory on the engine's concurrent task runner.
  /// The factory must support concurrent invocations.
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
  /// @param[in]  execution  Where the factory is invoked.
  /// @see        `CreateCompatibleGenerator`
  void AddFactory(ImageGeneratorFactory factory,
                  int32_t priority,
                  ImageGeneratorFactoryExecution execution =
                      ImageGeneratorFactoryExecution::kUITaskRunner);

  /// @brief      Asynchronously walks the list of image generator factories in
  ///             priority order. Factories registered for concurrent execution
  ///             are invoked on `concurrent_task_runner`; all other factories
  ///             are invoked on `ui_task_runner`. This method must be
  ///             called from `ui_task_runner`, where the registry is
  ///             accessed. The callback is always posted to that runner.
  /// @param[in]  buffer                  The raw encoded image data.
  /// @param[in]  concurrent_task_runner  Runner for factories that may perform
  ///                                     expensive compatibility checks.
  /// @param[in]  ui_task_runner          Runner on which `callback` is invoked.
  /// @param[in]  callback                Receives a compatible generator, or
  ///                                     `nullptr` if none was found.
  void CreateCompatibleGenerator(
      const sk_sp<SkData>& buffer,
      const std::shared_ptr<fml::ConcurrentTaskRunner>& concurrent_task_runner,
      const fml::RefPtr<fml::TaskRunner>& ui_task_runner,
      std::function<void(std::shared_ptr<ImageGenerator>)> callback);

  fml::TaskRunnerAffineWeakPtr<ImageGeneratorRegistry> GetWeakPtr() const;

 private:
  struct PrioritizedFactory {
    // Snapshots share the registered callback, including its captured state.
    std::shared_ptr<ImageGeneratorFactory> callback;

    int32_t priority = 0;
    // Used as a fallback priority comparison when equal.
    size_t ascending_nonce = 0;
    ImageGeneratorFactoryExecution execution =
        ImageGeneratorFactoryExecution::kUITaskRunner;
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

  // Owns the factory snapshot so queued work can outlive the registry.
  static void ResolveGenerator(
      std::shared_ptr<const std::vector<PrioritizedFactory>> factories,
      size_t index,
      sk_sp<SkData> buffer,
      std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
      fml::RefPtr<fml::TaskRunner> ui_task_runner,
      std::function<void(std::shared_ptr<ImageGenerator>)> callback);

  using FactorySet = std::set<PrioritizedFactory, Compare>;
  FactorySet image_generator_factories_;
  size_t nonce_ = 0;
  fml::TaskRunnerAffineWeakPtrFactory<ImageGeneratorRegistry> weak_factory_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_H_
