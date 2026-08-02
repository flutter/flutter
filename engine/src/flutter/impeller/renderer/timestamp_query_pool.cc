// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/timestamp_query_pool.h"

namespace impeller {

TimestampQueryPool::TimestampQueryPool(size_t query_count)
    : query_count_(query_count) {}

TimestampQueryPool::~TimestampQueryPool() = default;

size_t TimestampQueryPool::GetQueryCount() const {
  return query_count_;
}

bool TimestampWrites::IsValid() const {
  if (!pool) {
    return false;
  }
  const size_t count = pool->GetQueryCount();
  if (beginning_of_pass_write_index.has_value() &&
      beginning_of_pass_write_index.value() >= count) {
    return false;
  }
  if (end_of_pass_write_index.has_value() &&
      end_of_pass_write_index.value() >= count) {
    return false;
  }
  if (beginning_of_pass_write_index.has_value() &&
      beginning_of_pass_write_index == end_of_pass_write_index) {
    return false;
  }
  return true;
}

bool TimestampWrites::HasWrites() const {
  return pool != nullptr && (beginning_of_pass_write_index.has_value() ||
                             end_of_pass_write_index.has_value());
}

}  // namespace impeller
