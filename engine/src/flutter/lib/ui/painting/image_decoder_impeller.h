// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_IMPELLER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_IMPELLER_H_

#include <future>

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/painting/image_decoder.h"

namespace impeller {
class Context;
}  // namespace impeller

namespace flutter {

class ImageDecoderImpeller final : public ImageDecoder {
 public:
  ImageDecoderImpeller(
      TaskRunners runners,
      std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
      fml::WeakPtr<IOManager> io_manager);

  ~ImageDecoderImpeller() override;

  // |ImageDecoder|
  void Decode(fml::RefPtr<ImageDescriptor> descriptor,
              uint32_t target_width,
              uint32_t target_height,
              const ImageResult& result) override;

  static std::shared_ptr<SkBitmap> DecompressTexture(
      ImageDescriptor* descriptor,
      SkISize target_size);

 private:
  using FutureContext = std::shared_future<std::shared_ptr<impeller::Context>>;
  FutureContext context_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageDecoderImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_IMPELLER_H_
