// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/codec.h"

#include <variant>

#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/painting/frame_info.h"
#include "flutter/lib/ui/painting/multi_frame_codec.h"
#include "flutter/lib/ui/painting/single_frame_codec.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/include/core/SkPixelRef.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/typed_data/typed_list.h"

#if OS_ANDROID
#include <sys/mman.h>
#endif

using tonic::DartInvoke;
using tonic::DartPersistentValue;
using tonic::ToDart;

namespace flutter {

namespace {

// This needs to be kept in sync with _kDoNotResizeDimension in painting.dart
const int kDoNotResizeDimension = -1;

// This must be kept in sync with the enum in painting.dart
enum PixelFormat {
  kRGBA8888,
  kBGRA8888,
};

#if OS_ANDROID

// Compressed image buffers are allocated on the UI thread but are deleted on a
// decoder worker thread.  Android's implementation of malloc appears to
// continue growing the native heap size when the allocating thread is
// different from the freeing thread.  To work around this, create an SkData
// backed by an anonymous mapping.
sk_sp<SkData> MakeSkDataWithCopy(const void* data, size_t length) {
  if (length == 0) {
    return SkData::MakeEmpty();
  }

  size_t mapping_length = length + sizeof(size_t);
  void* mapping = ::mmap(nullptr, mapping_length, PROT_READ | PROT_WRITE,
                         MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);

  if (mapping == MAP_FAILED) {
    return SkData::MakeEmpty();
  }

  *reinterpret_cast<size_t*>(mapping) = mapping_length;
  void* mapping_data = reinterpret_cast<char*>(mapping) + sizeof(size_t);
  ::memcpy(mapping_data, data, length);

  SkData::ReleaseProc proc = [](const void* ptr, void* context) {
    size_t* size_ptr = reinterpret_cast<size_t*>(context);
    FML_DCHECK(ptr == size_ptr + 1);
    if (::munmap(const_cast<void*>(context), *size_ptr) == -1) {
      FML_LOG(ERROR) << "munmap of codec SkData failed";
    }
  };

  return SkData::MakeWithProc(mapping_data, length, proc, mapping);
}

#else

sk_sp<SkData> MakeSkDataWithCopy(const void* data, size_t length) {
  return SkData::MakeWithCopy(data, length);
}

#endif  // OS_ANDROID

}  // anonymous namespace

static std::variant<ImageDecoder::ImageInfo, std::string> ConvertImageInfo(
    Dart_Handle image_info_handle,
    Dart_NativeArguments args) {
  Dart_Handle width_handle = Dart_GetField(image_info_handle, ToDart("width"));
  if (!Dart_IsInteger(width_handle)) {
    return "ImageInfo.width must be an integer";
  }
  Dart_Handle height_handle =
      Dart_GetField(image_info_handle, ToDart("height"));
  if (!Dart_IsInteger(height_handle)) {
    return "ImageInfo.height must be an integer";
  }
  Dart_Handle format_handle =
      Dart_GetField(image_info_handle, ToDart("format"));
  if (!Dart_IsInteger(format_handle)) {
    return "ImageInfo.format must be an integer";
  }
  Dart_Handle row_bytes_handle =
      Dart_GetField(image_info_handle, ToDart("rowBytes"));
  if (!Dart_IsInteger(row_bytes_handle)) {
    return "ImageInfo.rowBytes must be an integer";
  }

  PixelFormat pixel_format = static_cast<PixelFormat>(
      tonic::DartConverter<int>::FromDart(format_handle));
  SkColorType color_type = kUnknown_SkColorType;
  switch (pixel_format) {
    case kRGBA8888:
      color_type = kRGBA_8888_SkColorType;
      break;
    case kBGRA8888:
      color_type = kBGRA_8888_SkColorType;
      break;
  }
  if (color_type == kUnknown_SkColorType) {
    return "Invalid pixel format";
  }

  int width = tonic::DartConverter<int>::FromDart(width_handle);
  if (width <= 0) {
    return "width must be greater than zero";
  }
  int height = tonic::DartConverter<int>::FromDart(height_handle);
  if (height <= 0) {
    return "height must be greater than zero";
  }

  ImageDecoder::ImageInfo image_info;
  image_info.sk_info =
      SkImageInfo::Make(width, height, color_type, kPremul_SkAlphaType);
  image_info.row_bytes =
      tonic::DartConverter<size_t>::FromDart(row_bytes_handle);

  if (image_info.row_bytes < image_info.sk_info.minRowBytes()) {
    return "rowBytes does not match the width of the image";
  }

  return image_info;
}

static void InstantiateImageCodec(Dart_NativeArguments args) {
  Dart_Handle callback_handle = Dart_GetNativeArgument(args, 1);
  if (!Dart_IsClosure(callback_handle)) {
    Dart_SetReturnValue(args, tonic::ToDart("Callback must be a function"));
    return;
  }

  Dart_Handle image_info_handle = Dart_GetNativeArgument(args, 2);

  std::optional<ImageDecoder::ImageInfo> image_info;

  if (!Dart_IsNull(image_info_handle)) {
    auto image_info_results = ConvertImageInfo(image_info_handle, args);
    if (auto value =
            std::get_if<ImageDecoder::ImageInfo>(&image_info_results)) {
      image_info = *value;
    } else if (auto error = std::get_if<std::string>(&image_info_results)) {
      Dart_SetReturnValue(args, tonic::ToDart(*error));
      return;
    }
  }

  sk_sp<SkData> buffer;

  {
    Dart_Handle exception = nullptr;
    tonic::Uint8List list =
        tonic::DartConverter<tonic::Uint8List>::FromArguments(args, 0,
                                                              exception);
    if (exception) {
      Dart_SetReturnValue(args, exception);
      return;
    }
    buffer = MakeSkDataWithCopy(list.data(), list.num_elements());
  }

  if (image_info) {
    const auto expected_size =
        image_info->row_bytes * image_info->sk_info.height();
    if (buffer->size() < expected_size) {
      Dart_SetReturnValue(
          args, ToDart("Pixel buffer size does not match image size"));
      return;
    }
  }

  const int targetWidth =
      tonic::DartConverter<int>::FromDart(Dart_GetNativeArgument(args, 3));
  const int targetHeight =
      tonic::DartConverter<int>::FromDart(Dart_GetNativeArgument(args, 4));

  std::unique_ptr<SkCodec> codec;
  bool single_frame;
  if (image_info) {
    single_frame = true;
  } else {
    codec = SkCodec::MakeFromData(buffer);
    if (!codec) {
      Dart_SetReturnValue(args, ToDart("Could not instantiate image codec."));
      return;
    }
    single_frame = codec->getFrameCount() == 1;
  }

  fml::RefPtr<Codec> ui_codec;

  if (single_frame) {
    ImageDecoder::ImageDescriptor descriptor;
    descriptor.decompressed_image_info = image_info;

    if (targetWidth != kDoNotResizeDimension) {
      descriptor.target_width = targetWidth;
    }
    if (targetHeight != kDoNotResizeDimension) {
      descriptor.target_height = targetHeight;
    }
    descriptor.data = std::move(buffer);

    ui_codec = fml::MakeRefCounted<SingleFrameCodec>(std::move(descriptor));
  } else {
    ui_codec = fml::MakeRefCounted<MultiFrameCodec>(std::move(codec));
  }

  tonic::DartInvoke(callback_handle, {ToDart(ui_codec)});
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Codec);

#define FOR_EACH_BINDING(V) \
  V(Codec, getNextFrame)    \
  V(Codec, frameCount)      \
  V(Codec, repetitionCount) \
  V(Codec, dispose)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void Codec::dispose() {
  ClearDartWrapper();
}

void Codec::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({
      {"instantiateImageCodec", InstantiateImageCodec, 5, true},
  });
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

}  // namespace flutter
