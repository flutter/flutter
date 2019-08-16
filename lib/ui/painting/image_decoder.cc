// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_decoder.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/codec/SkCodec.h"

namespace flutter {

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

  const auto aspect_ratio =
      static_cast<double>(current_size.width()) / current_size.height();

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
                                        std::optional<uint32_t> target_width,
                                        std::optional<uint32_t> target_height,
                                        const fml::tracing::TraceFlow& flow) {
  FML_DCHECK(!image->isTextureBacked());

  const auto resized_dimensions =
      GetResizedDimensions(image->dimensions(), target_width, target_height);

  if (resized_dimensions.isEmpty()) {
    FML_LOG(ERROR) << "Could not resize to empty dimensions.";
    return nullptr;
  }

  if (resized_dimensions == image->dimensions()) {
    // The resized dimesions are the same as the intrinsic dimensions of the
    // image. There is nothing to do.
    return image;
  }

  TRACE_EVENT0("flutter", __FUNCTION__);
  flow.Step(__FUNCTION__);

  const auto scaled_image_info = image->imageInfo().makeWH(
      resized_dimensions.width(), resized_dimensions.height());

  SkBitmap scaled_bitmap;
  if (!scaled_bitmap.tryAllocPixels(scaled_image_info)) {
    FML_LOG(ERROR) << "Could not allocate bitmap when attempting to scale.";
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

  return ResizeRasterImage(std::move(image), target_width, target_height, flow);
}

static sk_sp<SkImage> ImageFromCompressedData(
    sk_sp<SkData> data,
    std::optional<uint32_t> target_width,
    std::optional<uint32_t> target_height,
    const fml::tracing::TraceFlow& flow) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  flow.Step(__FUNCTION__);

  auto decoded_image = SkImage::MakeFromEncoded(data);

  if (!decoded_image) {
    return nullptr;
  }

  // Make sure to resolve all lazy images.
  decoded_image = decoded_image->makeRasterImage();

  if (!decoded_image) {
    return nullptr;
  }

  return ResizeRasterImage(decoded_image, target_width, target_height, flow);
}

static SkiaGPUObject<SkImage> UploadRasterImage(
    sk_sp<SkImage> image,
    fml::WeakPtr<GrContext> context,
    fml::RefPtr<flutter::SkiaUnrefQueue> queue,
    const fml::tracing::TraceFlow& flow) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  flow.Step(__FUNCTION__);

  // Should not already be a texture image because that is the entire point of
  // the this method.
  FML_DCHECK(!image->isTextureBacked());

  if (!context || !queue) {
    FML_LOG(ERROR)
        << "Could not acquire context of release queue for texture upload.";
    return {};
  }

  SkPixmap pixmap;
  if (!image->peekPixels(&pixmap)) {
    FML_LOG(ERROR) << "Could not peek pixels of image for texture upload.";
    return {};
  }

  auto texture_image =
      SkImage::MakeCrossContextFromPixmap(context.get(),  // context
                                          pixmap,         // pixmap
                                          true,           // buildMips,
                                          true  // limitToMaxTextureSize
      );

  if (!texture_image) {
    FML_LOG(ERROR) << "Could not make x-context image.";
    return {};
  }

  return {texture_image, queue};
}

void ImageDecoder::Decode(ImageDescriptor descriptor, ImageResult callback) {
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

          auto uploaded = UploadRasterImage(
              std::move(decompressed), io_manager->GetResourceContext(),
              io_manager->GetSkiaUnrefQueue(), flow);

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
