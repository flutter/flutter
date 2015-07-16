// Copyright 2006-2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Benchmarks for regular expression implementations.

#include "util/test.h"
#include "re2/prog.h"
#include "re2/re2.h"
#include "re2/regexp.h"
#include "util/pcre.h"
#include "util/benchmark.h"

namespace re2 {
void Test();
void MemoryUsage();
}  // namespace re2

typedef testing::MallocCounter MallocCounter;

namespace re2 {

void Test() {
  Regexp* re = Regexp::Parse("(\\d+)-(\\d+)-(\\d+)", Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  CHECK(prog->IsOnePass());
  const char* text = "650-253-0001";
  StringPiece sp[4];
  CHECK(prog->SearchOnePass(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
  CHECK_EQ(sp[0], "650-253-0001");
  CHECK_EQ(sp[1], "650");
  CHECK_EQ(sp[2], "253");
  CHECK_EQ(sp[3], "0001");
  delete prog;
  re->Decref();
  LOG(INFO) << "test passed\n";
}

void MemoryUsage() {
  const char* regexp = "(\\d+)-(\\d+)-(\\d+)";
  const char* text = "650-253-0001";
  {
    MallocCounter mc(MallocCounter::THIS_THREAD_ONLY);
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    // Can't pass mc.HeapGrowth() and mc.PeakHeapGrowth() to LOG(INFO) directly,
    // because LOG(INFO) might do a big allocation before they get evaluated.
    fprintf(stderr, "Regexp: %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
    mc.Reset();

    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    CHECK(prog->IsOnePass());
    fprintf(stderr, "Prog:   %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
    mc.Reset();

    StringPiece sp[4];
    CHECK(prog->SearchOnePass(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
    fprintf(stderr, "Search: %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
    delete prog;
    re->Decref();
  }

  {
    MallocCounter mc(MallocCounter::THIS_THREAD_ONLY);

    PCRE re(regexp, PCRE::UTF8);
    fprintf(stderr, "RE:     %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
    PCRE::FullMatch(text, re);
    fprintf(stderr, "RE:     %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
  }

  {
    MallocCounter mc(MallocCounter::THIS_THREAD_ONLY);

    PCRE* re = new PCRE(regexp, PCRE::UTF8);
    fprintf(stderr, "PCRE*:  %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
    PCRE::FullMatch(text, *re);
    fprintf(stderr, "PCRE*:  %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
    delete re;
  }

  {
    MallocCounter mc(MallocCounter::THIS_THREAD_ONLY);

    RE2 re(regexp);
    fprintf(stderr, "RE2:    %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
    RE2::FullMatch(text, re);
    fprintf(stderr, "RE2:    %7lld bytes (peak=%lld)\n", mc.HeapGrowth(), mc.PeakHeapGrowth());
  }

  fprintf(stderr, "sizeof: PCRE=%d RE2=%d Prog=%d Inst=%d\n",
          static_cast<int>(sizeof(PCRE)),
          static_cast<int>(sizeof(RE2)),
          static_cast<int>(sizeof(Prog)),
          static_cast<int>(sizeof(Prog::Inst)));
}

// Regular expression implementation wrappers.
// Defined at bottom of file, but they are repetitive
// and not interesting.

typedef void SearchImpl(int iters, const char* regexp, const StringPiece& text,
             Prog::Anchor anchor, bool expect_match);

SearchImpl SearchDFA, SearchNFA, SearchOnePass, SearchBitState,
           SearchPCRE, SearchRE2,
           SearchCachedDFA, SearchCachedNFA, SearchCachedOnePass, SearchCachedBitState,
           SearchCachedPCRE, SearchCachedRE2;

typedef void ParseImpl(int iters, const char* regexp, const StringPiece& text);

ParseImpl Parse1NFA, Parse1OnePass, Parse1BitState,
          Parse1PCRE, Parse1RE2,
          Parse1Backtrack,
          Parse1CachedNFA, Parse1CachedOnePass, Parse1CachedBitState,
          Parse1CachedPCRE, Parse1CachedRE2,
          Parse1CachedBacktrack;

ParseImpl Parse3NFA, Parse3OnePass, Parse3BitState,
          Parse3PCRE, Parse3RE2,
          Parse3Backtrack,
          Parse3CachedNFA, Parse3CachedOnePass, Parse3CachedBitState,
          Parse3CachedPCRE, Parse3CachedRE2,
          Parse3CachedBacktrack;

ParseImpl SearchParse2CachedPCRE, SearchParse2CachedRE2;

ParseImpl SearchParse1CachedPCRE, SearchParse1CachedRE2;

// Benchmark: failed search for regexp in random text.

// Generate random text that won't contain the search string,
// to test worst-case search behavior.
void MakeText(string* text, int nbytes) {
  text->resize(nbytes);
  srand(0);
  for (int i = 0; i < nbytes; i++) {
    if (!rand()%30)
      (*text)[i] = '\n';
    else
      (*text)[i] = rand()%(0x7E + 1 - 0x20)+0x20;
  }
}

// Makes text of size nbytes, then calls run to search
// the text for regexp iters times.
void Search(int iters, int nbytes, const char* regexp, SearchImpl* search) {
  StopBenchmarkTiming();
  string s;
  MakeText(&s, nbytes);
  BenchmarkMemoryUsage();
  StartBenchmarkTiming();
  search(iters, regexp, s, Prog::kUnanchored, false);
  SetBenchmarkBytesProcessed(static_cast<int64>(iters)*nbytes);
}

// These two are easy because they start with an A,
// giving the search loop something to memchr for.
#define EASY0      "ABCDEFGHIJKLMNOPQRSTUVWXYZ$"
#define EASY1      "A[AB]B[BC]C[CD]D[DE]E[EF]F[FG]G[GH]H[HI]I[IJ]J$"

// This is a little harder, since it starts with a character class
// and thus can't be memchr'ed.  Could look for ABC and work backward,
// but no one does that.
#define MEDIUM     "[XYZ]ABCDEFGHIJKLMNOPQRSTUVWXYZ$"

// This is a fair amount harder, because of the leading [ -~]*.
// A bad backtracking implementation will take O(text^2) time to
// figure out there's no match.
#define HARD       "[ -~]*ABCDEFGHIJKLMNOPQRSTUVWXYZ$"

// This stresses engines that are trying to track parentheses.
#define PARENS     "([ -~])*(A)(B)(C)(D)(E)(F)(G)(H)(I)(J)(K)(L)(M)" \
                   "(N)(O)(P)(Q)(R)(S)(T)(U)(V)(W)(X)(Y)(Z)$"

void Search_Easy0_CachedDFA(int i, int n)     { Search(i, n, EASY0, SearchCachedDFA); }
void Search_Easy0_CachedNFA(int i, int n)     { Search(i, n, EASY0, SearchCachedNFA); }
void Search_Easy0_CachedPCRE(int i, int n)    { Search(i, n, EASY0, SearchCachedPCRE); }
void Search_Easy0_CachedRE2(int i, int n)     { Search(i, n, EASY0, SearchCachedRE2); }

BENCHMARK_RANGE(Search_Easy0_CachedDFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Easy0_CachedNFA,     8, 256<<10)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Easy0_CachedPCRE,    8, 16<<20)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Easy0_CachedRE2,     8, 16<<20)->ThreadRange(1, NumCPUs());

void Search_Easy1_CachedDFA(int i, int n)     { Search(i, n, EASY1, SearchCachedDFA); }
void Search_Easy1_CachedNFA(int i, int n)     { Search(i, n, EASY1, SearchCachedNFA); }
void Search_Easy1_CachedPCRE(int i, int n)    { Search(i, n, EASY1, SearchCachedPCRE); }
void Search_Easy1_CachedRE2(int i, int n)     { Search(i, n, EASY1, SearchCachedRE2); }

BENCHMARK_RANGE(Search_Easy1_CachedDFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Easy1_CachedNFA,     8, 256<<10)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Easy1_CachedPCRE,    8, 16<<20)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Easy1_CachedRE2,     8, 16<<20)->ThreadRange(1, NumCPUs());

void Search_Medium_CachedDFA(int i, int n)     { Search(i, n, MEDIUM, SearchCachedDFA); }
void Search_Medium_CachedNFA(int i, int n)     { Search(i, n, MEDIUM, SearchCachedNFA); }
void Search_Medium_CachedPCRE(int i, int n)    { Search(i, n, MEDIUM, SearchCachedPCRE); }
void Search_Medium_CachedRE2(int i, int n)     { Search(i, n, MEDIUM, SearchCachedRE2); }

BENCHMARK_RANGE(Search_Medium_CachedDFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Medium_CachedNFA,     8, 256<<10)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Medium_CachedPCRE,    8, 256<<10)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Medium_CachedRE2,     8, 16<<20)->ThreadRange(1, NumCPUs());

void Search_Hard_CachedDFA(int i, int n)     { Search(i, n, HARD, SearchCachedDFA); }
void Search_Hard_CachedNFA(int i, int n)     { Search(i, n, HARD, SearchCachedNFA); }
void Search_Hard_CachedPCRE(int i, int n)    { Search(i, n, HARD, SearchCachedPCRE); }
void Search_Hard_CachedRE2(int i, int n)     { Search(i, n, HARD, SearchCachedRE2); }

BENCHMARK_RANGE(Search_Hard_CachedDFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Hard_CachedNFA,     8, 256<<10)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Hard_CachedPCRE,    8, 4<<10)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Hard_CachedRE2,     8, 16<<20)->ThreadRange(1, NumCPUs());

void Search_Parens_CachedDFA(int i, int n)     { Search(i, n, PARENS, SearchCachedDFA); }
void Search_Parens_CachedNFA(int i, int n)     { Search(i, n, PARENS, SearchCachedNFA); }
void Search_Parens_CachedPCRE(int i, int n)    { Search(i, n, PARENS, SearchCachedPCRE); }
void Search_Parens_CachedRE2(int i, int n)     { Search(i, n, PARENS, SearchCachedRE2); }

BENCHMARK_RANGE(Search_Parens_CachedDFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Parens_CachedNFA,     8, 256<<10)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Parens_CachedPCRE,    8, 8)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Parens_CachedRE2,     8, 16<<20)->ThreadRange(1, NumCPUs());

void SearchBigFixed(int iters, int nbytes, SearchImpl* search) {
  StopBenchmarkTiming();
  string s;
  s.append(nbytes/2, 'x');
  string regexp = "^" + s + ".*$";
  string t;
  MakeText(&t, nbytes/2);
  s += t;
  BenchmarkMemoryUsage();
  StartBenchmarkTiming();
  search(iters, regexp.c_str(), s, Prog::kUnanchored, true);
  SetBenchmarkBytesProcessed(static_cast<int64>(iters)*nbytes);
}

void Search_BigFixed_CachedDFA(int i, int n)     { SearchBigFixed(i, n, SearchCachedDFA); }
void Search_BigFixed_CachedNFA(int i, int n)     { SearchBigFixed(i, n, SearchCachedNFA); }
void Search_BigFixed_CachedPCRE(int i, int n)    { SearchBigFixed(i, n, SearchCachedPCRE); }
void Search_BigFixed_CachedRE2(int i, int n)     { SearchBigFixed(i, n, SearchCachedRE2); }

BENCHMARK_RANGE(Search_BigFixed_CachedDFA,     8, 1<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_BigFixed_CachedNFA,     8, 32<<10)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_BigFixed_CachedPCRE,    8, 32<<10)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_BigFixed_CachedRE2,     8, 1<<20)->ThreadRange(1, NumCPUs());

// Benchmark: FindAndConsume
void FindAndConsume(int iters, int nbytes) {
  StopBenchmarkTiming();
  string s;
  MakeText(&s, nbytes);
  s.append("Hello World");
  StartBenchmarkTiming();
  RE2 re("((Hello World))");
  for (int i = 0; i < iters; i++) {
    StringPiece t = s;
    StringPiece u;
    CHECK(RE2::FindAndConsume(&t, re, &u));
    CHECK_EQ(u, "Hello World");
  }
  SetBenchmarkBytesProcessed(static_cast<int64>(iters)*nbytes);
}

BENCHMARK_RANGE(FindAndConsume, 8, 16<<20)->ThreadRange(1, NumCPUs());

// Benchmark: successful anchored search.

void SearchSuccess(int iters, int nbytes, const char* regexp, SearchImpl* search) {
  string s;
  MakeText(&s, nbytes);
  BenchmarkMemoryUsage();
  search(iters, regexp, s, Prog::kAnchored, true);
  SetBenchmarkBytesProcessed(static_cast<int64>(iters)*nbytes);
}

// Unambiguous search (RE2 can use OnePass).

void Search_Success_DFA(int i, int n)     { SearchSuccess(i, n, ".*$", SearchDFA); }
void Search_Success_OnePass(int i, int n) { SearchSuccess(i, n, ".*$", SearchOnePass); }
void Search_Success_PCRE(int i, int n)    { SearchSuccess(i, n, ".*$", SearchPCRE); }
void Search_Success_RE2(int i, int n)     { SearchSuccess(i, n, ".*$", SearchRE2); }

BENCHMARK_RANGE(Search_Success_DFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success_PCRE,    8, 16<<20)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Success_RE2,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Success_OnePass, 8, 2<<20)->ThreadRange(1, NumCPUs());

void Search_Success_CachedDFA(int i, int n)     { SearchSuccess(i, n, ".*$", SearchCachedDFA); }
void Search_Success_CachedOnePass(int i, int n) { SearchSuccess(i, n, ".*$", SearchCachedOnePass); }
void Search_Success_CachedPCRE(int i, int n)    { SearchSuccess(i, n, ".*$", SearchCachedPCRE); }
void Search_Success_CachedRE2(int i, int n)     { SearchSuccess(i, n, ".*$", SearchCachedRE2); }

BENCHMARK_RANGE(Search_Success_CachedDFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success_CachedPCRE,    8, 16<<20)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Success_CachedRE2,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Success_CachedOnePass, 8, 2<<20)->ThreadRange(1, NumCPUs());

// Ambiguous search (RE2 cannot use OnePass).

void Search_Success1_DFA(int i, int n)     { SearchSuccess(i, n, ".*.$", SearchDFA); }
void Search_Success1_PCRE(int i, int n)    { SearchSuccess(i, n, ".*.$", SearchPCRE); }
void Search_Success1_RE2(int i, int n)     { SearchSuccess(i, n, ".*.$", SearchRE2); }
void Search_Success1_BitState(int i, int n)     { SearchSuccess(i, n, ".*.$", SearchBitState); }

BENCHMARK_RANGE(Search_Success1_DFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success1_PCRE,    8, 16<<20)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Success1_RE2,     8, 16<<20)->ThreadRange(1, NumCPUs());
BENCHMARK_RANGE(Search_Success1_BitState, 8, 2<<20)->ThreadRange(1, NumCPUs());

void Search_Success1_Cached_DFA(int i, int n)     { SearchSuccess(i, n, ".*.$", SearchCachedDFA); }
void Search_Success1_Cached_PCRE(int i, int n)    { SearchSuccess(i, n, ".*.$", SearchCachedPCRE); }
void Search_Success1_Cached_RE2(int i, int n)     { SearchSuccess(i, n, ".*.$", SearchCachedRE2); }

BENCHMARK_RANGE(Search_Success1_Cached_DFA,     8, 16<<20)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK_RANGE(Search_Success1_Cached_PCRE,    8, 16<<20)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(Search_Success1_Cached_RE2,     8, 16<<20)->ThreadRange(1, NumCPUs());

// Benchmark: use regexp to find phone number.

void SearchDigits(int iters, SearchImpl* search) {
  const char *text = "650-253-0001";
  int len = strlen(text);
  BenchmarkMemoryUsage();
  search(iters, "([0-9]+)-([0-9]+)-([0-9]+)",
         StringPiece(text, len), Prog::kAnchored, true);
  SetBenchmarkItemsProcessed(iters);
}

void Search_Digits_DFA(int i)         { SearchDigits(i, SearchDFA); }
void Search_Digits_NFA(int i)         { SearchDigits(i, SearchNFA); }
void Search_Digits_OnePass(int i)     { SearchDigits(i, SearchOnePass); }
void Search_Digits_PCRE(int i)        { SearchDigits(i, SearchPCRE); }
void Search_Digits_RE2(int i)         { SearchDigits(i, SearchRE2); }
void Search_Digits_BitState(int i)         { SearchDigits(i, SearchBitState); }

BENCHMARK(Search_Digits_DFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Search_Digits_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Search_Digits_OnePass)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK(Search_Digits_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Search_Digits_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Search_Digits_BitState)->ThreadRange(1, NumCPUs());

// Benchmark: use regexp to parse digit fields in phone number.

void Parse3Digits(int iters,
               void (*parse3)(int, const char*, const StringPiece&)) {
  BenchmarkMemoryUsage();
  parse3(iters, "([0-9]+)-([0-9]+)-([0-9]+)", "650-253-0001");
  SetBenchmarkItemsProcessed(iters);
}

void Parse_Digits_NFA(int i)         { Parse3Digits(i, Parse3NFA); }
void Parse_Digits_OnePass(int i)     { Parse3Digits(i, Parse3OnePass); }
void Parse_Digits_PCRE(int i)        { Parse3Digits(i, Parse3PCRE); }
void Parse_Digits_RE2(int i)         { Parse3Digits(i, Parse3RE2); }
void Parse_Digits_Backtrack(int i)   { Parse3Digits(i, Parse3Backtrack); }
void Parse_Digits_BitState(int i)   { Parse3Digits(i, Parse3BitState); }

BENCHMARK(Parse_Digits_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_Digits_OnePass)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK(Parse_Digits_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_Digits_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_Digits_Backtrack)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_Digits_BitState)->ThreadRange(1, NumCPUs());

void Parse_CachedDigits_NFA(int i)         { Parse3Digits(i, Parse3CachedNFA); }
void Parse_CachedDigits_OnePass(int i)     { Parse3Digits(i, Parse3CachedOnePass); }
void Parse_CachedDigits_PCRE(int i)        { Parse3Digits(i, Parse3CachedPCRE); }
void Parse_CachedDigits_RE2(int i)         { Parse3Digits(i, Parse3CachedRE2); }
void Parse_CachedDigits_Backtrack(int i)   { Parse3Digits(i, Parse3CachedBacktrack); }
void Parse_CachedDigits_BitState(int i)   { Parse3Digits(i, Parse3CachedBitState); }

BENCHMARK(Parse_CachedDigits_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedDigits_OnePass)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK(Parse_CachedDigits_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_CachedDigits_Backtrack)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedDigits_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedDigits_BitState)->ThreadRange(1, NumCPUs());

void Parse3DigitDs(int iters,
               void (*parse3)(int, const char*, const StringPiece&)) {
  BenchmarkMemoryUsage();
  parse3(iters, "(\\d+)-(\\d+)-(\\d+)", "650-253-0001");
  SetBenchmarkItemsProcessed(iters);
}

void Parse_DigitDs_NFA(int i)         { Parse3DigitDs(i, Parse3NFA); }
void Parse_DigitDs_OnePass(int i)     { Parse3DigitDs(i, Parse3OnePass); }
void Parse_DigitDs_PCRE(int i)        { Parse3DigitDs(i, Parse3PCRE); }
void Parse_DigitDs_RE2(int i)         { Parse3DigitDs(i, Parse3RE2); }
void Parse_DigitDs_Backtrack(int i)   { Parse3DigitDs(i, Parse3CachedBacktrack); }
void Parse_DigitDs_BitState(int i)   { Parse3DigitDs(i, Parse3CachedBitState); }

BENCHMARK(Parse_DigitDs_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_DigitDs_OnePass)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK(Parse_DigitDs_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_DigitDs_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_DigitDs_Backtrack)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_DigitDs_BitState)->ThreadRange(1, NumCPUs());

void Parse_CachedDigitDs_NFA(int i)         { Parse3DigitDs(i, Parse3CachedNFA); }
void Parse_CachedDigitDs_OnePass(int i)     { Parse3DigitDs(i, Parse3CachedOnePass); }
void Parse_CachedDigitDs_PCRE(int i)        { Parse3DigitDs(i, Parse3CachedPCRE); }
void Parse_CachedDigitDs_RE2(int i)         { Parse3DigitDs(i, Parse3CachedRE2); }
void Parse_CachedDigitDs_Backtrack(int i)   { Parse3DigitDs(i, Parse3CachedBacktrack); }
void Parse_CachedDigitDs_BitState(int i)   { Parse3DigitDs(i, Parse3CachedBitState); }

BENCHMARK(Parse_CachedDigitDs_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedDigitDs_OnePass)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK(Parse_CachedDigitDs_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_CachedDigitDs_Backtrack)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedDigitDs_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedDigitDs_BitState)->ThreadRange(1, NumCPUs());

// Benchmark: splitting off leading number field.

void Parse1Split(int iters,
              void (*parse1)(int, const char*, const StringPiece&)) {
  BenchmarkMemoryUsage();
  parse1(iters, "[0-9]+-(.*)", "650-253-0001");
  SetBenchmarkItemsProcessed(iters);
}

void Parse_Split_NFA(int i)         { Parse1Split(i, Parse1NFA); }
void Parse_Split_OnePass(int i)     { Parse1Split(i, Parse1OnePass); }
void Parse_Split_PCRE(int i)        { Parse1Split(i, Parse1PCRE); }
void Parse_Split_RE2(int i)         { Parse1Split(i, Parse1RE2); }
void Parse_Split_BitState(int i)         { Parse1Split(i, Parse1BitState); }

BENCHMARK(Parse_Split_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_Split_OnePass)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK(Parse_Split_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_Split_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_Split_BitState)->ThreadRange(1, NumCPUs());

void Parse_CachedSplit_NFA(int i)         { Parse1Split(i, Parse1CachedNFA); }
void Parse_CachedSplit_OnePass(int i)     { Parse1Split(i, Parse1CachedOnePass); }
void Parse_CachedSplit_PCRE(int i)        { Parse1Split(i, Parse1CachedPCRE); }
void Parse_CachedSplit_RE2(int i)         { Parse1Split(i, Parse1CachedRE2); }
void Parse_CachedSplit_BitState(int i)         { Parse1Split(i, Parse1CachedBitState); }

BENCHMARK(Parse_CachedSplit_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedSplit_OnePass)->ThreadRange(1, NumCPUs());
#ifdef USEPCRE
BENCHMARK(Parse_CachedSplit_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_CachedSplit_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedSplit_BitState)->ThreadRange(1, NumCPUs());

// Benchmark: splitting off leading number field but harder (ambiguous regexp).

void Parse1SplitHard(int iters,
                  void (*run)(int, const char*, const StringPiece&)) {
  BenchmarkMemoryUsage();
  run(iters, "[0-9]+.(.*)", "650-253-0001");
  SetBenchmarkItemsProcessed(iters);
}

void Parse_SplitHard_NFA(int i)         { Parse1SplitHard(i, Parse1NFA); }
void Parse_SplitHard_PCRE(int i)        { Parse1SplitHard(i, Parse1PCRE); }
void Parse_SplitHard_RE2(int i)         { Parse1SplitHard(i, Parse1RE2); }
void Parse_SplitHard_BitState(int i)         { Parse1SplitHard(i, Parse1BitState); }

#ifdef USEPCRE
BENCHMARK(Parse_SplitHard_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_SplitHard_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_SplitHard_BitState)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_SplitHard_NFA)->ThreadRange(1, NumCPUs());

void Parse_CachedSplitHard_NFA(int i)       { Parse1SplitHard(i, Parse1CachedNFA); }
void Parse_CachedSplitHard_PCRE(int i)      { Parse1SplitHard(i, Parse1CachedPCRE); }
void Parse_CachedSplitHard_RE2(int i)       { Parse1SplitHard(i, Parse1CachedRE2); }
void Parse_CachedSplitHard_BitState(int i)       { Parse1SplitHard(i, Parse1CachedBitState); }
void Parse_CachedSplitHard_Backtrack(int i)       { Parse1SplitHard(i, Parse1CachedBacktrack); }

#ifdef USEPCRE
BENCHMARK(Parse_CachedSplitHard_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_CachedSplitHard_RE2)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedSplitHard_BitState)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedSplitHard_NFA)->ThreadRange(1, NumCPUs());
BENCHMARK(Parse_CachedSplitHard_Backtrack)->ThreadRange(1, NumCPUs());

// Benchmark: Parse1SplitHard, big text, small match.

void Parse1SplitBig1(int iters,
                  void (*run)(int, const char*, const StringPiece&)) {
  string s;
  s.append(100000, 'x');
  s.append("650-253-0001");
  BenchmarkMemoryUsage();
  run(iters, "[0-9]+.(.*)", s);
  SetBenchmarkItemsProcessed(iters);
}

void Parse_CachedSplitBig1_PCRE(int i)      { Parse1SplitBig1(i, SearchParse1CachedPCRE); }
void Parse_CachedSplitBig1_RE2(int i)       { Parse1SplitBig1(i, SearchParse1CachedRE2); }

#ifdef USEPCRE
BENCHMARK(Parse_CachedSplitBig1_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_CachedSplitBig1_RE2)->ThreadRange(1, NumCPUs());

// Benchmark: Parse1SplitHard, big text, big match.

void Parse1SplitBig2(int iters,
                  void (*run)(int, const char*, const StringPiece&)) {
  string s;
  s.append("650-253-");
  s.append(100000, '0');
  BenchmarkMemoryUsage();
  run(iters, "[0-9]+.(.*)", s);
  SetBenchmarkItemsProcessed(iters);
}

void Parse_CachedSplitBig2_PCRE(int i)      { Parse1SplitBig2(i, SearchParse1CachedPCRE); }
void Parse_CachedSplitBig2_RE2(int i)       { Parse1SplitBig2(i, SearchParse1CachedRE2); }

#ifdef USEPCRE
BENCHMARK(Parse_CachedSplitBig2_PCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(Parse_CachedSplitBig2_RE2)->ThreadRange(1, NumCPUs());

// Benchmark: measure time required to parse (but not execute)
// a simple regular expression.

void ParseRegexp(int iters, const string& regexp) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    re->Decref();
  }
}

void SimplifyRegexp(int iters, const string& regexp) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Regexp* sre = re->Simplify();
    CHECK(sre);
    sre->Decref();
    re->Decref();
  }
}

void NullWalkRegexp(int iters, const string& regexp) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  for (int i = 0; i < iters; i++) {
    re->NullWalk();
  }
  re->Decref();
}

void SimplifyCompileRegexp(int iters, const string& regexp) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Regexp* sre = re->Simplify();
    CHECK(sre);
    Prog* prog = sre->CompileToProg(0);
    CHECK(prog);
    delete prog;
    sre->Decref();
    re->Decref();
  }
}

void CompileRegexp(int iters, const string& regexp) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    delete prog;
    re->Decref();
  }
}

void CompileToProg(int iters, const string& regexp) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  for (int i = 0; i < iters; i++) {
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    delete prog;
  }
  re->Decref();
}

void CompileByteMap(int iters, const string& regexp) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  for (int i = 0; i < iters; i++) {
    prog->ComputeByteMap();
  }
  delete prog;
  re->Decref();
}

void CompilePCRE(int iters, const string& regexp) {
  for (int i = 0; i < iters; i++) {
    PCRE re(regexp, PCRE::UTF8);
    CHECK_EQ(re.error(), "");
  }
}

void CompileRE2(int iters, const string& regexp) {
  for (int i = 0; i < iters; i++) {
    RE2 re(regexp);
    CHECK_EQ(re.error(), "");
  }
}

void RunBuild(int iters, const string& regexp, void (*run)(int, const string&)) {
  run(iters, regexp);
  SetBenchmarkItemsProcessed(iters);
}

}  // namespace re2

DEFINE_string(compile_regexp, "(.*)-(\\d+)-of-(\\d+)", "regexp for compile benchmarks");

namespace re2 {

void BM_PCRE_Compile(int i)      { RunBuild(i, FLAGS_compile_regexp, CompilePCRE); }
void BM_Regexp_Parse(int i)      { RunBuild(i, FLAGS_compile_regexp, ParseRegexp); }
void BM_Regexp_Simplify(int i)   { RunBuild(i, FLAGS_compile_regexp, SimplifyRegexp); }
void BM_CompileToProg(int i)     { RunBuild(i, FLAGS_compile_regexp, CompileToProg); }
void BM_CompileByteMap(int i)     { RunBuild(i, FLAGS_compile_regexp, CompileByteMap); }
void BM_Regexp_Compile(int i)    { RunBuild(i, FLAGS_compile_regexp, CompileRegexp); }
void BM_Regexp_SimplifyCompile(int i)   { RunBuild(i, FLAGS_compile_regexp, SimplifyCompileRegexp); }
void BM_Regexp_NullWalk(int i)   { RunBuild(i, FLAGS_compile_regexp, NullWalkRegexp); }
void BM_RE2_Compile(int i)       { RunBuild(i, FLAGS_compile_regexp, CompileRE2); }

#ifdef USEPCRE
BENCHMARK(BM_PCRE_Compile)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(BM_Regexp_Parse)->ThreadRange(1, NumCPUs());
BENCHMARK(BM_Regexp_Simplify)->ThreadRange(1, NumCPUs());
BENCHMARK(BM_CompileToProg)->ThreadRange(1, NumCPUs());
BENCHMARK(BM_CompileByteMap)->ThreadRange(1, NumCPUs());
BENCHMARK(BM_Regexp_Compile)->ThreadRange(1, NumCPUs());
BENCHMARK(BM_Regexp_SimplifyCompile)->ThreadRange(1, NumCPUs());
BENCHMARK(BM_Regexp_NullWalk)->ThreadRange(1, NumCPUs());
BENCHMARK(BM_RE2_Compile)->ThreadRange(1, NumCPUs());


// Makes text of size nbytes, then calls run to search
// the text for regexp iters times.
void SearchPhone(int iters, int nbytes, ParseImpl* search) {
  StopBenchmarkTiming();
  string s;
  MakeText(&s, nbytes);
  s.append("(650) 253-0001");
  BenchmarkMemoryUsage();
  StartBenchmarkTiming();
  search(iters, "(\\d{3}-|\\(\\d{3}\\)\\s+)(\\d{3}-\\d{4})", s);
  SetBenchmarkBytesProcessed(static_cast<int64>(iters)*nbytes);
}

void SearchPhone_CachedPCRE(int i, int n) {
  SearchPhone(i, n, SearchParse2CachedPCRE);
}
void SearchPhone_CachedRE2(int i, int n) {
  SearchPhone(i, n, SearchParse2CachedRE2);
}

#ifdef USEPCRE
BENCHMARK_RANGE(SearchPhone_CachedPCRE, 8, 16<<20)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK_RANGE(SearchPhone_CachedRE2, 8, 16<<20)->ThreadRange(1, NumCPUs());

/*
TODO(rsc): Make this work again.

// Generates and returns a string over binary alphabet {0,1} that contains
// all possible binary sequences of length n as subsequences.  The obvious
// brute force method would generate a string of length n * 2^n, but this
// generates a string of length n + 2^n - 1 called a De Bruijn cycle.
// See Knuth, The Art of Computer Programming, Vol 2, Exercise 3.2.2 #17.
static string DeBruijnString(int n) {
  CHECK_LT(n, 8*sizeof(int));
  CHECK_GT(n, 0);

  vector<bool> did(1<<n);
  for (int i = 0; i < 1<<n; i++)
    did[i] = false;

  string s;
  for (int i = 0; i < n-1; i++)
    s.append("0");
  int bits = 0;
  int mask = (1<<n) - 1;
  for (int i = 0; i < (1<<n); i++) {
    bits <<= 1;
    bits &= mask;
    if (!did[bits|1]) {
      bits |= 1;
      s.append("1");
    } else {
      s.append("0");
    }
    CHECK(!did[bits]);
    did[bits] = true;
  }
  return s;
}

void CacheFill(int iters, int n, SearchImpl *srch) {
  string s = DeBruijnString(n+1);
  string t;
  for (int i = n+1; i < 20; i++) {
    t = s + s;
    swap(s, t);
  }
  srch(iters, StringPrintf("0[01]{%d}$", n).c_str(), s,
       Prog::kUnanchored, true);
  SetBenchmarkBytesProcessed(static_cast<int64>(iters)*s.size());
}

void CacheFillPCRE(int i, int n) { CacheFill(i, n, SearchCachedPCRE); }
void CacheFillRE2(int i, int n)  { CacheFill(i, n, SearchCachedRE2); }
void CacheFillNFA(int i, int n)  { CacheFill(i, n, SearchCachedNFA); }
void CacheFillDFA(int i, int n)  { CacheFill(i, n, SearchCachedDFA); }

// BENCHMARK_WITH_ARG uses __LINE__ to generate distinct identifiers
// for the static BenchmarkRegisterer, which makes it unusable inside
// a macro like DO24 below.  MY_BENCHMARK_WITH_ARG uses the argument a
// to make the identifiers distinct (only possible when 'a' is a simple
// expression like 2, not like 1+1).
#define MY_BENCHMARK_WITH_ARG(n, a) \
  bool __benchmark_ ## n ## a =     \
    (new ::testing::Benchmark(#n, NewPermanentCallback(&n)))->ThreadRange(1, NumCPUs());

#define DO24(A, B) \
  A(B, 1);    A(B, 2);    A(B, 3);    A(B, 4);    A(B, 5);    A(B, 6);  \
  A(B, 7);    A(B, 8);    A(B, 9);    A(B, 10);   A(B, 11);   A(B, 12); \
  A(B, 13);   A(B, 14);   A(B, 15);   A(B, 16);   A(B, 17);   A(B, 18); \
  A(B, 19);   A(B, 20);   A(B, 21);   A(B, 22);   A(B, 23);   A(B, 24);

DO24(MY_BENCHMARK_WITH_ARG, CacheFillPCRE)
DO24(MY_BENCHMARK_WITH_ARG, CacheFillNFA)
DO24(MY_BENCHMARK_WITH_ARG, CacheFillRE2)
DO24(MY_BENCHMARK_WITH_ARG, CacheFillDFA)

#undef DO24
#undef MY_BENCHMARK_WITH_ARG
*/

////////////////////////////////////////////////////////////////////////
//
// Implementation routines.  Sad that there are so many,
// but all the interfaces are slightly different.

// Runs implementation to search for regexp in text, iters times.
// Expect_match says whether the regexp should be found.
// Anchored says whether to run an anchored search.

void SearchDFA(int iters, const char* regexp, const StringPiece& text,
            Prog::Anchor anchor, bool expect_match) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    bool failed = false;
    CHECK_EQ(prog->SearchDFA(text, NULL, anchor, Prog::kFirstMatch,
                             NULL, &failed, NULL),
             expect_match);
    CHECK(!failed);
    delete prog;
    re->Decref();
  }
}

void SearchNFA(int iters, const char* regexp, const StringPiece& text,
            Prog::Anchor anchor, bool expect_match) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    CHECK_EQ(prog->SearchNFA(text, NULL, anchor, Prog::kFirstMatch, NULL, 0),
             expect_match);
    delete prog;
    re->Decref();
  }
}

void SearchOnePass(int iters, const char* regexp, const StringPiece& text,
            Prog::Anchor anchor, bool expect_match) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    CHECK(prog->IsOnePass());
    CHECK_EQ(prog->SearchOnePass(text, text, anchor, Prog::kFirstMatch, NULL, 0),
             expect_match);
    delete prog;
    re->Decref();
  }
}

void SearchBitState(int iters, const char* regexp, const StringPiece& text,
            Prog::Anchor anchor, bool expect_match) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    CHECK_EQ(prog->SearchBitState(text, text, anchor, Prog::kFirstMatch, NULL, 0),
             expect_match);
    delete prog;
    re->Decref();
  }
}

void SearchPCRE(int iters, const char* regexp, const StringPiece& text,
                Prog::Anchor anchor, bool expect_match) {
  for (int i = 0; i < iters; i++) {
    PCRE re(regexp, PCRE::UTF8);
    CHECK_EQ(re.error(), "");
    if (anchor == Prog::kAnchored)
      CHECK_EQ(PCRE::FullMatch(text, re), expect_match);
    else
      CHECK_EQ(PCRE::PartialMatch(text, re), expect_match);
  }
}

void SearchRE2(int iters, const char* regexp, const StringPiece& text,
               Prog::Anchor anchor, bool expect_match) {
  for (int i = 0; i < iters; i++) {
    RE2 re(regexp);
    CHECK_EQ(re.error(), "");
    if (anchor == Prog::kAnchored)
      CHECK_EQ(RE2::FullMatch(text, re), expect_match);
    else
      CHECK_EQ(RE2::PartialMatch(text, re), expect_match);
  }
}

// SearchCachedXXX is like SearchXXX but only does the
// regexp parsing and compiling once.  This lets us measure
// search time without the per-regexp overhead.

void SearchCachedDFA(int iters, const char* regexp, const StringPiece& text,
                     Prog::Anchor anchor, bool expect_match) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(1LL<<31);
  CHECK(prog);
  for (int i = 0; i < iters; i++) {
    bool failed = false;
    CHECK_EQ(prog->SearchDFA(text, NULL, anchor,
                             Prog::kFirstMatch, NULL, &failed, NULL),
             expect_match);
    CHECK(!failed);
  }
  delete prog;
  re->Decref();
}

void SearchCachedNFA(int iters, const char* regexp, const StringPiece& text,
                     Prog::Anchor anchor, bool expect_match) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  for (int i = 0; i < iters; i++) {
    CHECK_EQ(prog->SearchNFA(text, NULL, anchor, Prog::kFirstMatch, NULL, 0),
             expect_match);
  }
  delete prog;
  re->Decref();
}

void SearchCachedOnePass(int iters, const char* regexp, const StringPiece& text,
                     Prog::Anchor anchor, bool expect_match) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  CHECK(prog->IsOnePass());
  for (int i = 0; i < iters; i++)
    CHECK_EQ(prog->SearchOnePass(text, text, anchor, Prog::kFirstMatch, NULL, 0),
             expect_match);
  delete prog;
  re->Decref();
}

void SearchCachedBitState(int iters, const char* regexp, const StringPiece& text,
                     Prog::Anchor anchor, bool expect_match) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  for (int i = 0; i < iters; i++)
    CHECK_EQ(prog->SearchBitState(text, text, anchor, Prog::kFirstMatch, NULL, 0),
             expect_match);
  delete prog;
  re->Decref();
}

void SearchCachedPCRE(int iters, const char* regexp, const StringPiece& text,
                     Prog::Anchor anchor, bool expect_match) {
  PCRE re(regexp, PCRE::UTF8);
  CHECK_EQ(re.error(), "");
  for (int i = 0; i < iters; i++) {
    if (anchor == Prog::kAnchored)
      CHECK_EQ(PCRE::FullMatch(text, re), expect_match);
    else
      CHECK_EQ(PCRE::PartialMatch(text, re), expect_match);
  }
}

void SearchCachedRE2(int iters, const char* regexp, const StringPiece& text,
                     Prog::Anchor anchor, bool expect_match) {
  RE2 re(regexp);
  CHECK_EQ(re.error(), "");
  for (int i = 0; i < iters; i++) {
    if (anchor == Prog::kAnchored)
      CHECK_EQ(RE2::FullMatch(text, re), expect_match);
    else
      CHECK_EQ(RE2::PartialMatch(text, re), expect_match);
  }
}


// Runs implementation to full match regexp against text,
// extracting three submatches.  Expects match always.

void Parse3NFA(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    StringPiece sp[4];  // 4 because sp[0] is whole match.
    CHECK(prog->SearchNFA(text, NULL, Prog::kAnchored, Prog::kFullMatch, sp, 4));
    delete prog;
    re->Decref();
  }
}

void Parse3OnePass(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    CHECK(prog->IsOnePass());
    StringPiece sp[4];  // 4 because sp[0] is whole match.
    CHECK(prog->SearchOnePass(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
    delete prog;
    re->Decref();
  }
}

void Parse3BitState(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    StringPiece sp[4];  // 4 because sp[0] is whole match.
    CHECK(prog->SearchBitState(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
    delete prog;
    re->Decref();
  }
}

void Parse3Backtrack(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    StringPiece sp[4];  // 4 because sp[0] is whole match.
    CHECK(prog->UnsafeSearchBacktrack(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
    delete prog;
    re->Decref();
  }
}

void Parse3PCRE(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    PCRE re(regexp, PCRE::UTF8);
    CHECK_EQ(re.error(), "");
    StringPiece sp1, sp2, sp3;
    CHECK(PCRE::FullMatch(text, re, &sp1, &sp2, &sp3));
  }
}

void Parse3RE2(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    RE2 re(regexp);
    CHECK_EQ(re.error(), "");
    StringPiece sp1, sp2, sp3;
    CHECK(RE2::FullMatch(text, re, &sp1, &sp2, &sp3));
  }
}

void Parse3CachedNFA(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  StringPiece sp[4];  // 4 because sp[0] is whole match.
  for (int i = 0; i < iters; i++) {
    CHECK(prog->SearchNFA(text, NULL, Prog::kAnchored, Prog::kFullMatch, sp, 4));
  }
  delete prog;
  re->Decref();
}

void Parse3CachedOnePass(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  CHECK(prog->IsOnePass());
  StringPiece sp[4];  // 4 because sp[0] is whole match.
  for (int i = 0; i < iters; i++)
    CHECK(prog->SearchOnePass(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
  delete prog;
  re->Decref();
}

void Parse3CachedBitState(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  StringPiece sp[4];  // 4 because sp[0] is whole match.
  for (int i = 0; i < iters; i++)
    CHECK(prog->SearchBitState(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
  delete prog;
  re->Decref();
}

void Parse3CachedBacktrack(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  StringPiece sp[4];  // 4 because sp[0] is whole match.
  for (int i = 0; i < iters; i++)
    CHECK(prog->UnsafeSearchBacktrack(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 4));
  delete prog;
  re->Decref();
}

void Parse3CachedPCRE(int iters, const char* regexp, const StringPiece& text) {
  PCRE re(regexp, PCRE::UTF8);
  CHECK_EQ(re.error(), "");
  StringPiece sp1, sp2, sp3;
  for (int i = 0; i < iters; i++) {
    CHECK(PCRE::FullMatch(text, re, &sp1, &sp2, &sp3));
  }
}

void Parse3CachedRE2(int iters, const char* regexp, const StringPiece& text) {
  RE2 re(regexp);
  CHECK_EQ(re.error(), "");
  StringPiece sp1, sp2, sp3;
  for (int i = 0; i < iters; i++) {
    CHECK(RE2::FullMatch(text, re, &sp1, &sp2, &sp3));
  }
}


// Runs implementation to full match regexp against text,
// extracting three submatches.  Expects match always.

void Parse1NFA(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    StringPiece sp[2];  // 2 because sp[0] is whole match.
    CHECK(prog->SearchNFA(text, NULL, Prog::kAnchored, Prog::kFullMatch, sp, 2));
    delete prog;
    re->Decref();
  }
}

void Parse1OnePass(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    CHECK(prog->IsOnePass());
    StringPiece sp[2];  // 2 because sp[0] is whole match.
    CHECK(prog->SearchOnePass(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 2));
    delete prog;
    re->Decref();
  }
}

void Parse1BitState(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    StringPiece sp[2];  // 2 because sp[0] is whole match.
    CHECK(prog->SearchBitState(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 2));
    delete prog;
    re->Decref();
  }
}

void Parse1PCRE(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    PCRE re(regexp, PCRE::UTF8);
    CHECK_EQ(re.error(), "");
    StringPiece sp1;
    CHECK(PCRE::FullMatch(text, re, &sp1));
  }
}

void Parse1RE2(int iters, const char* regexp, const StringPiece& text) {
  for (int i = 0; i < iters; i++) {
    RE2 re(regexp);
    CHECK_EQ(re.error(), "");
    StringPiece sp1;
    CHECK(RE2::FullMatch(text, re, &sp1));
  }
}

void Parse1CachedNFA(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  StringPiece sp[2];  // 2 because sp[0] is whole match.
  for (int i = 0; i < iters; i++) {
    CHECK(prog->SearchNFA(text, NULL, Prog::kAnchored, Prog::kFullMatch, sp, 2));
  }
  delete prog;
  re->Decref();
}

void Parse1CachedOnePass(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  CHECK(prog->IsOnePass());
  StringPiece sp[2];  // 2 because sp[0] is whole match.
  for (int i = 0; i < iters; i++)
    CHECK(prog->SearchOnePass(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 2));
  delete prog;
  re->Decref();
}

void Parse1CachedBitState(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  StringPiece sp[2];  // 2 because sp[0] is whole match.
  for (int i = 0; i < iters; i++)
    CHECK(prog->SearchBitState(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 2));
  delete prog;
  re->Decref();
}

void Parse1CachedBacktrack(int iters, const char* regexp, const StringPiece& text) {
  Regexp* re = Regexp::Parse(regexp, Regexp::LikePerl, NULL);
  CHECK(re);
  Prog* prog = re->CompileToProg(0);
  CHECK(prog);
  StringPiece sp[2];  // 2 because sp[0] is whole match.
  for (int i = 0; i < iters; i++)
    CHECK(prog->UnsafeSearchBacktrack(text, text, Prog::kAnchored, Prog::kFullMatch, sp, 2));
  delete prog;
  re->Decref();
}

void Parse1CachedPCRE(int iters, const char* regexp, const StringPiece& text) {
  PCRE re(regexp, PCRE::UTF8);
  CHECK_EQ(re.error(), "");
  StringPiece sp1;
  for (int i = 0; i < iters; i++) {
    CHECK(PCRE::FullMatch(text, re, &sp1));
  }
}

void Parse1CachedRE2(int iters, const char* regexp, const StringPiece& text) {
  RE2 re(regexp);
  CHECK_EQ(re.error(), "");
  StringPiece sp1;
  for (int i = 0; i < iters; i++) {
    CHECK(RE2::FullMatch(text, re, &sp1));
  }
}

void SearchParse2CachedPCRE(int iters, const char* regexp,
                            const StringPiece& text) {
  PCRE re(regexp, PCRE::UTF8);
  CHECK_EQ(re.error(), "");
  for (int i = 0; i < iters; i++) {
    StringPiece sp1, sp2;
    CHECK(PCRE::PartialMatch(text, re, &sp1, &sp2));
  }
}

void SearchParse2CachedRE2(int iters, const char* regexp,
                           const StringPiece& text) {
  RE2 re(regexp);
  CHECK_EQ(re.error(), "");
  for (int i = 0; i < iters; i++) {
    StringPiece sp1, sp2;
    CHECK(RE2::PartialMatch(text, re, &sp1, &sp2));
  }
}

void SearchParse1CachedPCRE(int iters, const char* regexp,
                            const StringPiece& text) {
  PCRE re(regexp, PCRE::UTF8);
  CHECK_EQ(re.error(), "");
  for (int i = 0; i < iters; i++) {
    StringPiece sp1;
    CHECK(PCRE::PartialMatch(text, re, &sp1));
  }
}

void SearchParse1CachedRE2(int iters, const char* regexp,
                           const StringPiece& text) {
  RE2 re(regexp);
  CHECK_EQ(re.error(), "");
  for (int i = 0; i < iters; i++) {
    StringPiece sp1;
    CHECK(RE2::PartialMatch(text, re, &sp1));
  }
}

void EmptyPartialMatchPCRE(int n) {
  PCRE re("");
  for (int i = 0; i < n; i++) {
    PCRE::PartialMatch("", re);
  }
}

void EmptyPartialMatchRE2(int n) {
  RE2 re("");
  for (int i = 0; i < n; i++) {
    RE2::PartialMatch("", re);
  }
}
#ifdef USEPCRE
BENCHMARK(EmptyPartialMatchPCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(EmptyPartialMatchRE2)->ThreadRange(1, NumCPUs());

void SimplePartialMatchPCRE(int n) {
  PCRE re("abcdefg");
  for (int i = 0; i < n; i++) {
    PCRE::PartialMatch("abcdefg", re);
  }
}

void SimplePartialMatchRE2(int n) {
  RE2 re("abcdefg");
  for (int i = 0; i < n; i++) {
    RE2::PartialMatch("abcdefg", re);
  }
}
#ifdef USEPCRE
BENCHMARK(SimplePartialMatchPCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(SimplePartialMatchRE2)->ThreadRange(1, NumCPUs());

static string http_text =
  "GET /asdfhjasdhfasdlfhasdflkjasdfkljasdhflaskdjhf"
  "alksdjfhasdlkfhasdlkjfhasdljkfhadsjklf HTTP/1.1";

void HTTPPartialMatchPCRE(int n) {
  StringPiece a;
  PCRE re("(?-s)^(?:GET|POST) +([^ ]+) HTTP");
  for (int i = 0; i < n; i++) {
    PCRE::PartialMatch(http_text, re, &a);
  }
}

void HTTPPartialMatchRE2(int n) {
  StringPiece a;
  RE2 re("(?-s)^(?:GET|POST) +([^ ]+) HTTP");
  for (int i = 0; i < n; i++) {
    RE2::PartialMatch(http_text, re, &a);
  }
}

#ifdef USEPCRE
BENCHMARK(HTTPPartialMatchPCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(HTTPPartialMatchRE2)->ThreadRange(1, NumCPUs());

static string http_smalltext =
  "GET /abc HTTP/1.1";

void SmallHTTPPartialMatchPCRE(int n) {
  StringPiece a;
  PCRE re("(?-s)^(?:GET|POST) +([^ ]+) HTTP");
  for (int i = 0; i < n; i++) {
    PCRE::PartialMatch(http_text, re, &a);
  }
}

void SmallHTTPPartialMatchRE2(int n) {
  StringPiece a;
  RE2 re("(?-s)^(?:GET|POST) +([^ ]+) HTTP");
  for (int i = 0; i < n; i++) {
    RE2::PartialMatch(http_text, re, &a);
  }
}

#ifdef USEPCRE
BENCHMARK(SmallHTTPPartialMatchPCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(SmallHTTPPartialMatchRE2)->ThreadRange(1, NumCPUs());

void DotMatchPCRE(int n) {
  StringPiece a;
  PCRE re("(?-s)^(.+)");
  for (int i = 0; i < n; i++) {
    PCRE::PartialMatch(http_text, re, &a);
  }
}

void DotMatchRE2(int n) {
  StringPiece a;
  RE2 re("(?-s)^(.+)");
  for (int i = 0; i < n; i++) {
    RE2::PartialMatch(http_text, re, &a);
  }
}

#ifdef USEPCRE
BENCHMARK(DotMatchPCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(DotMatchRE2)->ThreadRange(1, NumCPUs());

void ASCIIMatchPCRE(int n) {
  StringPiece a;
  PCRE re("(?-s)^([ -~]+)");
  for (int i = 0; i < n; i++) {
    PCRE::PartialMatch(http_text, re, &a);
  }
}

void ASCIIMatchRE2(int n) {
  StringPiece a;
  RE2 re("(?-s)^([ -~]+)");
  for (int i = 0; i < n; i++) {
    RE2::PartialMatch(http_text, re, &a);
  }
}

#ifdef USEPCRE
BENCHMARK(ASCIIMatchPCRE)->ThreadRange(1, NumCPUs());
#endif
BENCHMARK(ASCIIMatchRE2)->ThreadRange(1, NumCPUs());

void FullMatchPCRE(int iter, int n, const char *regexp) {
  StopBenchmarkTiming();
  string s;
  MakeText(&s, n);
  s += "ABCDEFGHIJ";
  BenchmarkMemoryUsage();
  PCRE re(regexp);
  StartBenchmarkTiming();
  for (int i = 0; i < iter; i++)
    CHECK(PCRE::FullMatch(s, re));
  SetBenchmarkBytesProcessed(static_cast<int64>(iter)*n);
}

void FullMatchRE2(int iter, int n, const char *regexp) {
  StopBenchmarkTiming();
  string s;
  MakeText(&s, n);
  s += "ABCDEFGHIJ";
  BenchmarkMemoryUsage();
  RE2 re(regexp, RE2::Latin1);
  StartBenchmarkTiming();
  for (int i = 0; i < iter; i++)
    CHECK(RE2::FullMatch(s, re));
  SetBenchmarkBytesProcessed(static_cast<int64>(iter)*n);
}

void FullMatch_DotStar_CachedPCRE(int i, int n) { FullMatchPCRE(i, n, "(?s).*"); }
void FullMatch_DotStar_CachedRE2(int i, int n)  { FullMatchRE2(i, n, "(?s).*"); }

void FullMatch_DotStarDollar_CachedPCRE(int i, int n) { FullMatchPCRE(i, n, "(?s).*$"); }
void FullMatch_DotStarDollar_CachedRE2(int i, int n)  { FullMatchRE2(i, n, "(?s).*$"); }

void FullMatch_DotStarCapture_CachedPCRE(int i, int n) { FullMatchPCRE(i, n, "(?s)((.*)()()($))"); }
void FullMatch_DotStarCapture_CachedRE2(int i, int n)  { FullMatchRE2(i, n, "(?s)((.*)()()($))"); }

#ifdef USEPCRE
BENCHMARK_RANGE(FullMatch_DotStar_CachedPCRE, 8, 2<<20);
#endif
BENCHMARK_RANGE(FullMatch_DotStar_CachedRE2,  8, 2<<20);

#ifdef USEPCRE
BENCHMARK_RANGE(FullMatch_DotStarDollar_CachedPCRE, 8, 2<<20);
#endif
BENCHMARK_RANGE(FullMatch_DotStarDollar_CachedRE2,  8, 2<<20);

#ifdef USEPCRE
BENCHMARK_RANGE(FullMatch_DotStarCapture_CachedPCRE, 8, 2<<20);
#endif
BENCHMARK_RANGE(FullMatch_DotStarCapture_CachedRE2,  8, 2<<20);

}  // namespace re2
