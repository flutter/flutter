// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_FILES_DIR_READER_FALLBACK_H_
#define BASE_FILES_DIR_READER_FALLBACK_H_

namespace base {

class DirReaderFallback {
 public:
  // Open a directory. If |IsValid| is true, then |Next| can be called to start
  // the iteration at the beginning of the directory.
  explicit DirReaderFallback(const char* directory_path) {}

  // After construction, IsValid returns true iff the directory was
  // successfully opened.
  bool IsValid() const { return false; }

  // Move to the next entry returning false if the iteration is complete.
  bool Next() { return false; }

  // Return the name of the current directory entry.
  const char* name() { return 0;}

  // Return the file descriptor which is being used.
  int fd() const { return -1; }

  // Returns true if this is a no-op fallback class (for testing).
  static bool IsFallback() { return true; }
};

}  // namespace base

#endif  // BASE_FILES_DIR_READER_FALLBACK_H_
