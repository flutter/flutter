// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Unicode character groups.

// The codes get split into ranges of 16-bit codes
// and ranges of 32-bit codes.  It would be simpler
// to use only 32-bit ranges, but these tables are large
// enough to warrant extra care.
//
// Using just 32-bit ranges gives 27 kB of data.
// Adding 16-bit ranges gives 18 kB of data.
// Adding an extra table of 16-bit singletons would reduce
// to 16.5 kB of data but make the data harder to use;
// we don't bother.

#ifndef RE2_UNICODE_GROUPS_H__
#define RE2_UNICODE_GROUPS_H__

#include "util/util.h"

namespace re2 {

struct URange16
{
  uint16 lo;
  uint16 hi;
};

struct URange32
{
  uint32 lo;
  uint32 hi;
};

struct UGroup
{
  const char *name;
  int sign;  // +1 for [abc], -1 for [^abc]
  URange16 *r16;
  int nr16;
  URange32 *r32;
  int nr32;
};

// Named by property or script name (e.g., "Nd", "N", "Han").
// Negated groups are not included.
extern UGroup unicode_groups[];
extern int num_unicode_groups;

// Named by POSIX name (e.g., "[:alpha:]", "[:^lower:]").
// Negated groups are included.
extern UGroup posix_groups[];
extern int num_posix_groups;

// Named by Perl name (e.g., "\\d", "\\D").
// Negated groups are included.
extern UGroup perl_groups[];
extern int num_perl_groups;

}  // namespace re2

#endif  // RE2_UNICODE_GROUPS_H__
