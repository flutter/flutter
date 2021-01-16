// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "third_party/zlib/zlib.h"

// Fuzzer builds often have NDEBUG set, so roll our own assert macro.
#define ASSERT(cond)                                                           \
  do {                                                                         \
    if (!(cond)) {                                                             \
      fprintf(stderr, "%s:%d Assert failed: %s\n", __FILE__, __LINE__, #cond); \
      exit(1);                                                                 \
    }                                                                          \
  } while (0)

// Entry point for LibFuzzer.
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  // Deflate data.
  z_stream comp_strm;
  comp_strm.zalloc = Z_NULL;
  comp_strm.zfree = Z_NULL;
  comp_strm.opaque = Z_NULL;
  int ret = deflateInit(&comp_strm, Z_DEFAULT_COMPRESSION);
  ASSERT(ret == Z_OK);

  size_t comp_buf_cap = deflateBound(&comp_strm, size);
  uint8_t* comp_buf = (uint8_t*)malloc(comp_buf_cap);
  ASSERT(comp_buf != nullptr);
  comp_strm.next_out = comp_buf;
  comp_strm.avail_out = comp_buf_cap;
  comp_strm.next_in = (unsigned char*)data;
  comp_strm.avail_in = size;
  ret = deflate(&comp_strm, Z_FINISH);
  ASSERT(ret == Z_STREAM_END);
  size_t comp_sz = comp_buf_cap - comp_strm.avail_out;

  // Inflate comp_buf one chunk at a time.
  z_stream decomp_strm;
  decomp_strm.zalloc = Z_NULL;
  decomp_strm.zfree = Z_NULL;
  decomp_strm.opaque = Z_NULL;
  ret = inflateInit(&decomp_strm);
  ASSERT(ret == Z_OK);
  decomp_strm.next_in = comp_buf;
  decomp_strm.avail_in = comp_sz;

  while (decomp_strm.avail_in > 0) {
    uint8_t decomp_buf[1024];
    decomp_strm.next_out = decomp_buf;
    decomp_strm.avail_out = sizeof(decomp_buf);
    ret = inflate(&decomp_strm, Z_FINISH);
    ASSERT(ret == Z_OK || ret == Z_STREAM_END || ret == Z_BUF_ERROR);

    // Verify the output bytes.
    size_t num_out = sizeof(decomp_buf) - decomp_strm.avail_out;
    for (size_t i = 0; i < num_out; i++) {
      ASSERT(decomp_buf[i] == data[decomp_strm.total_out - num_out + i]);
    }
  }

  ret = deflateEnd(&comp_strm);
  ASSERT(ret == Z_OK);
  free(comp_buf);

  inflateEnd(&decomp_strm);
  ASSERT(ret == Z_OK);

  return 0;
}
