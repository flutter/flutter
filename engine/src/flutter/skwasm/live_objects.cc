// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/live_objects.h"

#include "flutter/skwasm/export.h"

uint32_t Skwasm::liveLineBreakBufferCount = 0;
uint32_t Skwasm::liveUnicodePositionBufferCount = 0;
uint32_t Skwasm::liveLineMetricsCount = 0;
uint32_t Skwasm::liveTextBoxListCount = 0;
uint32_t Skwasm::liveParagraphBuilderCount = 0;
uint32_t Skwasm::liveParagraphCount = 0;
uint32_t Skwasm::liveStrutStyleCount = 0;
uint32_t Skwasm::liveTextStyleCount = 0;
uint32_t Skwasm::liveAnimatedImageCount = 0;
uint32_t Skwasm::liveCountourMeasureIterCount = 0;
uint32_t Skwasm::liveCountourMeasureCount = 0;
uint32_t Skwasm::liveDataCount = 0;
uint32_t Skwasm::liveColorFilterCount = 0;
uint32_t Skwasm::liveImageFilterCount = 0;
uint32_t Skwasm::liveMaskFilterCount = 0;
uint32_t Skwasm::liveTypefaceCount = 0;
uint32_t Skwasm::liveFontCollectionCount = 0;
uint32_t Skwasm::liveImageCount = 0;
uint32_t Skwasm::livePaintCount = 0;
uint32_t Skwasm::livePathCount = 0;
uint32_t Skwasm::livePictureCount = 0;
uint32_t Skwasm::livePictureRecorderCount = 0;
uint32_t Skwasm::liveShaderCount = 0;
uint32_t Skwasm::liveRuntimeEffectCount = 0;
uint32_t Skwasm::liveStringCount = 0;
uint32_t Skwasm::liveString16Count = 0;
uint32_t Skwasm::liveSurfaceCount = 0;
uint32_t Skwasm::liveVerticesCount = 0;

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
  counts->lineBreakBufferCount = Skwasm::liveLineBreakBufferCount;
  counts->unicodePositionBufferCount = Skwasm::liveUnicodePositionBufferCount;
  counts->lineMetricsCount = Skwasm::liveLineMetricsCount;
  counts->textBoxListCount = Skwasm::liveTextBoxListCount;
  counts->paragraphBuilderCount = Skwasm::liveParagraphBuilderCount;
  counts->paragraphCount = Skwasm::liveParagraphCount;
  counts->strutStyleCount = Skwasm::liveStrutStyleCount;
  counts->textStyleCount = Skwasm::liveTextStyleCount;
  counts->animatedImageCount = Skwasm::liveAnimatedImageCount;
  counts->countourMeasureIterCount = Skwasm::liveCountourMeasureIterCount;
  counts->countourMeasureCount = Skwasm::liveCountourMeasureCount;
  counts->dataCount = Skwasm::liveDataCount;
  counts->colorFilterCount = Skwasm::liveColorFilterCount;
  counts->imageFilterCount = Skwasm::liveImageFilterCount;
  counts->maskFilterCount = Skwasm::liveMaskFilterCount;
  counts->typefaceCount = Skwasm::liveTypefaceCount;
  counts->fontCollectionCount = Skwasm::liveFontCollectionCount;
  counts->imageCount = Skwasm::liveImageCount;
  counts->paintCount = Skwasm::livePaintCount;
  counts->pathCount = Skwasm::livePathCount;
  counts->pictureCount = Skwasm::livePictureCount;
  counts->pictureRecorderCount = Skwasm::livePictureRecorderCount;
  counts->shaderCount = Skwasm::liveShaderCount;
  counts->runtimeEffectCount = Skwasm::liveRuntimeEffectCount;
  counts->stringCount = Skwasm::liveStringCount;
  counts->string16Count = Skwasm::liveString16Count;
  counts->surfaceCount = Skwasm::liveSurfaceCount;
  counts->verticesCount = Skwasm::liveVerticesCount;
}
