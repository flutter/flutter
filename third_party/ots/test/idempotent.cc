// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if !defined(_WIN32)
#ifdef __linux__
// Linux
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_OUTLINE_H
#else
// Mac OS X
#include <ApplicationServices/ApplicationServices.h>  // g++ -framework Cocoa
#endif  // __linux__
#include <unistd.h>
#else
// Windows
#include <io.h>
#include <Windows.h>
#endif  // !defiend(_WIN32)

#include <fcntl.h>
#include <sys/stat.h>

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

bool ReadFile(const char *file_name, uint8_t **data, size_t *file_size);
bool DumpResults(const uint8_t *result1, const size_t len1,
                 const uint8_t *result2, const size_t len2);

#if defined(_WIN32)
#define ADDITIONAL_OPEN_FLAGS O_BINARY
#else
#define ADDITIONAL_OPEN_FLAGS 0
#endif

bool ReadFile(const char *file_name, uint8_t **data, size_t *file_size) {
  const int fd = open(file_name, O_RDONLY | ADDITIONAL_OPEN_FLAGS);
  if (fd < 0) {
    return false;
  }

  struct stat st;
  fstat(fd, &st);

  *file_size = st.st_size;
  *data = new uint8_t[st.st_size];
  if (read(fd, *data, st.st_size) != st.st_size) {
    close(fd);
    return false;
  }
  close(fd);
  return true;
}

bool DumpResults(const uint8_t *result1, const size_t len1,
                 const uint8_t *result2, const size_t len2) {
  int fd1 = open("out1.ttf",
                 O_WRONLY | O_CREAT | O_TRUNC | ADDITIONAL_OPEN_FLAGS, 0600);
  int fd2 = open("out2.ttf",
                 O_WRONLY | O_CREAT | O_TRUNC | ADDITIONAL_OPEN_FLAGS, 0600);
  if (fd1 < 0 || fd2 < 0) {
    perror("opening output file");
    return false;
  }
  if ((write(fd1, result1, len1) < 0) ||
      (write(fd2, result2, len2) < 0)) {
    perror("writing output file");
    close(fd1);
    close(fd2);
    return false;
  }
  close(fd1);
  close(fd2);
  return true;
}

// Platform specific implementations.
bool VerifyTranscodedFont(uint8_t *result, const size_t len);

#if defined(__linux__)
// Linux
bool VerifyTranscodedFont(uint8_t *result, const size_t len) {
  FT_Library library;
  FT_Error error = ::FT_Init_FreeType(&library);
  if (error) {
    return false;
  }
  FT_Face dummy;
  error = ::FT_New_Memory_Face(library, result, len, 0, &dummy);
  if (error) {
    return false;
  }
  ::FT_Done_Face(dummy);
  return true;
}

#elif defined(__APPLE_CC__)
// Mac
bool VerifyTranscodedFont(uint8_t *result, const size_t len) {
  CFDataRef data = CFDataCreate(0, result, len);
  if (!data) {
    return false;
  }

  CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(data);
  CGFontRef cgFontRef = CGFontCreateWithDataProvider(dataProvider);
  CGDataProviderRelease(dataProvider);
  CFRelease(data);
  if (!cgFontRef) {
    return false;
  }

  size_t numGlyphs = CGFontGetNumberOfGlyphs(cgFontRef);
  CGFontRelease(cgFontRef);
  if (!numGlyphs) {
    return false;
  }
  return true;
}

#elif defined(_WIN32)
// Windows
bool VerifyTranscodedFont(uint8_t *result, const size_t len) {
  DWORD num_fonts = 0;
  HANDLE handle = AddFontMemResourceEx(result, len, 0, &num_fonts);
  if (!handle) {
    return false;
  }
  RemoveFontMemResourceEx(handle);
  return true;
}

#else
bool VerifyTranscodedFont(uint8_t *result, const size_t len) {
  std::fprintf(stderr, "Can't verify the transcoded font on this platform.\n");
  return false;
}

#endif

}  // namespace

int main(int argc, char **argv) {
  if (argc != 2) return Usage(argv[0]);

  size_t file_size = 0;
  uint8_t *data = 0;
  if (!ReadFile(argv[1], &data, &file_size)) {
    std::fprintf(stderr, "Failed to read file!\n");
    return 1;
  }

  // A transcoded font is usually smaller than an original font.
  // However, it can be slightly bigger than the original one due to
  // name table replacement and/or padding for glyf table.
  //
  // However, a WOFF font gets decompressed and so can be *much* larger than
  // the original.
  uint8_t *result = new uint8_t[file_size * 8];
  ots::MemoryStream output(result, file_size * 8);

  ots::OTSContext context;

  bool r = context.Process(&output, data, file_size);
  if (!r) {
    std::fprintf(stderr, "Failed to sanitise file!\n");
    return 1;
  }
  const size_t result_len = output.Tell();
  delete[] data;

  uint8_t *result2 = new uint8_t[result_len];
  ots::MemoryStream output2(result2, result_len);
  r = context.Process(&output2, result, result_len);
  if (!r) {
    std::fprintf(stderr, "Failed to sanitise previous output!\n");
    return 1;
  }
  const size_t result2_len = output2.Tell();

  bool dump_results = false;
  if (result2_len != result_len) {
    std::fprintf(stderr, "Outputs differ in length\n");
    dump_results = true;
  } else if (std::memcmp(result2, result, result_len)) {
    std::fprintf(stderr, "Outputs differ in content\n");
    dump_results = true;
  }

  if (dump_results) {
    std::fprintf(stderr, "Dumping results to out1.tff and out2.tff\n");
    if (!DumpResults(result, result_len, result2, result2_len)) {
      std::fprintf(stderr, "Failed to dump output files.\n");
      return 1;
    }
  }

  // Verify that the transcoded font can be opened by the font renderer for
  // Linux (FreeType2), Mac OS X, or Windows.
  if (!VerifyTranscodedFont(result, result_len)) {
    std::fprintf(stderr, "Failed to verify the transcoded font\n");
    return 1;
  }

  return 0;
}
