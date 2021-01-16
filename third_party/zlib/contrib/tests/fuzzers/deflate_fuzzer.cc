// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuzzer/FuzzedDataProvider.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vector>

#include "third_party/zlib/zlib.h"

// Fuzzer builds often have NDEBUG set, so roll our own assert macro.
#define ASSERT(cond)                                                           \
  do {                                                                         \
    if (!(cond)) {                                                             \
      fprintf(stderr, "%s:%d Assert failed: %s\n", __FILE__, __LINE__, #cond); \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  FuzzedDataProvider fdp(data, size);
  int level = fdp.PickValueInArray({0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
  int windowBits = fdp.PickValueInArray({9, 10, 11, 12, 13, 14, 15});
  int memLevel = fdp.PickValueInArray({1, 2, 3, 4, 5, 6, 7, 8, 9});
  int strategy = fdp.PickValueInArray(
      {Z_DEFAULT_STRATEGY, Z_FILTERED, Z_HUFFMAN_ONLY, Z_RLE, Z_FIXED});
  std::vector<uint8_t> src = fdp.ConsumeRemainingBytes<uint8_t>();

  z_stream stream;
  stream.zalloc = Z_NULL;
  stream.zfree = Z_NULL;

  // Compress the data one byte at a time to exercise the streaming code.
  int ret =
      deflateInit2(&stream, level, Z_DEFLATED, windowBits, memLevel, strategy);
  ASSERT(ret == Z_OK);
  std::vector<uint8_t> compressed(src.size() * 2 + 1000);
  stream.next_out = compressed.data();
  stream.avail_out = compressed.size();
  for (uint8_t b : src) {
    stream.next_in = &b;
    stream.avail_in = 1;
    ret = deflate(&stream, Z_NO_FLUSH);
    ASSERT(ret == Z_OK);
  }
  stream.next_in = Z_NULL;
  stream.avail_in = 0;
  ret = deflate(&stream, Z_FINISH);
  ASSERT(ret == Z_STREAM_END);
  compressed.resize(compressed.size() - stream.avail_out);
  deflateEnd(&stream);

  // Verify that the data decompresses correctly.
  ret = inflateInit2(&stream, windowBits);
  ASSERT(ret == Z_OK);
  // Make room for at least one byte so it's never empty.
  std::vector<uint8_t> decompressed(src.size() + 1);
  stream.next_in = compressed.data();
  stream.avail_in = compressed.size();
  stream.next_out = decompressed.data();
  stream.avail_out = decompressed.size();
  ret = inflate(&stream, Z_FINISH);
  ASSERT(ret == Z_STREAM_END);
  decompressed.resize(decompressed.size() - stream.avail_out);
  inflateEnd(&stream);

  ASSERT(decompressed == src);

  return 0;
}
