/* Copyright 2018 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the Chromium source repository LICENSE file.
 */
#ifndef __SLIDE_HASH__NEON__
#define __SLIDE_HASH__NEON__

#include "deflate.h"
#include <arm_neon.h>

inline static void ZLIB_INTERNAL neon_slide_hash_update(Posf *hash,
                                                        const uInt hash_size,
                                                        const ush w_size)
{
   /* NEON 'Q' registers allow to store 128 bits, so we can load 8x16-bits
     * values. For further details, check:
     * ARM DHT 0002A, section 1.3.2 NEON Registers.
     */
    const size_t chunk = sizeof(uint16x8_t) / sizeof(uint16_t);
    /* Unrolling the operation yielded a compression performance boost in both
     * ARMv7 (from 11.7% to 13.4%) and ARMv8 (from 3.7% to 7.5%) for HTML4
     * content. For full benchmarking data, check: http://crbug.com/863257.
     */
    const size_t stride = 2*chunk;
    const uint16x8_t v = vdupq_n_u16(w_size);

    for (Posf *end = hash + hash_size; hash != end; hash += stride) {
        uint16x8_t m_low = vld1q_u16(hash);
        uint16x8_t m_high = vld1q_u16(hash + chunk);

        /* The first 'q' in vqsubq_u16 makes these subtracts saturate to zero,
         * replacing the ternary operator expression in the original code:
         * (m >= wsize ? m - wsize : NIL).
         */
        m_low = vqsubq_u16(m_low, v);
        m_high = vqsubq_u16(m_high, v);

        vst1q_u16(hash, m_low);
        vst1q_u16(hash + chunk, m_high);
    }
}


inline static void ZLIB_INTERNAL neon_slide_hash(Posf *head, Posf *prev,
                                                 const unsigned short w_size,
                                                 const uInt hash_size)
{
    /*
     * SIMD implementation for hash table rebase assumes:
     * 1. hash chain offset (Pos) is 2 bytes.
     * 2. hash table size is multiple of 32 bytes.
     * #1 should be true as Pos is defined as "ush"
     * #2 should be true as hash_bits are greater than 7
     */
    const size_t size = hash_size * sizeof(head[0]);
    Assert(sizeof(Pos) == 2, "Wrong Pos size.");
    Assert((size % sizeof(uint16x8_t) * 2) == 0, "Hash table size error.");

    neon_slide_hash_update(head, hash_size, w_size);
#ifndef FASTEST
    neon_slide_hash_update(prev, w_size, w_size);
#endif
}

#endif
