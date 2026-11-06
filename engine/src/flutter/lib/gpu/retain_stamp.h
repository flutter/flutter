// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_RETAIN_STAMP_H_
#define FLUTTER_LIB_GPU_RETAIN_STAMP_H_

#include <atomic>
#include <cstdint>

namespace flutter {
namespace gpu {

/// The last recording that retained an object.
///
/// A pass binds the same few resources thousands of times. Stamping each
/// object makes every retain after the first one comparison, where it would
/// otherwise be an atomic increment and a vector entry.
///
/// A stale stamp only costs a duplicate retain, and a matching stamp always
/// means that recording holds the object, so interleaved recordings stay
/// correct.
class RetainStamp {
 public:
  RetainStamp() = default;

  // A copy is a new object that no recording has retained.
  RetainStamp(const RetainStamp&) {}

  RetainStamp& operator=(const RetainStamp&) { return *this; }

  /// Stamps the object with [recording_id]. Returns false if it already was.
  bool Update(uint64_t recording_id) const {
    if (recording_id_.load(std::memory_order_relaxed) == recording_id) {
      return false;
    }
    recording_id_.store(recording_id, std::memory_order_relaxed);
    return true;
  }

 private:
  mutable std::atomic<uint64_t> recording_id_ = 0;
};

}  // namespace gpu
}  // namespace flutter

#endif  // FLUTTER_LIB_GPU_RETAIN_STAMP_H_
