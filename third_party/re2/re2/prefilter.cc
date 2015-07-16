// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/util.h"
#include "re2/prefilter.h"
#include "re2/re2.h"
#include "re2/unicode_casefold.h"
#include "re2/walker-inl.h"

namespace re2 {

static const int Trace = false;

typedef set<string>::iterator SSIter;
typedef set<string>::const_iterator ConstSSIter;

static int alloc_id = 100000;  // Used for debugging.
// Initializes a Prefilter, allocating subs_ as necessary.
Prefilter::Prefilter(Op op) {
  op_ = op;
  subs_ = NULL;
  if (op_ == AND || op_ == OR)
    subs_ = new vector<Prefilter*>;

  alloc_id_ = alloc_id++;
  VLOG(10) << "alloc_id: " << alloc_id_;
}

// Destroys a Prefilter.
Prefilter::~Prefilter() {
  VLOG(10) << "Deleted: " << alloc_id_;
  if (subs_) {
    for (int i = 0; i < subs_->size(); i++)
      delete (*subs_)[i];
    delete subs_;
    subs_ = NULL;
  }
}

// Simplify if the node is an empty Or or And.
Prefilter* Prefilter::Simplify() {
  if (op_ != AND && op_ != OR) {
    return this;
  }

  // Nothing left in the AND/OR.
  if (subs_->size() == 0) {
    if (op_ == AND)
      op_ = ALL;  // AND of nothing is true
    else
      op_ = NONE;  // OR of nothing is false

    return this;
  }

  // Just one subnode: throw away wrapper.
  if (subs_->size() == 1) {
    Prefilter* a = (*subs_)[0];
    subs_->clear();
    delete this;
    return a->Simplify();
  }

  return this;
}

// Combines two Prefilters together to create an "op" (AND or OR).
// The passed Prefilters will be part of the returned Prefilter or deleted.
// Does lots of work to avoid creating unnecessarily complicated structures.
Prefilter* Prefilter::AndOr(Op op, Prefilter* a, Prefilter* b) {
  // If a, b can be rewritten as op, do so.
  a = a->Simplify();
  b = b->Simplify();

  // Canonicalize: a->op <= b->op.
  if (a->op() > b->op()) {
    Prefilter* t = a;
    a = b;
    b = t;
  }

  // Trivial cases.
  //    ALL AND b = b
  //    NONE OR b = b
  //    ALL OR b   = ALL
  //    NONE AND b = NONE
  // Don't need to look at b, because of canonicalization above.
  // ALL and NONE are smallest opcodes.
  if (a->op() == ALL || a->op() == NONE) {
    if ((a->op() == ALL && op == AND) ||
        (a->op() == NONE && op == OR)) {
      delete a;
      return b;
    } else {
      delete b;
      return a;
    }
  }

  // If a and b match op, merge their contents.
  if (a->op() == op && b->op() == op) {
    for (int i = 0; i < b->subs()->size(); i++) {
      Prefilter* bb = (*b->subs())[i];
      a->subs()->push_back(bb);
    }
    b->subs()->clear();
    delete b;
    return a;
  }

  // If a already has the same op as the op that is under construction
  // add in b (similarly if b already has the same op, add in a).
  if (b->op() == op) {
    Prefilter* t = a;
    a = b;
    b = t;
  }
  if (a->op() == op) {
    a->subs()->push_back(b);
    return a;
  }

  // Otherwise just return the op.
  Prefilter* c = new Prefilter(op);
  c->subs()->push_back(a);
  c->subs()->push_back(b);
  return c;
}

Prefilter* Prefilter::And(Prefilter* a, Prefilter* b) {
  return AndOr(AND, a, b);
}

Prefilter* Prefilter::Or(Prefilter* a, Prefilter* b) {
  return AndOr(OR, a, b);
}

static void SimplifyStringSet(set<string> *ss) {
  // Now make sure that the strings aren't redundant.  For example, if
  // we know "ab" is a required string, then it doesn't help at all to
  // know that "abc" is also a required string, so delete "abc". This
  // is because, when we are performing a string search to filter
  // regexps, matching ab will already allow this regexp to be a
  // candidate for match, so further matching abc is redundant.

  for (SSIter i = ss->begin(); i != ss->end(); ++i) {
    SSIter j = i;
    ++j;
    while (j != ss->end()) {
      // Increment j early so that we can erase the element it points to.
      SSIter old_j = j;
      ++j;
      if (old_j->find(*i) != string::npos)
        ss->erase(old_j);
    }
  }
}

Prefilter* Prefilter::OrStrings(set<string>* ss) {
  SimplifyStringSet(ss);
  Prefilter* or_prefilter = NULL;
  if (!ss->empty()) {
    or_prefilter = new Prefilter(NONE);
    for (SSIter i = ss->begin(); i != ss->end(); ++i)
      or_prefilter = Or(or_prefilter, FromString(*i));
  }
  return or_prefilter;
}

static Rune ToLowerRune(Rune r) {
  if (r < Runeself) {
    if ('A' <= r && r <= 'Z')
      r += 'a' - 'A';
    return r;
  }

  CaseFold *f = LookupCaseFold(unicode_tolower, num_unicode_tolower, r);
  if (f == NULL || r < f->lo)
    return r;
  return ApplyFold(f, r);
}

static Rune ToLowerRuneLatin1(Rune r) {
  if ('A' <= r && r <= 'Z')
    r += 'a' - 'A';
  return r;
}

Prefilter* Prefilter::FromString(const string& str) {
  Prefilter* m = new Prefilter(Prefilter::ATOM);
  m->atom_ = str;
  return m;
}

// Information about a regexp used during computation of Prefilter.
// Can be thought of as information about the set of strings matching
// the given regular expression.
class Prefilter::Info {
 public:
  Info();
  ~Info();

  // More constructors.  They delete their Info* arguments.
  static Info* Alt(Info* a, Info* b);
  static Info* Concat(Info* a, Info* b);
  static Info* And(Info* a, Info* b);
  static Info* Star(Info* a);
  static Info* Plus(Info* a);
  static Info* Quest(Info* a);
  static Info* EmptyString();
  static Info* NoMatch();
  static Info* AnyChar();
  static Info* CClass(CharClass* cc, bool latin1);
  static Info* Literal(Rune r);
  static Info* LiteralLatin1(Rune r);
  static Info* AnyMatch();

  // Format Info as a string.
  string ToString();

  // Caller takes ownership of the Prefilter.
  Prefilter* TakeMatch();

  set<string>& exact() { return exact_; }

  bool is_exact() const { return is_exact_; }

  class Walker;

 private:
  set<string> exact_;

  // When is_exact_ is true, the strings that match
  // are placed in exact_. When it is no longer an exact
  // set of strings that match this RE, then is_exact_
  // is false and the match_ contains the required match
  // criteria.
  bool is_exact_;

  // Accumulated Prefilter query that any
  // match for this regexp is guaranteed to match.
  Prefilter* match_;
};


Prefilter::Info::Info()
  : is_exact_(false),
    match_(NULL) {
}

Prefilter::Info::~Info() {
  delete match_;
}

Prefilter* Prefilter::Info::TakeMatch() {
  if (is_exact_) {
    match_ = Prefilter::OrStrings(&exact_);
    is_exact_ = false;
  }
  Prefilter* m = match_;
  match_ = NULL;
  return m;
}

// Format a Info in string form.
string Prefilter::Info::ToString() {
  if (is_exact_) {
    int n = 0;
    string s;
    for (set<string>::iterator i = exact_.begin(); i != exact_.end(); ++i) {
      if (n++ > 0)
        s += ",";
      s += *i;
    }
    return s;
  }

  if (match_)
    return match_->DebugString();

  return "";
}

// Add the strings from src to dst.
static void CopyIn(const set<string>& src, set<string>* dst) {
  for (ConstSSIter i = src.begin(); i != src.end(); ++i)
    dst->insert(*i);
}

// Add the cross-product of a and b to dst.
// (For each string i in a and j in b, add i+j.)
static void CrossProduct(const set<string>& a,
                         const set<string>& b,
                         set<string>* dst) {
  for (ConstSSIter i = a.begin(); i != a.end(); ++i)
    for (ConstSSIter j = b.begin(); j != b.end(); ++j)
      dst->insert(*i + *j);
}

// Concats a and b. Requires that both are exact sets.
// Forms an exact set that is a crossproduct of a and b.
Prefilter::Info* Prefilter::Info::Concat(Info* a, Info* b) {
  if (a == NULL)
    return b;
  DCHECK(a->is_exact_);
  DCHECK(b && b->is_exact_);
  Info *ab = new Info();

  CrossProduct(a->exact_, b->exact_, &ab->exact_);
  ab->is_exact_ = true;

  delete a;
  delete b;
  return ab;
}

// Constructs an inexact Info for ab given a and b.
// Used only when a or b is not exact or when the
// exact cross product is likely to be too big.
Prefilter::Info* Prefilter::Info::And(Info* a, Info* b) {
  if (a == NULL)
    return b;
  if (b == NULL)
    return a;

  Info *ab = new Info();

  ab->match_ = Prefilter::And(a->TakeMatch(), b->TakeMatch());
  ab->is_exact_ = false;
  delete a;
  delete b;
  return ab;
}

// Constructs Info for a|b given a and b.
Prefilter::Info* Prefilter::Info::Alt(Info* a, Info* b) {
  Info *ab = new Info();

  if (a->is_exact_ && b->is_exact_) {
    CopyIn(a->exact_, &ab->exact_);
    CopyIn(b->exact_, &ab->exact_);
    ab->is_exact_ = true;
  } else {
    // Either a or b has is_exact_ = false. If the other
    // one has is_exact_ = true, we move it to match_ and
    // then create a OR of a,b. The resulting Info has
    // is_exact_ = false.
    ab->match_ = Prefilter::Or(a->TakeMatch(), b->TakeMatch());
    ab->is_exact_ = false;
  }

  delete a;
  delete b;
  return ab;
}

// Constructs Info for a? given a.
Prefilter::Info* Prefilter::Info::Quest(Info *a) {
  Info *ab = new Info();

  ab->is_exact_ = false;
  ab->match_ = new Prefilter(ALL);
  delete a;
  return ab;
}

// Constructs Info for a* given a.
// Same as a? -- not much to do.
Prefilter::Info* Prefilter::Info::Star(Info *a) {
  return Quest(a);
}

// Constructs Info for a+ given a. If a was exact set, it isn't
// anymore.
Prefilter::Info* Prefilter::Info::Plus(Info *a) {
  Info *ab = new Info();

  ab->match_ = a->TakeMatch();
  ab->is_exact_ = false;

  delete a;
  return ab;
}

static string RuneToString(Rune r) {
  char buf[UTFmax];
  int n = runetochar(buf, &r);
  return string(buf, n);
}

static string RuneToStringLatin1(Rune r) {
  char c = r & 0xff;
  return string(&c, 1);
}

// Constructs Info for literal rune.
Prefilter::Info* Prefilter::Info::Literal(Rune r) {
  Info* info = new Info();
  info->exact_.insert(RuneToString(ToLowerRune(r)));
  info->is_exact_ = true;
  return info;
}

// Constructs Info for literal rune for Latin1 encoded string.
Prefilter::Info* Prefilter::Info::LiteralLatin1(Rune r) {
  Info* info = new Info();
  info->exact_.insert(RuneToStringLatin1(ToLowerRuneLatin1(r)));
  info->is_exact_ = true;
  return info;
}

// Constructs Info for dot (any character).
Prefilter::Info* Prefilter::Info::AnyChar() {
  Prefilter::Info* info = new Prefilter::Info();
  info->match_ = new Prefilter(ALL);
  return info;
}

// Constructs Prefilter::Info for no possible match.
Prefilter::Info* Prefilter::Info::NoMatch() {
  Prefilter::Info* info = new Prefilter::Info();
  info->match_ = new Prefilter(NONE);
  return info;
}

// Constructs Prefilter::Info for any possible match.
// This Prefilter::Info is valid for any regular expression,
// since it makes no assertions whatsoever about the
// strings being matched.
Prefilter::Info* Prefilter::Info::AnyMatch() {
  Prefilter::Info *info = new Prefilter::Info();
  info->match_ = new Prefilter(ALL);
  return info;
}

// Constructs Prefilter::Info for just the empty string.
Prefilter::Info* Prefilter::Info::EmptyString() {
  Prefilter::Info* info = new Prefilter::Info();
  info->is_exact_ = true;
  info->exact_.insert("");
  return info;
}

// Constructs Prefilter::Info for a character class.
typedef CharClass::iterator CCIter;
Prefilter::Info* Prefilter::Info::CClass(CharClass *cc,
                                         bool latin1) {
  if (Trace) {
    VLOG(0) << "CharClassInfo:";
    for (CCIter i = cc->begin(); i != cc->end(); ++i)
      VLOG(0) << "  " << i->lo << "-" << i->hi;
  }

  // If the class is too large, it's okay to overestimate.
  if (cc->size() > 10)
    return AnyChar();

  Prefilter::Info *a = new Prefilter::Info();
  for (CCIter i = cc->begin(); i != cc->end(); ++i)
    for (Rune r = i->lo; r <= i->hi; r++) {
      if (latin1) {
        a->exact_.insert(RuneToStringLatin1(ToLowerRuneLatin1(r)));
      } else {
        a->exact_.insert(RuneToString(ToLowerRune(r)));
      }
    }


  a->is_exact_ = true;

  if (Trace) {
    VLOG(0) << " = " << a->ToString();
  }

  return a;
}

class Prefilter::Info::Walker : public Regexp::Walker<Prefilter::Info*> {
 public:
  Walker(bool latin1) : latin1_(latin1) {}

  virtual Info* PostVisit(
      Regexp* re, Info* parent_arg,
      Info* pre_arg,
      Info** child_args, int nchild_args);

  virtual Info* ShortVisit(
      Regexp* re,
      Info* parent_arg);

  bool latin1() { return latin1_; }
 private:
  bool latin1_;
  DISALLOW_EVIL_CONSTRUCTORS(Walker);
};

Prefilter::Info* Prefilter::BuildInfo(Regexp* re) {
  if (Trace) {
    LOG(INFO) << "BuildPrefilter::Info: " << re->ToString();
  }

  bool latin1 = re->parse_flags() & Regexp::Latin1;
  Prefilter::Info::Walker w(latin1);
  Prefilter::Info* info = w.WalkExponential(re, NULL, 100000);

  if (w.stopped_early()) {
    delete info;
    return NULL;
  }

  return info;
}

Prefilter::Info* Prefilter::Info::Walker::ShortVisit(
    Regexp* re, Prefilter::Info* parent_arg) {
  return AnyMatch();
}

// Constructs the Prefilter::Info for the given regular expression.
// Assumes re is simplified.
Prefilter::Info* Prefilter::Info::Walker::PostVisit(
    Regexp* re, Prefilter::Info* parent_arg,
    Prefilter::Info* pre_arg, Prefilter::Info** child_args,
    int nchild_args) {
  Prefilter::Info *info;
  switch (re->op()) {
    default:
    case kRegexpRepeat:
      LOG(DFATAL) << "Bad regexp op " << re->op();
      info = EmptyString();
      break;

    case kRegexpNoMatch:
      info = NoMatch();
      break;

    // These ops match the empty string:
    case kRegexpEmptyMatch:      // anywhere
    case kRegexpBeginLine:       // at beginning of line
    case kRegexpEndLine:         // at end of line
    case kRegexpBeginText:       // at beginning of text
    case kRegexpEndText:         // at end of text
    case kRegexpWordBoundary:    // at word boundary
    case kRegexpNoWordBoundary:  // not at word boundary
      info = EmptyString();
      break;

    case kRegexpLiteral:
      if (latin1()) {
        info = LiteralLatin1(re->rune());
      }
      else {
        info = Literal(re->rune());
      }
      break;

    case kRegexpLiteralString:
      if (re->nrunes() == 0) {
        info = NoMatch();
        break;
      }
      if (latin1()) {
        info = LiteralLatin1(re->runes()[0]);
        for (int i = 1; i < re->nrunes(); i++) {
          info = Concat(info, LiteralLatin1(re->runes()[i]));
        }
      } else {
        info = Literal(re->runes()[0]);
        for (int i = 1; i < re->nrunes(); i++) {
          info = Concat(info, Literal(re->runes()[i]));
        }
      }
      break;

    case kRegexpConcat: {
      // Accumulate in info.
      // Exact is concat of recent contiguous exact nodes.
      info = NULL;
      Info* exact = NULL;
      for (int i = 0; i < nchild_args; i++) {
        Info* ci = child_args[i];  // child info
        if (!ci->is_exact() ||
            (exact && ci->exact().size() * exact->exact().size() > 16)) {
          // Exact run is over.
          info = And(info, exact);
          exact = NULL;
          // Add this child's info.
          info = And(info, ci);
        } else {
          // Append to exact run.
          exact = Concat(exact, ci);
        }
      }
      info = And(info, exact);
    }
      break;

    case kRegexpAlternate:
      info = child_args[0];
      for (int i = 1; i < nchild_args; i++)
        info = Alt(info, child_args[i]);
      VLOG(10) << "Alt: " << info->ToString();
      break;

    case kRegexpStar:
      info = Star(child_args[0]);
      break;

    case kRegexpQuest:
      info = Quest(child_args[0]);
      break;

    case kRegexpPlus:
      info = Plus(child_args[0]);
      break;

    case kRegexpAnyChar:
      // Claim nothing, except that it's not empty.
      info = AnyChar();
      break;

    case kRegexpCharClass:
      info = CClass(re->cc(), latin1());
      break;

    case kRegexpCapture:
      // These don't affect the set of matching strings.
      info = child_args[0];
      break;
  }

  if (Trace) {
    VLOG(0) << "BuildInfo " << re->ToString()
            << ": " << (info ? info->ToString() : "");
  }

  return info;
}


Prefilter* Prefilter::FromRegexp(Regexp* re) {
  if (re == NULL)
    return NULL;

  Regexp* simple = re->Simplify();
  Prefilter::Info *info = BuildInfo(simple);

  simple->Decref();
  if (info == NULL)
    return NULL;

  Prefilter* m = info->TakeMatch();

  delete info;
  return m;
}

string Prefilter::DebugString() const {
  switch (op_) {
    default:
      LOG(DFATAL) << "Bad op in Prefilter::DebugString: " << op_;
      return StringPrintf("op%d", op_);
    case NONE:
      return "*no-matches*";
    case ATOM:
      return atom_;
    case ALL:
      return "";
    case AND: {
      string s = "";
      for (int i = 0; i < subs_->size(); i++) {
        if (i > 0)
          s += " ";
        Prefilter* sub = (*subs_)[i];
        s += sub ? sub->DebugString() : "<nil>";
      }
      return s;
    }
    case OR: {
      string s = "(";
      for (int i = 0; i < subs_->size(); i++) {
        if (i > 0)
          s += "|";
        Prefilter* sub = (*subs_)[i];
        s += sub ? sub->DebugString() : "<nil>";
      }
      s += ")";
      return s;
    }
  }
}

Prefilter* Prefilter::FromRE2(const RE2* re2) {
  if (re2 == NULL)
    return NULL;

  Regexp* regexp = re2->Regexp();
  if (regexp == NULL)
    return NULL;

  return FromRegexp(regexp);
}


}  // namespace re2
