// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_TONIC_DART_WRAPPER_INFO_H_
#define LIB_TONIC_DART_WRAPPER_INFO_H_

#include <cstddef>

namespace tonic {
class DartWrappable;

typedef void (*DartWrappableAccepter)(DartWrappable*);

struct DartWrapperInfo {
  const char* library_name;
  const char* interface_name;
  const size_t size_in_bytes;

 private:
  DartWrapperInfo(const DartWrapperInfo&) = delete;
  DartWrapperInfo& operator=(const DartWrapperInfo&) = delete;
};

}  // namespace tonic

#endif  // LIB_TONIC_DART_WRAPPER_INFO_H_
