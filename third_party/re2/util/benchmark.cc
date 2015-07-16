// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/util.h"
#include "util/flags.h"
#include "util/benchmark.h"
#include "re2/re2.h"

DEFINE_string(test_tmpdir, "/var/tmp", "temp directory");

using testing::Benchmark;
using namespace re2;

static Benchmark* benchmarks[10000];
static int nbenchmarks;

void Benchmark::Register() {
	benchmarks[nbenchmarks] = this;
	if(lo < 1)
		lo = 1;
	if(hi < lo)
		hi = lo;
	nbenchmarks++;
}

static int64 nsec() {
	struct timeval tv;
	if(gettimeofday(&tv, 0) < 0)
		return -1;
	return (int64)tv.tv_sec*1000*1000*1000 + tv.tv_usec*1000;
}

static int64 bytes;
static int64 ns;
static int64 t0;
static int64 items;

void SetBenchmarkBytesProcessed(long long x) {
	bytes = x;
}

void StopBenchmarkTiming() {
	if(t0 != 0)
		ns += nsec() - t0;
	t0 = 0;
}

void StartBenchmarkTiming() {
	if(t0 == 0)
		t0 = nsec();
}

void SetBenchmarkItemsProcessed(int n) {
	items = n;
}

void BenchmarkMemoryUsage() {
	// TODO(rsc): Implement.
}

int NumCPUs() {
	return 1;
}

static void runN(Benchmark *b, int n, int siz) {
	bytes = 0;
	items = 0;
	ns = 0;
	t0 = nsec();
	if(b->fn)
		b->fn(n);
	else if(b->fnr)
		b->fnr(n, siz);
	else {
		fprintf(stderr, "%s: missing function\n", b->name);
		exit(2);
	}
	if(t0 != 0)
		ns += nsec() - t0;
}

static int round(int n) {
	int base = 1;
	
	while(base*10 < n)
		base *= 10;
	if(n < 2*base)
		return 2*base;
	if(n < 5*base)
		return 5*base;
	return 10*base;
}

void RunBench(Benchmark* b, int nthread, int siz) {
	int n, last;

	// TODO(rsc): Threaded benchmarks.
	if(nthread != 1)
		return;
	
	// run once in case it's expensive
	n = 1;
	runN(b, n, siz);
	while(ns < (int)1e9 && n < (int)1e9) {
		last = n;
		if(ns/n == 0)
			n = 1e9;
		else
			n = 1e9 / (ns/n);
		
		n = max(last+1, min(n+n/2, 100*last));
		n = round(n);
		runN(b, n, siz);
	}
	
	char mb[100];
	char suf[100];
	mb[0] = '\0';
	suf[0] = '\0';
	if(ns > 0 && bytes > 0)
		snprintf(mb, sizeof mb, "\t%7.2f MB/s", ((double)bytes/1e6)/((double)ns/1e9));
	if(b->fnr || b->lo != b->hi) {
		if(siz >= (1<<20))
			snprintf(suf, sizeof suf, "/%dM", siz/(1<<20));
		else if(siz >= (1<<10))
			snprintf(suf, sizeof suf, "/%dK", siz/(1<<10));
		else
			snprintf(suf, sizeof suf, "/%d", siz);
	}
	printf("%s%s\t%8lld\t%10lld ns/op%s\n", b->name, suf, (long long)n, (long long)ns/n, mb);
	fflush(stdout);
}

static int match(const char* name, int argc, const char** argv) {
	if(argc == 1)
		return 1;
	for(int i = 1; i < argc; i++)
		if(RE2::PartialMatch(name, argv[i]))
			return 1;
	return 0;
}

int main(int argc, const char** argv) {
	for(int i = 0; i < nbenchmarks; i++) {
		Benchmark* b = benchmarks[i];
		if(match(b->name, argc, argv))
			for(int j = b->threadlo; j <= b->threadhi; j++)
				for(int k = max(b->lo, 1); k <= max(b->hi, 1); k<<=1)
					RunBench(b, j, k);
	}
}

