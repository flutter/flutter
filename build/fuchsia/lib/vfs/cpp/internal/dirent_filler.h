// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_VFS_CPP_INTERNAL_DIRENT_FILLER_H_
#define LIB_VFS_CPP_INTERNAL_DIRENT_FILLER_H_

#include <stdint.h>
#include <zircon/types.h>

#include <string>

namespace vfs {
namespace internal {

// Helper class used to fill direntries during calls to Readdir.
class DirentFiller {
 public:
  DirentFiller(const DirentFiller&) = delete;
  DirentFiller& operator=(const DirentFiller&) = delete;

  DirentFiller(void* ptr, uint64_t len);

  // Attempts to add the name to the end of the dirent buffer
  // which is returned by readdir.
  // Will not write anything incase of error.
  zx_status_t Next(const std::string& name, uint8_t type, uint64_t ino);

  // Attempts to add the name to the end of the dirent buffer
  // which is returned by readdir.
  // Will not write anything incase of error.
  zx_status_t Next(const char* name, size_t name_len, uint8_t type,
                   uint64_t ino);

  uint64_t GetBytesFilled() const { return pos_; }

 private:
  char* ptr_;
  uint64_t pos_;
  const uint64_t len_;
};

}  // namespace internal
}  // namespace vfs

#endif  // LIB_VFS_CPP_INTERNAL_DIRENT_FILLER_H_
