// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/threads.h"
#include "third_party/skia/include/core/SkRefCnt.h"

namespace blink {

template <typename T> void SkiaUnrefOnIOThread(sk_sp<T>* sp) {
  T* object = sp->release();
  if (object) {
    Threads::IO()->PostTask([object]() { object->unref(); });
  }
}

} // namespace blink
