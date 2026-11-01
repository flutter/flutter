// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/private/SkSemaphore.h"

#include <emscripten/wasm_worker.h>

#if !defined(__EMSCRIPTEN_WASM_WORKERS__)
#error "This SkSemaphore implementation requires Emscripten Wasm Workers."
#endif

// POSIX semaphores are stubs in Wasm Worker builds without pthreads.
struct SkSemaphore::OSSemaphore {
  emscripten_semaphore_t fSemaphore =
      EMSCRIPTEN_SEMAPHORE_T_STATIC_INITIALIZER(0);

  void signal(int n) { emscripten_semaphore_release(&fSemaphore, n); }

  void wait() {
    if (emscripten_current_thread_is_wasm_worker()) {
      emscripten_semaphore_waitinf_acquire(&fSemaphore, 1);
      return;
    }
    // The browser main thread cannot block. The signaling worker must not
    // depend on the main event loop.
    while (emscripten_semaphore_try_acquire(&fSemaphore, 1) < 0) {
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
  if (count > 0) {
    return fCount.compare_exchange_weak(count, count - 1,
                                        std::memory_order_acquire);
  }
  return false;
}
