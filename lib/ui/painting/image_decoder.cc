// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoder.h"

#include <algorithm>

#include "flutter/fml/make_copyable.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/src/codec/SkCodecImageGenerator.h"

namespace flutter {
namespace {

constexpr double kAspectRatioChangedThreshold = 0.01;

}  // namespace

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

static double AspectRatio(const SkISize& size) {
  return static_cast<double>(size.width()) / size.height();
}

// Get the updated dimensions of the image. If both dimensions are specified,
// use them. If one of them is specified, respect the one that is and use the
// aspect ratio to calculate the other. If neither dimension is specified, use
// intrinsic dimensions of the image.
static SkISize GetResizedDimensions(SkISize current_size,
                                    std::optional<uint32_t> target_width,
                                    std::optional<uint32_t> target_height) {
  if (current_size.isEmpty()) {
    return SkISize::MakeEmpty();
  }

  if (target_width && target_height) {
    return SkISize::Make(target_width.value(), target_height.value());
  }

  const auto aspect_ratio = AspectRatio(current_size);

  if (target_width) {
    return SkISize::Make(target_width.value(),
                         target_width.value() / aspect_ratio);
  }

  if (target_height) {
    return SkISize::Make(target_height.value() * aspect_ratio,
                         target_height.value());
  }

  return current_size;
}

static sk_sp<SkImage> ResizeRasterImage(sk_sp<SkImage> image,
                                        const SkISize& resized_dimensions,
                                        const fml::tracing::TraceFlow& flow) {
  FML_DCHECK(!image->isTextureBacked());

  TRACE_EVENT0("flutter", __FUNCTION__);
  flow.Step(__FUNCTION__);

  if (resized_dimensions.isEmpty()) {
    FML_LOG(ERROR) << "Could not resize to empty dimensions.";
    return nullptr;
  }

  if (image->dimensions() == resized_dimensions) {
    return image->makeRasterImage();
  }

  if (resized_dimensions.width() > image->dimensions().width() ||
      resized_dimensions.height() > image->dimensions().height()) {
    FML_LOG(WARNING) << "Image is being upsized from "
                     << image->dimensions().width() << "x"
                     << image->dimensions().height() << " to "
                     << resized_dimensions.width() << "x"
                     << resized_dimensions.height()
                     << ". Are cache(Height|Width) used correctly?";
    // TOOD(48885): consider exiting here, there's no good reason to support
    // upsampling in a "caching"-optimization context..
  }

  const bool aspect_ratio_changed =
      std::abs(AspectRatio(resized_dimensions) -
               AspectRatio(image->dimensions())) > kAspectRatioChangedThreshold;
  if (aspect_ratio_changed) {
    // This is probably a bug. If a user passes dimensions that change the
    // aspect ratio in a "caching" context that's probably not working as
    // intended and rather a signal that the API is hard to use.
    FML_LOG(WARNING)
        << "Aspect ratio changes. Are cache(Height|Width) used correctly?";
  }

  const auto scaled_image_info =
      image->imageInfo().makeDimensions(resized_dimensions);

  SkBitmap scaled_bitmap;
  if (!scaled_bitmap.tryAllocPixels(scaled_image_info)) {
    FML_LOG(ERROR) << "Failed to allocate memory for bitmap of size "
                   << scaled_image_info.computeMinByteSize() << "B";
    return nullptr;
  }

  if (!image->scalePixels(scaled_bitmap.pixmap(), kLow_SkFilterQuality,
                          SkImage::kDisallow_CachingHint)) {
    FML_LOG(ERROR) << "Could not scale pixels";
    return nullptr;
  }

  // Marking this as immutable makes the MakeFromBitmap call share the pixels
  // instead of copying.
  scaled_bitmap.setImmutable();

  auto scaled_image = SkImage::MakeFromBitmap(scaled_bitmap);
  if (!scaled_image) {
    FML_LOG(ERROR) << "Could not create a scaled image from a scaled bitmap.";
    return nullptr;
  }

  return scaled_image;
}

static sk_sp<SkImage> ImageFromDecompressedData(
    sk_sp<SkData> data,
    ImageDecoder::ImageInfo info,
    std::optional<uint32_t> target_width,
    std::optional<uint32_t> target_height,
    const fml::tracing::TraceFlow& flow) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  flow.Step(__FUNCTION__);
  auto image = SkImage::MakeRasterData(info.sk_info, data, info.row_bytes);

  if (!image) {
    FML_LOG(ERROR) << "Could not create image from decompressed bytes.";
    return nullptr;
  }

  if (!target_width && !target_height) {
    // No resizing requested. Just rasterize the image.
    return image->makeRasterImage();
  }

  auto resized_dimensions =
      GetResizedDimensions(image->dimensions(), target_width, target_height);

  return ResizeRasterImage(std::move(image), resized_dimensions, flow);
}

sk_sp<SkImage> ImageFromCompressedData(sk_sp<SkData> data,
                                       std::optional<uint32_t> target_width,
                                       std::optional<uint32_t> target_height,
                                       const fml::tracing::TraceFlow& flow) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  flow.Step(__FUNCTION__);

  if (!target_width && !target_height) {
    // No resizing requested. Just decode & rasterize the image.
    return SkImage::MakeFromEncoded(data)->makeRasterImage();
  }

  auto codec = SkCodec::MakeFromData(data);
  if (codec == nullptr) {
    return nullptr;
  }

  const auto* codec_ptr = codec.get();

  // Note that we cannot read the dimensions from the codec since they don't
  // respect image orientation provided e.g. in EXIF data.
  auto image_generator = SkCodecImageGenerator::MakeFromCodec(std::move(codec));
  const auto& source_dimensions = image_generator->getInfo().dimensions();

  auto resized_dimensions =
      GetResizedDimensions(source_dimensions, target_width, target_height);

  // No resize needed.
  if (resized_dimensions == source_dimensions) {
    return SkImage::MakeFromEncoded(data)->makeRasterImage();
  }

  auto decode_dimensions = codec_ptr->getScaledDimensions(
      std::max(static_cast<double>(resized_dimensions.width()) /
                   source_dimensions.width(),
               static_cast<double>(resized_dimensions.height()) /
                   source_dimensions.height()));

  // If the codec supports efficient sub-pixel decoding, decoded at a resolution
  // close to the target resolution before resizing.
  if (decode_dimensions != codec_ptr->dimensions()) {
    if (source_dimensions != codec_ptr->dimensions()) {
      decode_dimensions =
          SkISize::Make(decode_dimensions.height(), decode_dimensions.width());
    }

    auto scaled_image_info =
        image_generator->getInfo().makeDimensions(decode_dimensions);

    SkBitmap scaled_bitmap;
    if (!scaled_bitmap.tryAllocPixels(scaled_image_info)) {
      FML_LOG(ERROR) << "Failed to allocate memory for bitmap of size "
                     << scaled_image_info.computeMinByteSize() << "B";
      return nullptr;
    }

    const auto& pixmap = scaled_bitmap.pixmap();
    if (image_generator->getPixels(pixmap.info(), pixmap.writable_addr(),
                                   pixmap.rowBytes())) {
      // Marking this as immutable makes the MakeFromBitmap call share
      // the pixels instead of copying.
      scaled_bitmap.setImmutable();

      auto decoded_image = SkImage::MakeFromBitmap(scaled_bitmap);
      FML_DCHECK(decoded_image);
      if (!decoded_image) {
        FML_LOG(ERROR)
            << "Could not create a scaled image from a scaled bitmap.";
        return nullptr;
      }
      return ResizeRasterImage(std::move(decoded_image), resized_dimensions,
                               flow);
    }
  }

  auto image = SkImage::MakeFromEncoded(data);
  if (!image) {
    return nullptr;
  }

  return ResizeRasterImage(std::move(image), resized_dimensions, flow);
}

static SkiaGPUObject<SkImage> UploadRasterImage(
    sk_sp<SkImage> image,
    fml::WeakPtr<IOManager> io_manager,
    const fml::tracing::TraceFlow& flow) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  flow.Step(__FUNCTION__);

  // Should not already be a texture image because that is the entire point of
  // the this method.
  FML_DCHECK(!image->isTextureBacked());

  if (!io_manager->GetResourceContext() || !io_manager->GetSkiaUnrefQueue()) {
    FML_LOG(ERROR)
        << "Could not acquire context of release queue for texture upload.";
    return {};
  }

  SkPixmap pixmap;
  if (!image->peekPixels(&pixmap)) {
    FML_LOG(ERROR) << "Could not peek pixels of image for texture upload.";
    return {};
  }

  SkiaGPUObject<SkImage> result;
  io_manager->GetIsGpuDisabledSyncSwitch()->Execute(
      fml::SyncSwitch::Handlers()
          .SetIfTrue([&result, &pixmap, &image] {
            SkSafeRef(image.get());
            sk_sp<SkImage> texture_image = SkImage::MakeFromRaster(
                pixmap,
                [](const void* pixels, SkImage::ReleaseContext context) {
                  SkSafeUnref(static_cast<SkImage*>(context));
                },
                image.get());
            result = {texture_image, nullptr};
          })
          .SetIfFalse([&result, context = io_manager->GetResourceContext(),
                       &pixmap, queue = io_manager->GetSkiaUnrefQueue()] {
            TRACE_EVENT0("flutter", "MakeCrossContextImageFromPixmap");
            sk_sp<SkImage> texture_image = SkImage::MakeCrossContextFromPixmap(
                context.get(),  // context
                pixmap,         // pixmap
                true,           // buildMips,
                true            // limitToMaxTextureSize
            );
            if (!texture_image) {
              FML_LOG(ERROR) << "Could not make x-context image.";
              result = {};
            } else {
              result = {texture_image, queue};
            }
          }));

  return result;
}

void ImageDecoder::Decode(ImageDescriptor descriptor,
                          const ImageResult& callback) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  fml::tracing::TraceFlow flow(__FUNCTION__);

  FML_DCHECK(callback);
  FML_DCHECK(runners_.GetUITaskRunner()->RunsTasksOnCurrentThread());

  // Always service the callback on the UI thread.
  auto result = [callback, ui_runner = runners_.GetUITaskRunner()](
                    SkiaGPUObject<SkImage> image,
                    fml::tracing::TraceFlow flow) {
    ui_runner->PostTask(fml::MakeCopyable(
        [callback, image = std::move(image), flow = std::move(flow)]() mutable {
          // We are going to terminate the trace flow here. Flows cannot
          // terminate without a base trace. Add one explicitly.
          TRACE_EVENT0("flutter", "ImageDecodeCallback");
          flow.End();
          callback(std::move(image));
        }));
  };

  if (!descriptor.data || descriptor.data->size() == 0) {
    result({}, std::move(flow));
    return;
  }

  concurrent_task_runner_->PostTask(
      fml::MakeCopyable([descriptor,                              //
                         io_manager = io_manager_,                //
                         io_runner = runners_.GetIOTaskRunner(),  //
                         result,                                  //
                         flow = std::move(flow)                   //
  ]() mutable {
        // Step 1: Decompress the image.
        // On Worker.

        auto decompressed =
            descriptor.decompressed_image_info
                ? ImageFromDecompressedData(
                      std::move(descriptor.data),                  //
                      descriptor.decompressed_image_info.value(),  //
                      descriptor.target_width,                     //
                      descriptor.target_height,                    //
                      flow                                         //
                      )
                : ImageFromCompressedData(std::move(descriptor.data),  //
                                          descriptor.target_width,     //
                                          descriptor.target_height,    //
                                          flow);

        if (!decompressed) {
          FML_LOG(ERROR) << "Could not decompress image.";
          result({}, std::move(flow));
          return;
        }

        // Step 2: Update the image to the GPU.
        // On IO Thread.

        io_runner->PostTask(fml::MakeCopyable([io_manager, decompressed, result,
                                               flow =
                                                   std::move(flow)]() mutable {
          if (!io_manager) {
            FML_LOG(ERROR) << "Could not acquire IO manager.";
            return result({}, std::move(flow));
          }

          // If the IO manager does not have a resource context, the caller
          // might not have set one or a software backend could be in use.
          // Either way, just return the image as-is.
          if (!io_manager->GetResourceContext()) {
            result({std::move(decompressed), io_manager->GetSkiaUnrefQueue()},
                   std::move(flow));
            return;
          }

          auto uploaded =
              UploadRasterImage(std::move(decompressed), io_manager, flow);

          if (!uploaded.get()) {
            FML_LOG(ERROR) << "Could not upload image to the GPU.";
            result({}, std::move(flow));
            return;
          }

          // Finally, all done.
          result(std::move(uploaded), std::move(flow));
        }));
      }));
}

fml::WeakPtr<ImageDecoder> ImageDecoder::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

}  // namespace flutter
