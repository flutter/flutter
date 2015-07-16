/*
 * The authors of this software are Rob Pike and Ken Thompson.
 *              Copyright (c) 2002 by Lucent Technologies.
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR, NEITHER THE AUTHORS NOR LUCENT TECHNOLOGIES MAKE ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
 * OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 *
 * This file and rune.cc have been converted to compile as C++ code
 * in name space re2.
 */
#ifndef RE2_UTIL_UTF_H__
#define RE2_UTIL_UTF_H__

#include <stdint.h>

namespace re2 {

typedef signed int Rune;	/* Code-point values in Unicode 4.0 are 21 bits wide.*/

enum
{
  UTFmax	= 4,		/* maximum bytes per rune */
  Runesync	= 0x80,		/* cannot represent part of a UTF sequence (<) */
  Runeself	= 0x80,		/* rune and UTF sequences are the same (<) */
  Runeerror	= 0xFFFD,	/* decoding error in UTF */
  Runemax	= 0x10FFFF,	/* maximum rune value */
};

int runetochar(char* s, const Rune* r);
int chartorune(Rune* r, const char* s);
int fullrune(const char* s, int n);
int utflen(const char* s);
char* utfrune(const char*, Rune);

}  // namespace re2

#endif  // RE2_UTIL_UTF_H__
