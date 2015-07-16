// Copyright 2010 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "re2/set.h"

#include "util/util.h"
#include "re2/stringpiece.h"
#include "re2/prog.h"
#include "re2/re2.h"
#include "re2/regexp.h"

using namespace re2;

RE2::Set::Set(const RE2::Options& options, RE2::Anchor anchor) {
  options_.Copy(options);
  anchor_ = anchor;
  prog_ = NULL;
  compiled_ = false;
}

RE2::Set::~Set() {
  for (int i = 0; i < re_.size(); i++)
    re_[i]->Decref();
  delete prog_;
}

int RE2::Set::Add(const StringPiece& pattern, string* error) {
  if (compiled_) {
    LOG(DFATAL) << "RE2::Set::Add after Compile";
    return -1;
  }

  Regexp::ParseFlags pf = static_cast<Regexp::ParseFlags>(
    options_.ParseFlags());

  RegexpStatus status;
  re2::Regexp* re = Regexp::Parse(pattern, pf, &status);
  if (re == NULL) {
    if (error != NULL)
      *error = status.Text();
    if (options_.log_errors())
      LOG(ERROR) << "Error parsing '" << pattern << "': " << status.Text();
    return -1;
  }

  // Concatenate with match index and push on vector.
  int n = re_.size();
  re2::Regexp* m = re2::Regexp::HaveMatch(n, pf);
  if (re->op() == kRegexpConcat) {
    int nsub = re->nsub();
    re2::Regexp** sub = new re2::Regexp*[nsub + 1];
    for (int i = 0; i < nsub; i++)
      sub[i] = re->sub()[i]->Incref();
    sub[nsub] = m;
    re->Decref();
    re = re2::Regexp::Concat(sub, nsub + 1, pf);
    delete[] sub;
  } else {
    re2::Regexp* sub[2];
    sub[0] = re;
    sub[1] = m;
    re = re2::Regexp::Concat(sub, 2, pf);
  }
  re_.push_back(re);
  return n;
}

bool RE2::Set::Compile() {
  if (compiled_) {
    LOG(DFATAL) << "RE2::Set::Compile multiple times";
    return false;
  }
  compiled_ = true;

  Regexp::ParseFlags pf = static_cast<Regexp::ParseFlags>(
    options_.ParseFlags());
  re2::Regexp* re = re2::Regexp::Alternate(const_cast<re2::Regexp**>(&re_[0]),
                                           re_.size(), pf);
  re_.clear();
  re2::Regexp* sre = re->Simplify();
  re->Decref();
  re = sre;
  if (re == NULL) {
    if (options_.log_errors())
      LOG(ERROR) << "Error simplifying during Compile.";
    return false;
  }

  prog_ = Prog::CompileSet(options_, anchor_, re);
  return prog_ != NULL;
}

bool RE2::Set::Match(const StringPiece& text, vector<int>* v) const {
  if (!compiled_) {
    LOG(DFATAL) << "RE2::Set::Match without Compile";
    return false;
  }
  v->clear();
  bool failed;
  bool ret = prog_->SearchDFA(text, text, Prog::kAnchored,
                              Prog::kManyMatch, NULL, &failed, v);
  if (failed)
    LOG(DFATAL) << "RE2::Set::Match: DFA ran out of cache space";

  if (ret == false)
    return false;
  if (v->size() == 0) {
    LOG(DFATAL) << "RE2::Set::Match: match but unknown regexp set";
    return false;
  }
  return true;
}
