// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Regular expression representation.
// Tested by parse_test.cc

#include "util/util.h"
#include "re2/regexp.h"
#include "re2/stringpiece.h"
#include "re2/walker-inl.h"

namespace re2 {

// Constructor.  Allocates vectors as appropriate for operator.
Regexp::Regexp(RegexpOp op, ParseFlags parse_flags)
  : op_(op),
    simple_(false),
    parse_flags_(static_cast<uint16>(parse_flags)),
    ref_(1),
    nsub_(0),
    down_(NULL) {
  subone_ = NULL;
  memset(the_union_, 0, sizeof the_union_);
}

// Destructor.  Assumes already cleaned up children.
// Private: use Decref() instead of delete to destroy Regexps.
// Can't call Decref on the sub-Regexps here because
// that could cause arbitrarily deep recursion, so
// required Decref() to have handled them for us.
Regexp::~Regexp() {
  if (nsub_ > 0)
    LOG(DFATAL) << "Regexp not destroyed.";

  switch (op_) {
    default:
      break;
    case kRegexpCapture:
      delete name_;
      break;
    case kRegexpLiteralString:
      delete[] runes_;
      break;
    case kRegexpCharClass:
      cc_->Delete();
      delete ccb_;
      break;
  }
}

// If it's possible to destroy this regexp without recurring,
// do so and return true.  Else return false.
bool Regexp::QuickDestroy() {
  if (nsub_ == 0) {
    delete this;
    return true;
  }
  return false;
}

static map<Regexp*, int> *ref_map;
GLOBAL_MUTEX(ref_mutex);

int Regexp::Ref() {
  if (ref_ < kMaxRef)
    return ref_;

  GLOBAL_MUTEX_LOCK(ref_mutex);
  int r = 0;
  if (ref_map != NULL) {
    r = (*ref_map)[this];
  }
  GLOBAL_MUTEX_UNLOCK(ref_mutex);
  return r;
}

// Increments reference count, returns object as convenience.
Regexp* Regexp::Incref() {
  if (ref_ >= kMaxRef-1) {
    // Store ref count in overflow map.
    GLOBAL_MUTEX_LOCK(ref_mutex);
    if (ref_map == NULL) {
      ref_map = new map<Regexp*, int>;
    }
    if (ref_ == kMaxRef) {
      // already overflowed
      (*ref_map)[this]++;
    } else {
      // overflowing now
      (*ref_map)[this] = kMaxRef;
      ref_ = kMaxRef;
    }
    GLOBAL_MUTEX_UNLOCK(ref_mutex);
    return this;
  }

  ref_++;
  return this;
}

// Decrements reference count and deletes this object if count reaches 0.
void Regexp::Decref() {
  if (ref_ == kMaxRef) {
    // Ref count is stored in overflow map.
    GLOBAL_MUTEX_LOCK(ref_mutex);
    int r = (*ref_map)[this] - 1;
    if (r < kMaxRef) {
      ref_ = r;
      ref_map->erase(this);
    } else {
      (*ref_map)[this] = r;
    }
    GLOBAL_MUTEX_UNLOCK(ref_mutex);
    return;
  }
  ref_--;
  if (ref_ == 0)
    Destroy();
}

// Deletes this object; ref count has count reached 0.
void Regexp::Destroy() {
  if (QuickDestroy())
    return;

  // Handle recursive Destroy with explicit stack
  // to avoid arbitrarily deep recursion on process stack [sigh].
  down_ = NULL;
  Regexp* stack = this;
  while (stack != NULL) {
    Regexp* re = stack;
    stack = re->down_;
    if (re->ref_ != 0)
      LOG(DFATAL) << "Bad reference count " << re->ref_;
    if (re->nsub_ > 0) {
      Regexp** subs = re->sub();
      for (int i = 0; i < re->nsub_; i++) {
        Regexp* sub = subs[i];
        if (sub == NULL)
          continue;
        if (sub->ref_ == kMaxRef)
          sub->Decref();
        else
          --sub->ref_;
        if (sub->ref_ == 0 && !sub->QuickDestroy()) {
          sub->down_ = stack;
          stack = sub;
        }
      }
      if (re->nsub_ > 1)
        delete[] subs;
      re->nsub_ = 0;
    }
    delete re;
  }
}

void Regexp::AddRuneToString(Rune r) {
  DCHECK(op_ == kRegexpLiteralString);
  if (nrunes_ == 0) {
    // start with 8
    runes_ = new Rune[8];
  } else if (nrunes_ >= 8 && (nrunes_ & (nrunes_ - 1)) == 0) {
    // double on powers of two
    Rune *old = runes_;
    runes_ = new Rune[nrunes_ * 2];
    for (int i = 0; i < nrunes_; i++)
      runes_[i] = old[i];
    delete[] old;
  }

  runes_[nrunes_++] = r;
}

Regexp* Regexp::HaveMatch(int match_id, ParseFlags flags) {
  Regexp* re = new Regexp(kRegexpHaveMatch, flags);
  re->match_id_ = match_id;
  return re;
}

Regexp* Regexp::Plus(Regexp* sub, ParseFlags flags) {
  if (sub->op() == kRegexpPlus && sub->parse_flags() == flags)
    return sub;
  Regexp* re = new Regexp(kRegexpPlus, flags);
  re->AllocSub(1);
  re->sub()[0] = sub;
  return re;
}

Regexp* Regexp::Star(Regexp* sub, ParseFlags flags) {
  if (sub->op() == kRegexpStar && sub->parse_flags() == flags)
    return sub;
  Regexp* re = new Regexp(kRegexpStar, flags);
  re->AllocSub(1);
  re->sub()[0] = sub;
  return re;
}

Regexp* Regexp::Quest(Regexp* sub, ParseFlags flags) {
  if (sub->op() == kRegexpQuest && sub->parse_flags() == flags)
    return sub;
  Regexp* re = new Regexp(kRegexpQuest, flags);
  re->AllocSub(1);
  re->sub()[0] = sub;
  return re;
}

Regexp* Regexp::ConcatOrAlternate(RegexpOp op, Regexp** sub, int nsub,
                                  ParseFlags flags, bool can_factor) {
  if (nsub == 1)
    return sub[0];

  Regexp** subcopy = NULL;
  if (op == kRegexpAlternate && can_factor) {
    // Going to edit sub; make a copy so we don't step on caller.
    subcopy = new Regexp*[nsub];
    memmove(subcopy, sub, nsub * sizeof sub[0]);
    sub = subcopy;
    nsub = FactorAlternation(sub, nsub, flags);
    if (nsub == 1) {
      Regexp* re = sub[0];
      delete[] subcopy;
      return re;
    }
  }

  if (nsub > kMaxNsub) {
    // Too many subexpressions to fit in a single Regexp.
    // Make a two-level tree.  Two levels gets us to 65535^2.
    int nbigsub = (nsub+kMaxNsub-1)/kMaxNsub;
    Regexp* re = new Regexp(op, flags);
    re->AllocSub(nbigsub);
    Regexp** subs = re->sub();
    for (int i = 0; i < nbigsub - 1; i++)
      subs[i] = ConcatOrAlternate(op, sub+i*kMaxNsub, kMaxNsub, flags, false);
    subs[nbigsub - 1] = ConcatOrAlternate(op, sub+(nbigsub-1)*kMaxNsub,
                                          nsub - (nbigsub-1)*kMaxNsub, flags,
                                          false);
    delete[] subcopy;
    return re;
  }

  Regexp* re = new Regexp(op, flags);
  re->AllocSub(nsub);
  Regexp** subs = re->sub();
  for (int i = 0; i < nsub; i++)
    subs[i] = sub[i];

  delete[] subcopy;
  return re;
}

Regexp* Regexp::Concat(Regexp** sub, int nsub, ParseFlags flags) {
  return ConcatOrAlternate(kRegexpConcat, sub, nsub, flags, false);
}

Regexp* Regexp::Alternate(Regexp** sub, int nsub, ParseFlags flags) {
  return ConcatOrAlternate(kRegexpAlternate, sub, nsub, flags, true);
}

Regexp* Regexp::AlternateNoFactor(Regexp** sub, int nsub, ParseFlags flags) {
  return ConcatOrAlternate(kRegexpAlternate, sub, nsub, flags, false);
}

Regexp* Regexp::Capture(Regexp* sub, ParseFlags flags, int cap) {
  Regexp* re = new Regexp(kRegexpCapture, flags);
  re->AllocSub(1);
  re->sub()[0] = sub;
  re->cap_ = cap;
  return re;
}

Regexp* Regexp::Repeat(Regexp* sub, ParseFlags flags, int min, int max) {
  Regexp* re = new Regexp(kRegexpRepeat, flags);
  re->AllocSub(1);
  re->sub()[0] = sub;
  re->min_ = min;
  re->max_ = max;
  return re;
}

Regexp* Regexp::NewLiteral(Rune rune, ParseFlags flags) {
  Regexp* re = new Regexp(kRegexpLiteral, flags);
  re->rune_ = rune;
  return re;
}

Regexp* Regexp::LiteralString(Rune* runes, int nrunes, ParseFlags flags) {
  if (nrunes <= 0)
    return new Regexp(kRegexpEmptyMatch, flags);
  if (nrunes == 1)
    return NewLiteral(runes[0], flags);
  Regexp* re = new Regexp(kRegexpLiteralString, flags);
  for (int i = 0; i < nrunes; i++)
    re->AddRuneToString(runes[i]);
  return re;
}

Regexp* Regexp::NewCharClass(CharClass* cc, ParseFlags flags) {
  Regexp* re = new Regexp(kRegexpCharClass, flags);
  re->cc_ = cc;
  return re;
}

// Swaps this and that in place.
void Regexp::Swap(Regexp* that) {
  // Can use memmove because Regexp is just a struct (no vtable).
  char tmp[sizeof *this];
  memmove(tmp, this, sizeof tmp);
  memmove(this, that, sizeof tmp);
  memmove(that, tmp, sizeof tmp);
}

// Tests equality of all top-level structure but not subregexps.
static bool TopEqual(Regexp* a, Regexp* b) {
  if (a->op() != b->op())
    return false;

  switch (a->op()) {
    case kRegexpNoMatch:
    case kRegexpEmptyMatch:
    case kRegexpAnyChar:
    case kRegexpAnyByte:
    case kRegexpBeginLine:
    case kRegexpEndLine:
    case kRegexpWordBoundary:
    case kRegexpNoWordBoundary:
    case kRegexpBeginText:
      return true;

    case kRegexpEndText:
      // The parse flags remember whether it's \z or (?-m:$),
      // which matters when testing against PCRE.
      return ((a->parse_flags() ^ b->parse_flags()) & Regexp::WasDollar) == 0;

    case kRegexpLiteral:
      return a->rune() == b->rune() &&
             ((a->parse_flags() ^ b->parse_flags()) & Regexp::FoldCase) == 0;

    case kRegexpLiteralString:
      return a->nrunes() == b->nrunes() &&
             ((a->parse_flags() ^ b->parse_flags()) & Regexp::FoldCase) == 0 &&
             memcmp(a->runes(), b->runes(),
                    a->nrunes() * sizeof a->runes()[0]) == 0;

    case kRegexpAlternate:
    case kRegexpConcat:
      return a->nsub() == b->nsub();

    case kRegexpStar:
    case kRegexpPlus:
    case kRegexpQuest:
      return ((a->parse_flags() ^ b->parse_flags()) & Regexp::NonGreedy) == 0;

    case kRegexpRepeat:
      return ((a->parse_flags() ^ b->parse_flags()) & Regexp::NonGreedy) == 0 &&
             a->min() == b->min() &&
             a->max() == b->max();

    case kRegexpCapture:
      return a->cap() == b->cap() && a->name() == b->name();

    case kRegexpHaveMatch:
      return a->match_id() == b->match_id();

    case kRegexpCharClass: {
      CharClass* acc = a->cc();
      CharClass* bcc = b->cc();
      return acc->size() == bcc->size() &&
             acc->end() - acc->begin() == bcc->end() - bcc->begin() &&
             memcmp(acc->begin(), bcc->begin(),
                    (acc->end() - acc->begin()) * sizeof acc->begin()[0]) == 0;
    }
  }

  LOG(DFATAL) << "Unexpected op in Regexp::Equal: " << a->op();
  return 0;
}

bool Regexp::Equal(Regexp* a, Regexp* b) {
  if (a == NULL || b == NULL)
    return a == b;

  if (!TopEqual(a, b))
    return false;

  // Fast path:
  // return without allocating vector if there are no subregexps.
  switch (a->op()) {
    case kRegexpAlternate:
    case kRegexpConcat:
    case kRegexpStar:
    case kRegexpPlus:
    case kRegexpQuest:
    case kRegexpRepeat:
    case kRegexpCapture:
      break;

    default:
      return true;
  }

  // Committed to doing real work.
  // The stack (vector) has pairs of regexps waiting to
  // be compared.  The regexps are only equal if
  // all the pairs end up being equal.
  vector<Regexp*> stk;

  for (;;) {
    // Invariant: TopEqual(a, b) == true.
    Regexp* a2;
    Regexp* b2;
    switch (a->op()) {
      default:
        break;
      case kRegexpAlternate:
      case kRegexpConcat:
        for (int i = 0; i < a->nsub(); i++) {
          a2 = a->sub()[i];
          b2 = b->sub()[i];
          if (!TopEqual(a2, b2))
            return false;
          stk.push_back(a2);
          stk.push_back(b2);
        }
        break;

      case kRegexpStar:
      case kRegexpPlus:
      case kRegexpQuest:
      case kRegexpRepeat:
      case kRegexpCapture:
        a2 = a->sub()[0];
        b2 = b->sub()[0];
        if (!TopEqual(a2, b2))
          return false;
        // Really:
        //   stk.push_back(a2);
        //   stk.push_back(b2);
        //   break;
        // but faster to assign directly and loop.
        a = a2;
        b = b2;
        continue;
    }

    int n = stk.size();
    if (n == 0)
      break;

    a = stk[n-2];
    b = stk[n-1];
    stk.resize(n-2);
  }

  return true;
}

// Keep in sync with enum RegexpStatusCode in regexp.h
static const char *kErrorStrings[] = {
  "no error",
  "unexpected error",
  "invalid escape sequence",
  "invalid character class",
  "invalid character class range",
  "missing ]",
  "missing )",
  "trailing \\",
  "no argument for repetition operator",
  "invalid repetition size",
  "bad repetition operator",
  "invalid perl operator",
  "invalid UTF-8",
  "invalid named capture group",
};

string RegexpStatus::CodeText(enum RegexpStatusCode code) {
  if (code < 0 || code >= arraysize(kErrorStrings))
    code = kRegexpInternalError;
  return kErrorStrings[code];
}

string RegexpStatus::Text() const {
  if (error_arg_.empty())
    return CodeText(code_);
  string s;
  s.append(CodeText(code_));
  s.append(": ");
  s.append(error_arg_.data(), error_arg_.size());
  return s;
}

void RegexpStatus::Copy(const RegexpStatus& status) {
  code_ = status.code_;
  error_arg_ = status.error_arg_;
}

typedef int Ignored;  // Walker<void> doesn't exist

// Walker subclass to count capturing parens in regexp.
class NumCapturesWalker : public Regexp::Walker<Ignored> {
 public:
  NumCapturesWalker() : ncapture_(0) {}
  int ncapture() { return ncapture_; }

  virtual Ignored PreVisit(Regexp* re, Ignored ignored, bool* stop) {
    if (re->op() == kRegexpCapture)
      ncapture_++;
    return ignored;
  }
  virtual Ignored ShortVisit(Regexp* re, Ignored ignored) {
    // Should never be called: we use Walk not WalkExponential.
    LOG(DFATAL) << "NumCapturesWalker::ShortVisit called";
    return ignored;
  }

 private:
  int ncapture_;
  DISALLOW_EVIL_CONSTRUCTORS(NumCapturesWalker);
};

int Regexp::NumCaptures() {
  NumCapturesWalker w;
  w.Walk(this, 0);
  return w.ncapture();
}

// Walker class to build map of named capture groups and their indices.
class NamedCapturesWalker : public Regexp::Walker<Ignored> {
 public:
  NamedCapturesWalker() : map_(NULL) {}
  ~NamedCapturesWalker() { delete map_; }

  map<string, int>* TakeMap() {
    map<string, int>* m = map_;
    map_ = NULL;
    return m;
  }

  Ignored PreVisit(Regexp* re, Ignored ignored, bool* stop) {
    if (re->op() == kRegexpCapture && re->name() != NULL) {
      // Allocate map once we find a name.
      if (map_ == NULL)
        map_ = new map<string, int>;

      // Record first occurrence of each name.
      // (The rule is that if you have the same name
      // multiple times, only the leftmost one counts.)
      if (map_->find(*re->name()) == map_->end())
        (*map_)[*re->name()] = re->cap();
    }
    return ignored;
  }

  virtual Ignored ShortVisit(Regexp* re, Ignored ignored) {
    // Should never be called: we use Walk not WalkExponential.
    LOG(DFATAL) << "NamedCapturesWalker::ShortVisit called";
    return ignored;
  }

 private:
  map<string, int>* map_;
  DISALLOW_EVIL_CONSTRUCTORS(NamedCapturesWalker);
};

map<string, int>* Regexp::NamedCaptures() {
  NamedCapturesWalker w;
  w.Walk(this, 0);
  return w.TakeMap();
}

// Walker class to build map from capture group indices to their names.
class CaptureNamesWalker : public Regexp::Walker<Ignored> {
 public:
  CaptureNamesWalker() : map_(NULL) {}
  ~CaptureNamesWalker() { delete map_; }

  map<int, string>* TakeMap() {
    map<int, string>* m = map_;
    map_ = NULL;
    return m;
  }

  Ignored PreVisit(Regexp* re, Ignored ignored, bool* stop) {
    if (re->op() == kRegexpCapture && re->name() != NULL) {
      // Allocate map once we find a name.
      if (map_ == NULL)
        map_ = new map<int, string>;

      (*map_)[re->cap()] = *re->name();
    }
    return ignored;
  }

  virtual Ignored ShortVisit(Regexp* re, Ignored ignored) {
    // Should never be called: we use Walk not WalkExponential.
    LOG(DFATAL) << "CaptureNamesWalker::ShortVisit called";
    return ignored;
  }

 private:
  map<int, string>* map_;
  DISALLOW_EVIL_CONSTRUCTORS(CaptureNamesWalker);
};

map<int, string>* Regexp::CaptureNames() {
  CaptureNamesWalker w;
  w.Walk(this, 0);
  return w.TakeMap();
}

// Determines whether regexp matches must be anchored
// with a fixed string prefix.  If so, returns the prefix and
// the regexp that remains after the prefix.  The prefix might
// be ASCII case-insensitive.
bool Regexp::RequiredPrefix(string *prefix, bool *foldcase, Regexp** suffix) {
  // No need for a walker: the regexp must be of the form
  // 1. some number of ^ anchors
  // 2. a literal char or string
  // 3. the rest
  prefix->clear();
  *foldcase = false;
  *suffix = NULL;
  if (op_ != kRegexpConcat)
    return false;

  // Some number of anchors, then a literal or concatenation.
  int i = 0;
  Regexp** sub = this->sub();
  while (i < nsub_ && sub[i]->op_ == kRegexpBeginText)
    i++;
  if (i == 0 || i >= nsub_)
    return false;

  Regexp* re = sub[i];
  switch (re->op_) {
    default:
      return false;

    case kRegexpLiteralString:
      // Convert to string in proper encoding.
      if (re->parse_flags() & Latin1) {
        prefix->resize(re->nrunes_);
        for (int j = 0; j < re->nrunes_; j++)
          (*prefix)[j] = re->runes_[j];
      } else {
        // Convert to UTF-8 in place.
        // Assume worst-case space and then trim.
        prefix->resize(re->nrunes_ * UTFmax);
        char *p = &(*prefix)[0];
        for (int j = 0; j < re->nrunes_; j++) {
          Rune r = re->runes_[j];
          if (r < Runeself)
            *p++ = r;
          else
            p += runetochar(p, &r);
        }
        prefix->resize(p - &(*prefix)[0]);
      }
      break;

    case kRegexpLiteral:
      if ((re->parse_flags() & Latin1) || re->rune_ < Runeself) {
        prefix->append(1, re->rune_);
      } else {
        char buf[UTFmax];
        prefix->append(buf, runetochar(buf, &re->rune_));
      }
      break;
  }
  *foldcase = (sub[i]->parse_flags() & FoldCase);
  i++;

  // The rest.
  if (i < nsub_) {
    for (int j = i; j < nsub_; j++)
      sub[j]->Incref();
    re = Concat(sub + i, nsub_ - i, parse_flags());
  } else {
    re = new Regexp(kRegexpEmptyMatch, parse_flags());
  }
  *suffix = re;
  return true;
}

// Character class builder is a balanced binary tree (STL set)
// containing non-overlapping, non-abutting RuneRanges.
// The less-than operator used in the tree treats two
// ranges as equal if they overlap at all, so that
// lookups for a particular Rune are possible.

CharClassBuilder::CharClassBuilder() {
  nrunes_ = 0;
  upper_ = 0;
  lower_ = 0;
}

// Add lo-hi to the class; return whether class got bigger.
bool CharClassBuilder::AddRange(Rune lo, Rune hi) {
  if (hi < lo)
    return false;

  if (lo <= 'z' && hi >= 'A') {
    // Overlaps some alpha, maybe not all.
    // Update bitmaps telling which ASCII letters are in the set.
    Rune lo1 = max<Rune>(lo, 'A');
    Rune hi1 = min<Rune>(hi, 'Z');
    if (lo1 <= hi1)
      upper_ |= ((1 << (hi1 - lo1 + 1)) - 1) << (lo1 - 'A');

    lo1 = max<Rune>(lo, 'a');
    hi1 = min<Rune>(hi, 'z');
    if (lo1 <= hi1)
      lower_ |= ((1 << (hi1 - lo1 + 1)) - 1) << (lo1 - 'a');
  }

  {  // Check whether lo, hi is already in the class.
    iterator it = ranges_.find(RuneRange(lo, lo));
    if (it != end() && it->lo <= lo && hi <= it->hi)
      return false;
  }

  // Look for a range abutting lo on the left.
  // If it exists, take it out and increase our range.
  if (lo > 0) {
    iterator it = ranges_.find(RuneRange(lo-1, lo-1));
    if (it != end()) {
      lo = it->lo;
      if (it->hi > hi)
        hi = it->hi;
      nrunes_ -= it->hi - it->lo + 1;
      ranges_.erase(it);
    }
  }

  // Look for a range abutting hi on the right.
  // If it exists, take it out and increase our range.
  if (hi < Runemax) {
    iterator it = ranges_.find(RuneRange(hi+1, hi+1));
    if (it != end()) {
      hi = it->hi;
      nrunes_ -= it->hi - it->lo + 1;
      ranges_.erase(it);
    }
  }

  // Look for ranges between lo and hi.  Take them out.
  // This is only safe because the set has no overlapping ranges.
  // We've already removed any ranges abutting lo and hi, so
  // any that overlap [lo, hi] must be contained within it.
  for (;;) {
    iterator it = ranges_.find(RuneRange(lo, hi));
    if (it == end())
      break;
    nrunes_ -= it->hi - it->lo + 1;
    ranges_.erase(it);
  }

  // Finally, add [lo, hi].
  nrunes_ += hi - lo + 1;
  ranges_.insert(RuneRange(lo, hi));
  return true;
}

void CharClassBuilder::AddCharClass(CharClassBuilder *cc) {
  for (iterator it = cc->begin(); it != cc->end(); ++it)
    AddRange(it->lo, it->hi);
}

bool CharClassBuilder::Contains(Rune r) {
  return ranges_.find(RuneRange(r, r)) != end();
}

// Does the character class behave the same on A-Z as on a-z?
bool CharClassBuilder::FoldsASCII() {
  return ((upper_ ^ lower_) & AlphaMask) == 0;
}

CharClassBuilder* CharClassBuilder::Copy() {
  CharClassBuilder* cc = new CharClassBuilder;
  for (iterator it = begin(); it != end(); ++it)
    cc->ranges_.insert(RuneRange(it->lo, it->hi));
  cc->upper_ = upper_;
  cc->lower_ = lower_;
  cc->nrunes_ = nrunes_;
  return cc;
}



void CharClassBuilder::RemoveAbove(Rune r) {
  if (r >= Runemax)
    return;

  if (r < 'z') {
    if (r < 'a')
      lower_ = 0;
    else
      lower_ &= AlphaMask >> ('z' - r);
  }

  if (r < 'Z') {
    if (r < 'A')
      upper_ = 0;
    else
      upper_ &= AlphaMask >> ('Z' - r);
  }

  for (;;) {

    iterator it = ranges_.find(RuneRange(r + 1, Runemax));
    if (it == end())
      break;
    RuneRange rr = *it;
    ranges_.erase(it);
    nrunes_ -= rr.hi - rr.lo + 1;
    if (rr.lo <= r) {
      rr.hi = r;
      ranges_.insert(rr);
      nrunes_ += rr.hi - rr.lo + 1;
    }
  }
}

void CharClassBuilder::Negate() {
  // Build up negation and then copy in.
  // Could edit ranges in place, but C++ won't let me.
  vector<RuneRange> v;
  v.reserve(ranges_.size() + 1);

  // In negation, first range begins at 0, unless
  // the current class begins at 0.
  iterator it = begin();
  if (it == end()) {
    v.push_back(RuneRange(0, Runemax));
  } else {
    int nextlo = 0;
    if (it->lo == 0) {
      nextlo = it->hi + 1;
      ++it;
    }
    for (; it != end(); ++it) {
      v.push_back(RuneRange(nextlo, it->lo - 1));
      nextlo = it->hi + 1;
    }
    if (nextlo <= Runemax)
      v.push_back(RuneRange(nextlo, Runemax));
  }

  ranges_.clear();
  for (int i = 0; i < v.size(); i++)
    ranges_.insert(v[i]);

  upper_ = AlphaMask & ~upper_;
  lower_ = AlphaMask & ~lower_;
  nrunes_ = Runemax+1 - nrunes_;
}

// Character class is a sorted list of ranges.
// The ranges are allocated in the same block as the header,
// necessitating a special allocator and Delete method.

CharClass* CharClass::New(int maxranges) {
  CharClass* cc;
  uint8* data = new uint8[sizeof *cc + maxranges*sizeof cc->ranges_[0]];
  cc = reinterpret_cast<CharClass*>(data);
  cc->ranges_ = reinterpret_cast<RuneRange*>(data + sizeof *cc);
  cc->nranges_ = 0;
  cc->folds_ascii_ = false;
  cc->nrunes_ = 0;
  return cc;
}

void CharClass::Delete() {
  uint8 *data = reinterpret_cast<uint8*>(this);
  delete[] data;
}

CharClass* CharClass::Negate() {
  CharClass* cc = CharClass::New(nranges_+1);
  cc->folds_ascii_ = folds_ascii_;
  cc->nrunes_ = Runemax + 1 - nrunes_;
  int n = 0;
  int nextlo = 0;
  for (CharClass::iterator it = begin(); it != end(); ++it) {
    if (it->lo == nextlo) {
      nextlo = it->hi + 1;
    } else {
      cc->ranges_[n++] = RuneRange(nextlo, it->lo - 1);
      nextlo = it->hi + 1;
    }
  }
  if (nextlo <= Runemax)
    cc->ranges_[n++] = RuneRange(nextlo, Runemax);
  cc->nranges_ = n;
  return cc;
}

bool CharClass::Contains(Rune r) {
  RuneRange* rr = ranges_;
  int n = nranges_;
  while (n > 0) {
    int m = n/2;
    if (rr[m].hi < r) {
      rr += m+1;
      n -= m+1;
    } else if (r < rr[m].lo) {
      n = m;
    } else {  // rr[m].lo <= r && r <= rr[m].hi
      return true;
    }
  }
  return false;
}

CharClass* CharClassBuilder::GetCharClass() {
  CharClass* cc = CharClass::New(ranges_.size());
  int n = 0;
  for (iterator it = begin(); it != end(); ++it)
    cc->ranges_[n++] = *it;
  cc->nranges_ = n;
  DCHECK_LE(n, ranges_.size());
  cc->nrunes_ = nrunes_;
  cc->folds_ascii_ = FoldsASCII();
  return cc;
}

}  // namespace re2
