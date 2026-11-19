// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/recording.h"

#include <memory>
#include <utility>

namespace flutter {
namespace gpu {

OpStream::~OpStream() {
  Reset();
}

void OpStream::AddChunk() {
  // Not value-initialized, which would zero the whole chunk.
  auto chunk = std::make_unique_for_overwrite<RecordingChunk>();
  RecordingChunk* added = chunk.get();
  if (tail_) {
    tail_->used = cursor_ - tail_->data;
    tail_->next = std::move(chunk);
  } else {
    head_ = std::move(chunk);
  }
  tail_ = added;
  cursor_ = added->data;
  limit_ = added->data + sizeof(added->data);
}

void OpStream::Reset() {
  // One chunk at a time, since dropping the head alone would recurse through
  // every chunk after it.
  while (head_) {
    head_ = std::move(head_->next);
  }
  tail_ = nullptr;
  cursor_ = nullptr;
  limit_ = nullptr;
}

}  // namespace gpu
}  // namespace flutter
