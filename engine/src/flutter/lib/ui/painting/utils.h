// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "lib/fxl/synchronization/mutex.h"
#include "third_party/skia/include/core/SkRefCnt.h"

#include <queue>

namespace blink {

// A queue that holds Skia objects that must be destructed on the IO thread.
class SkiaUnrefQueue {
 public:
  static SkiaUnrefQueue& Get();

  void Unref(SkRefCnt* object);

 private:
  SkiaUnrefQueue();
  void Drain();

  static SkiaUnrefQueue instance_;

  fxl::Mutex mutex_;
  std::deque<SkRefCnt*> objects_ FXL_GUARDED_BY(mutex_);
  bool drain_pending_ FXL_GUARDED_BY(mutex_);
};

template <typename T>
void SkiaUnrefOnIOThread(sk_sp<T>* sp) {
  T* object = sp->release();
  if (object) {
    SkiaUnrefQueue::Get().Unref(object);
  }
}

}  // namespace blink
