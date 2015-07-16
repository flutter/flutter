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
//
// Checks basic properties of the sampler

#include "config_for_unittests.h"
#include <stdlib.h>        // defines posix_memalign
#include <stdio.h>         // for the printf at the end
#if defined HAVE_STDINT_H
#include <stdint.h>             // to get uintptr_t
#elif defined HAVE_INTTYPES_H
#include <inttypes.h>           // another place uintptr_t might be defined
#endif
#include <sys/types.h>
#include <iostream>
#include <algorithm>
#include <vector>
#include <string>
#include <cmath>
#include "base/logging.h"
#include "base/commandlineflags.h"
#include "sampler.h"       // The Sampler class being tested

using std::sort;
using std::min;
using std::max;
using std::vector;
using std::abs;

vector<void (*)()> g_testlist;  // the tests to run

#define TEST(a, b)                                      \
  struct Test_##a##_##b {                               \
    Test_##a##_##b() { g_testlist.push_back(&Run); }    \
    static void Run();                                  \
  };                                                    \
  static Test_##a##_##b g_test_##a##_##b;               \
  void Test_##a##_##b::Run()


static int RUN_ALL_TESTS() {
  vector<void (*)()>::const_iterator it;
  for (it = g_testlist.begin(); it != g_testlist.end(); ++it) {
    (*it)();   // The test will error-exit if there's a problem.
  }
  fprintf(stderr, "\nPassed %d tests\n\nPASS\n", (int)g_testlist.size());
  return 0;
}

#undef LOG   // defined in base/logging.h
// Ideally, we'd put the newline at the end, but this hack puts the
// newline at the end of the previous log message, which is good enough :-)
#define LOG(level)  std::cerr << "\n"

static std::string StringPrintf(const char* format, ...) {
  char buf[256];   // should be big enough for all logging
  va_list ap;
  va_start(ap, format);
  perftools_vsnprintf(buf, sizeof(buf), format, ap);
  va_end(ap);
  return buf;
}

namespace {
template<typename T> class scoped_array {
 public:
  scoped_array(T* p) : p_(p) { }
  ~scoped_array() { delete[] p_; }
  const T* get() const { return p_; }
  T* get() { return p_; }
  T& operator[](int i) { return p_[i]; }
 private:
  T* p_;
};
}

// Note that these tests are stochastic.
// This mean that the chance of correct code passing the test is,
// in the case of 5 standard deviations:
// kSigmas=5:    ~99.99994267%
// in the case of 4 standard deviations:
// kSigmas=4:    ~99.993666%
static const double kSigmas = 4;
static const size_t kSamplingInterval = 512*1024;

// Tests that GetSamplePeriod returns the expected value
// which is 1<<19
TEST(Sampler, TestGetSamplePeriod) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  uint64_t sample_period;
  sample_period = sampler.GetSamplePeriod();
  CHECK_GT(sample_period, 0);
}

// Tests of the quality of the random numbers generated
// This uses the Anderson Darling test for uniformity.
// See "Evaluating the Anderson-Darling Distribution" by Marsaglia
// for details.

// Short cut version of ADinf(z), z>0 (from Marsaglia)
// This returns the p-value for Anderson Darling statistic in
// the limit as n-> infinity. For finite n, apply the error fix below.
double AndersonDarlingInf(double z) {
  if (z < 2) {
    return exp(-1.2337141 / z) / sqrt(z) * (2.00012 + (0.247105 -
                (0.0649821 - (0.0347962 - (0.011672 - 0.00168691
                * z) * z) * z) * z) * z);
  }
  return exp( - exp(1.0776 - (2.30695 - (0.43424 - (0.082433 -
                    (0.008056 - 0.0003146 * z) * z) * z) * z) * z));
}

// Corrects the approximation error in AndersonDarlingInf for small values of n
// Add this to AndersonDarlingInf to get a better approximation
// (from Marsaglia)
double AndersonDarlingErrFix(int n, double x) {
  if (x > 0.8) {
    return (-130.2137 + (745.2337 - (1705.091 - (1950.646 -
            (1116.360 - 255.7844 * x) * x) * x) * x) * x) / n;
  }
  double cutoff = 0.01265 + 0.1757 / n;
  double t;
  if (x < cutoff) {
    t = x / cutoff;
    t = sqrt(t) * (1 - t) * (49 * t - 102);
    return t * (0.0037 / (n * n) + 0.00078 / n + 0.00006) / n;
  } else {
    t = (x - cutoff) / (0.8 - cutoff);
    t = -0.00022633 + (6.54034 - (14.6538 - (14.458 - (8.259 - 1.91864
          * t) * t) * t) * t) * t;
    return t * (0.04213 + 0.01365 / n) / n;
  }
}

// Returns the AndersonDarling p-value given n and the value of the statistic
double AndersonDarlingPValue(int n, double z) {
  double ad = AndersonDarlingInf(z);
  double errfix = AndersonDarlingErrFix(n, ad);
  return ad + errfix;
}

double AndersonDarlingStatistic(int n, double* random_sample) {
  double ad_sum = 0;
  for (int i = 0; i < n; i++) {
    ad_sum += (2*i + 1) * log(random_sample[i] * (1 - random_sample[n-1-i]));
  }
  double ad_statistic = - n - 1/static_cast<double>(n) * ad_sum;
  return ad_statistic;
}

// Tests if the array of doubles is uniformly distributed.
// Returns the p-value of the Anderson Darling Statistic
// for the given set of sorted random doubles
// See "Evaluating the Anderson-Darling Distribution" by
// Marsaglia and Marsaglia for details.
double AndersonDarlingTest(int n, double* random_sample) {
  double ad_statistic = AndersonDarlingStatistic(n, random_sample);
  LOG(INFO) << StringPrintf("AD stat = %f, n=%d\n", ad_statistic, n);
  double p = AndersonDarlingPValue(n, ad_statistic);
  return p;
}

// Test the AD Test. The value of the statistic should go to zero as n->infty
// Not run as part of regular tests
void ADTestTest(int n) {
  scoped_array<double> random_sample(new double[n]);
  for (int i = 0; i < n; i++) {
    random_sample[i] = (i+0.01)/n;
  }
  sort(random_sample.get(), random_sample.get() + n);
  double ad_stat = AndersonDarlingStatistic(n, random_sample.get());
  LOG(INFO) << StringPrintf("Testing the AD test. n=%d, ad_stat = %f",
                            n, ad_stat);
}

// Print the CDF of the distribution of the Anderson-Darling Statistic
// Used for checking the Anderson-Darling Test
// Not run as part of regular tests
void ADCDF() {
  for (int i = 1; i < 40; i++) {
    double x = i/10.0;
    LOG(INFO) << "x= " << x << "  adpv= "
              << AndersonDarlingPValue(100, x) << ", "
              << AndersonDarlingPValue(1000, x);
  }
}

// Testing that NextRandom generates uniform
// random numbers.
// Applies the Anderson-Darling test for uniformity
void TestNextRandom(int n) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  uint64_t x = 1;
  // This assumes that the prng returns 48 bit numbers
  uint64_t max_prng_value = static_cast<uint64_t>(1)<<48;
  // Initialize
  for (int i = 1; i <= 20; i++) {  // 20 mimics sampler.Init()
    x = sampler.NextRandom(x);
  }
  scoped_array<uint64_t> int_random_sample(new uint64_t[n]);
  // Collect samples
  for (int i = 0; i < n; i++) {
    int_random_sample[i] = x;
    x = sampler.NextRandom(x);
  }
  // First sort them...
  sort(int_random_sample.get(), int_random_sample.get() + n);
  scoped_array<double> random_sample(new double[n]);
  // Convert them to uniform randoms (in the range [0,1])
  for (int i = 0; i < n; i++) {
    random_sample[i] = static_cast<double>(int_random_sample[i])/max_prng_value;
  }
  // Now compute the Anderson-Darling statistic
  double ad_pvalue = AndersonDarlingTest(n, random_sample.get());
  LOG(INFO) << StringPrintf("pvalue for AndersonDarlingTest "
                            "with n= %d is p= %f\n", n, ad_pvalue);
  CHECK_GT(min(ad_pvalue, 1 - ad_pvalue), 0.0001);
  //           << StringPrintf("prng is not uniform, %d\n", n);
}


TEST(Sampler, TestNextRandom_MultipleValues) {
  TestNextRandom(10);  // Check short-range correlation
  TestNextRandom(100);
  TestNextRandom(1000);
  TestNextRandom(10000);  // Make sure there's no systematic error
}

// Tests that PickNextSamplePeriod generates
// geometrically distributed random numbers.
// First converts to uniforms then applied the
// Anderson-Darling test for uniformity.
void TestPickNextSample(int n) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  scoped_array<uint64_t> int_random_sample(new uint64_t[n]);
  int sample_period = sampler.GetSamplePeriod();
  int ones_count = 0;
  for (int i = 0; i < n; i++) {
    int_random_sample[i] = sampler.PickNextSamplingPoint();
    CHECK_GE(int_random_sample[i], 1);
    if (int_random_sample[i] == 1) {
      ones_count += 1;
    }
    CHECK_LT(ones_count, 4); // << " out of " << i << " samples.";
  }
  // First sort them...
  sort(int_random_sample.get(), int_random_sample.get() + n);
  scoped_array<double> random_sample(new double[n]);
  // Convert them to uniform random numbers
  // by applying the geometric CDF
  for (int i = 0; i < n; i++) {
    random_sample[i] = 1 - exp(-static_cast<double>(int_random_sample[i])
                           / sample_period);
  }
  // Now compute the Anderson-Darling statistic
  double geom_ad_pvalue = AndersonDarlingTest(n, random_sample.get());
  LOG(INFO) << StringPrintf("pvalue for geometric AndersonDarlingTest "
                             "with n= %d is p= %f\n", n, geom_ad_pvalue);
  CHECK_GT(min(geom_ad_pvalue, 1 - geom_ad_pvalue), 0.0001);
      //          << "PickNextSamplingPoint does not produce good "
      //             "geometric/exponential random numbers\n";
}

TEST(Sampler, TestPickNextSample_MultipleValues) {
  TestPickNextSample(10);  // Make sure the first few are good (enough)
  TestPickNextSample(100);
  TestPickNextSample(1000);
  TestPickNextSample(10000);  // Make sure there's no systematic error
}


// This is superceeded by the Anderson-Darling Test
// and it not run now.
// Tests how fast nearby values are spread out with  LRand64
// The purpose of this code is to determine how many
// steps to apply to the seed during initialization
void TestLRand64Spread() {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  uint64_t current_value;
  printf("Testing LRand64 Spread\n");
  for (int i = 1; i < 10; i++) {
    printf("%d ", i);
    current_value = i;
    for (int j = 1; j < 100; j++) {
      current_value = sampler.NextRandom(current_value);
    }
    LOG(INFO) << current_value;
  }
}


// Test for Fastlog2 code
// We care about the percentage error because we're using this
// for choosing step sizes, so "close" is relative to the size of
// the step we would get if we used the built-in log function
TEST(Sampler, FastLog2) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  double max_ratio_error = 0;
  for (double d = -1021.9; d < 1; d+= 0.13124235) {
    double e = pow(2.0, d);
    double truelog = log(e) / log(2.0);  // log_2(e)
    double fastlog = sampler.FastLog2(e);
    max_ratio_error = max(max_ratio_error,
                          max(truelog/fastlog-1, fastlog/truelog-1));
    CHECK_LE(max_ratio_error, 0.01);
        //        << StringPrintf("d = %f, e=%f, truelog = %f, fastlog= %f\n",
        //                        d, e, truelog, fastlog);
  }
  LOG(INFO) << StringPrintf("Fastlog2: max_ratio_error = %f\n",
                            max_ratio_error);
}

// Futher tests

bool CheckMean(size_t mean, int num_samples) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  size_t total = 0;
  for (int i = 0; i < num_samples; i++) {
    total += sampler.PickNextSamplingPoint();
  }
  double empirical_mean = total / static_cast<double>(num_samples);
  double expected_sd = mean / pow(num_samples * 1.0, 0.5);
  return(fabs(mean-empirical_mean) < expected_sd * kSigmas);
}

// Prints a sequence so you can look at the distribution
void OutputSequence(int sequence_length) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  size_t next_step;
  for (int i = 0; i< sequence_length; i++) {
    next_step = sampler.PickNextSamplingPoint();
    LOG(INFO) << next_step;
  }
}


double StandardDeviationsErrorInSample(
              int total_samples, int picked_samples,
              int alloc_size, int sampling_interval) {
  double p = 1 - exp(-(static_cast<double>(alloc_size) / sampling_interval));
  double expected_samples = total_samples * p;
  double sd = pow(p*(1-p)*total_samples, 0.5);
  return((picked_samples - expected_samples) / sd);
}

TEST(Sampler, LargeAndSmallAllocs_CombinedTest) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  int counter_big = 0;
  int counter_small = 0;
  int size_big = 129*8*1024+1;
  int size_small = 1024*8;
  int num_iters = 128*4*8;
  // Allocate in mixed chunks
  for (int i = 0; i < num_iters; i++) {
    if (sampler.SampleAllocation(size_big)) {
      counter_big += 1;
    }
    for (int i = 0; i < 129; i++) {
      if (sampler.SampleAllocation(size_small)) {
        counter_small += 1;
      }
    }
  }
  // Now test that there are the right number of each
  double large_allocs_sds =
     StandardDeviationsErrorInSample(num_iters, counter_big,
                                     size_big, kSamplingInterval);
  double small_allocs_sds =
     StandardDeviationsErrorInSample(num_iters*129, counter_small,
                                     size_small, kSamplingInterval);
  LOG(INFO) << StringPrintf("large_allocs_sds = %f\n", large_allocs_sds);
  LOG(INFO) << StringPrintf("small_allocs_sds = %f\n", small_allocs_sds);
  CHECK_LE(fabs(large_allocs_sds), kSigmas);
  CHECK_LE(fabs(small_allocs_sds), kSigmas);
}

// Tests whether the mean is about right over 1000 samples
TEST(Sampler, IsMeanRight) {
  CHECK(CheckMean(kSamplingInterval, 1000));
}

// This flag is for the OldSampler class to use
const int64 FLAGS_mock_tcmalloc_sample_parameter = 1<<19;

// A cut down and slightly refactored version of the old Sampler
class OldSampler {
 public:
  void Init(uint32_t seed);
  void Cleanup() {}

  // Record allocation of "k" bytes.  Return true iff allocation
  // should be sampled
  bool SampleAllocation(size_t k);

  // Generate a geometric with mean 1M (or FLAG value)
  void PickNextSample(size_t k);

  // Initialize the statics for the Sample class
  static void InitStatics() {
    sample_period = 1048583;
  }
  size_t bytes_until_sample_;

 private:
  uint32_t rnd_;                   // Cheap random number generator
  static uint64_t sample_period;
  // Should be a prime just above a power of 2:
  // 2, 5, 11, 17, 37, 67, 131, 257,
  // 521, 1031, 2053, 4099, 8209, 16411,
  // 32771, 65537, 131101, 262147, 524309, 1048583,
  // 2097169, 4194319, 8388617, 16777259, 33554467
};

// Statics for OldSampler
uint64_t OldSampler::sample_period;

void OldSampler::Init(uint32_t seed) {
  // Initialize PRNG -- run it for a bit to get to good values
  if (seed != 0) {
    rnd_ = seed;
  } else {
    rnd_ = 12345;
  }
  bytes_until_sample_ = 0;
  for (int i = 0; i < 100; i++) {
    PickNextSample(sample_period * 2);
  }
};

// A cut-down version of the old PickNextSampleRoutine
void OldSampler::PickNextSample(size_t k) {
  // Make next "random" number
  // x^32+x^22+x^2+x^1+1 is a primitive polynomial for random numbers
  static const uint32_t kPoly = (1 << 22) | (1 << 2) | (1 << 1) | (1 << 0);
  uint32_t r = rnd_;
  rnd_ = (r << 1) ^ ((static_cast<int32_t>(r) >> 31) & kPoly);

  // Next point is "rnd_ % (sample_period)".  I.e., average
  // increment is "sample_period/2".
  const int flag_value = FLAGS_mock_tcmalloc_sample_parameter;
  static int last_flag_value = -1;

  if (flag_value != last_flag_value) {
    // There should be a spinlock here, but this code is
    // for benchmarking only.
    sample_period = 1048583;
    last_flag_value = flag_value;
  }

  bytes_until_sample_ += rnd_ % sample_period;

  if (k > (static_cast<size_t>(-1) >> 2)) {
    // If the user has asked for a huge allocation then it is possible
    // for the code below to loop infinitely.  Just return (note that
    // this throws off the sampling accuracy somewhat, but a user who
    // is allocating more than 1G of memory at a time can live with a
    // minor inaccuracy in profiling of small allocations, and also
    // would rather not wait for the loop below to terminate).
    return;
  }

  while (bytes_until_sample_ < k) {
    // Increase bytes_until_sample_ by enough average sampling periods
    // (sample_period >> 1) to allow us to sample past the current
    // allocation.
    bytes_until_sample_ += (sample_period >> 1);
  }

  bytes_until_sample_ -= k;
}

inline bool OldSampler::SampleAllocation(size_t k) {
  if (bytes_until_sample_ < k) {
    PickNextSample(k);
    return true;
  } else {
    bytes_until_sample_ -= k;
    return false;
  }
}

// This checks that the stated maximum value for the
// tcmalloc_sample_parameter flag never overflows bytes_until_sample_
TEST(Sampler, bytes_until_sample_Overflow_Underflow) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  uint64_t one = 1;
  // sample_parameter = 0;  // To test the edge case
  uint64_t sample_parameter_array[4] = {0, 1, one<<19, one<<58};
  for (int i = 0; i < 4; i++) {
    uint64_t sample_parameter = sample_parameter_array[i];
    LOG(INFO) << "sample_parameter = " << sample_parameter;
    double sample_scaling = - log(2.0) * sample_parameter;
    // Take the top 26 bits as the random number
    // (This plus the 1<<26 sampling bound give a max step possible of
    // 1209424308 bytes.)
    const uint64_t prng_mod_power = 48;  // Number of bits in prng

    // First, check the largest_prng value
    uint64_t largest_prng_value = (static_cast<uint64_t>(1)<<48) - 1;
    double q = (largest_prng_value >> (prng_mod_power - 26)) + 1.0;
    LOG(INFO) << StringPrintf("q = %f\n", q);
    LOG(INFO) << StringPrintf("FastLog2(q) = %f\n", sampler.FastLog2(q));
    LOG(INFO) << StringPrintf("log2(q) = %f\n", log(q)/log(2.0));
    // Replace min(sampler.FastLog2(q) - 26, 0.0) with
    // (sampler.FastLog2(q) - 26.000705) when using that optimization
    uint64_t smallest_sample_step
        = static_cast<uint64_t>(min(sampler.FastLog2(q) - 26, 0.0)
                                * sample_scaling + 1);
    LOG(INFO) << "Smallest sample step is " << smallest_sample_step;
    uint64_t cutoff = static_cast<uint64_t>(10)
                      * (sample_parameter/(one<<24) + 1);
    LOG(INFO) << "Acceptable value is < " << cutoff;
    // This checks that the answer is "small" and positive
    CHECK_LE(smallest_sample_step, cutoff);

    // Next, check with the smallest prng value
    uint64_t smallest_prng_value = 0;
    q = (smallest_prng_value >> (prng_mod_power - 26)) + 1.0;
    LOG(INFO) << StringPrintf("q = %f\n", q);
    // Replace min(sampler.FastLog2(q) - 26, 0.0) with
    // (sampler.FastLog2(q) - 26.000705) when using that optimization
    uint64_t largest_sample_step
        = static_cast<uint64_t>(min(sampler.FastLog2(q) - 26, 0.0)
                                * sample_scaling + 1);
    LOG(INFO) << "Largest sample step is " << largest_sample_step;
    CHECK_LE(largest_sample_step, one<<63);
    CHECK_GE(largest_sample_step, smallest_sample_step);
  }
}


// Test that NextRand is in the right range.  Unfortunately, this is a
// stochastic test which could miss problems.
TEST(Sampler, NextRand_range) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  uint64_t one = 1;
  // The next number should be (one << 48) - 1
  uint64_t max_value = (one << 48) - 1;
  uint64_t x = (one << 55);
  int n = 22;  // 27;
  LOG(INFO) << "Running sampler.NextRandom 1<<" << n << " times";
  for (int i = 1; i <= (1<<n); i++) {  // 20 mimics sampler.Init()
    x = sampler.NextRandom(x);
    CHECK_LE(x, max_value);
  }
}

// Tests certain arithmetic operations to make sure they compute what we
// expect them too (for testing across different platforms)
TEST(Sampler, arithmetic_1) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  uint64_t rnd;  // our 48 bit random number, which we don't trust
  const uint64_t prng_mod_power = 48;
  uint64_t one = 1;
  rnd = one;
  uint64_t max_value = (one << 48) - 1;
  for (int i = 1; i <= (1>>27); i++) {  // 20 mimics sampler.Init()
    rnd = sampler.NextRandom(rnd);
    CHECK_LE(rnd, max_value);
    double q = (rnd >> (prng_mod_power - 26)) + 1.0;
    CHECK_GE(q, 0); // << rnd << "  " << prng_mod_power;
  }
  // Test some potentially out of bounds value for rnd
  for (int i = 1; i <= 66; i++) {
    rnd = one << i;
    double q = (rnd >> (prng_mod_power - 26)) + 1.0;
    LOG(INFO) << "rnd = " << rnd << " i=" << i << " q=" << q;
    CHECK_GE(q, 0);
    //        << " rnd=" << rnd << "  i=" << i << " prng_mod_power" << prng_mod_power;
  }
}

void test_arithmetic(uint64_t rnd) {
  const uint64_t prng_mod_power = 48;  // Number of bits in prng
  uint64_t shifted_rnd = rnd >> (prng_mod_power - 26);
  CHECK_GE(shifted_rnd, 0);
  CHECK_LT(shifted_rnd, (1<<26));
  LOG(INFO) << shifted_rnd;
  LOG(INFO) << static_cast<double>(shifted_rnd);
  CHECK_GE(static_cast<double>(static_cast<uint32_t>(shifted_rnd)), 0);
      //      << " rnd=" << rnd << "  srnd=" << shifted_rnd;
  CHECK_GE(static_cast<double>(shifted_rnd), 0);
      //      << " rnd=" << rnd << "  srnd=" << shifted_rnd;
  double q = static_cast<double>(shifted_rnd) + 1.0;
  CHECK_GT(q, 0);
}

// Tests certain arithmetic operations to make sure they compute what we
// expect them too (for testing across different platforms)
// know bad values under with -c dbg --cpu piii for _some_ binaries:
// rnd=227453640600554
// shifted_rnd=54229173
// (hard to reproduce)
TEST(Sampler, arithmetic_2) {
  uint64_t rnd = 227453640600554LL;
  test_arithmetic(rnd);
}


// It's not really a test, but it's good to know
TEST(Sample, size_of_class) {
  tcmalloc::Sampler sampler;
  sampler.Init(1);
  LOG(INFO) << "Size of Sampler class is: " << sizeof(tcmalloc::Sampler);
  LOG(INFO) << "Size of Sampler object is: " << sizeof(sampler);
}

// Make sure sampling is enabled, or the tests won't work right.
DECLARE_int64(tcmalloc_sample_parameter);

int main(int argc, char **argv) {
  if (FLAGS_tcmalloc_sample_parameter == 0)
    FLAGS_tcmalloc_sample_parameter = 524288;
  return RUN_ALL_TESTS();
}
