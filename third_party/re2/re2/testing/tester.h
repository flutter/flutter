// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Comparative tester for regular expression matching.
// Checks all implementations against each other.

#ifndef RE2_TESTING_TESTER_H__
#define RE2_TESTING_TESTER_H__

#include "re2/stringpiece.h"
#include "re2/prog.h"
#include "re2/regexp.h"
#include "re2/re2.h"
#include "util/pcre.h"

namespace re2 {

class Regexp;

// All the supported regexp engines.
enum Engine {
  kEngineBacktrack = 0,    // Prog::BadSearchBacktrack
  kEngineNFA,              // Prog::SearchNFA
  kEngineDFA,              // Prog::SearchDFA, only ask whether it matched
  kEngineDFA1,             // Prog::SearchDFA, ask for match[0]
  kEngineOnePass,          // Prog::SearchOnePass, if applicable
  kEngineBitState,         // Prog::SearchBitState
  kEngineRE2,              // RE2, all submatches
  kEngineRE2a,             // RE2, only ask for match[0]
  kEngineRE2b,             // RE2, only ask whether it matched
  kEnginePCRE,             // PCRE (util/pcre.h)

  kEngineMax,
};

// Make normal math on the enum preserve the type.
// By default, C++ doesn't define ++ on enum, and e+1 has type int.
static inline void operator++(Engine& e, int unused) {
  e = static_cast<Engine>(e+1);
}

static inline Engine operator+(Engine e, int i) {
  return static_cast<Engine>(static_cast<int>(e)+i);
}

// A TestInstance caches per-regexp state for a given
// regular expression in a given configuration
// (UTF-8 vs Latin1, longest vs first match, etc.).
class TestInstance {
 public:
  struct Result;

  TestInstance(const StringPiece& regexp, Prog::MatchKind kind,
               Regexp::ParseFlags flags);
  ~TestInstance();
  Regexp::ParseFlags flags() { return flags_; }
  bool error() { return error_; }

  // Runs a single test case: search in text, which is in context,
  // using the given anchoring.
  bool RunCase(const StringPiece& text, const StringPiece& context,
               Prog::Anchor anchor);

 private:
  // Runs a single search using the named engine type.
  void RunSearch(Engine type,
                 const StringPiece& text, const StringPiece& context,
                 Prog::Anchor anchor,
                 Result *result);

  void LogMatch(const char* prefix, Engine e, const StringPiece& text,
                const StringPiece& context, Prog::Anchor anchor);

  const StringPiece& regexp_str_;   // regexp being tested
  Prog::MatchKind kind_;            // kind of match
  Regexp::ParseFlags flags_;        // flags for parsing regexp_str_
  bool error_;                      // error during constructor?

  Regexp* regexp_;                  // parsed regexp
  int num_captures_;                // regexp_->NumCaptures() cached
  Prog* prog_;                      // compiled program
  Prog* rprog_;                     // compiled reverse program
  PCRE* re_;                        // PCRE implementation
  RE2* re2_;                        // RE2 implementation

  DISALLOW_EVIL_CONSTRUCTORS(TestInstance);
};

// A group of TestInstances for all possible configurations.
class Tester {
 public:
  explicit Tester(const StringPiece& regexp);
  ~Tester();

  bool error() { return error_; }

  // Runs a single test case: search in text, which is in context,
  // using the given anchoring.
  bool TestCase(const StringPiece& text, const StringPiece& context,
                Prog::Anchor anchor);

  // Run TestCase(text, text, anchor) for all anchoring modes.
  bool TestInput(const StringPiece& text);

  // Run TestCase(text, context, anchor) for all anchoring modes.
  bool TestInputInContext(const StringPiece& text, const StringPiece& context);

 private:
  bool error_;
  vector<TestInstance*> v_;

  DISALLOW_EVIL_CONSTRUCTORS(Tester);
};

// Run all possible tests using regexp and text.
bool TestRegexpOnText(const StringPiece& regexp, const StringPiece& text);

}  // namespace re2

#endif  // RE2_TESTING_TESTER_H__
