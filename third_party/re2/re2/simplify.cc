// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Rewrite POSIX and other features in re
// to use simple extended regular expression features.
// Also sort and simplify character classes.

#include "util/util.h"
#include "re2/regexp.h"
#include "re2/walker-inl.h"

namespace re2 {

// Parses the regexp src and then simplifies it and sets *dst to the
// string representation of the simplified form.  Returns true on success.
// Returns false and sets *error (if error != NULL) on error.
bool Regexp::SimplifyRegexp(const StringPiece& src, ParseFlags flags,
                            string* dst,
                            RegexpStatus* status) {
  Regexp* re = Parse(src, flags, status);
  if (re == NULL)
    return false;
  Regexp* sre = re->Simplify();
  re->Decref();
  if (sre == NULL) {
    // Should not happen, since Simplify never fails.
    LOG(ERROR) << "Simplify failed on " << src;
    if (status) {
      status->set_code(kRegexpInternalError);
      status->set_error_arg(src);
    }
    return false;
  }
  *dst = sre->ToString();
  sre->Decref();
  return true;
}

// Assuming the simple_ flags on the children are accurate,
// is this Regexp* simple?
bool Regexp::ComputeSimple() {
  Regexp** subs;
  switch (op_) {
    case kRegexpNoMatch:
    case kRegexpEmptyMatch:
    case kRegexpLiteral:
    case kRegexpLiteralString:
    case kRegexpBeginLine:
    case kRegexpEndLine:
    case kRegexpBeginText:
    case kRegexpWordBoundary:
    case kRegexpNoWordBoundary:
    case kRegexpEndText:
    case kRegexpAnyChar:
    case kRegexpAnyByte:
    case kRegexpHaveMatch:
      return true;
    case kRegexpConcat:
    case kRegexpAlternate:
      // These are simple as long as the subpieces are simple.
      subs = sub();
      for (int i = 0; i < nsub_; i++)
        if (!subs[i]->simple_)
          return false;
      return true;
    case kRegexpCharClass:
      // Simple as long as the char class is not empty, not full.
      if (ccb_ != NULL)
        return !ccb_->empty() && !ccb_->full();
      return !cc_->empty() && !cc_->full();
    case kRegexpCapture:
      subs = sub();
      return subs[0]->simple_;
    case kRegexpStar:
    case kRegexpPlus:
    case kRegexpQuest:
      subs = sub();
      if (!subs[0]->simple_)
        return false;
      switch (subs[0]->op_) {
        case kRegexpStar:
        case kRegexpPlus:
        case kRegexpQuest:
        case kRegexpEmptyMatch:
        case kRegexpNoMatch:
          return false;
        default:
          break;
      }
      return true;
    case kRegexpRepeat:
      return false;
  }
  LOG(DFATAL) << "Case not handled in ComputeSimple: " << op_;
  return false;
}

// Walker subclass used by Simplify.
// The simplify walk is purely post-recursive: given the simplified children,
// PostVisit creates the simplified result.
// The child_args are simplified Regexp*s.
class SimplifyWalker : public Regexp::Walker<Regexp*> {
 public:
  SimplifyWalker() {}
  virtual Regexp* PreVisit(Regexp* re, Regexp* parent_arg, bool* stop);
  virtual Regexp* PostVisit(Regexp* re,
                            Regexp* parent_arg,
                            Regexp* pre_arg,
                            Regexp** child_args, int nchild_args);
  virtual Regexp* Copy(Regexp* re);
  virtual Regexp* ShortVisit(Regexp* re, Regexp* parent_arg);

 private:
  // These functions are declared inside SimplifyWalker so that
  // they can edit the private fields of the Regexps they construct.

  // Creates a concatenation of two Regexp, consuming refs to re1 and re2.
  // Caller must Decref return value when done with it.
  static Regexp* Concat2(Regexp* re1, Regexp* re2, Regexp::ParseFlags flags);

  // Simplifies the expression re{min,max} in terms of *, +, and ?.
  // Returns a new regexp.  Does not edit re.  Does not consume reference to re.
  // Caller must Decref return value when done with it.
  static Regexp* SimplifyRepeat(Regexp* re, int min, int max,
                                Regexp::ParseFlags parse_flags);

  // Simplifies a character class by expanding any named classes
  // into rune ranges.  Does not edit re.  Does not consume ref to re.
  // Caller must Decref return value when done with it.
  static Regexp* SimplifyCharClass(Regexp* re);

  DISALLOW_EVIL_CONSTRUCTORS(SimplifyWalker);
};

// Simplifies a regular expression, returning a new regexp.
// The new regexp uses traditional Unix egrep features only,
// plus the Perl (?:) non-capturing parentheses.
// Otherwise, no POSIX or Perl additions.  The new regexp
// captures exactly the same subexpressions (with the same indices)
// as the original.
// Does not edit current object.
// Caller must Decref() return value when done with it.

Regexp* Regexp::Simplify() {
  if (simple_)
    return Incref();
  SimplifyWalker w;
  return w.Walk(this, NULL);
}

#define Simplify DontCallSimplify  // Avoid accidental recursion

Regexp* SimplifyWalker::Copy(Regexp* re) {
  return re->Incref();
}

Regexp* SimplifyWalker::ShortVisit(Regexp* re, Regexp* parent_arg) {
  // This should never be called, since we use Walk and not
  // WalkExponential.
  LOG(DFATAL) << "SimplifyWalker::ShortVisit called";
  return re->Incref();
}

Regexp* SimplifyWalker::PreVisit(Regexp* re, Regexp* parent_arg, bool* stop) {
  if (re->simple_) {
    *stop = true;
    return re->Incref();
  }
  return NULL;
}

Regexp* SimplifyWalker::PostVisit(Regexp* re,
                                  Regexp* parent_arg,
                                  Regexp* pre_arg,
                                  Regexp** child_args,
                                  int nchild_args) {
  switch (re->op()) {
    case kRegexpNoMatch:
    case kRegexpEmptyMatch:
    case kRegexpLiteral:
    case kRegexpLiteralString:
    case kRegexpBeginLine:
    case kRegexpEndLine:
    case kRegexpBeginText:
    case kRegexpWordBoundary:
    case kRegexpNoWordBoundary:
    case kRegexpEndText:
    case kRegexpAnyChar:
    case kRegexpAnyByte:
    case kRegexpHaveMatch:
      // All these are always simple.
      re->simple_ = true;
      return re->Incref();

    case kRegexpConcat:
    case kRegexpAlternate: {
      // These are simple as long as the subpieces are simple.
      // Two passes to avoid allocation in the common case.
      bool changed = false;
      Regexp** subs = re->sub();
      for (int i = 0; i < re->nsub_; i++) {
        Regexp* sub = subs[i];
        Regexp* newsub = child_args[i];
        if (newsub != sub) {
          changed = true;
          break;
        }
      }
      if (!changed) {
        for (int i = 0; i < re->nsub_; i++) {
          Regexp* newsub = child_args[i];
          newsub->Decref();
        }
        re->simple_ = true;
        return re->Incref();
      }
      Regexp* nre = new Regexp(re->op(), re->parse_flags());
      nre->AllocSub(re->nsub_);
      Regexp** nre_subs = nre->sub();
      for (int i = 0; i <re->nsub_; i++)
        nre_subs[i] = child_args[i];
      nre->simple_ = true;
      return nre;
    }

    case kRegexpCapture: {
      Regexp* newsub = child_args[0];
      if (newsub == re->sub()[0]) {
        newsub->Decref();
        re->simple_ = true;
        return re->Incref();
      }
      Regexp* nre = new Regexp(kRegexpCapture, re->parse_flags());
      nre->AllocSub(1);
      nre->sub()[0] = newsub;
      nre->cap_ = re->cap_;
      nre->simple_ = true;
      return nre;
    }

    case kRegexpStar:
    case kRegexpPlus:
    case kRegexpQuest: {
      Regexp* newsub = child_args[0];
      // Special case: repeat the empty string as much as
      // you want, but it's still the empty string.
      if (newsub->op() == kRegexpEmptyMatch)
        return newsub;

      // These are simple as long as the subpiece is simple.
      if (newsub == re->sub()[0]) {
        newsub->Decref();
        re->simple_ = true;
        return re->Incref();
      }

      // These are also idempotent if flags are constant.
      if (re->op() == newsub->op() &&
          re->parse_flags() == newsub->parse_flags())
        return newsub;

      Regexp* nre = new Regexp(re->op(), re->parse_flags());
      nre->AllocSub(1);
      nre->sub()[0] = newsub;
      nre->simple_ = true;
      return nre;
    }

    case kRegexpRepeat: {
      Regexp* newsub = child_args[0];
      // Special case: repeat the empty string as much as
      // you want, but it's still the empty string.
      if (newsub->op() == kRegexpEmptyMatch)
        return newsub;

      Regexp* nre = SimplifyRepeat(newsub, re->min_, re->max_,
                                   re->parse_flags());
      newsub->Decref();
      nre->simple_ = true;
      return nre;
    }

    case kRegexpCharClass: {
      Regexp* nre = SimplifyCharClass(re);
      nre->simple_ = true;
      return nre;
    }
  }

  LOG(ERROR) << "Simplify case not handled: " << re->op();
  return re->Incref();
}

// Creates a concatenation of two Regexp, consuming refs to re1 and re2.
// Returns a new Regexp, handing the ref to the caller.
Regexp* SimplifyWalker::Concat2(Regexp* re1, Regexp* re2,
                                Regexp::ParseFlags parse_flags) {
  Regexp* re = new Regexp(kRegexpConcat, parse_flags);
  re->AllocSub(2);
  Regexp** subs = re->sub();
  subs[0] = re1;
  subs[1] = re2;
  return re;
}

// Simplifies the expression re{min,max} in terms of *, +, and ?.
// Returns a new regexp.  Does not edit re.  Does not consume reference to re.
// Caller must Decref return value when done with it.
// The result will *not* necessarily have the right capturing parens
// if you call ToString() and re-parse it: (x){2} becomes (x)(x),
// but in the Regexp* representation, both (x) are marked as $1.
Regexp* SimplifyWalker::SimplifyRepeat(Regexp* re, int min, int max,
                                       Regexp::ParseFlags f) {
  // x{n,} means at least n matches of x.
  if (max == -1) {
    // Special case: x{0,} is x*
    if (min == 0)
      return Regexp::Star(re->Incref(), f);

    // Special case: x{1,} is x+
    if (min == 1)
      return Regexp::Plus(re->Incref(), f);

    // General case: x{4,} is xxxx+
    Regexp* nre = new Regexp(kRegexpConcat, f);
    nre->AllocSub(min);
    VLOG(1) << "Simplify " << min;
    Regexp** nre_subs = nre->sub();
    for (int i = 0; i < min-1; i++)
      nre_subs[i] = re->Incref();
    nre_subs[min-1] = Regexp::Plus(re->Incref(), f);
    return nre;
  }

  // Special case: (x){0} matches only empty string.
  if (min == 0 && max == 0)
    return new Regexp(kRegexpEmptyMatch, f);

  // Special case: x{1} is just x.
  if (min == 1 && max == 1)
    return re->Incref();

  // General case: x{n,m} means n copies of x and m copies of x?.
  // The machine will do less work if we nest the final m copies,
  // so that x{2,5} = xx(x(x(x)?)?)?

  // Build leading prefix: xx.  Capturing only on the last one.
  Regexp* nre = NULL;
  if (min > 0) {
    nre = new Regexp(kRegexpConcat, f);
    nre->AllocSub(min);
    Regexp** nre_subs = nre->sub();
    for (int i = 0; i < min; i++)
      nre_subs[i] = re->Incref();
  }

  // Build and attach suffix: (x(x(x)?)?)?
  if (max > min) {
    Regexp* suf = Regexp::Quest(re->Incref(), f);
    for (int i = min+1; i < max; i++)
      suf = Regexp::Quest(Concat2(re->Incref(), suf, f), f);
    if (nre == NULL)
      nre = suf;
    else
      nre = Concat2(nre, suf, f);
  }

  if (nre == NULL) {
    // Some degenerate case, like min > max, or min < max < 0.
    // This shouldn't happen, because the parser rejects such regexps.
    LOG(DFATAL) << "Malformed repeat " << re->ToString() << " " << min << " " << max;
    return new Regexp(kRegexpNoMatch, f);
  }

  return nre;
}

// Simplifies a character class.
// Caller must Decref return value when done with it.
Regexp* SimplifyWalker::SimplifyCharClass(Regexp* re) {
  CharClass* cc = re->cc();

  // Special cases
  if (cc->empty())
    return new Regexp(kRegexpNoMatch, re->parse_flags());
  if (cc->full())
    return new Regexp(kRegexpAnyChar, re->parse_flags());

  return re->Incref();
}

}  // namespace re2
