// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Regular expression generator: generates all possible
// regular expressions within given parameters (see below for details).

#ifndef RE2_TESTING_REGEXP_GENERATOR_H__
#define RE2_TESTING_REGEXP_GENERATOR_H__

#include <string>
#include <vector>
#include "util/random.h"
#include "util/util.h"
#include "re2/stringpiece.h"

namespace re2 {

// Regular expression generator.
//
// Given a set of atom expressions like "a", "b", or "."
// and operators like "%s*", generates all possible regular expressions
// using at most maxbases base expressions and maxops operators.
// For each such expression re, calls HandleRegexp(re).
//
// Callers are expected to subclass RegexpGenerator and provide HandleRegexp.
//
class RegexpGenerator {
 public:
  RegexpGenerator(int maxatoms, int maxops, const vector<string>& atoms,
                  const vector<string>& ops);
  virtual ~RegexpGenerator() {}

  // Generates all the regular expressions, calling HandleRegexp(re) for each.
  void Generate();

  // Generates n random regular expressions, calling HandleRegexp(re) for each.
  void GenerateRandom(int32 seed, int n);

  // Handles a regular expression.  Must be provided by subclass.
  virtual void HandleRegexp(const string& regexp) = 0;

  // The egrep regexp operators: * + ? | and concatenation.
  static const vector<string>& EgrepOps();

 private:
  void RunPostfix(const vector<string>& post);
  void GeneratePostfix(vector<string>* post, int nstk, int ops, int lits);
  bool GenerateRandomPostfix(vector<string>* post, int nstk, int ops, int lits);

  int maxatoms_;           // Maximum number of atoms allowed in expr.
  int maxops_;             // Maximum number of ops allowed in expr.
  vector<string> atoms_;   // Possible atoms.
  vector<string> ops_;     // Possible ops.
  ACMRandom* acm_;         // Random generator.
  DISALLOW_EVIL_CONSTRUCTORS(RegexpGenerator);
};

// Helpers for preparing arguments to RegexpGenerator constructor.

// Returns one string for each character in s.
vector<string> Explode(const StringPiece& s);

// Splits string everywhere sep is found, returning
// vector of pieces.
vector<string> Split(const StringPiece& sep, const StringPiece& s);

}  // namespace re2

#endif  // RE2_TESTING_REGEXP_GENERATOR_H__
