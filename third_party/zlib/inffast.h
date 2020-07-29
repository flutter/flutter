/* inffast.h -- header to use inffast.c
 * Copyright (C) 1995-2003, 2010 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

/* WARNING: this file should *not* be used by applications. It is
   part of the implementation of the compression library and is
   subject to change. Applications should only use zlib.h.
 */

/* INFLATE_FAST_MIN_INPUT: the minimum number of input bytes needed so that
   we can safely call inflate_fast() with only one up-front bounds check. One
   length/distance code pair (15 bits for the length code, 5 bits for length
   extra, 15 bits for the distance code, 13 bits for distance extra) requires
   reading up to 48 input bits (6 bytes).
*/
#define INFLATE_FAST_MIN_INPUT 6

/* INFLATE_FAST_MIN_OUTPUT: the minimum number of output bytes needed so that
   we can safely call inflate_fast() with only one up-front bounds check. One
   length/distance code pair can output up to 258 bytes, which is the maximum
   length that can be coded.
 */
#define INFLATE_FAST_MIN_OUTPUT 258

void ZLIB_INTERNAL inflate_fast OF((z_streamp strm, unsigned start));
