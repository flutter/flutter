// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/display_list/image/dl_image.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/skwasm_support.h"
#include "third_party/skia/include/android/SkAnimatedImage.h"
#include "third_party/skia/include/codec/SkAndroidCodec.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/include/codec/SkGifDecoder.h"
#include "third_party/skia/include/codec/SkWebpDecoder.h"

namespace {
std::unique_ptr<SkCodec> getCodecForData(SkData* data) {
  if (SkGifDecoder::IsGif(data->data(), data->size())) {
    return SkGifDecoder::Decode(sk_ref_sp(data), nullptr);
  }
  if (SkWebpDecoder::IsWebp(data->data(), data->size())) {
    return SkWebpDecoder::Decode(sk_ref_sp(data), nullptr);
  }
  return nullptr;
}
}  // namespace

SKWASM_EXPORT SkAnimatedImage* animatedImage_create(SkData* data,
                                                    int target_width,
                                                    int target_height) {
  Skwasm::live_animated_image_count++;
  auto codec = getCodecForData(data);
  if (!codec) {
    printf("Failed to create codec for animated image.\n");
    return nullptr;
  }

  auto android_codec = SkAndroidCodec::MakeFromCodec(std::move(codec));
  if (android_codec == nullptr) {
    printf("Failed to create codec for animated image.\n");
    return nullptr;
  }

  if (target_width == 0 || target_height == 0) {
    return SkAnimatedImage::Make(std::move(android_codec)).release();
  }

  return SkAnimatedImage::Make(
             std::move(android_codec),
             SkImageInfo::MakeUnknown(target_width, target_height),
             SkIRect::MakeWH(target_width, target_height), nullptr)
      .release();
}

SKWASM_EXPORT void animatedImage_dispose(SkAnimatedImage* image) {
  Skwasm::live_animated_image_count--;
  image->unref();
}

SKWASM_EXPORT int animatedImage_getFrameCount(SkAnimatedImage* image) {
  return image->getFrameCount();
}

SKWASM_EXPORT int animatedImage_getRepetitionCount(SkAnimatedImage* image) {
  return image->getRepetitionCount();
}

SKWASM_EXPORT int animatedImage_getCurrentFrameDurationMilliseconds(
    SkAnimatedImage* image) {
  return image->currentFrameDuration();
}

SKWASM_EXPORT void animatedImage_decodeNextFrame(SkAnimatedImage* image) {
  image->decodeNextFrame();
}

SKWASM_EXPORT flutter::DlImage* animatedImage_getCurrentFrame(
    SkAnimatedImage* image) {
  Skwasm::live_image_count++;
  return flutter::DlImage::Make(image->getCurrentFrame()).release();
}
