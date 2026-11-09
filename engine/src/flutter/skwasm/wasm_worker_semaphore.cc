// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <errno.h>
#include <semaphore.h>
#include <string.h>

#include "flutter/skwasm/export.h"

// Skwasm and Wimp are compiled with Emscripten Wasm Workers (-sWASM_WORKERS=1)
// rather than pthreads (-pthread). Under -sWASM_WORKERS=1, Emscripten's
// libc-ww.a (library_pthread_stub.c) defines POSIX sem_init, sem_destroy,
// sem_post, sem_trywait, and sem_wait as no-op stubs that always return 0.
//
// Skia's SkSemaphore (which backs SkMutex, including FreeType's global
// f_t_mutex() in SkFontHost_FreeType.cpp) relies on POSIX semaphores whenever
// its userspace atomic fast-path contends across threads. Without real sem_*
// implementations, concurrent FreeType calls from the UI thread
// (Paragraph.layout) and the render worker race on shared FT_Face state.
//
// Defining sem_* here (linked with -Wl,--allow-multiple-definition so these
// strong symbols override libc-ww.a's bitcode stubs during LTO) implements
// POSIX semaphores using Emscripten's Wasm Worker semaphore primitives
// (blocking via Atomics.wait on worker threads and spin-waiting on the main
// browser thread where Atomics.wait is disallowed).
#if defined(__EMSCRIPTEN_WASM_WORKERS__)

#include <emscripten/wasm_worker.h>
#include <limits.h>
#include <stdint.h>

namespace {

volatile uint32_t* AsSem(sem_t* sem) {
  return reinterpret_cast<volatile uint32_t*>(sem);
}

bool CanBlock() {
  static thread_local const bool can_block =
      emscripten_wasm_worker_self_id() != 0;
  return can_block;
}

}  // namespace

extern "C" {

int sem_init(sem_t* sem, int /*pshared*/, unsigned int value) {
  if (!sem || value > SEM_VALUE_MAX) {
    errno = EINVAL;
    return -1;
  }
  emscripten_semaphore_init(AsSem(sem), static_cast<int>(value));
  return 0;
}

int sem_destroy(sem_t* sem) {
  if (!sem) {
    errno = EINVAL;
    return -1;
  }
  return 0;
}

int sem_post(sem_t* sem) {
  if (!sem) {
    errno = EINVAL;
    return -1;
  }
  emscripten_semaphore_release(AsSem(sem), 1);
  return 0;
}

int sem_trywait(sem_t* sem) {
  if (!sem) {
    errno = EINVAL;
    return -1;
  }
  if (emscripten_semaphore_try_acquire(AsSem(sem), 1) >= 0) {
    return 0;
  }
  errno = EAGAIN;
  return -1;
}

int sem_wait(sem_t* sem) {
  if (!sem) {
    errno = EINVAL;
    return -1;
  }
  if (CanBlock()) {
    emscripten_semaphore_waitinf_acquire(AsSem(sem), 1);
    return 0;
  }
  // Atomics.wait is not allowed on the main browser thread.
  while (emscripten_semaphore_try_acquire(AsSem(sem), 1) < 0) {
  }
  return 0;
}

}  // extern "C"

#endif  // defined(__EMSCRIPTEN_WASM_WORKERS__)

// Returns 0 when the sem_* functions linked into this module behave like real
// semaphores, or a bitmask of failed checks when they behave like Emscripten's
// -sWASM_WORKERS=1 no-op stubs (which always return 0). The sequence never
// calls sem_wait on a zero count, so it cannot spin even if sem_post is a stub.
SKWASM_EXPORT int skwasm_verifySemaphores() {
  sem_t sem;
  // A stub sem_init leaves this sentinel in place.
  memset(&sem, 0xAB, sizeof(sem));
  int failures = 0;
  if (sem_init(&sem, 0, 1) != 0) {
    failures |= 1 << 0;
  }
  sem_wait(&sem);  // 1 -> 0.
  errno = 0;
  if (sem_trywait(&sem) != -1 || errno != EAGAIN) {
    failures |= 1 << 1;  // sem_init, sem_wait or sem_trywait is a stub.
  }
  sem_post(&sem);  // 0 -> 1.
  if (sem_trywait(&sem) != 0) {
    failures |= 1 << 2;  // sem_post is a stub.
  }
  if (sem_trywait(&sem) != -1) {
    failures |= 1 << 3;  // sem_trywait is a stub.
  }
  sem_destroy(&sem);
  return failures;
}
