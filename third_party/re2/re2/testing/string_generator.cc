// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// String generator: generates all possible strings of up to
// maxlen letters using the set of letters in alpha.
// Fetch strings using a Java-like Next()/HasNext() interface.

#include <string>
#include <vector>
#include "util/test.h"
#include "re2/testing/string_generator.h"

namespace re2 {

StringGenerator::StringGenerator(int maxlen, const vector<string>& alphabet)
    : maxlen_(maxlen), alphabet_(alphabet),
      generate_null_(false),
      random_(false), nrandom_(0), acm_(NULL) {

  // Degenerate case: no letters, no non-empty strings.
  if (alphabet_.size() == 0)
    maxlen_ = 0;

  // Next() will return empty string (digits_ is empty).
  hasnext_ = true;
}

StringGenerator::~StringGenerator() {
  delete acm_;
}

// Resets the string generator state to the beginning.
void StringGenerator::Reset() {
  digits_.clear();
  hasnext_ = true;
  random_ = false;
  nrandom_ = 0;
  generate_null_ = false;
}

// Increments the big number in digits_, returning true if successful.
// Returns false if all the numbers have been used.
bool StringGenerator::IncrementDigits() {
  // First try to increment the current number.
  for (int i = digits_.size() - 1; i >= 0; i--) {
    if (++digits_[i] < alphabet_.size())
      return true;
    digits_[i] = 0;
  }

  // If that failed, make a longer number.
  if (digits_.size() < maxlen_) {
    digits_.push_back(0);
    return true;
  }

  return false;
}

// Generates random digits_, return true if successful.
// Returns false if the random sequence is over.
bool StringGenerator::RandomDigits() {
  if (--nrandom_ <= 0)
    return false;

  // Pick length.
  int len = acm_->Uniform(maxlen_+1);
  digits_.resize(len);
  for (int i = 0; i < len; i++)
    digits_[i] = acm_->Uniform(alphabet_.size());
  return true;
}

// Returns the next string in the iteration, which is the one
// currently described by digits_.  Calls IncrementDigits
// after computing the string, so that it knows the answer
// for subsequent HasNext() calls.
const StringPiece& StringGenerator::Next() {
  CHECK(hasnext_);
  if (generate_null_) {
    generate_null_ = false;
    sp_ = NULL;
    return sp_;
  }
  s_.clear();
  for (int i = 0; i < digits_.size(); i++) {
    s_ += alphabet_[digits_[i]];
  }
  hasnext_ = random_ ? RandomDigits() : IncrementDigits();
  sp_ = s_;
  return sp_;
}

// Sets generator up to return n random strings.
void StringGenerator::Random(int32 seed, int n) {
  if (acm_ == NULL)
    acm_ = new ACMRandom(seed);
  else
    acm_->Reset(seed);

  random_ = true;
  nrandom_ = n;
  hasnext_ = nrandom_ > 0;
}

void StringGenerator::GenerateNULL() {
  generate_null_ = true;
  hasnext_ = true;
}

}  // namespace re2

