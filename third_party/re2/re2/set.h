// Copyright 2010 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef RE2_SET_H
#define RE2_SET_H

#include <utility>
#include <vector>

#include "re2/re2.h"

namespace re2 {
using std::vector;

// An RE2::Set represents a collection of regexps that can
// be searched for simultaneously.
class RE2::Set {
 public:
  Set(const RE2::Options& options, RE2::Anchor anchor);
  ~Set();

  // Add adds regexp pattern to the set, interpreted using the RE2 options.
  // (The RE2 constructor's default options parameter is RE2::UTF8.)
  // Add returns the regexp index that will be used to identify
  // it in the result of Match, or -1 if the regexp cannot be parsed.
  // Indices are assigned in sequential order starting from 0.
  // Error returns do not increment the index.
  // If an error occurs and error != NULL, *error will hold an error message.
  int Add(const StringPiece& pattern, string* error);

  // Compile prepares the Set for matching.
  // Add must not be called again after Compile.
  // Compile must be called before FullMatch or PartialMatch.
  // Compile may return false if it runs out of memory.
  bool Compile();

  // Match returns true if text matches any of the regexps in the set.
  // If so, it fills v with the indices of the matching regexps.
  bool Match(const StringPiece& text, vector<int>* v) const;

 private:
  RE2::Options options_;
  RE2::Anchor anchor_;
  vector<re2::Regexp*> re_;
  re2::Prog* prog_;
  bool compiled_;
  //DISALLOW_EVIL_CONSTRUCTORS(Set);
  Set(const Set&);
  void operator=(const Set&);
};

}  // namespace re2

#endif  // RE2_SET_H
