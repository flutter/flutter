// Copyright 2006-2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/test.h"
#include "util/thread.h"
#include "re2/prog.h"
#include "re2/re2.h"
#include "re2/regexp.h"
#include "re2/testing/regexp_generator.h"
#include "re2/testing/string_generator.h"

DECLARE_bool(re2_dfa_bail_when_slow);

DEFINE_int32(size, 8, "log2(number of DFA nodes)");
DEFINE_int32(repeat, 2, "Repetition count.");
DEFINE_int32(threads, 4, "number of threads");

namespace re2 {

// Check that multithreaded access to DFA class works.

// Helper thread: builds entire DFA for prog.
class BuildThread : public Thread {
 public:
  BuildThread(Prog* prog) : prog_(prog) {}
  virtual void Run() {
    CHECK(prog_->BuildEntireDFA(Prog::kFirstMatch));
  }

 private:
  Prog* prog_;
};

TEST(Multithreaded, BuildEntireDFA) {
  // Create regexp with 2^FLAGS_size states in DFA.
  string s = "a";
  for (int i = 0; i < FLAGS_size; i++)
    s += "[ab]";
  s += "b";

  // Check that single-threaded code works.
  {
    //LOG(INFO) << s;
    Regexp* re = Regexp::Parse(s.c_str(), Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);
    BuildThread* t = new BuildThread(prog);
    t->SetJoinable(true);
    t->Start();
    t->Join();
    delete t;
    delete prog;
    re->Decref();
  }

  // Build the DFA simultaneously in a bunch of threads.
  for (int i = 0; i < FLAGS_repeat; i++) {
    Regexp* re = Regexp::Parse(s.c_str(), Regexp::LikePerl, NULL);
    CHECK(re);
    Prog* prog = re->CompileToProg(0);
    CHECK(prog);

    vector<BuildThread*> threads;
    for (int j = 0; j < FLAGS_threads; j++) {
      BuildThread *t = new BuildThread(prog);
      t->SetJoinable(true);
      threads.push_back(t);
    }
    for (int j = 0; j < FLAGS_threads; j++)
      threads[j]->Start();
    for (int j = 0; j < FLAGS_threads; j++) {
      threads[j]->Join();
      delete threads[j];
    }

    // One more compile, to make sure everything is okay.
    prog->BuildEntireDFA(Prog::kFirstMatch);
    delete prog;
    re->Decref();
  }
}

// Check that DFA size requirements are followed.
// BuildEntireDFA will, like SearchDFA, stop building out
// the DFA once the memory limits are reached.
TEST(SingleThreaded, BuildEntireDFA) {
  // Create regexp with 2^30 states in DFA.
  string s = "a";
  for (int i = 0; i < 30; i++)
    s += "[ab]";
  s += "b";

  //LOG(INFO) << s;
  Regexp* re = Regexp::Parse(s.c_str(), Regexp::LikePerl, NULL);
  CHECK(re);
  int max = 24;
  for (int i = 17; i < max; i++) {
    int limit = 1<<i;
    int usage;
    //int progusage, dfamem;
    {
      testing::MallocCounter m(testing::MallocCounter::THIS_THREAD_ONLY);
      Prog* prog = re->CompileToProg(limit);
      CHECK(prog);
      //progusage = m.HeapGrowth();
      //dfamem = prog->dfa_mem();
      prog->BuildEntireDFA(Prog::kFirstMatch);
      prog->BuildEntireDFA(Prog::kLongestMatch);
      usage = m.HeapGrowth();
      delete prog;
    }
    if (!UsingMallocCounter)
      continue;
    //LOG(INFO) << StringPrintf("Limit %d: prog used %d, DFA budget %d, total %d\n",
    //                          limit, progusage, dfamem, usage);
    CHECK_GT(usage, limit*9/10);
    CHECK_LT(usage, limit + (16<<10));  // 16kB of slop okay
  }
  re->Decref();
}

// Generates and returns a string over binary alphabet {0,1} that contains
// all possible binary sequences of length n as subsequences.  The obvious
// brute force method would generate a string of length n * 2^n, but this
// generates a string of length n + 2^n - 1 called a De Bruijn cycle.
// See Knuth, The Art of Computer Programming, Vol 2, Exercise 3.2.2 #17.
// Such a string is useful for testing a DFA.  If you have a DFA
// where distinct last n bytes implies distinct states, then running on a
// DeBruijn string causes the DFA to need to create a new state at every
// position in the input, never reusing any states until it gets to the
// end of the string.  This is the worst possible case for DFA execution.
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

// Test that the DFA gets the right result even if it runs
// out of memory during a search.  The regular expression
// 0[01]{n}$ matches a binary string of 0s and 1s only if
// the (n+1)th-to-last character is a 0.  Matching this in
// a single forward pass (as done by the DFA) requires
// keeping one bit for each of the last n+1 characters
// (whether each was a 0), or 2^(n+1) possible states.
// If we run this regexp to search in a string that contains
// every possible n-character binary string as a substring,
// then it will have to run through at least 2^n states.
// States are big data structures -- certainly more than 1 byte --
// so if the DFA can search correctly while staying within a
// 2^n byte limit, it must be handling out-of-memory conditions
// gracefully.
TEST(SingleThreaded, SearchDFA) {
  // Choice of n is mostly arbitrary, except that:
  //   * making n too big makes the test run for too long.
  //   * making n too small makes the DFA refuse to run,
  //     because it has so little memory compared to the program size.
  // Empirically, n = 18 is a good compromise between the two.
  const int n = 18;

  Regexp* re = Regexp::Parse(StringPrintf("0[01]{%d}$", n),
                             Regexp::LikePerl, NULL);
  CHECK(re);

  // The De Bruijn string for n ends with a 1 followed by n 0s in a row,
  // which is not a match for 0[01]{n}$.  Adding one more 0 is a match.
  string no_match = DeBruijnString(n);
  string match = no_match + "0";

  // The De Bruijn string is the worst case input for this regexp.
  // By default, the DFA will notice that it is flushing its cache
  // too frequently and will bail out early, so that RE2 can use the
  // NFA implementation instead.  (The DFA loses its speed advantage
  // if it can't get a good cache hit rate.)
  // Tell the DFA to trudge along instead.
  FLAGS_re2_dfa_bail_when_slow = false;

  int64 usage;
  int64 peak_usage;
  {
    testing::MallocCounter m(testing::MallocCounter::THIS_THREAD_ONLY);
    Prog* prog = re->CompileToProg(1<<n);
    CHECK(prog);
    for (int i = 0; i < 10; i++) {
      bool matched, failed = false;
      matched = prog->SearchDFA(match, NULL,
                                Prog::kUnanchored, Prog::kFirstMatch,
                                NULL, &failed, NULL);
      CHECK(!failed);
      CHECK(matched);
      matched = prog->SearchDFA(no_match, NULL,
                                Prog::kUnanchored, Prog::kFirstMatch,
                                NULL, &failed, NULL);
      CHECK(!failed);
      CHECK(!matched);
    }
    usage = m.HeapGrowth();
    peak_usage = m.PeakHeapGrowth();
    delete prog;
  }
  re->Decref();

  if (!UsingMallocCounter)
    return;
  //LOG(INFO) << "usage " << usage << " " << peak_usage;
  CHECK_LT(usage, 1<<n);
  CHECK_LT(peak_usage, 1<<n);
}

// Helper thread: searches for match, which should match,
// and no_match, which should not.
class SearchThread : public Thread {
 public:
  SearchThread(Prog* prog, const StringPiece& match,
               const StringPiece& no_match)
    : prog_(prog), match_(match), no_match_(no_match) {}

  virtual void Run() {
    for (int i = 0; i < 2; i++) {
      bool matched, failed = false;
      matched = prog_->SearchDFA(match_, NULL,
                                 Prog::kUnanchored, Prog::kFirstMatch,
                                 NULL, &failed, NULL);
      CHECK(!failed);
      CHECK(matched);
      matched = prog_->SearchDFA(no_match_, NULL,
                                 Prog::kUnanchored, Prog::kFirstMatch,
                                 NULL, &failed, NULL);
      CHECK(!failed);
      CHECK(!matched);
    }
  }

 private:
  Prog* prog_;
  StringPiece match_;
  StringPiece no_match_;
};

TEST(Multithreaded, SearchDFA) {
  // Same as single-threaded test above.
  const int n = 18;
  Regexp* re = Regexp::Parse(StringPrintf("0[01]{%d}$", n),
                             Regexp::LikePerl, NULL);
  CHECK(re);
  string no_match = DeBruijnString(n);
  string match = no_match + "0";
  FLAGS_re2_dfa_bail_when_slow = false;

  // Check that single-threaded code works.
  {
    Prog* prog = re->CompileToProg(1<<n);
    CHECK(prog);
    SearchThread* t = new SearchThread(prog, match, no_match);
    t->SetJoinable(true);
    t->Start();
    t->Join();
    delete t;
    delete prog;
  }

  // Run the search simultaneously in a bunch of threads.
  // Reuse same flags for Multithreaded.BuildDFA above.
  for (int i = 0; i < FLAGS_repeat; i++) {
    //LOG(INFO) << "Search " << i;
    Prog* prog = re->CompileToProg(1<<n);
    CHECK(prog);

    vector<SearchThread*> threads;
    for (int j = 0; j < FLAGS_threads; j++) {
      SearchThread *t = new SearchThread(prog, match, no_match);
      t->SetJoinable(true);
      threads.push_back(t);
    }
    for (int j = 0; j < FLAGS_threads; j++)
      threads[j]->Start();
    for (int j = 0; j < FLAGS_threads; j++) {
      threads[j]->Join();
      delete threads[j];
    }
    delete prog;
  }
  re->Decref();
}

struct ReverseTest {
  const char *regexp;
  const char *text;
  bool match;
};

// Test that reverse DFA handles anchored/unanchored correctly.
// It's in the DFA interface but not used by RE2.
ReverseTest reverse_tests[] = {
  { "\\A(a|b)", "abc", true },
  { "(a|b)\\z", "cba", true },
  { "\\A(a|b)", "cba", false },
  { "(a|b)\\z", "abc", false },
};

TEST(DFA, ReverseMatch) {
  int nfail = 0;
  for (int i = 0; i < arraysize(reverse_tests); i++) {
    const ReverseTest& t = reverse_tests[i];
    Regexp* re = Regexp::Parse(t.regexp, Regexp::LikePerl, NULL);
    CHECK(re);
    Prog *prog = re->CompileToReverseProg(0);
    CHECK(prog);
    bool failed = false;
    bool matched = prog->SearchDFA(t.text, NULL, Prog::kUnanchored, Prog::kFirstMatch, NULL, &failed, NULL);
    if (matched != t.match) {
      LOG(ERROR) << t.regexp << " on " << t.text << ": want " << t.match;
      nfail++;
    }
    delete prog;
    re->Decref();
  }
  EXPECT_EQ(nfail, 0);
}

}  // namespace re2
