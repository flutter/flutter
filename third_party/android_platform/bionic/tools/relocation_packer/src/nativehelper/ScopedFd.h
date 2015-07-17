/*
 * Copyright (C) 2009 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef SCOPED_FD_H_included
#define SCOPED_FD_H_included

#include <unistd.h>

// Local definition of DISALLOW_COPY_AND_ASSIGN, avoids depending on base.
#define DISALLOW_COPY_AND_ASSIGN(TypeName) \
  TypeName(const TypeName&);               \
  void operator=(const TypeName&)

// A smart pointer that closes the given fd on going out of scope.
// Use this when the fd is incidental to the purpose of your function,
// but needs to be cleaned up on exit.
class ScopedFd {
public:
    explicit ScopedFd(int fd) : fd_(fd) {
    }

    ~ScopedFd() {
      reset();
    }

    int get() const {
        return fd_;
    }

    int release() __attribute__((warn_unused_result)) {
        int localFd = fd_;
        fd_ = -1;
        return localFd;
    }

    void reset(int new_fd = -1) {
      if (fd_ != -1) {
          TEMP_FAILURE_RETRY(close(fd_));
      }
      fd_ = new_fd;
    }

private:
    int fd_;

    DISALLOW_COPY_AND_ASSIGN(ScopedFd);
};

#endif  // SCOPED_FD_H_included
