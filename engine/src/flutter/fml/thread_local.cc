// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/thread_local.h"

#if FML_THREAD_LOCAL_PTHREADS

#include "flutter/fml/logging.h"

namespace fml {
namespace internal {

ThreadLocalPointer::ThreadLocalPointer(void (*destroy)(void*)) {
  FML_CHECK(pthread_key_create(&key_, destroy) == 0);
}

ThreadLocalPointer::~ThreadLocalPointer() {
  FML_CHECK(pthread_key_delete(key_) == 0);
}

void* ThreadLocalPointer::get() const {
  return pthread_getspecific(key_);
}

void* ThreadLocalPointer::swap(void* ptr) {
  void* old_ptr = get();
  int err = pthread_setspecific(key_, ptr);
  if (err) {
    FML_CHECK(false) << "pthread_setspecific failed (" << err
                     << "): " << strerror(err);
  }
  return old_ptr;
}

}  // namespace internal
}  // namespace fml

#endif  // FML_THREAD_LOCAL_PTHREADS
