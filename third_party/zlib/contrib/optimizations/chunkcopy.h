/* chunkcopy.h -- fast chunk copy and set operations
 * Copyright (C) 2017 ARM, Inc.
 * Copyright 2017 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the Chromium source repository LICENSE file.
 */

#ifndef CHUNKCOPY_H
#define CHUNKCOPY_H

#include <stdint.h>
#include "zutil.h"

#define Z_STATIC_ASSERT(name, assert) typedef char name[(assert) ? 1 : -1]

#if __STDC_VERSION__ >= 199901L
#define Z_RESTRICT restrict
#else
#define Z_RESTRICT
#endif

#if defined(__clang__) || defined(__GNUC__) || defined(__llvm__)
#define Z_BUILTIN_MEMCPY __builtin_memcpy
#else
#define Z_BUILTIN_MEMCPY zmemcpy
#endif

#if defined(INFLATE_CHUNK_SIMD_NEON)
#include <arm_neon.h>
typedef uint8x16_t z_vec128i_t;
#elif defined(INFLATE_CHUNK_SIMD_SSE2)
#include <emmintrin.h>
typedef __m128i z_vec128i_t;
#else
#error chunkcopy.h inflate chunk SIMD is not defined for your build target
#endif

/*
 * chunk copy type: the z_vec128i_t type size should be exactly 128-bits
 * and equal to CHUNKCOPY_CHUNK_SIZE.
 */
#define CHUNKCOPY_CHUNK_SIZE sizeof(z_vec128i_t)

Z_STATIC_ASSERT(vector_128_bits_wide,
                CHUNKCOPY_CHUNK_SIZE == sizeof(int8_t) * 16);

/*
 * Ask the compiler to perform a wide, unaligned load with a machine
 * instruction appropriate for the z_vec128i_t type.
 */
static inline z_vec128i_t loadchunk(
    const unsigned char FAR* s) {
  z_vec128i_t v;
  Z_BUILTIN_MEMCPY(&v, s, sizeof(v));
  return v;
}

/*
 * Ask the compiler to perform a wide, unaligned store with a machine
 * instruction appropriate for the z_vec128i_t type.
 */
static inline void storechunk(
    unsigned char FAR* d,
    const z_vec128i_t v) {
  Z_BUILTIN_MEMCPY(d, &v, sizeof(v));
}

/*
 * Perform a memcpy-like operation, assuming that length is non-zero and that
 * it's OK to overwrite at least CHUNKCOPY_CHUNK_SIZE bytes of output even if
 * the length is shorter than this.
 *
 * It also guarantees that it will properly unroll the data if the distance
 * between `out` and `from` is at least CHUNKCOPY_CHUNK_SIZE, which we rely on
 * in chunkcopy_relaxed().
 *
 * Aside from better memory bus utilisation, this means that short copies
 * (CHUNKCOPY_CHUNK_SIZE bytes or fewer) will fall straight through the loop
 * without iteration, which will hopefully make the branch prediction more
 * reliable.
 */
static inline unsigned char FAR* chunkcopy_core(
    unsigned char FAR* out,
    const unsigned char FAR* from,
    unsigned len) {
  const int bump = (--len % CHUNKCOPY_CHUNK_SIZE) + 1;
  storechunk(out, loadchunk(from));
  out += bump;
  from += bump;
  len /= CHUNKCOPY_CHUNK_SIZE;
  while (len-- > 0) {
    storechunk(out, loadchunk(from));
    out += CHUNKCOPY_CHUNK_SIZE;
    from += CHUNKCOPY_CHUNK_SIZE;
  }
  return out;
}

/*
 * Like chunkcopy_core(), but avoid writing beyond of legal output.
 *
 * Accepts an additional pointer to the end of safe output.  A generic safe
 * copy would use (out + len), but it's normally the case that the end of the
 * output buffer is beyond the end of the current copy, and this can still be
 * exploited.
 */
static inline unsigned char FAR* chunkcopy_core_safe(
    unsigned char FAR* out,
    const unsigned char FAR* from,
    unsigned len,
    unsigned char FAR* limit) {
  Assert(out + len <= limit, "chunk copy exceeds safety limit");
  if ((limit - out) < (ptrdiff_t)CHUNKCOPY_CHUNK_SIZE) {
    const unsigned char FAR* Z_RESTRICT rfrom = from;
    Assert((uintptr_t)out - (uintptr_t)from >= len,
           "invalid restrict in chunkcopy_core_safe");
    Assert((uintptr_t)from - (uintptr_t)out >= len,
           "invalid restrict in chunkcopy_core_safe");
    if (len & 8) {
      Z_BUILTIN_MEMCPY(out, rfrom, 8);
      out += 8;
      rfrom += 8;
    }
    if (len & 4) {
      Z_BUILTIN_MEMCPY(out, rfrom, 4);
      out += 4;
      rfrom += 4;
    }
    if (len & 2) {
      Z_BUILTIN_MEMCPY(out, rfrom, 2);
      out += 2;
      rfrom += 2;
    }
    if (len & 1) {
      *out++ = *rfrom++;
    }
    return out;
  }
  return chunkcopy_core(out, from, len);
}

/*
 * Perform short copies until distance can be rewritten as being at least
 * CHUNKCOPY_CHUNK_SIZE.
 *
 * Assumes it's OK to overwrite at least the first 2*CHUNKCOPY_CHUNK_SIZE
 * bytes of output even if the copy is shorter than this.  This assumption
 * holds within zlib inflate_fast(), which starts every iteration with at
 * least 258 bytes of output space available (258 being the maximum length
 * output from a single token; see inffast.c).
 */
static inline unsigned char FAR* chunkunroll_relaxed(
    unsigned char FAR* out,
    unsigned FAR* dist,
    unsigned FAR* len) {
  const unsigned char FAR* from = out - *dist;
  while (*dist < *len && *dist < CHUNKCOPY_CHUNK_SIZE) {
    storechunk(out, loadchunk(from));
    out += *dist;
    *len -= *dist;
    *dist += *dist;
  }
  return out;
}

#if defined(INFLATE_CHUNK_SIMD_NEON)
/*
 * v_load64_dup(): load *src as an unaligned 64-bit int and duplicate it in
 * every 64-bit component of the 128-bit result (64-bit int splat).
 */
static inline z_vec128i_t v_load64_dup(const void* src) {
  return vcombine_u8(vld1_u8(src), vld1_u8(src));
}

/*
 * v_load32_dup(): load *src as an unaligned 32-bit int and duplicate it in
 * every 32-bit component of the 128-bit result (32-bit int splat).
 */
static inline z_vec128i_t v_load32_dup(const void* src) {
  int32_t i32;
  Z_BUILTIN_MEMCPY(&i32, src, sizeof(i32));
  return vreinterpretq_u8_s32(vdupq_n_s32(i32));
}

/*
 * v_load16_dup(): load *src as an unaligned 16-bit int and duplicate it in
 * every 16-bit component of the 128-bit result (16-bit int splat).
 */
static inline z_vec128i_t v_load16_dup(const void* src) {
  int16_t i16;
  Z_BUILTIN_MEMCPY(&i16, src, sizeof(i16));
  return vreinterpretq_u8_s16(vdupq_n_s16(i16));
}

/*
 * v_load8_dup(): load the 8-bit int *src and duplicate it in every 8-bit
 * component of the 128-bit result (8-bit int splat).
 */
static inline z_vec128i_t v_load8_dup(const void* src) {
  return vld1q_dup_u8((const uint8_t*)src);
}

/*
 * v_store_128(): store the 128-bit vec in a memory destination (that might
 * not be 16-byte aligned) void* out.
 */
static inline void v_store_128(void* out, const z_vec128i_t vec) {
  vst1q_u8(out, vec);
}

#elif defined(INFLATE_CHUNK_SIMD_SSE2)
/*
 * v_load64_dup(): load *src as an unaligned 64-bit int and duplicate it in
 * every 64-bit component of the 128-bit result (64-bit int splat).
 */
static inline z_vec128i_t v_load64_dup(const void* src) {
  int64_t i64;
  Z_BUILTIN_MEMCPY(&i64, src, sizeof(i64));
  return _mm_set1_epi64x(i64);
}

/*
 * v_load32_dup(): load *src as an unaligned 32-bit int and duplicate it in
 * every 32-bit component of the 128-bit result (32-bit int splat).
 */
static inline z_vec128i_t v_load32_dup(const void* src) {
  int32_t i32;
  Z_BUILTIN_MEMCPY(&i32, src, sizeof(i32));
  return _mm_set1_epi32(i32);
}

/*
 * v_load16_dup(): load *src as an unaligned 16-bit int and duplicate it in
 * every 16-bit component of the 128-bit result (16-bit int splat).
 */
static inline z_vec128i_t v_load16_dup(const void* src) {
  int16_t i16;
  Z_BUILTIN_MEMCPY(&i16, src, sizeof(i16));
  return _mm_set1_epi16(i16);
}

/*
 * v_load8_dup(): load the 8-bit int *src and duplicate it in every 8-bit
 * component of the 128-bit result (8-bit int splat).
 */
static inline z_vec128i_t v_load8_dup(const void* src) {
  return _mm_set1_epi8(*(const char*)src);
}

/*
 * v_store_128(): store the 128-bit vec in a memory destination (that might
 * not be 16-byte aligned) void* out.
 */
static inline void v_store_128(void* out, const z_vec128i_t vec) {
  _mm_storeu_si128((__m128i*)out, vec);
}
#endif

/*
 * Perform an overlapping copy which behaves as a memset() operation, but
 * supporting periods other than one, and assume that length is non-zero and
 * that it's OK to overwrite at least CHUNKCOPY_CHUNK_SIZE*3 bytes of output
 * even if the length is shorter than this.
 */
static inline unsigned char FAR* chunkset_core(
    unsigned char FAR* out,
    unsigned period,
    unsigned len) {
  z_vec128i_t v;
  const int bump = ((len - 1) % sizeof(v)) + 1;

  switch (period) {
    case 1:
      v = v_load8_dup(out - 1);
      v_store_128(out, v);
      out += bump;
      len -= bump;
      while (len > 0) {
        v_store_128(out, v);
        out += sizeof(v);
        len -= sizeof(v);
      }
      return out;
    case 2:
      v = v_load16_dup(out - 2);
      v_store_128(out, v);
      out += bump;
      len -= bump;
      if (len > 0) {
        v = v_load16_dup(out - 2);
        do {
          v_store_128(out, v);
          out += sizeof(v);
          len -= sizeof(v);
        } while (len > 0);
      }
      return out;
    case 4:
      v = v_load32_dup(out - 4);
      v_store_128(out, v);
      out += bump;
      len -= bump;
      if (len > 0) {
        v = v_load32_dup(out - 4);
        do {
          v_store_128(out, v);
          out += sizeof(v);
          len -= sizeof(v);
        } while (len > 0);
      }
      return out;
    case 8:
      v = v_load64_dup(out - 8);
      v_store_128(out, v);
      out += bump;
      len -= bump;
      if (len > 0) {
        v = v_load64_dup(out - 8);
        do {
          v_store_128(out, v);
          out += sizeof(v);
          len -= sizeof(v);
        } while (len > 0);
      }
      return out;
  }
  out = chunkunroll_relaxed(out, &period, &len);
  return chunkcopy_core(out, out - period, len);
}

/*
 * Perform a memcpy-like operation, but assume that length is non-zero and that
 * it's OK to overwrite at least CHUNKCOPY_CHUNK_SIZE bytes of output even if
 * the length is shorter than this.
 *
 * Unlike chunkcopy_core() above, no guarantee is made regarding the behaviour
 * of overlapping buffers, regardless of the distance between the pointers.
 * This is reflected in the `restrict`-qualified pointers, allowing the
 * compiler to re-order loads and stores.
 */
static inline unsigned char FAR* chunkcopy_relaxed(
    unsigned char FAR* Z_RESTRICT out,
    const unsigned char FAR* Z_RESTRICT from,
    unsigned len) {
  Assert((uintptr_t)out - (uintptr_t)from >= len,
         "invalid restrict in chunkcopy_relaxed");
  Assert((uintptr_t)from - (uintptr_t)out >= len,
         "invalid restrict in chunkcopy_relaxed");
  return chunkcopy_core(out, from, len);
}

/*
 * Like chunkcopy_relaxed(), but avoid writing beyond of legal output.
 *
 * Unlike chunkcopy_core_safe() above, no guarantee is made regarding the
 * behaviour of overlapping buffers, regardless of the distance between the
 * pointers.  This is reflected in the `restrict`-qualified pointers, allowing
 * the compiler to re-order loads and stores.
 *
 * Accepts an additional pointer to the end of safe output.  A generic safe
 * copy would use (out + len), but it's normally the case that the end of the
 * output buffer is beyond the end of the current copy, and this can still be
 * exploited.
 */
static inline unsigned char FAR* chunkcopy_safe(
    unsigned char FAR* out,
    const unsigned char FAR* Z_RESTRICT from,
    unsigned len,
    unsigned char FAR* limit) {
  Assert(out + len <= limit, "chunk copy exceeds safety limit");
  Assert((uintptr_t)out - (uintptr_t)from >= len,
         "invalid restrict in chunkcopy_safe");
  Assert((uintptr_t)from - (uintptr_t)out >= len,
         "invalid restrict in chunkcopy_safe");

  return chunkcopy_core_safe(out, from, len, limit);
}

/*
 * Perform chunky copy within the same buffer, where the source and destination
 * may potentially overlap.
 *
 * Assumes that len > 0 on entry, and that it's safe to write at least
 * CHUNKCOPY_CHUNK_SIZE*3 bytes to the output.
 */
static inline unsigned char FAR* chunkcopy_lapped_relaxed(
    unsigned char FAR* out,
    unsigned dist,
    unsigned len) {
  if (dist < len && dist < CHUNKCOPY_CHUNK_SIZE) {
    return chunkset_core(out, dist, len);
  }
  return chunkcopy_core(out, out - dist, len);
}

/*
 * Behave like chunkcopy_lapped_relaxed(), but avoid writing beyond of legal
 * output.
 *
 * Accepts an additional pointer to the end of safe output.  A generic safe
 * copy would use (out + len), but it's normally the case that the end of the
 * output buffer is beyond the end of the current copy, and this can still be
 * exploited.
 */
static inline unsigned char FAR* chunkcopy_lapped_safe(
    unsigned char FAR* out,
    unsigned dist,
    unsigned len,
    unsigned char FAR* limit) {
  Assert(out + len <= limit, "chunk copy exceeds safety limit");
  if ((limit - out) < (ptrdiff_t)(3 * CHUNKCOPY_CHUNK_SIZE)) {
    /* TODO(cavalcantii): try harder to optimise this */
    while (len-- > 0) {
      *out = *(out - dist);
      out++;
    }
    return out;
  }
  return chunkcopy_lapped_relaxed(out, dist, len);
}

/* TODO(cavalcanti): see crbug.com/1110083. */
static inline unsigned char FAR* chunkcopy_safe_ugly(unsigned char FAR* out,
                                                     unsigned dist,
                                                     unsigned len,
                                                     unsigned char FAR* limit) {
#if defined(__GNUC__) && !defined(__clang__)
  /* Speed is the same as using chunkcopy_safe
     w/ GCC on ARM (tested gcc 6.3 and 7.5) and avoids
     undefined behavior.
  */
  return chunkcopy_core_safe(out, out - dist, len, limit);
#elif defined(__clang__) && defined(ARMV8_OS_ANDROID) && !defined(__aarch64__)
  /* Seems to perform better on 32bit (i.e. Android). */
  return chunkcopy_core_safe(out, out - dist, len, limit);
#else
  /* Seems to perform better on 64bit. */
  return chunkcopy_lapped_safe(out, dist, len, limit);
#endif
}

/*
 * The chunk-copy code above deals with writing the decoded DEFLATE data to
 * the output with SIMD methods to increase decode speed. Reading the input
 * to the DEFLATE decoder with a wide, SIMD method can also increase decode
 * speed. This option is supported on little endian machines, and reads the
 * input data in 64-bit (8 byte) chunks.
 */

#ifdef INFLATE_CHUNK_READ_64LE
/*
 * Buffer the input in a uint64_t (8 bytes) in the wide input reading case.
 */
typedef uint64_t inflate_holder_t;

/*
 * Ask the compiler to perform a wide, unaligned load of a uint64_t using a
 * machine instruction appropriate for the uint64_t type.
 */
static inline inflate_holder_t read64le(const unsigned char FAR *in) {
    inflate_holder_t input;
    Z_BUILTIN_MEMCPY(&input, in, sizeof(input));
    return input;
}
#else
/*
 * Otherwise, buffer the input bits using zlib's default input buffer type.
 */
typedef unsigned long inflate_holder_t;

#endif /* INFLATE_CHUNK_READ_64LE */

#undef Z_STATIC_ASSERT
#undef Z_RESTRICT
#undef Z_BUILTIN_MEMCPY

#endif /* CHUNKCOPY_H */
