// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef RE2_UTIL_BENCHMARK_H__
#define RE2_UTIL_BENCHMARK_H__

namespace testing {
struct Benchmark {
  const char* name;
  void (*fn)(int);
  void (*fnr)(int, int);
  int lo;
  int hi;
  int threadlo;
  int threadhi;
  
  void Register();
  Benchmark(const char* name, void (*f)(int)) { Clear(name); fn = f; Register(); }
  Benchmark(const char* name, void (*f)(int, int), int l, int h) { Clear(name); fnr = f; lo = l; hi = h; Register(); }
  void Clear(const char* n) { name = n; fn = 0; fnr = 0; lo = 0; hi = 0; threadlo = 0; threadhi = 0; }
  Benchmark* ThreadRange(int lo, int hi) { threadlo = lo; threadhi = hi; return this; }
};
}  // namespace testing

void SetBenchmarkBytesProcessed(long long);
void StopBenchmarkTiming();
void StartBenchmarkTiming();
void BenchmarkMemoryUsage();
void SetBenchmarkItemsProcessed(int);

int NumCPUs();

#define BENCHMARK(f) \
	::testing::Benchmark* _benchmark_##f = (new ::testing::Benchmark(#f, f))

#define BENCHMARK_RANGE(f, lo, hi) \
	::testing::Benchmark* _benchmark_##f = \
	(new ::testing::Benchmark(#f, f, lo, hi))

#endif  // RE2_UTIL_BENCHMARK_H__
