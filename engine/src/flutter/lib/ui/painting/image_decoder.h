// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/lib/ui/io_manager.h"
#include "flutter/lib/ui/painting/image_descriptor.h"
#include "third_party/skia/include/core/SkPixmap.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

// An object that coordinates image decompression and texture upload across
// multiple threads/components in the shell. This object must be created,
// accessed and collected on the UI thread (typically the engine or its runtime
// controller). None of the expensive operations performed by this component
// occur in a frame pipeline.
class ImageDecoder {
 public:
  static std::unique_ptr<ImageDecoder> Make(
      const Settings& settings,
      const TaskRunners& runners,
      std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
      const fml::WeakPtr<IOManager>& io_manager,
      const std::shared_ptr<fml::SyncSwitch>& gpu_disabled_switch);

  virtual ~ImageDecoder();

  using ImageResult = std::function<void(sk_sp<DlImage>, std::string)>;

  enum TargetPixelFormat {
    /// An unknown pixel format, reserved for error cases.
    kUnknown,
    /// Explicitly declare the target pixel is left for the engine to decide.
    kDontCare,
    kR32G32B32A32Float,
    kR32Float,
  };

  struct Options {
    uint32_t target_width = 0;
    uint32_t target_height = 0;
    TargetPixelFormat target_format = TargetPixelFormat::kDontCare;
  };

  // Takes an image descriptor and returns a handle to a texture resident on the
  // GPU. All image decompression and resizes are done on a worker thread
  // concurrently. Texture upload is done on the IO thread and the result
  // returned back on the UI thread. On error, the texture is null but the
  // callback is guaranteed to return on the UI thread.
  virtual void Decode(fml::RefPtr<ImageDescriptor> descriptor,
                      const Options& options,
                      const ImageResult& result) = 0;

  fml::TaskRunnerAffineWeakPtr<ImageDecoder> GetWeakPtr() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns the size of the next step when resizing an image from
  ///             |size| to |target_size|.
  ///
  ///             A linear filter only reads the 2x2 pixels nearest to each
  ///             sample point, so scaling down by more than 2x in one step
  ///             skips source pixels and makes thin details alias. Images are
  ///             therefore resized in steps: every side that is at least twice
  ///             as long as the target is halved, which averages exactly two
  ///             source pixels per destination pixel like building a mipmap
  ///             level does, and the final step scales by less than 2x. The
  ///             result is close to drawing the full size image with mipmaps
  ///             (`FilterQuality.medium`, the default of the `Image` widget).
  ///
  ///             See https://github.com/flutter/flutter/issues/193779.
  ///
  /// @return     The size of an intermediate halving step, or |target_size| if
  ///             the next step is the final one.
  ///
  static SkISize GetResizeStepSize(const SkISize& size,
                                   const SkISize& target_size);

  //----------------------------------------------------------------------------
  /// @brief      Resizes |source| to the size of |destination| in the steps
  ///             described in |GetResizeStepSize|.
  ///
  /// @return     Whether the resized pixels were written to |destination|.
  ///
  static bool ResizePixels(const SkPixmap& source, const SkPixmap& destination);

 protected:
  TaskRunners runners_;
  std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner_;
  fml::WeakPtr<IOManager> io_manager_;

  ImageDecoder(
      const TaskRunners& runners,
      std::shared_ptr<fml::ConcurrentTaskRunner> concurrent_task_runner,
      fml::WeakPtr<IOManager> io_manager);

 private:
  fml::TaskRunnerAffineWeakPtrFactory<ImageDecoder> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageDecoder);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_DECODER_H_
