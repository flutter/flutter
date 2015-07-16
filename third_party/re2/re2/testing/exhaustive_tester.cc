// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Exhaustive testing of regular expression matching.

// Each test picks an alphabet (e.g., "abc"), a maximum string length,
// a maximum regular expression length, and a maximum number of letters
// that can appear in the regular expression.  Given these parameters,
// it tries every possible regular expression and string, verifying that
// the NFA, DFA, and a trivial backtracking implementation agree about
// the location of the match.

#include <stdlib.h>
#include <stdio.h>

#ifndef LOGGING
#define LOGGING 0
#endif

#include "util/test.h"
#include "re2/testing/exhaustive_tester.h"
#include "re2/testing/tester.h"

DEFINE_bool(show_regexps, false, "show regexps during testing");

DEFINE_int32(max_bad_regexp_inputs, 1,
             "Stop testing a regular expression after finding this many "
             "strings that break it.");

// Compiled in debug mode, the usual tests run for over an hour.
// Have to cut it down to make the unit test machines happy.
DEFINE_bool(quick_debug_mode, true, "Run fewer tests in debug mode.");

namespace re2 {

static char* escape(const StringPiece& sp) {
  static char buf[512];
  char* p = buf;
  *p++ = '\"';
  for (int i = 0; i < sp.size(); i++) {
    if(p+5 >= buf+sizeof buf)
      LOG(FATAL) << "ExhaustiveTester escape: too long";
    if(sp[i] == '\\' || sp[i] == '\"') {
      *p++ = '\\';
      *p++ = sp[i];
    } else if(sp[i] == '\n') {
      *p++ = '\\';
      *p++ = 'n';
    } else {
      *p++ = sp[i];
    }
  }
  *p++ = '\"';
  *p = '\0';
  return buf;
}

static void PrintResult(const RE2& re, const StringPiece& input, RE2::Anchor anchor, StringPiece *m, int n) {
  if (!re.Match(input, 0, input.size(), anchor, m, n)) {
    printf("-");
    return;
  }
  for (int i = 0; i < n; i++) {
    if (i > 0)
      printf(" ");
    if (m[i].begin() == NULL)
      printf("-");
    else
      printf("%d-%d", static_cast<int>(m[i].begin() - input.begin()), static_cast<int>(m[i].end() - input.begin()));
  }
}
	
// Processes a single generated regexp.
// Compiles it using Regexp interface and PCRE, and then
// checks that NFA, DFA, and PCRE all return the same results.
void ExhaustiveTester::HandleRegexp(const string& const_regexp) {
  regexps_++;
  string regexp = const_regexp;
  if (!topwrapper_.empty())
    regexp = StringPrintf(topwrapper_.c_str(), regexp.c_str());

  if (FLAGS_show_regexps) {
    printf("\r%s", regexp.c_str());
    fflush(stdout);
  }

  if (LOGGING) {
    // Write out test cases and answers for use in testing
    // other implementations, such as Go's regexp package.
    if (randomstrings_)
      LOG(ERROR) << "Cannot log with random strings.";
    if (regexps_ == 1) {  // first
      printf("strings\n");
      strgen_.Reset();
      while (strgen_.HasNext())
        printf("%s\n", escape(strgen_.Next()));
      printf("regexps\n");
    }
    printf("%s\n", escape(regexp));

    RE2 re(regexp);
    RE2::Options longest;
    longest.set_longest_match(true);
    RE2 relongest(regexp, longest);
    int ngroup = re.NumberOfCapturingGroups()+1;
    StringPiece* group = new StringPiece[ngroup];

    strgen_.Reset();
    while (strgen_.HasNext()) {
      StringPiece input = strgen_.Next();
      PrintResult(re, input, RE2::ANCHOR_BOTH, group, ngroup);
      printf(";");
      PrintResult(re, input, RE2::UNANCHORED, group, ngroup);
      printf(";");
      PrintResult(relongest, input, RE2::ANCHOR_BOTH, group, ngroup);
      printf(";");
      PrintResult(relongest, input, RE2::UNANCHORED, group, ngroup);
      printf("\n");
    }
    delete[] group;
    return;
  }

  Tester tester(regexp);
  if (tester.error())
    return;

  strgen_.Reset();
  strgen_.GenerateNULL();
  if (randomstrings_)
    strgen_.Random(stringseed_, stringcount_);
  int bad_inputs = 0;
  while (strgen_.HasNext()) {
    tests_++;
    if (!tester.TestInput(strgen_.Next())) {
      failures_++;
      if (++bad_inputs >= FLAGS_max_bad_regexp_inputs)
        break;
    }
  }
}

// Runs an exhaustive test on the given parameters.
void ExhaustiveTest(int maxatoms, int maxops,
                    const vector<string>& alphabet,
                    const vector<string>& ops,
                    int maxstrlen, const vector<string>& stralphabet,
                    const string& wrapper,
                    const string& topwrapper) {
  if (DEBUG_MODE && FLAGS_quick_debug_mode) {
    if (maxatoms > 1)
      maxatoms--;
    if (maxops > 1)
      maxops--;
    if (maxstrlen > 1)
      maxstrlen--;
  }
  ExhaustiveTester t(maxatoms, maxops, alphabet, ops,
                     maxstrlen, stralphabet, wrapper,
                     topwrapper);
  t.Generate();
  if (!LOGGING) {
    printf("%d regexps, %d tests, %d failures [%d/%d str]\n",
           t.regexps(), t.tests(), t.failures(), maxstrlen, (int)stralphabet.size());
  }
  EXPECT_EQ(0, t.failures());
}

// Runs an exhaustive test using the given parameters and
// the basic egrep operators.
void EgrepTest(int maxatoms, int maxops, const string& alphabet,
               int maxstrlen, const string& stralphabet,
               const string& wrapper) {
  const char* tops[] = { "", "^(?:%s)", "(?:%s)$", "^(?:%s)$" };

  for (int i = 0; i < arraysize(tops); i++) {
    ExhaustiveTest(maxatoms, maxops,
                   Split("", alphabet),
                   RegexpGenerator::EgrepOps(),
                   maxstrlen,
                   Split("", stralphabet),
                   wrapper,
                   tops[i]);
  }
}

}  // namespace re2
