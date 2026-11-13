// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/recording.h"

namespace flutter {
namespace gpu {

OpStream::~OpStream() {
  Reset();
}

void OpStream::AddChunk() {
  // Not value-initialized, which would zero the whole chunk.
  auto* chunk = new RecordingChunk;
  if (tail_) {
    tail_->used = cursor_ - tail_->data;
    tail_->next = chunk;
  } else {
    head_ = chunk;
  }
  tail_ = chunk;
  cursor_ = chunk->data;
  limit_ = chunk->data + sizeof(chunk->data);
}

void OpStream::Reset() {
  while (head_) {
    RecordingChunk* next = head_->next;
    delete head_;
    head_ = next;
  }
  tail_ = nullptr;
  cursor_ = nullptr;
  limit_ = nullptr;
}

}  // namespace gpu
}  // namespace flutter
