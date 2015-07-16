// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// String generator: generates all possible strings of up to
// maxlen letters using the set of letters in alpha.
// Fetch strings using a Java-like Next()/HasNext() interface.

#ifndef RE2_TESTING_STRING_GENERATOR_H__
#define RE2_TESTING_STRING_GENERATOR_H__

#include <string>
#include <vector>
#include "util/util.h"
#include "util/random.h"
#include "re2/stringpiece.h"

namespace re2 {

class StringGenerator {
 public:
  StringGenerator(int maxlen, const vector<string>& alphabet);
  ~StringGenerator();
  const StringPiece& Next();
  bool HasNext() { return hasnext_; }

  // Resets generator to start sequence over.
  void Reset();

  // Causes generator to emit random strings for next n calls to Next().
  void Random(int32 seed, int n);

  // Causes generator to emit a NULL as the next call.
  void GenerateNULL();

 private:
  bool IncrementDigits();
  bool RandomDigits();

  // Global state.
  int maxlen_;               // Maximum length string to generate.
  vector<string> alphabet_;  // Alphabet, one string per letter.

  // Iteration state.
  StringPiece sp_;           // Last StringPiece returned by Next().
  string s_;                 // String data in last StringPiece returned by Next().
  bool hasnext_;             // Whether Next() can be called again.
  vector<int> digits_;       // Alphabet indices for next string.
  bool generate_null_;       // Whether to generate a NULL StringPiece next.
  bool random_;              // Whether generated strings are random.
  int nrandom_;              // Number of random strings left to generate.
  ACMRandom* acm_;           // Random number generator
  DISALLOW_EVIL_CONSTRUCTORS(StringGenerator);
};

}  // namespace re2

#endif  // RE2_TESTING_STRING_GENERATOR_H__
