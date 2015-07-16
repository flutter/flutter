// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_file_util.h"

#include "base/test/test_timeouts.h"
#include "base/threading/platform_thread.h"

namespace base {

bool EvictFileFromSystemCacheWithRetry(const FilePath& path) {
  const int kCycles = 10;
  const TimeDelta kDelay = TestTimeouts::action_timeout() / kCycles;
  for (int i = 0; i < kCycles; i++) {
    if (EvictFileFromSystemCache(path))
      return true;
    PlatformThread::Sleep(kDelay);
  }
  return false;
}

// Declared in base/files/file_path.h.
void PrintTo(const FilePath& path, std::ostream* out) {
  *out << path.value();
}

}  // namespace base
