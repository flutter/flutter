// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "live_objects.h"
#include "skwasm_support.h"

#include "third_party/skia/include/android/SkAnimatedImage.h"
#include "third_party/skia/include/codec/SkAndroidCodec.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/include/codec/SkGifDecoder.h"
#include "third_party/skia/include/codec/SkWebpDecoder.h"

#include <memory>

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
                                                    int targetWidth,
                                                    int targetHeight) {
  liveAnimatedImageCount++;
  auto codec = getCodecForData(data);
  if (!codec) {
    printf("Failed to create codec for animated image.\n");
    return nullptr;
  }

  auto aCodec = SkAndroidCodec::MakeFromCodec(std::move(codec));
  if (aCodec == nullptr) {
    printf("Failed to create codec for animated image.\n");
    return nullptr;
  }

  if (targetWidth == 0 || targetHeight == 0) {
    return SkAnimatedImage::Make(std::move(aCodec)).release();
  }

  return SkAnimatedImage::Make(
             std::move(aCodec),
             SkImageInfo::MakeUnknown(targetWidth, targetHeight),
             SkIRect::MakeWH(targetWidth, targetHeight), nullptr)
      .release();
}

SKWASM_EXPORT void animatedImage_dispose(SkAnimatedImage* image) {
  liveAnimatedImageCount--;
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

SKWASM_EXPORT SkImage* animatedImage_getCurrentFrame(SkAnimatedImage* image) {
  liveImageCount++;
  return image->getCurrentFrame().release();
}
