// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_FLAGS_H_
#define LIB_VFS_CPP_FLAGS_H_

#include <fuchsia/io/cpp/fidl.h>

namespace vfs {

class Flags {
 public:
  Flags() = delete;

  static bool IsReadable(uint32_t flags) {
    return (flags & fuchsia::io::OPEN_RIGHT_READABLE) != 0;
  }

  static bool IsWritable(uint32_t flags) {
    return (flags & fuchsia::io::OPEN_RIGHT_WRITABLE) != 0;
  }

  static bool IsDirectory(uint32_t flags) {
    return (flags & fuchsia::io::OPEN_FLAG_DIRECTORY) != 0;
  }

  static bool ShouldDescribe(uint32_t flags) {
    return (flags & fuchsia::io::OPEN_FLAG_DESCRIBE) != 0;
  }

  static bool IsPathOnly(uint32_t flags) {
    return (flags & fuchsia::io::OPEN_FLAG_NODE_REFERENCE) != 0;
  }
};

}  // namespace vfs

#endif  // LIB_VFS_CPP_FLAGS_H_
