// Copyright (c) 2008, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// All Rights Reserved.
//
// Author: Daniel Ford

#ifndef TCMALLOC_SAMPLER_H_
#define TCMALLOC_SAMPLER_H_

#include "config.h"
#include <stddef.h>                     // for size_t
#ifdef HAVE_STDINT_H
#include <stdint.h>                     // for uint64_t, uint32_t, int32_t
#endif
#include <string.h>                     // for memcpy
#include "base/basictypes.h"  // for ASSERT
#include "internal_logging.h"  // for ASSERT

namespace tcmalloc {

//-------------------------------------------------------------------
// Sampler to decide when to create a sample trace for an allocation
// Not thread safe: Each thread should have it's own sampler object.
// Caller must use external synchronization if used
// from multiple threads.
//
// With 512K average sample step (the default):
//  the probability of sampling a 4K allocation is about 0.00778
//  the probability of sampling a 1MB allocation is about 0.865
//  the probability of sampling a 1GB allocation is about 1.00000
// In general, the probablity of sampling is an allocation of size X
// given a flag value of Y (default 1M) is:
//  1 - e^(-X/Y)
//
// With 128K average sample step:
//  the probability of sampling a 1MB allocation is about 0.99966
//  the probability of sampling a 1GB allocation is about 1.0
//  (about 1 - 2**(-26))
// With 1M average sample step:
//  the probability of sampling a 4K allocation is about 0.00390
//  the probability of sampling a 1MB allocation is about 0.632
//  the probability of sampling a 1GB allocation is about 1.0
//
// The sampler works by representing memory as a long stream from
// which allocations are taken. Some of the bytes in this stream are
// marked and if an allocation includes a marked byte then it is
// sampled. Bytes are marked according to a Poisson point process
// with each byte being marked independently with probability
// p = 1/tcmalloc_sample_parameter.  This makes the probability
// of sampling an allocation of X bytes equal to the CDF of
// a geometric with mean tcmalloc_sample_parameter. (ie. the
// probability that at least one byte in the range is marked). This
// is accurately given by the CDF of the corresponding exponential
// distribution : 1 - e^(X/tcmalloc_sample_parameter_)
// Independence of the byte marking ensures independence of
// the sampling of each allocation.
//
// This scheme is implemented by noting that, starting from any
// fixed place, the number of bytes until the next marked byte
// is geometrically distributed. This number is recorded as
// bytes_until_sample_.  Every allocation subtracts from this
// number until it is less than 0. When this happens the current
// allocation is sampled.
//
// When an allocation occurs, bytes_until_sample_ is reset to
// a new independtly sampled geometric number of bytes. The
// memoryless property of the point process means that this may
// be taken as the number of bytes after the end of the current
// allocation until the next marked byte. This ensures that
// very large allocations which would intersect many marked bytes
// only result in a single call to PickNextSamplingPoint.
//-------------------------------------------------------------------

class PERFTOOLS_DLL_DECL Sampler {
 public:
  // Initialize this sampler.
  // Passing a seed of 0 gives a non-deterministic
  // seed value given by casting the object ("this")
  void Init(uint32_t seed);
  void Cleanup();

  // Record allocation of "k" bytes.  Return true iff allocation
  // should be sampled
  bool SampleAllocation(size_t k);

  // Generate a geometric with mean 512K (or FLAG_tcmalloc_sample_parameter)
  size_t PickNextSamplingPoint();

  // Initialize the statics for the Sampler class
  static void InitStatics();

  // Returns the current sample period
  int GetSamplePeriod();

  // The following are public for the purposes of testing
  static uint64_t NextRandom(uint64_t rnd_);  // Returns the next prng value
  static double FastLog2(const double & d);  // Computes Log2(x) quickly
  static void PopulateFastLog2Table();  // Populate the lookup table

 private:
  size_t        bytes_until_sample_;    // Bytes until we sample next
  uint64_t      rnd_;                   // Cheap random number generator

  // Statics for the fast log
  // Note that this code may not depend on anything in //util
  // hence the duplication of functionality here
  static const int kFastlogNumBits = 10;
  static const int kFastlogMask = (1 << kFastlogNumBits) - 1;
  static double log_table_[1<<kFastlogNumBits];  // Constant
};

inline bool Sampler::SampleAllocation(size_t k) {
  if (bytes_until_sample_ < k) {
    bytes_until_sample_ = PickNextSamplingPoint();
    return true;
  } else {
    bytes_until_sample_ -= k;
    return false;
  }
}

// Inline functions which are public for testing purposes

// Returns the next prng value.
// pRNG is: aX+b mod c with a = 0x5DEECE66D, b =  0xB, c = 1<<48
// This is the lrand64 generator.
inline uint64_t Sampler::NextRandom(uint64_t rnd) {
  const uint64_t prng_mult = 0x5DEECE66DLL;
  const uint64_t prng_add = 0xB;
  const uint64_t prng_mod_power = 48;
  const uint64_t prng_mod_mask =
                ~((~static_cast<uint64_t>(0)) << prng_mod_power);
  return (prng_mult * rnd + prng_add) & prng_mod_mask;
}

// Adapted from //util/math/fastmath.[h|cc] by Noam Shazeer
// This mimics the VeryFastLog2 code in those files
inline double Sampler::FastLog2(const double & d) {
  ASSERT(d>0);
  COMPILE_ASSERT(sizeof(d) == sizeof(uint64_t), DoubleMustBe64Bits);
  uint64_t x;
  memcpy(&x, &d, sizeof(x));   // we depend on the compiler inlining this
  const uint32_t x_high = x >> 32;
  const uint32_t y = x_high >> (20 - kFastlogNumBits) & kFastlogMask;
  const int32_t exponent = ((x_high >> 20) & 0x7FF) - 1023;
  return exponent + log_table_[y];
}

}  // namespace tcmalloc

#endif  // TCMALLOC_SAMPLER_H_
