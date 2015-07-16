// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Dump the regexp into a string showing structure.
// Tested by parse_unittest.cc

// This function traverses the regexp recursively,
// meaning that on inputs like Regexp::Simplify of
// a{100}{100}{100}{100}{100}{100}{100}{100}{100}{100},
// it takes time and space exponential in the size of the
// original regular expression.  It can also use stack space
// linear in the size of the regular expression for inputs
// like ((((((((((((((((a*)*)*)*)*)*)*)*)*)*)*)*)*)*)*)*)*.
// IT IS NOT SAFE TO CALL FROM PRODUCTION CODE.
// As a result, Dump is provided only in the testing
// library (see BUILD).

#include <string>
#include <vector>
#include "util/test.h"
#include "re2/stringpiece.h"
#include "re2/regexp.h"

// Cause a link error if this file is used outside of testing.
DECLARE_string(test_tmpdir);

namespace re2 {

static const char* kOpcodeNames[] = {
  "bad",
  "no",
  "emp",
  "lit",
  "str",
  "cat",
  "alt",
  "star",
  "plus",
  "que",
  "rep",
  "cap",
  "dot",
  "byte",
  "bol",
  "eol",
  "wb",   // kRegexpWordBoundary
  "nwb",  // kRegexpNoWordBoundary
  "bot",
  "eot",
  "cc",
  "match",
};

// Create string representation of regexp with explicit structure.
// Nothing pretty, just for testing.
static void DumpRegexpAppending(Regexp* re, string* s) {
  if (re->op() < 0 || re->op() >= arraysize(kOpcodeNames)) {
    StringAppendF(s, "op%d", re->op());
  } else {
    switch (re->op()) {
      default:
        break;
      case kRegexpStar:
      case kRegexpPlus:
      case kRegexpQuest:
      case kRegexpRepeat:
        if (re->parse_flags() & Regexp::NonGreedy)
          s->append("n");
        break;
    }
    s->append(kOpcodeNames[re->op()]);
    if (re->op() == kRegexpLiteral && (re->parse_flags() & Regexp::FoldCase)) {
      Rune r = re->rune();
      if ('a' <= r && r <= 'z')
        s->append("fold");
    }
    if (re->op() == kRegexpLiteralString && (re->parse_flags() & Regexp::FoldCase)) {
      for (int i = 0; i < re->nrunes(); i++) {
        Rune r = re->runes()[i];
        if ('a' <= r && r <= 'z') {
          s->append("fold");
          break;
        }
      }
    }
  }
  s->append("{");
  switch (re->op()) {
    default:
      break;
    case kRegexpEndText:
      if (!(re->parse_flags() & Regexp::WasDollar)) {
        s->append("\\z");
      }
      break;
    case kRegexpLiteral: {
      Rune r = re->rune();
      char buf[UTFmax+1];
      buf[runetochar(buf, &r)] = 0;
      s->append(buf);
      break;
    }
    case kRegexpLiteralString:
      for (int i = 0; i < re->nrunes(); i++) {
        Rune r = re->runes()[i];
        char buf[UTFmax+1];
        buf[runetochar(buf, &r)] = 0;
        s->append(buf);
      }
      break;
    case kRegexpConcat:
    case kRegexpAlternate:
      for (int i = 0; i < re->nsub(); i++)
        DumpRegexpAppending(re->sub()[i], s);
      break;
    case kRegexpStar:
    case kRegexpPlus:
    case kRegexpQuest:
      DumpRegexpAppending(re->sub()[0], s);
      break;
    case kRegexpCapture:
      if (re->name()) {
        s->append(*re->name());
        s->append(":");
      }
      DumpRegexpAppending(re->sub()[0], s);
      break;
    case kRegexpRepeat:
      s->append(StringPrintf("%d,%d ", re->min(), re->max()));
      DumpRegexpAppending(re->sub()[0], s);
      break;
    case kRegexpCharClass: {
      string sep;
      for (CharClass::iterator it = re->cc()->begin();
           it != re->cc()->end(); ++it) {
        RuneRange rr = *it;
        s->append(sep);
        if (rr.lo == rr.hi)
          s->append(StringPrintf("%#x", rr.lo));
        else
          s->append(StringPrintf("%#x-%#x", rr.lo, rr.hi));
        sep = " ";
      }
      break;
    }
  }
  s->append("}");
}

string Regexp::Dump() {
  string s;

  // Make sure being called from a unit test.
  if (FLAGS_test_tmpdir.empty()) {
    LOG(ERROR) << "Cannot use except for testing.";
    return s;
  }

  DumpRegexpAppending(this, &s);
  return s;
}

}  // namespace re2
