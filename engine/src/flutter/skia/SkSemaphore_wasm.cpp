// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/private/SkSemaphore.h"

#include <emscripten/threading.h>
#include <emscripten/wasm_worker.h>

// Wasm Workers do not implement POSIX semaphores. Keep SkSemaphore's atomic
// fast path, but use the Wasm Workers semaphore API for contended waits.
struct SkSemaphore::OSSemaphore {
  emscripten_semaphore_t semaphore =
      EMSCRIPTEN_SEMAPHORE_T_STATIC_INITIALIZER(0);

  void signal(int n) { emscripten_semaphore_release(&semaphore, n); }

  void wait() {
    if (emscripten_is_main_browser_thread()) {
      // Browsers forbid Atomics.wait on the main thread. Skia's synchronous
      // critical sections cannot yield here; their holders must not depend on
      // a callback to the main thread in order to release the semaphore.
      while (emscripten_semaphore_try_acquire(&semaphore, 1) < 0) {
      }
    } else {
      emscripten_semaphore_waitinf_acquire(&semaphore, 1);
    }
  }
};

SkSemaphore::~SkSemaphore() {
  delete fOSSemaphore;
}

void SkSemaphore::osSignal(int n) {
  fOSSemaphoreOnce([this] { fOSSemaphore = new OSSemaphore; });
  fOSSemaphore->signal(n);
}

void SkSemaphore::osWait() {
  fOSSemaphoreOnce([this] { fOSSemaphore = new OSSemaphore; });
  fOSSemaphore->wait();
}

bool SkSemaphore::try_wait() {
  int count = fCount.load(std::memory_order_relaxed);
  return count > 0 && fCount.compare_exchange_weak(count, count - 1,
                                                   std::memory_order_acquire);
}
