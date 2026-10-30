// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_TEST_UTILS_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_TEST_UTILS_H_

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/lib/ui/painting/image_generator_registry.h"

namespace flutter::testing {

// Creates a registry on a dedicated UI thread, optionally adds factories,
// and blocks the calling thread until CreateCompatibleGenerator reports a
// result.
inline std::shared_ptr<ImageGenerator> CreateTestImageGenerator(
    const sk_sp<SkData>& buffer,
    const std::function<void(ImageGeneratorRegistry&)>& add_factories =
        nullptr) {
  fml::Thread ui_thread("image_generator_test");
  auto concurrent_loop = fml::ConcurrentMessageLoop::Create(1u);
  fml::AutoResetWaitableEvent latch;
  std::shared_ptr<ImageGenerator> result;
  ui_thread.GetTaskRunner()->PostTask([&]() {
    ImageGeneratorRegistry registry;
    if (add_factories) {
      add_factories(registry);
    }
    registry.CreateCompatibleGenerator(
        buffer, concurrent_loop->GetTaskRunner(), ui_thread.GetTaskRunner(),
        [&](std::shared_ptr<ImageGenerator> generator) {
          result = std::move(generator);
          latch.Signal();
        });
  });
  latch.Wait();
  return result;
}

}  // namespace flutter::testing

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_GENERATOR_REGISTRY_TEST_UTILS_H_
