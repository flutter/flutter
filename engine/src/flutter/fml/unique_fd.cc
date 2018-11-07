// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/unique_fd.h"

#include "flutter/fml/eintr_wrapper.h"

namespace fml {
namespace internal {

#if OS_WIN

namespace os_win {

void UniqueFDTraits::Free(HANDLE fd) {
  CloseHandle(fd);
}

}  // namespace os_win

#else  // OS_WIN

namespace os_unix {

void UniqueFDTraits::Free(int fd) {
  close(fd);
}

}  // namespace os_unix

#endif  // OS_WIN

}  // namespace internal
}  // namespace fml
