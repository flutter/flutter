// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A very simple driver program while sanitises the file given as argv[1] and
// writes the sanitised version to stdout.

#include <fcntl.h>
#include <sys/stat.h>
#if defined(_WIN32)
#include <io.h>
#else
#include <unistd.h>
#endif  // defined(_WIN32)

#include <cstdarg>
#include <cstdio>
#include <cstdlib>

#include "file-stream.h"
#include "opentype-sanitiser.h"

#if defined(_WIN32)
#define ADDITIONAL_OPEN_FLAGS O_BINARY
#else
#define ADDITIONAL_OPEN_FLAGS 0
#endif

namespace {

int Usage(const char *argv0) {
  std::fprintf(stderr, "Usage: %s ttf_file [dest_ttf_file]\n", argv0);
  return 1;
}

class Context: public ots::OTSContext {
 public:
  virtual void Message(int level, const char *format, ...) {
    va_list va;

    if (level == 0)
      std::fprintf(stderr, "ERROR: ");
    else
      std::fprintf(stderr, "WARNING: ");
    va_start(va, format);
    std::vfprintf(stderr, format, va);
    std::fprintf(stderr, "\n");
    va_end(va);
  }

  virtual ots::TableAction GetTableAction(uint32_t tag) {
#define TAG(a, b, c, d) ((a) << 24 | (b) << 16 | (c) << 8 | (d))
    switch (tag) {
      case TAG('S','i','l','f'):
      case TAG('S','i','l','l'):
      case TAG('G','l','o','c'):
      case TAG('G','l','a','t'):
      case TAG('F','e','a','t'):
        return ots::TABLE_ACTION_PASSTHRU;
      default:
        return ots::TABLE_ACTION_DEFAULT;
    }
#undef TAG
  }
};

}  // namespace

int main(int argc, char **argv) {
  if (argc < 2 || argc > 3) return Usage(argv[0]);

  const int fd = ::open(argv[1], O_RDONLY | ADDITIONAL_OPEN_FLAGS);
  if (fd < 0) {
    ::perror("open");
    return 1;
  }

  struct stat st;
  ::fstat(fd, &st);

  uint8_t *data = new uint8_t[st.st_size];
  if (::read(fd, data, st.st_size) != st.st_size) {
    ::perror("read");
    return 1;
  }
  ::close(fd);

  Context context;

  FILE* out = NULL;
  if (argc == 3)
    out = fopen(argv[2], "wb");

  ots::FILEStream output(out);
  const bool result = context.Process(&output, data, st.st_size);

  if (!result) {
    std::fprintf(stderr, "Failed to sanitise file!\n");
  }
  return !result;
}
