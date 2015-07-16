// Copyright (c) 2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_DMG_FP_H_
#define THIRD_PARTY_DMG_FP_H_

namespace dmg_fp {

// Return a nearest machine number to the input decimal
// string (or set errno to ERANGE). With IEEE arithmetic, ties are
// broken by the IEEE round-even rule.  Otherwise ties are broken by
// biased rounding (add half and chop).
double strtod(const char* s00, char** se);

// Convert double to ASCII string. For meaning of parameters
// see dtoa.cc file.
char* dtoa(double d, int mode, int ndigits,
           int* decpt, int* sign, char** rve);

// Must be used to free values returned by dtoa.
void freedtoa(char* s);

// Store the closest decimal approximation to x in b (null terminated).
// Returns a pointer to b.  It is sufficient for |b| to be 32 characters.
char* g_fmt(char* b, double x);

}  // namespace dmg_fp

#endif  // THIRD_PARTY_DMG_FP_H_
