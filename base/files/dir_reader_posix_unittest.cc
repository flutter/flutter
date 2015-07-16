// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/dir_reader_posix.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "base/logging.h"
#include "testing/gtest/include/gtest/gtest.h"

#if defined(OS_ANDROID)
#include "base/os_compat_android.h"
#endif

namespace base {

TEST(DirReaderPosixUnittest, Read) {
  static const unsigned kNumFiles = 100;

  if (DirReaderPosix::IsFallback())
    return;

  char kDirTemplate[] = "/tmp/org.chromium.dir-reader-posix-XXXXXX";
  const char* dir = mkdtemp(kDirTemplate);
  ASSERT_TRUE(dir);

  const int prev_wd = open(".", O_RDONLY | O_DIRECTORY);
  DCHECK_GE(prev_wd, 0);

  PCHECK(chdir(dir) == 0);

  for (unsigned i = 0; i < kNumFiles; i++) {
    char buf[16];
    snprintf(buf, sizeof(buf), "%d", i);
    const int fd = open(buf, O_CREAT | O_RDONLY | O_EXCL, 0600);
    PCHECK(fd >= 0);
    PCHECK(close(fd) == 0);
  }

  std::set<unsigned> seen;

  DirReaderPosix reader(dir);
  EXPECT_TRUE(reader.IsValid());

  if (!reader.IsValid())
    return;

  bool seen_dot = false, seen_dotdot = false;

  for (; reader.Next(); ) {
    if (strcmp(reader.name(), ".") == 0) {
      seen_dot = true;
      continue;
    }
    if (strcmp(reader.name(), "..") == 0) {
      seen_dotdot = true;
      continue;
    }

    SCOPED_TRACE(testing::Message() << "reader.name(): " << reader.name());

    char *endptr;
    const unsigned long value = strtoul(reader.name(), &endptr, 10);

    EXPECT_FALSE(*endptr);
    EXPECT_LT(value, kNumFiles);
    EXPECT_EQ(0u, seen.count(value));
    seen.insert(value);
  }

  for (unsigned i = 0; i < kNumFiles; i++) {
    char buf[16];
    snprintf(buf, sizeof(buf), "%d", i);
    PCHECK(unlink(buf) == 0);
  }

  PCHECK(rmdir(dir) == 0);

  PCHECK(fchdir(prev_wd) == 0);
  PCHECK(close(prev_wd) == 0);

  EXPECT_TRUE(seen_dot);
  EXPECT_TRUE(seen_dotdot);
  EXPECT_EQ(kNumFiles, seen.size());
}

}  // namespace base
