// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Unicode case folding tables.

// The Unicode case folding tables encode the mapping from one Unicode point
// to the next largest Unicode point with equivalent folding.  The largest
// point wraps back to the first.  For example, the tables map:
//
//     'A' -> 'a'
//     'a' -> 'A'
//
//     'K' -> 'k'
//     'k' -> 'K'  (Kelvin symbol)
//     'K' -> 'K'
//
// Like everything Unicode, these tables are big.  If we represent the table
// as a sorted list of uint32 pairs, it has 2049 entries and is 16 kB.
// Most table entries look like the ones around them:
// 'A' maps to 'A'+32, 'B' maps to 'B'+32, etc.
// Instead of listing all the pairs explicitly, we make a list of ranges
// and deltas, so that the table entries for 'A' through 'Z' can be represented
// as a single entry { 'A', 'Z', +32 }.
//
// In addition to blocks that map to each other (A-Z mapping to a-z)
// there are blocks of pairs that individually map to each other
// (for example, 0100<->0101, 0102<->0103, 0104<->0105, ...).
// For those, the special delta value EvenOdd marks even/odd pairs
// (if even, add 1; if odd, subtract 1), and OddEven marks odd/even pairs.
//
// In this form, the table has 274 entries, about 3kB.  If we were to split
// the table into one for 16-bit codes and an overflow table for larger ones,
// we could get it down to about 1.5kB, but that's not worth the complexity.
//
// The grouped form also allows for efficient fold range calculations
// rather than looping one character at a time.

#ifndef RE2_UNICODE_CASEFOLD_H__
#define RE2_UNICODE_CASEFOLD_H__

#include "util/util.h"

namespace re2 {

enum {
  EvenOdd = 1,
  OddEven = -1,
  EvenOddSkip = 1<<30,
  OddEvenSkip,
};

struct CaseFold {
  uint32 lo;
  uint32 hi;
  int32 delta;
};

extern CaseFold unicode_casefold[];
extern int num_unicode_casefold;

extern CaseFold unicode_tolower[];
extern int num_unicode_tolower;

// Returns the CaseFold* in the tables that contains rune.
// If rune is not in the tables, returns the first CaseFold* after rune.
// If rune is larger than any value in the tables, returns NULL.
extern CaseFold* LookupCaseFold(CaseFold*, int, Rune rune);

// Returns the result of applying the fold f to the rune r.
extern Rune ApplyFold(CaseFold *f, Rune r);

}  // namespace re2

#endif  // RE2_UNICODE_CASEFOLD_H__
