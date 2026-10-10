// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/display_list/dl_text_impeller.h"

#include <array>
#include <cstdint>

#include "flutter/impeller/typographer/backends/skia/text_frame_skia.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace flutter {

std::shared_ptr<DlTextImpeller> DlTextImpeller::Make(
    const std::shared_ptr<impeller::TextFrame>& frame) {
  return std::make_shared<DlTextImpeller>(frame);
}

std::shared_ptr<DlTextImpeller> DlTextImpeller::MakeFromBlob(
    const sk_sp<SkTextBlob>& blob) {
  if (!blob) {
    return nullptr;
  }
  const uint32_t unique_id = blob->uniqueID();
  if (unique_id == 0) {
    return DlTextImpeller::Make(impeller::MakeTextFrameFromTextBlobSkia(blob));
  }

  struct CacheEntry {
    uint32_t unique_id = 0;
    uint32_t last_used = 0;
    std::shared_ptr<DlTextImpeller> dl_text;
  };
  struct CacheSet {
    std::array<CacheEntry, 4> ways = {};
  };
  constexpr size_t kNumSets = 1024;  // 4,096 entries max
  struct BlobCache {
    std::array<CacheSet, kNumSets> sets = {};
    uint32_t clock = 0;
  };

  thread_local BlobCache cache;
  const uint32_t tick = ++cache.clock;
  const size_t set_idx = (unique_id ^ (unique_id >> 10)) & (kNumSets - 1);
  auto& ways = cache.sets[set_idx].ways;

  size_t victim_idx = 0;
  uint32_t min_last_used = UINT32_MAX;
  for (size_t i = 0; i < ways.size(); ++i) {
    if (ways[i].unique_id == unique_id) {
      ways[i].last_used = tick;
      return ways[i].dl_text;
    }
    if (ways[i].unique_id == 0) {
      victim_idx = i;
      min_last_used = 0;
    } else if (min_last_used != 0 &&
               (i == 0 ||
                static_cast<int32_t>(ways[i].last_used - min_last_used) < 0)) {
      min_last_used = ways[i].last_used;
      victim_idx = i;
    }
  }

  auto dl_text =
      DlTextImpeller::Make(impeller::MakeTextFrameFromTextBlobSkia(blob));
  ways[victim_idx] = CacheEntry{
      .unique_id = unique_id,
      .last_used = tick,
      .dl_text = dl_text,
  };
  return dl_text;
}

DlTextImpeller::DlTextImpeller(
    const std::shared_ptr<impeller::TextFrame>& frame)
    : frame_(frame) {}

}  // namespace flutter
