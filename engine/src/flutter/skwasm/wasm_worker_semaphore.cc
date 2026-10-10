// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(__EMSCRIPTEN_WASM_WORKERS__)

#include <emscripten/threading.h>
#include <emscripten/wasm_worker.h>
#include <errno.h>
#include <limits.h>
#include <semaphore.h>

extern "C" {

int __wrap_sem_init(sem_t* sem, int pshared, unsigned int value) {
  if (!sem || value > SEM_VALUE_MAX) {
    errno = EINVAL;
    return -1;
  }
  auto* count = reinterpret_cast<volatile int*>(sem);
  *count = static_cast<int>(value);
  return 0;
}

int __wrap_sem_destroy(sem_t* sem) {
  return 0;
}

int __wrap_sem_post(sem_t* sem) {
  if (!sem) {
    errno = EINVAL;
    return -1;
  }
  auto* count = reinterpret_cast<int*>(sem);
  for (;;) {
    int cur = __c11_atomic_load(reinterpret_cast<_Atomic(int)*>(count),
                                __ATOMIC_RELAXED);
    if (cur >= SEM_VALUE_MAX) {
      errno = EOVERFLOW;
      return -1;
    }
    if (__c11_atomic_compare_exchange_weak(
            reinterpret_cast<_Atomic(int)*>(count), &cur, cur + 1,
            __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
      break;
    }
  }
  emscripten_atomic_notify(count, 1);
  return 0;
}

int __wrap_sem_trywait(sem_t* sem) {
  if (!sem) {
    errno = EINVAL;
    return -1;
  }
  auto* count = reinterpret_cast<int*>(sem);
  int cur = __c11_atomic_load(reinterpret_cast<_Atomic(int)*>(count),
                              __ATOMIC_RELAXED);
  while (cur > 0) {
    if (__c11_atomic_compare_exchange_weak(
            reinterpret_cast<_Atomic(int)*>(count), &cur, cur - 1,
            __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
      return 0;
    }
  }
  errno = EAGAIN;
  return -1;
}

int __wrap_sem_wait(sem_t* sem) {
  if (!sem) {
    errno = EINVAL;
    return -1;
  }
  auto* count = reinterpret_cast<int*>(sem);
  const bool can_block = emscripten_wasm_worker_self_id() != 0;
  for (;;) {
    int cur = __c11_atomic_load(reinterpret_cast<_Atomic(int)*>(count),
                                __ATOMIC_RELAXED);
    while (cur > 0) {
      if (__c11_atomic_compare_exchange_weak(
              reinterpret_cast<_Atomic(int)*>(count), &cur, cur - 1,
              __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
        return 0;
      }
    }
    if (can_block) {
      emscripten_atomic_wait_u32(count, 0, -1);
    }
  }
}

}  // extern "C"

#endif  // defined(__EMSCRIPTEN_WASM_WORKERS__)
