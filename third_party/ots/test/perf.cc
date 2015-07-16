// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <time.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "opentype-sanitiser.h"
#include "ots-memory-stream.h"

namespace {

int Usage(const char *argv0) {
  std::fprintf(stderr, "Usage: %s <ttf file>\n", argv0);
  return 1;
}

}  // namespace

int main(int argc, char **argv) {
  if (argc != 2) return Usage(argv[0]);

  const int fd = ::open(argv[1], O_RDONLY);
  if (fd < 0) {
    ::perror("open");
    return 1;
  }

  struct stat st;
  ::fstat(fd, &st);

  uint8_t *data = new uint8_t[st.st_size];
  if (::read(fd, data, st.st_size) != st.st_size) {
    std::fprintf(stderr, "Failed to read file!\n");
    return 1;
  }

  // A transcoded font is usually smaller than an original font.
  // However, it can be slightly bigger than the original one due to
  // name table replacement and/or padding for glyf table.
  static const size_t kPadLen = 20 * 1024;
  uint8_t *result = new uint8_t[st.st_size + kPadLen];

  int num_repeat = 250;
  if (st.st_size < 1024 * 1024) {
    num_repeat = 2500;
  }
  if (st.st_size < 1024 * 100) {
    num_repeat = 5000;
  }

  struct timeval start, end, elapsed;
  ::gettimeofday(&start, 0);
  for (int i = 0; i < num_repeat; ++i) {
    ots::MemoryStream output(result, st.st_size + kPadLen);
    ots::OTSContext context;
    bool r = context.Process(&output, data, st.st_size);
    if (!r) {
      std::fprintf(stderr, "Failed to sanitise file!\n");
      return 1;
    }
  }
  ::gettimeofday(&end, 0);
  timersub(&end, &start, &elapsed);

  long long unsigned us
      = ((elapsed.tv_sec * 1000 * 1000) + elapsed.tv_usec) / num_repeat;
  std::fprintf(stderr, "%llu [us] %s (%llu bytes, %llu [byte/us])\n",
               us, argv[1], static_cast<long long>(st.st_size),
               (us ? st.st_size / us : 0));

  return 0;
}
