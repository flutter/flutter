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

#include "sampler.h"

#include <algorithm>  // For min()
#include <math.h>
#include "base/commandlineflags.h"

using std::min;

// The approximate gap in bytes between sampling actions.
// I.e., we take one sample approximately once every
// tcmalloc_sample_parameter bytes of allocation
// i.e. about once every 512KB if value is 1<<19.
#ifdef NO_TCMALLOC_SAMPLES
DEFINE_int64(tcmalloc_sample_parameter, 0,
             "Unused: code is compiled with NO_TCMALLOC_SAMPLES");
#else
DEFINE_int64(tcmalloc_sample_parameter,
             EnvToInt64("TCMALLOC_SAMPLE_PARAMETER", 0),
             "The approximate gap in bytes between sampling actions. "
             "This must be between 1 and 2^58.");
#endif

namespace tcmalloc {

// Statics for Sampler
double Sampler::log_table_[1<<kFastlogNumBits];

// Populate the lookup table for FastLog2.
// This approximates the log2 curve with a step function.
// Steps have height equal to log2 of the mid-point of the step.
void Sampler::PopulateFastLog2Table() {
  for (int i = 0; i < (1<<kFastlogNumBits); i++) {
    log_table_[i] = (log(1.0 + static_cast<double>(i+0.5)/(1<<kFastlogNumBits))
                     / log(2.0));
  }
}

int Sampler::GetSamplePeriod() {
  return FLAGS_tcmalloc_sample_parameter;
}

// Run this before using your sampler
void Sampler::Init(uint32_t seed) {
  // Initialize PRNG
  if (seed != 0) {
    rnd_ = seed;
  } else {
    rnd_ = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(this));
    if (rnd_ == 0) {
      rnd_ = 1;
    }
  }
  // Step it forward 20 times for good measure
  for (int i = 0; i < 20; i++) {
    rnd_ = NextRandom(rnd_);
  }
  // Initialize counter
  bytes_until_sample_ = PickNextSamplingPoint();
}

// Initialize the Statics for the Sampler class
void Sampler::InitStatics() {
  PopulateFastLog2Table();
}

// Generates a geometric variable with the specified mean (512K by default).
// This is done by generating a random number between 0 and 1 and applying
// the inverse cumulative distribution function for an exponential.
// Specifically: Let m be the inverse of the sample period, then
// the probability distribution function is m*exp(-mx) so the CDF is
// p = 1 - exp(-mx), so
// q = 1 - p = exp(-mx)
// log_e(q) = -mx
// -log_e(q)/m = x
// log_2(q) * (-log_e(2) * 1/m) = x
// In the code, q is actually in the range 1 to 2**26, hence the -26 below
size_t Sampler::PickNextSamplingPoint() {
  rnd_ = NextRandom(rnd_);
  // Take the top 26 bits as the random number
  // (This plus the 1<<58 sampling bound give a max possible step of
  // 5194297183973780480 bytes.)
  const uint64_t prng_mod_power = 48;  // Number of bits in prng
  // The uint32_t cast is to prevent a (hard-to-reproduce) NAN
  // under piii debug for some binaries.
  double q = static_cast<uint32_t>(rnd_ >> (prng_mod_power - 26)) + 1.0;
  // Put the computed p-value through the CDF of a geometric.
  // For faster performance (save ~1/20th exec time), replace
  // min(0.0, FastLog2(q) - 26)  by  (Fastlog2(q) - 26.000705)
  // The value 26.000705 is used rather than 26 to compensate
  // for inaccuracies in FastLog2 which otherwise result in a
  // negative answer.
  return static_cast<size_t>(min(0.0, (FastLog2(q) - 26)) * (-log(2.0)
                             * FLAGS_tcmalloc_sample_parameter) + 1);
}

}  // namespace tcmalloc
