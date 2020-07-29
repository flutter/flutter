// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_DESCRIPTOR_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_DESCRIPTOR_H_

#include <cstdint>
#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/immutable_buffer.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/include/core/SkImageGenerator.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/src/codec/SkCodecImageGenerator.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

/// Creates an image descriptor for encoded or decoded image data, describing
/// the width, height, and bytes per pixel for that image.
///
/// This class will hold a reference on the underlying image data, and in the
/// case of compressed data, an SkCodec and SkImageGenerator for the data.
/// The Codec initialization actually happens in initEncoded, making
/// initstantiateCodec a lightweight operation.
class ImageDescriptor : public RefCountedDartWrappable<ImageDescriptor> {
 public:
  ~ImageDescriptor() override = default;

  // This must be kept in sync with the enum in painting.dart
  enum PixelFormat {
    kRGBA8888,
    kBGRA8888,
  };

  /// Asynchronously initlializes an ImageDescriptor for an encoded image, as
  /// long as the format is supported by Skia.
  ///
  /// Calling this method will result in creating an SkCodec and
  /// SkImageGenerator to read EXIF corrected dimensions from the image data.
  static void initEncoded(Dart_NativeArguments args);

  /// Synchronously initializes an ImageDescriptor for decompressed image data
  /// as specified by the PixelFormat.
  static void initRaw(Dart_Handle descriptor_handle,
                      fml::RefPtr<ImmutableBuffer> data,
                      int width,
                      int height,
                      int row_bytes,
                      PixelFormat pixel_format);

  /// Associates a flutter::Codec object with the dart.ui Codec handle.
  void instantiateCodec(Dart_Handle codec, int target_width, int target_height);

  /// The width of this image, EXIF oriented if applicable.
  int width() const { return image_info_.width(); }

  /// The height of this image. EXIF oriented if applicable.
  int height() const { return image_info_.height(); }

  /// The bytes per pixel of the image.
  int bytesPerPixel() const { return image_info_.bytesPerPixel(); }

  /// The byte length of the first row of the image.
  ///
  /// Defaults to width() * 4.
  int row_bytes() const {
    return row_bytes_.value_or(
        static_cast<size_t>(image_info_.width() * image_info_.bytesPerPixel()));
  }

  /// Whether the given target_width or target_height differ from width() and
  /// height() respectively.
  bool should_resize(int target_width, int target_height) const {
    return target_width != width() || target_height != height();
  }

  /// The underlying buffer for this image.
  sk_sp<SkData> data() const { return buffer_; }

  sk_sp<SkImage> image() const;

  /// Whether this descriptor represents compressed (encoded) data or not.
  bool is_compressed() const { return generator_ || platform_image_generator_; }

  /// The orientation corrected image info for this image.
  const SkImageInfo& image_info() const { return image_info_; }

  /// Gets the scaled dimensions of this image, if backed by a codec that can
  /// perform efficient subpixel scaling.
  SkISize get_scaled_dimensions(float scale) {
    if (generator_) {
      return generator_->getScaledDimensions(scale);
    }
    return image_info_.dimensions();
  }

  /// Gets pixels for this image transformed based on the EXIF orientation tag,
  /// if applicable.
  bool get_pixels(const SkPixmap& pixmap) const;

  void dispose() {
    ClearDartWrapper();
    generator_.reset();
    platform_image_generator_.reset();
  }

  size_t GetAllocationSize() const override {
    return sizeof(ImageDescriptor) + sizeof(SkImageInfo) + buffer_->size();
  }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  ImageDescriptor(sk_sp<SkData> buffer,
                  const SkImageInfo& image_info,
                  std::optional<size_t> row_bytes);
  ImageDescriptor(sk_sp<SkData> buffer, std::unique_ptr<SkCodec> codec);
  ImageDescriptor(sk_sp<SkData> buffer,
                  std::unique_ptr<SkImageGenerator> generator);

  sk_sp<SkData> buffer_;
  std::shared_ptr<SkCodecImageGenerator> generator_;
  std::unique_ptr<SkImageGenerator> platform_image_generator_;
  const SkImageInfo image_info_;
  std::optional<size_t> row_bytes_;

  const SkImageInfo CreateImageInfo() const;

  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ImageDescriptor);
  FML_DISALLOW_COPY_AND_ASSIGN(ImageDescriptor);

  friend class ImageDecoderFixtureTest;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_DESCRIPTOR_H_
