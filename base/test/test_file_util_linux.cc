// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_file_util.h"

#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/files/file_path.h"
#include "base/files/scoped_file.h"

namespace base {

bool EvictFileFromSystemCache(const FilePath& file) {
  ScopedFD fd(open(file.value().c_str(), O_RDONLY));
  if (!fd.is_valid())
    return false;
  if (fdatasync(fd.get()) != 0)
    return false;
  if (posix_fadvise(fd.get(), 0, 0, POSIX_FADV_DONTNEED) != 0)
    return false;
  return true;
}

}  // namespace base
