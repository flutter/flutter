// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_H_

#include <memory>
#include <optional>

#include "flutter/common/task_runners.h"
#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/io_manager.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

// An object that coordinates image decompression and texture upload across
// multiple threads/components in the shell. This object must be created,
// accessed and collected on the UI thread (typically the engine or its runtime
// controller). None of the expensive operations performed by this component
// occur in a frame pipeline.
class ImageDecoder {
 public:
  ImageDecoder(
      TaskRunners runners,
      std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
      fml::WeakPtr<IOManager> io_manager);

  ~ImageDecoder();

  struct ImageInfo {
    SkImageInfo sk_info = {};
    size_t row_bytes = 0;
  };

  struct ImageDescriptor {
    sk_sp<SkData> data;
    std::optional<ImageInfo> decompressed_image_info;
    std::optional<uint32_t> target_width;
    std::optional<uint32_t> target_height;
  };

  using ImageResult = std::function<void(SkiaGPUObject<SkImage>)>;

  // Takes an image descriptor and returns a handle to a texture resident on the
  // GPU. All image decompression and resizes are done on a worker thread
  // concurrently. Texture upload is done on the IO thread and the result
  // returned back on the UI thread. On error, the texture is null but the
  // callback is guaranteed to return on the UI thread.
  void Decode(ImageDescriptor descriptor, const ImageResult& result);

  fml::WeakPtr<ImageDecoder> GetWeakPtr() const;

 private:
  TaskRunners runners_;
  std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner_;
  fml::WeakPtr<IOManager> io_manager_;
  fml::WeakPtrFactory<ImageDecoder> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageDecoder);
};

sk_sp<SkImage> ImageFromCompressedData(sk_sp<SkData> data,
                                       std::optional<uint32_t> target_width,
                                       std::optional<uint32_t> target_height,
                                       const fml::tracing::TraceFlow& flow);

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_H_
