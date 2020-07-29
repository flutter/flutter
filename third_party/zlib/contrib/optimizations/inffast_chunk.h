/* inffast_chunk.h -- header to use inffast_chunk.c
 * Copyright (C) 1995-2003, 2010 Mark Adler
 * Copyright (C) 2017 ARM, Inc.
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

/* WARNING: this file should *not* be used by applications. It is
   part of the implementation of the compression library and is
   subject to change. Applications should only use zlib.h.
 */

#include "inffast.h"

/* INFLATE_FAST_MIN_INPUT: the minimum number of input bytes needed so that
   we can safely call inflate_fast() with only one up-front bounds check. One
   length/distance code pair (15 bits for the length code, 5 bits for length
   extra, 15 bits for the distance code, 13 bits for distance extra) requires
   reading up to 48 input bits (6 bytes). The wide input data reading option
   requires a little endian machine, and reads 64 input bits (8 bytes).
*/
#ifdef INFLATE_CHUNK_READ_64LE
#undef INFLATE_FAST_MIN_INPUT
#define INFLATE_FAST_MIN_INPUT 8
#endif

void ZLIB_INTERNAL inflate_fast_chunk_ OF((z_streamp strm, unsigned start));
