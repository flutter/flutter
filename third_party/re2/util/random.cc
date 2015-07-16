// Copyright 2005-2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Modified from Google perftools's tcmalloc_unittest.cc.

#include "util/random.h"

namespace re2 {

int32 ACMRandom::Next() {
  const int32 M = 2147483647L;   // 2^31-1
  const int32 A = 16807;
  // In effect, we are computing seed_ = (seed_ * A) % M, where M = 2^31-1
  uint32 lo = A * (int32)(seed_ & 0xFFFF);
  uint32 hi = A * (int32)((uint32)seed_ >> 16);
  lo += (hi & 0x7FFF) << 16;
  if (lo > M) {
    lo &= M;
    ++lo;
  }
  lo += hi >> 15;
  if (lo > M) {
    lo &= M;
    ++lo;
  }
  return (seed_ = (int32) lo);
}

int32 ACMRandom::Uniform(int32 n) {
  return Next() % n;
}

}  // namespace re2
