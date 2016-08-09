/* simd_stub.c -- stub implementations
* Copyright (C) 2014 Intel Corporation
* For conditions of distribution and use, see copyright notice in zlib.h
*/
#include <assert.h>

#include "deflate.h"
#include "x86.h"

int x86_cpu_enable_simd = 0;

void ZLIB_INTERNAL crc_fold_init(deflate_state *const s) {
    assert(0);
}

void ZLIB_INTERNAL crc_fold_copy(deflate_state *const s,
                                 unsigned char *dst,
                                 const unsigned char *src,
                                 long len) {
    assert(0);
}

unsigned ZLIB_INTERNAL crc_fold_512to32(deflate_state *const s) {
    assert(0);
    return 0;
}

void ZLIB_INTERNAL fill_window_sse(deflate_state *s)
{
    assert(0);
}

void x86_check_features(void)
{
}
