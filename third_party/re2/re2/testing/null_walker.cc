// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/test.h"
#include "re2/regexp.h"
#include "re2/walker-inl.h"

namespace re2 {

// Null walker.  For benchmarking the walker itself.

class NullWalker : public Regexp::Walker<bool> {
 public:
  NullWalker() { }
  bool PostVisit(Regexp* re, bool parent_arg, bool pre_arg,
                 bool* child_args, int nchild_args);

  bool ShortVisit(Regexp* re, bool a) {
    // Should never be called: we use Walk not WalkExponential.
    LOG(DFATAL) << "NullWalker::ShortVisit called";
    return a;
  }

 private:
  DISALLOW_EVIL_CONSTRUCTORS(NullWalker);
};

// Called after visiting re's children.  child_args contains the return
// value from each of the children's PostVisits (i.e., whether each child
// can match an empty string).  Returns whether this clause can match an
// empty string.
bool NullWalker::PostVisit(Regexp* re, bool parent_arg, bool pre_arg,
                                  bool* child_args, int nchild_args) {
  return false;
}

// Returns whether re can match an empty string.
void Regexp::NullWalk() {
  NullWalker w;
  w.Walk(this, false);
}

}  // namespace re2
