// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_IMAGE_GENERATOR_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_IMAGE_GENERATOR_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/painting/image_generator.h"
#include "flutter/lib/ui/painting/image_generator_registry.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

class EmbedderImageGenerator : public ImageGenerator {
 public:
  explicit EmbedderImageGenerator(FlutterImageGenerator generator,
                                  const SkImageInfo& image_info);

  ~EmbedderImageGenerator() override;

  // |ImageGenerator|
  const SkImageInfo& GetInfo() override;

  // |ImageGenerator|
  unsigned int GetFrameCount() const override;

  // |ImageGenerator|
  unsigned int GetPlayCount() const override;

  // |ImageGenerator|
  const ImageGenerator::FrameInfo GetFrameInfo(
      unsigned int frame_index) override;

  // |ImageGenerator|
  SkISize GetScaledDimensions(float desired_scale) override;

  // |ImageGenerator|
  bool GetPixels(
      const SkImageInfo& info,
      void* pixels,
      size_t row_bytes,
      unsigned int frame_index = 0,
      std::optional<unsigned int> prior_frame = std::nullopt) override;

  const FlutterImageGenerator& GetGenerator() const { return generator_; }

 private:
  FlutterImageGenerator generator_;
  SkImageInfo image_info_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(EmbedderImageGenerator);
};

std::shared_ptr<ImageGenerator> MakeEmbedderImageGenerator(
    const FlutterImageGenerator& generator);

ImageGeneratorFactory CreateEmbedderImageGeneratorFactory(
    const FlutterImageGeneratorRegistrationInfo& registration_info);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_IMAGE_GENERATOR_H_
