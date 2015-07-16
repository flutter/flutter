// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef RE2_TESTING_EXHAUSTIVE_TESTER_H__
#define RE2_TESTING_EXHAUSTIVE_TESTER_H__

#include <string>
#include <vector>
#include "util/util.h"
#include "re2/testing/regexp_generator.h"
#include "re2/testing/string_generator.h"

namespace re2 {

// Exhaustive regular expression test: generate all regexps within parameters,
// then generate all strings of a given length over a given alphabet,
// then check that NFA, DFA, and PCRE agree about whether each regexp matches
// each possible string, and if so, where the match is.
//
// Can also be used in a "random" mode that generates a given number
// of random regexp and strings, allowing testing of larger expressions
// and inputs.
class ExhaustiveTester : public RegexpGenerator {
 public:
  ExhaustiveTester(int maxatoms,
                   int maxops,
                   const vector<string>& alphabet,
                   const vector<string>& ops,
                   int maxstrlen,
                   const vector<string>& stralphabet,
                   const string& wrapper,
                   const string& topwrapper)
    : RegexpGenerator(maxatoms, maxops, alphabet, ops),
      strgen_(maxstrlen, stralphabet),
      wrapper_(wrapper),
      topwrapper_(topwrapper),
      regexps_(0), tests_(0), failures_(0),
      randomstrings_(0), stringseed_(0), stringcount_(0)  { }

  int regexps()  { return regexps_; }
  int tests()    { return tests_; }
  int failures() { return failures_; }

  // Needed for RegexpGenerator interface.
  void HandleRegexp(const string& regexp);

  // Causes testing to generate random input strings.
  void RandomStrings(int32 seed, int32 count) {
    randomstrings_ = true;
    stringseed_ = seed;
    stringcount_ = count;
  }

 private:
  StringGenerator strgen_;
  string wrapper_;      // Regexp wrapper - either empty or has one %s.
  string topwrapper_;   // Regexp top-level wrapper.
  int regexps_;   // Number of HandleRegexp calls
  int tests_;     // Number of regexp tests.
  int failures_;  // Number of tests failed.

  bool randomstrings_;  // Whether to use random strings
  int32 stringseed_;    // If so, the seed.
  int stringcount_;     // If so, how many to generate.
  DISALLOW_EVIL_CONSTRUCTORS(ExhaustiveTester);
};

// Runs an exhaustive test on the given parameters.
void ExhaustiveTest(int maxatoms, int maxops,
                    const vector<string>& alphabet,
                    const vector<string>& ops,
                    int maxstrlen, const vector<string>& stralphabet,
                    const string& wrapper,
                    const string& topwrapper);

// Runs an exhaustive test using the given parameters and
// the basic egrep operators.
void EgrepTest(int maxatoms, int maxops, const string& alphabet,
               int maxstrlen, const string& stralphabet,
               const string& wrapper);

}  // namespace re2

#endif  // RE2_TESTING_EXHAUSTIVE_TESTER_H__
