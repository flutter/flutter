// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_UNIQUE_FD_H_
#define FLUTTER_FML_UNIQUE_FD_H_

#include "flutter/fml/build_config.h"
#include "flutter/fml/unique_object.h"

#if OS_WIN

#include <windows.h>

#endif  // OS_WIN

namespace fml {
namespace internal {

#if OS_WIN

namespace win {

struct UniqueFDTraits {
  static HANDLE InvalidValue() { return INVALID_HANDLE_VALUE; }
  static bool IsValid(HANDLE value) { return value != InvalidValue(); }
  static void Free(HANDLE fd);
};

}  // namespace win

#else  // OS_WIN

namespace unix {

struct UniqueFDTraits {
  static int InvalidValue() { return -1; }
  static bool IsValid(int value) { return value >= 0; }
  static void Free(int fd);
};

}  // namespace unix

#endif  // OS_WIN

}  // namespace internal

#if OS_WIN

using UniqueFD = UniqueObject<HANDLE, internal::win::UniqueFDTraits>;

#else  // OS_WIN

using UniqueFD = UniqueObject<int, internal::unix::UniqueFDTraits>;

#endif  // OS_WIN

}  // namespace fml

#endif  // FLUTTER_FML_UNIQUE_FD_H_
