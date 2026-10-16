// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(__EMSCRIPTEN_WASM_WORKERS__)

#include <emscripten/wasm_worker.h>
#include <errno.h>
#include <limits.h>
#include <semaphore.h>
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
