// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "live_objects.h"

#include "export.h"

uint32_t liveLineBreakBufferCount = 0;
uint32_t liveUnicodePositionBufferCount = 0;
uint32_t liveLineMetricsCount = 0;
uint32_t liveTextBoxListCount = 0;
uint32_t liveParagraphBuilderCount = 0;
uint32_t liveParagraphCount = 0;
uint32_t liveStrutStyleCount = 0;
uint32_t liveTextStyleCount = 0;
uint32_t liveAnimatedImageCount = 0;
uint32_t liveCountourMeasureIterCount = 0;
uint32_t liveCountourMeasureCount = 0;
uint32_t liveDataCount = 0;
uint32_t liveColorFilterCount = 0;
uint32_t liveImageFilterCount = 0;
uint32_t liveMaskFilterCount = 0;
uint32_t liveTypefaceCount = 0;
uint32_t liveFontCollectionCount = 0;
uint32_t liveImageCount = 0;
uint32_t livePaintCount = 0;
uint32_t livePathCount = 0;
uint32_t livePictureCount = 0;
uint32_t livePictureRecorderCount = 0;
uint32_t liveShaderCount = 0;
uint32_t liveRuntimeEffectCount = 0;
uint32_t liveStringCount = 0;
uint32_t liveString16Count = 0;
uint32_t liveSurfaceCount = 0;
uint32_t liveVerticesCount = 0;

namespace {
struct LiveObjectCounts {
  uint32_t lineBreakBufferCount;
  uint32_t unicodePositionBufferCount;
  uint32_t lineMetricsCount;
  uint32_t textBoxListCount;
  uint32_t paragraphBuilderCount;
  uint32_t paragraphCount;
  uint32_t strutStyleCount;
  uint32_t textStyleCount;
  uint32_t animatedImageCount;
  uint32_t countourMeasureIterCount;
  uint32_t countourMeasureCount;
  uint32_t dataCount;
  uint32_t colorFilterCount;
  uint32_t imageFilterCount;
  uint32_t maskFilterCount;
  uint32_t typefaceCount;
  uint32_t fontCollectionCount;
  uint32_t imageCount;
  uint32_t paintCount;
  uint32_t pathCount;
  uint32_t pictureCount;
  uint32_t pictureRecorderCount;
  uint32_t shaderCount;
  uint32_t runtimeEffectCount;
  uint32_t stringCount;
  uint32_t string16Count;
  uint32_t surfaceCount;
  uint32_t verticesCount;
};
}  // namespace

SKWASM_EXPORT void skwasm_getLiveObjectCounts(LiveObjectCounts* counts) {
  counts->lineBreakBufferCount = liveLineBreakBufferCount;
  counts->unicodePositionBufferCount = liveUnicodePositionBufferCount;
  counts->lineMetricsCount = liveLineMetricsCount;
  counts->textBoxListCount = liveTextBoxListCount;
  counts->paragraphBuilderCount = liveParagraphBuilderCount;
  counts->paragraphCount = liveParagraphCount;
  counts->strutStyleCount = liveStrutStyleCount;
  counts->textStyleCount = liveTextStyleCount;
  counts->animatedImageCount = liveAnimatedImageCount;
  counts->countourMeasureIterCount = liveCountourMeasureIterCount;
  counts->countourMeasureCount = liveCountourMeasureCount;
  counts->dataCount = liveDataCount;
  counts->colorFilterCount = liveColorFilterCount;
  counts->imageFilterCount = liveImageFilterCount;
  counts->maskFilterCount = liveMaskFilterCount;
  counts->typefaceCount = liveTypefaceCount;
  counts->fontCollectionCount = liveFontCollectionCount;
  counts->imageCount = liveImageCount;
  counts->paintCount = livePaintCount;
  counts->pathCount = livePathCount;
  counts->pictureCount = livePictureCount;
  counts->pictureRecorderCount = livePictureRecorderCount;
  counts->shaderCount = liveShaderCount;
  counts->runtimeEffectCount = liveRuntimeEffectCount;
  counts->stringCount = liveStringCount;
  counts->string16Count = liveString16Count;
  counts->surfaceCount = liveSurfaceCount;
  counts->verticesCount = liveVerticesCount;
}
