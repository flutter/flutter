// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/synchronization/semaphore.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"

#if OS_MACOSX
#include <dispatch/dispatch.h>

namespace flutter {

class PlatformSemaphore {
 public:
  explicit PlatformSemaphore(uint32_t count)
      : _sem(dispatch_semaphore_create(count)), _initial(count) {}

  ~PlatformSemaphore() {
    for (uint32_t i = 0; i < _initial; ++i) {
      Signal();
    }
    if (_sem != nullptr) {
      dispatch_release(reinterpret_cast<dispatch_object_t>(_sem));
      _sem = nullptr;
    }
  }

  bool IsValid() const { return _sem != nullptr; }

  bool TryWait() {
    if (_sem == nullptr) {
      return false;
    }

    return dispatch_semaphore_wait(_sem, DISPATCH_TIME_NOW) == 0;
  }

  void Signal() {
    if (_sem != nullptr) {
      dispatch_semaphore_signal(_sem);
    }
  }

 private:
  dispatch_semaphore_t _sem;
  const uint32_t _initial;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformSemaphore);
};

}  // namespace flutter

#elif OS_WIN
#include <windows.h>

namespace flutter {

class PlatformSemaphore {
 public:
  explicit PlatformSemaphore(uint32_t count)
      : _sem(CreateSemaphore(NULL, count, LONG_MAX, NULL)) {}

  ~PlatformSemaphore() {
    if (_sem != nullptr) {
      CloseHandle(_sem);
      _sem = nullptr;
    }
  }

  bool IsValid() const { return _sem != nullptr; }

  bool TryWait() {
    if (_sem == nullptr) {
      return false;
    }

    return WaitForSingleObject(_sem, 0) == WAIT_OBJECT_0;
  }

  void Signal() {
    if (_sem != nullptr) {
      ReleaseSemaphore(_sem, 1, NULL);
    }
  }

 private:
  HANDLE _sem;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformSemaphore);
};

}  // namespace flutter

#else
#include <semaphore.h>
#include "flutter/fml/eintr_wrapper.h"

namespace flutter {

class PlatformSemaphore {
 public:
  explicit PlatformSemaphore(uint32_t count)
      : valid_(::sem_init(&sem_, 0 /* not shared */, count) == 0) {}

  ~PlatformSemaphore() {
    if (valid_) {
      int result = ::sem_destroy(&sem_);
      // Can only be EINVAL which should not be possible since we checked for
      // validity.
      FML_DCHECK(result == 0);
    }
  }

  bool IsValid() const { return valid_; }

  bool TryWait() {
    if (!valid_) {
      return false;
    }

    return FML_HANDLE_EINTR(::sem_trywait(&sem_)) == 0;
  }

  void Signal() {
    if (!valid_) {
      return;
    }

    ::sem_post(&sem_);

    return;
  }

 private:
  bool valid_;
  sem_t sem_;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformSemaphore);
};

}  // namespace flutter

#endif

namespace flutter {

Semaphore::Semaphore(uint32_t count) : _impl(new PlatformSemaphore(count)) {}

Semaphore::~Semaphore() = default;

bool Semaphore::IsValid() const {
  return _impl->IsValid();
}

bool Semaphore::TryWait() {
  return _impl->TryWait();
}

void Semaphore::Signal() {
  return _impl->Signal();
}

}  // namespace flutter
