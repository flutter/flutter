// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Regular expression parser.

// The parser is a simple precedence-based parser with a
// manual stack.  The parsing work is done by the methods
// of the ParseState class.  The Regexp::Parse function is
// essentially just a lexer that calls the ParseState method
// for each token.

// The parser recognizes POSIX extended regular expressions
// excluding backreferences, collating elements, and collating
// classes.  It also allows the empty string as a regular expression
// and recognizes the Perl escape sequences \d, \s, \w, \D, \S, and \W.
// See regexp.h for rationale.

#include "util/util.h"
#include "re2/regexp.h"
#include "re2/stringpiece.h"
#include "re2/unicode_casefold.h"
#include "re2/unicode_groups.h"

namespace re2 {

// Regular expression parse state.
// The list of parsed regexps so far is maintained as a vector of
// Regexp pointers called the stack.  Left parenthesis and vertical
// bar markers are also placed on the stack, as Regexps with
// non-standard opcodes.
// Scanning a left parenthesis causes the parser to push a left parenthesis
// marker on the stack.
// Scanning a vertical bar causes the parser to pop the stack until it finds a
// vertical bar or left parenthesis marker (not popping the marker),
// concatenate all the popped results, and push them back on
// the stack (DoConcatenation).
// Scanning a right parenthesis causes the parser to act as though it
// has seen a vertical bar, which then leaves the top of the stack in the
// form LeftParen regexp VerticalBar regexp VerticalBar ... regexp VerticalBar.
// The parser pops all this off the stack and creates an alternation of the
// regexps (DoAlternation).

class Regexp::ParseState {
 public:
  ParseState(ParseFlags flags, const StringPiece& whole_regexp,
             RegexpStatus* status);
  ~ParseState();

  ParseFlags flags() { return flags_; }
  int rune_max() { return rune_max_; }

  // Parse methods.  All public methods return a bool saying
  // whether parsing should continue.  If a method returns
  // false, it has set fields in *status_, and the parser
  // should return NULL.

  // Pushes the given regular expression onto the stack.
  // Could check for too much memory used here.
  bool PushRegexp(Regexp* re);

  // Pushes the literal rune r onto the stack.
  bool PushLiteral(Rune r);

  // Pushes a regexp with the given op (and no args) onto the stack.
  bool PushSimpleOp(RegexpOp op);

  // Pushes a ^ onto the stack.
  bool PushCarat();

  // Pushes a \b (word == true) or \B (word == false) onto the stack.
  bool PushWordBoundary(bool word);

  // Pushes a $ onto the stack.
  bool PushDollar();

  // Pushes a . onto the stack
  bool PushDot();

  // Pushes a repeat operator regexp onto the stack.
  // A valid argument for the operator must already be on the stack.
  // s is the name of the operator, for use in error messages.
  bool PushRepeatOp(RegexpOp op, const StringPiece& s, bool nongreedy);

  // Pushes a repetition regexp onto the stack.
  // A valid argument for the operator must already be on the stack.
  bool PushRepetition(int min, int max, const StringPiece& s, bool nongreedy);

  // Checks whether a particular regexp op is a marker.
  bool IsMarker(RegexpOp op);

  // Processes a left parenthesis in the input.
  // Pushes a marker onto the stack.
  bool DoLeftParen(const StringPiece& name);
  bool DoLeftParenNoCapture();

  // Processes a vertical bar in the input.
  bool DoVerticalBar();

  // Processes a right parenthesis in the input.
  bool DoRightParen();

  // Processes the end of input, returning the final regexp.
  Regexp* DoFinish();

  // Finishes the regexp if necessary, preparing it for use
  // in a more complicated expression.
  // If it is a CharClassBuilder, converts into a CharClass.
  Regexp* FinishRegexp(Regexp*);

  // These routines don't manipulate the parse stack
  // directly, but they do need to look at flags_.
  // ParseCharClass also manipulates the internals of Regexp
  // while creating *out_re.

  // Parse a character class into *out_re.
  // Removes parsed text from s.
  bool ParseCharClass(StringPiece* s, Regexp** out_re,
                      RegexpStatus* status);

  // Parse a character class character into *rp.
  // Removes parsed text from s.
  bool ParseCCCharacter(StringPiece* s, Rune *rp,
                        const StringPiece& whole_class,
                        RegexpStatus* status);

  // Parse a character class range into rr.
  // Removes parsed text from s.
  bool ParseCCRange(StringPiece* s, RuneRange* rr,
                    const StringPiece& whole_class,
                    RegexpStatus* status);

  // Parse a Perl flag set or non-capturing group from s.
  bool ParsePerlFlags(StringPiece* s);


  // Finishes the current concatenation,
  // collapsing it into a single regexp on the stack.
  void DoConcatenation();

  // Finishes the current alternation,
  // collapsing it to a single regexp on the stack.
  void DoAlternation();

  // Generalized DoAlternation/DoConcatenation.
  void DoCollapse(RegexpOp op);

  // Maybe concatenate Literals into LiteralString.
  bool MaybeConcatString(int r, ParseFlags flags);

private:
  ParseFlags flags_;
  StringPiece whole_regexp_;
  RegexpStatus* status_;
  Regexp* stacktop_;
  int ncap_;  // number of capturing parens seen
  int rune_max_;  // maximum char value for this encoding

  DISALLOW_EVIL_CONSTRUCTORS(ParseState);
};

// Pseudo-operators - only on parse stack.
const RegexpOp kLeftParen = static_cast<RegexpOp>(kMaxRegexpOp+1);
const RegexpOp kVerticalBar = static_cast<RegexpOp>(kMaxRegexpOp+2);

Regexp::ParseState::ParseState(ParseFlags flags,
                               const StringPiece& whole_regexp,
                               RegexpStatus* status)
  : flags_(flags), whole_regexp_(whole_regexp),
    status_(status), stacktop_(NULL), ncap_(0) {
  if (flags_ & Latin1)
    rune_max_ = 0xFF;
  else
    rune_max_ = Runemax;
}

// Cleans up by freeing all the regexps on the stack.
Regexp::ParseState::~ParseState() {
  Regexp* next;
  for (Regexp* re = stacktop_; re != NULL; re = next) {
    next = re->down_;
    re->down_ = NULL;
    if (re->op() == kLeftParen)
      delete re->name_;
    re->Decref();
  }
}

// Finishes the regexp if necessary, preparing it for use in
// a more complex expression.
// If it is a CharClassBuilder, converts into a CharClass.
Regexp* Regexp::ParseState::FinishRegexp(Regexp* re) {
  if (re == NULL)
    return NULL;
  re->down_ = NULL;

  if (re->op_ == kRegexpCharClass && re->ccb_ != NULL) {
    CharClassBuilder* ccb = re->ccb_;
    re->ccb_ = NULL;
    re->cc_ = ccb->GetCharClass();
    delete ccb;
  }

  return re;
}

// Pushes the given regular expression onto the stack.
// Could check for too much memory used here.
bool Regexp::ParseState::PushRegexp(Regexp* re) {
  MaybeConcatString(-1, NoParseFlags);

  // Special case: a character class of one character is just
  // a literal.  This is a common idiom for escaping
  // single characters (e.g., [.] instead of \.), and some
  // analysis does better with fewer character classes.
  // Similarly, [Aa] can be rewritten as a literal A with ASCII case folding.
  if (re->op_ == kRegexpCharClass) {
    if (re->ccb_->size() == 1) {
      Rune r = re->ccb_->begin()->lo;
      re->Decref();
      re = new Regexp(kRegexpLiteral, flags_);
      re->rune_ = r;
    } else if (re->ccb_->size() == 2) {
      Rune r = re->ccb_->begin()->lo;
      if ('A' <= r && r <= 'Z' && re->ccb_->Contains(r + 'a' - 'A')) {
        re->Decref();
        re = new Regexp(kRegexpLiteral, flags_ | FoldCase);
        re->rune_ = r + 'a' - 'A';
      }
    }
  }

  if (!IsMarker(re->op()))
    re->simple_ = re->ComputeSimple();
  re->down_ = stacktop_;
  stacktop_ = re;
  return true;
}

// Searches the case folding tables and returns the CaseFold* that contains r.
// If there isn't one, returns the CaseFold* with smallest f->lo bigger than r.
// If there isn't one, returns NULL.
CaseFold* LookupCaseFold(CaseFold *f, int n, Rune r) {
  CaseFold* ef = f + n;

  // Binary search for entry containing r.
  while (n > 0) {
    int m = n/2;
    if (f[m].lo <= r && r <= f[m].hi)
      return &f[m];
    if (r < f[m].lo) {
      n = m;
    } else {
      f += m+1;
      n -= m+1;
    }
  }

  // There is no entry that contains r, but f points
  // where it would have been.  Unless f points at
  // the end of the array, it points at the next entry
  // after r.
  if (f < ef)
    return f;

  // No entry contains r; no entry contains runes > r.
  return NULL;
}

// Returns the result of applying the fold f to the rune r.
Rune ApplyFold(CaseFold *f, Rune r) {
  switch (f->delta) {
    default:
      return r + f->delta;

    case EvenOddSkip:  // even <-> odd but only applies to every other
      if ((r - f->lo) % 2)
        return r;
      // fall through
    case EvenOdd:  // even <-> odd
      if (r%2 == 0)
        return r + 1;
      return r - 1;

    case OddEvenSkip:  // odd <-> even but only applies to every other
      if ((r - f->lo) % 2)
        return r;
      // fall through
    case OddEven:  // odd <-> even
      if (r%2 == 1)
        return r + 1;
      return r - 1;
  }
}

// Returns the next Rune in r's folding cycle (see unicode_casefold.h).
// Examples:
//   CycleFoldRune('A') = 'a'
//   CycleFoldRune('a') = 'A'
//
//   CycleFoldRune('K') = 'k'
//   CycleFoldRune('k') = 0x212A (Kelvin)
//   CycleFoldRune(0x212A) = 'K'
//
//   CycleFoldRune('?') = '?'
Rune CycleFoldRune(Rune r) {
  CaseFold* f = LookupCaseFold(unicode_casefold, num_unicode_casefold, r);
  if (f == NULL || r < f->lo)
    return r;
  return ApplyFold(f, r);
}

// Add lo-hi to the class, along with their fold-equivalent characters.
// If lo-hi is already in the class, assume that the fold-equivalent
// chars are there too, so there's no work to do.
static void AddFoldedRange(CharClassBuilder* cc, Rune lo, Rune hi, int depth) {
  // AddFoldedRange calls itself recursively for each rune in the fold cycle.
  // Most folding cycles are small: there aren't any bigger than four in the
  // current Unicode tables.  make_unicode_casefold.py checks that
  // the cycles are not too long, and we double-check here using depth.
  if (depth > 10) {
    LOG(DFATAL) << "AddFoldedRange recurses too much.";
    return;
  }

  if (!cc->AddRange(lo, hi))  // lo-hi was already there? we're done
    return;

  while (lo <= hi) {
    CaseFold* f = LookupCaseFold(unicode_casefold, num_unicode_casefold, lo);
    if (f == NULL)  // lo has no fold, nor does anything above lo
      break;
    if (lo < f->lo) {  // lo has no fold; next rune with a fold is f->lo
      lo = f->lo;
      continue;
    }

    // Add in the result of folding the range lo - f->hi
    // and that range's fold, recursively.
    Rune lo1 = lo;
    Rune hi1 = min<Rune>(hi, f->hi);
    switch (f->delta) {
      default:
        lo1 += f->delta;
        hi1 += f->delta;
        break;
      case EvenOdd:
        if (lo1%2 == 1)
          lo1--;
        if (hi1%2 == 0)
          hi1++;
        break;
      case OddEven:
        if (lo1%2 == 0)
          lo1--;
        if (hi1%2 == 1)
          hi1++;
        break;
    }
    AddFoldedRange(cc, lo1, hi1, depth+1);

    // Pick up where this fold left off.
    lo = f->hi + 1;
  }
}

// Pushes the literal rune r onto the stack.
bool Regexp::ParseState::PushLiteral(Rune r) {
  // Do case folding if needed.
  if ((flags_ & FoldCase) && CycleFoldRune(r) != r) {
    Regexp* re = new Regexp(kRegexpCharClass, flags_ & ~FoldCase);
    re->ccb_ = new CharClassBuilder;
    Rune r1 = r;
    do {
      if (!(flags_ & NeverNL) || r != '\n') {
        re->ccb_->AddRange(r, r);
      }
      r = CycleFoldRune(r);
    } while (r != r1);
    re->ccb_->RemoveAbove(rune_max_);
    return PushRegexp(re);
  }

  // Exclude newline if applicable.
  if ((flags_ & NeverNL) && r == '\n')
    return PushRegexp(new Regexp(kRegexpNoMatch, flags_));

  // No fancy stuff worked.  Ordinary literal.
  if (MaybeConcatString(r, flags_))
    return true;

  Regexp* re = new Regexp(kRegexpLiteral, flags_);
  re->rune_ = r;
  return PushRegexp(re);
}

// Pushes a ^ onto the stack.
bool Regexp::ParseState::PushCarat() {
  if (flags_ & OneLine) {
    return PushSimpleOp(kRegexpBeginText);
  }
  return PushSimpleOp(kRegexpBeginLine);
}

// Pushes a \b or \B onto the stack.
bool Regexp::ParseState::PushWordBoundary(bool word) {
  if (word)
    return PushSimpleOp(kRegexpWordBoundary);
  return PushSimpleOp(kRegexpNoWordBoundary);
}

// Pushes a $ onto the stack.
bool Regexp::ParseState::PushDollar() {
  if (flags_ & OneLine) {
    // Clumsy marker so that MimicsPCRE() can tell whether
    // this kRegexpEndText was a $ and not a \z.
    Regexp::ParseFlags oflags = flags_;
    flags_ = flags_ | WasDollar;
    bool ret = PushSimpleOp(kRegexpEndText);
    flags_ = oflags;
    return ret;
  }
  return PushSimpleOp(kRegexpEndLine);
}

// Pushes a . onto the stack.
bool Regexp::ParseState::PushDot() {
  if ((flags_ & DotNL) && !(flags_ & NeverNL))
    return PushSimpleOp(kRegexpAnyChar);
  // Rewrite . into [^\n]
  Regexp* re = new Regexp(kRegexpCharClass, flags_ & ~FoldCase);
  re->ccb_ = new CharClassBuilder;
  re->ccb_->AddRange(0, '\n' - 1);
  re->ccb_->AddRange('\n' + 1, rune_max_);
  return PushRegexp(re);
}

// Pushes a regexp with the given op (and no args) onto the stack.
bool Regexp::ParseState::PushSimpleOp(RegexpOp op) {
  Regexp* re = new Regexp(op, flags_);
  return PushRegexp(re);
}

// Pushes a repeat operator regexp onto the stack.
// A valid argument for the operator must already be on the stack.
// The char c is the name of the operator, for use in error messages.
bool Regexp::ParseState::PushRepeatOp(RegexpOp op, const StringPiece& s,
                                      bool nongreedy) {
  if (stacktop_ == NULL || IsMarker(stacktop_->op())) {
    status_->set_code(kRegexpRepeatArgument);
    status_->set_error_arg(s);
    return false;
  }
  Regexp::ParseFlags fl = flags_;
  if (nongreedy)
    fl = fl ^ NonGreedy;
  Regexp* re = new Regexp(op, fl);
  re->AllocSub(1);
  re->down_ = stacktop_->down_;
  re->sub()[0] = FinishRegexp(stacktop_);
  re->simple_ = re->ComputeSimple();
  stacktop_ = re;
  return true;
}

// Pushes a repetition regexp onto the stack.
// A valid argument for the operator must already be on the stack.
bool Regexp::ParseState::PushRepetition(int min, int max,
                                        const StringPiece& s,
                                        bool nongreedy) {
  if ((max != -1 && max < min) || min > 1000 || max > 1000) {
    status_->set_code(kRegexpRepeatSize);
    status_->set_error_arg(s);
    return false;
  }
  if (stacktop_ == NULL || IsMarker(stacktop_->op())) {
    status_->set_code(kRegexpRepeatArgument);
    status_->set_error_arg(s);
    return false;
  }
  Regexp::ParseFlags fl = flags_;
  if (nongreedy)
    fl = fl ^ NonGreedy;
  Regexp* re = new Regexp(kRegexpRepeat, fl);
  re->min_ = min;
  re->max_ = max;
  re->AllocSub(1);
  re->down_ = stacktop_->down_;
  re->sub()[0] = FinishRegexp(stacktop_);
  re->simple_ = re->ComputeSimple();

  stacktop_ = re;
  return true;
}

// Checks whether a particular regexp op is a marker.
bool Regexp::ParseState::IsMarker(RegexpOp op) {
  return op >= kLeftParen;
}

// Processes a left parenthesis in the input.
// Pushes a marker onto the stack.
bool Regexp::ParseState::DoLeftParen(const StringPiece& name) {
  Regexp* re = new Regexp(kLeftParen, flags_);
  re->cap_ = ++ncap_;
  if (name.data() != NULL)
    re->name_ = new string(name.as_string());
  return PushRegexp(re);
}

// Pushes a non-capturing marker onto the stack.
bool Regexp::ParseState::DoLeftParenNoCapture() {
  Regexp* re = new Regexp(kLeftParen, flags_);
  re->cap_ = -1;
  return PushRegexp(re);
}

// Adds r to cc, along with r's upper case if foldascii is set.
static void AddLiteral(CharClassBuilder* cc, Rune r, bool foldascii) {
  cc->AddRange(r, r);
  if (foldascii && 'a' <= r && r <= 'z')
    cc->AddRange(r + 'A' - 'a', r + 'A' - 'a');
}

// Processes a vertical bar in the input.
bool Regexp::ParseState::DoVerticalBar() {
  MaybeConcatString(-1, NoParseFlags);
  DoConcatenation();

  // Below the vertical bar is a list to alternate.
  // Above the vertical bar is a list to concatenate.
  // We just did the concatenation, so either swap
  // the result below the vertical bar or push a new
  // vertical bar on the stack.
  Regexp* r1;
  Regexp* r2;
  if ((r1 = stacktop_) != NULL &&
      (r2 = stacktop_->down_) != NULL &&
      r2->op() == kVerticalBar) {
    // If above and below vertical bar are literal or char class,
    // can merge into a single char class.
    Regexp* r3;
    if ((r1->op() == kRegexpLiteral ||
         r1->op() == kRegexpCharClass ||
         r1->op() == kRegexpAnyChar) &&
        (r3 = r2->down_) != NULL) {
      Rune rune;
      switch (r3->op()) {
        case kRegexpLiteral:  // convert to char class
          rune = r3->rune_;
          r3->op_ = kRegexpCharClass;
          r3->cc_ = NULL;
          r3->ccb_ = new CharClassBuilder;
          AddLiteral(r3->ccb_, rune, r3->parse_flags_ & Regexp::FoldCase);
          // fall through
        case kRegexpCharClass:
          if (r1->op() == kRegexpLiteral)
            AddLiteral(r3->ccb_, r1->rune_,
                       r1->parse_flags_ & Regexp::FoldCase);
          else if (r1->op() == kRegexpCharClass)
            r3->ccb_->AddCharClass(r1->ccb_);
          if (r1->op() == kRegexpAnyChar || r3->ccb_->full()) {
            delete r3->ccb_;
            r3->ccb_ = NULL;
            r3->op_ = kRegexpAnyChar;
          }
          // fall through
        case kRegexpAnyChar:
          // pop r1
          stacktop_ = r2;
          r1->Decref();
          return true;
        default:
          break;
      }
    }

    // Swap r1 below vertical bar (r2).
    r1->down_ = r2->down_;
    r2->down_ = r1;
    stacktop_ = r2;
    return true;
  }
  return PushSimpleOp(kVerticalBar);
}

// Processes a right parenthesis in the input.
bool Regexp::ParseState::DoRightParen() {
  // Finish the current concatenation and alternation.
  DoAlternation();

  // The stack should be: LeftParen regexp
  // Remove the LeftParen, leaving the regexp,
  // parenthesized.
  Regexp* r1;
  Regexp* r2;
  if ((r1 = stacktop_) == NULL ||
      (r2 = r1->down_) == NULL ||
      r2->op() != kLeftParen) {
    status_->set_code(kRegexpMissingParen);
    status_->set_error_arg(whole_regexp_);
    return false;
  }

  // Pop off r1, r2.  Will Decref or reuse below.
  stacktop_ = r2->down_;

  // Restore flags from when paren opened.
  Regexp* re = r2;
  flags_ = re->parse_flags();

  // Rewrite LeftParen as capture if needed.
  if (re->cap_ > 0) {
    re->op_ = kRegexpCapture;
    // re->cap_ is already set
    re->AllocSub(1);
    re->sub()[0] = FinishRegexp(r1);
    re->simple_ = re->ComputeSimple();
  } else {
    re->Decref();
    re = r1;
  }
  return PushRegexp(re);
}

// Processes the end of input, returning the final regexp.
Regexp* Regexp::ParseState::DoFinish() {
  DoAlternation();
  Regexp* re = stacktop_;
  if (re != NULL && re->down_ != NULL) {
    status_->set_code(kRegexpMissingParen);
    status_->set_error_arg(whole_regexp_);
    return NULL;
  }
  stacktop_ = NULL;
  return FinishRegexp(re);
}

// Returns the leading regexp that re starts with.
// The returned Regexp* points into a piece of re,
// so it must not be used after the caller calls re->Decref().
Regexp* Regexp::LeadingRegexp(Regexp* re) {
  if (re->op() == kRegexpEmptyMatch)
    return NULL;
  if (re->op() == kRegexpConcat && re->nsub() >= 2) {
    Regexp** sub = re->sub();
    if (sub[0]->op() == kRegexpEmptyMatch)
      return NULL;
    return sub[0];
  }
  return re;
}

// Removes LeadingRegexp(re) from re and returns what's left.
// Consumes the reference to re and may edit it in place.
// If caller wants to hold on to LeadingRegexp(re),
// must have already Incref'ed it.
Regexp* Regexp::RemoveLeadingRegexp(Regexp* re) {
  if (re->op() == kRegexpEmptyMatch)
    return re;
  if (re->op() == kRegexpConcat && re->nsub() >= 2) {
    Regexp** sub = re->sub();
    if (sub[0]->op() == kRegexpEmptyMatch)
      return re;
    sub[0]->Decref();
    sub[0] = NULL;
    if (re->nsub() == 2) {
      // Collapse concatenation to single regexp.
      Regexp* nre = sub[1];
      sub[1] = NULL;
      re->Decref();
      return nre;
    }
    // 3 or more -> 2 or more.
    re->nsub_--;
    memmove(sub, sub + 1, re->nsub_ * sizeof sub[0]);
    return re;
  }
  Regexp::ParseFlags pf = re->parse_flags();
  re->Decref();
  return new Regexp(kRegexpEmptyMatch, pf);
}

// Returns the leading string that re starts with.
// The returned Rune* points into a piece of re,
// so it must not be used after the caller calls re->Decref().
Rune* Regexp::LeadingString(Regexp* re, int *nrune,
                            Regexp::ParseFlags *flags) {
  while (re->op() == kRegexpConcat && re->nsub() > 0)
    re = re->sub()[0];

  *flags = static_cast<Regexp::ParseFlags>(re->parse_flags_ & Regexp::FoldCase);

  if (re->op() == kRegexpLiteral) {
    *nrune = 1;
    return &re->rune_;
  }

  if (re->op() == kRegexpLiteralString) {
    *nrune = re->nrunes_;
    return re->runes_;
  }

  *nrune = 0;
  return NULL;
}

// Removes the first n leading runes from the beginning of re.
// Edits re in place.
void Regexp::RemoveLeadingString(Regexp* re, int n) {
  // Chase down concats to find first string.
  // For regexps generated by parser, nested concats are
  // flattened except when doing so would overflow the 16-bit
  // limit on the size of a concatenation, so we should never
  // see more than two here.
  Regexp* stk[4];
  int d = 0;
  while (re->op() == kRegexpConcat) {
    if (d < arraysize(stk))
      stk[d++] = re;
    re = re->sub()[0];
  }

  // Remove leading string from re.
  if (re->op() == kRegexpLiteral) {
    re->rune_ = 0;
    re->op_ = kRegexpEmptyMatch;
  } else if (re->op() == kRegexpLiteralString) {
    if (n >= re->nrunes_) {
      delete[] re->runes_;
      re->runes_ = NULL;
      re->nrunes_ = 0;
      re->op_ = kRegexpEmptyMatch;
    } else if (n == re->nrunes_ - 1) {
      Rune rune = re->runes_[re->nrunes_ - 1];
      delete[] re->runes_;
      re->runes_ = NULL;
      re->nrunes_ = 0;
      re->rune_ = rune;
      re->op_ = kRegexpLiteral;
    } else {
      re->nrunes_ -= n;
      memmove(re->runes_, re->runes_ + n, re->nrunes_ * sizeof re->runes_[0]);
    }
  }

  // If re is now empty, concatenations might simplify too.
  while (d-- > 0) {
    re = stk[d];
    Regexp** sub = re->sub();
    if (sub[0]->op() == kRegexpEmptyMatch) {
      sub[0]->Decref();
      sub[0] = NULL;
      // Delete first element of concat.
      switch (re->nsub()) {
        case 0:
        case 1:
          // Impossible.
          LOG(DFATAL) << "Concat of " << re->nsub();
          re->submany_ = NULL;
          re->op_ = kRegexpEmptyMatch;
          break;

        case 2: {
          // Replace re with sub[1].
          Regexp* old = sub[1];
          sub[1] = NULL;
          re->Swap(old);
          old->Decref();
          break;
        }

        default:
          // Slide down.
          re->nsub_--;
          memmove(sub, sub + 1, re->nsub_ * sizeof sub[0]);
          break;
      }
    }
  }
}

// Factors common prefixes from alternation.
// For example,
//     ABC|ABD|AEF|BCX|BCY
// simplifies to
//     A(B(C|D)|EF)|BC(X|Y)
// which the normal parse state routines will further simplify to
//     A(B[CD]|EF)|BC[XY]
//
// Rewrites sub to contain simplified list to alternate and returns
// the new length of sub.  Adjusts reference counts accordingly
// (incoming sub[i] decremented, outgoing sub[i] incremented).

// It's too much of a pain to write this code with an explicit stack,
// so instead we let the caller specify a maximum depth and
// don't simplify beyond that.  There are around 15 words of local
// variables and parameters in the frame, so allowing 8 levels
// on a 64-bit machine is still less than a kilobyte of stack and
// probably enough benefit for practical uses.
const int kFactorAlternationMaxDepth = 8;

int Regexp::FactorAlternation(
    Regexp** sub, int n,
    Regexp::ParseFlags altflags) {
  return FactorAlternationRecursive(sub, n, altflags,
                                    kFactorAlternationMaxDepth);
}

int Regexp::FactorAlternationRecursive(
    Regexp** sub, int n,
    Regexp::ParseFlags altflags,
    int maxdepth) {

  if (maxdepth <= 0)
    return n;

  // Round 1: Factor out common literal prefixes.
  Rune *rune = NULL;
  int nrune = 0;
  Regexp::ParseFlags runeflags = Regexp::NoParseFlags;
  int start = 0;
  int out = 0;
  for (int i = 0; i <= n; i++) {
    // Invariant: what was in sub[0:start] has been Decref'ed
    // and that space has been reused for sub[0:out] (out <= start).
    //
    // Invariant: sub[start:i] consists of regexps that all begin
    // with the string rune[0:nrune].

    Rune* rune_i = NULL;
    int nrune_i = 0;
    Regexp::ParseFlags runeflags_i = Regexp::NoParseFlags;
    if (i < n) {
      rune_i = LeadingString(sub[i], &nrune_i, &runeflags_i);
      if (runeflags_i == runeflags) {
        int same = 0;
        while (same < nrune && same < nrune_i && rune[same] == rune_i[same])
          same++;
        if (same > 0) {
          // Matches at least one rune in current range.  Keep going around.
          nrune = same;
          continue;
        }
      }
    }

    // Found end of a run with common leading literal string:
    // sub[start:i] all begin with rune[0:nrune] but sub[i]
    // does not even begin with rune[0].
    //
    // Factor out common string and append factored expression to sub[0:out].
    if (i == start) {
      // Nothing to do - first iteration.
    } else if (i == start+1) {
      // Just one: don't bother factoring.
      sub[out++] = sub[start];
    } else {
      // Construct factored form: prefix(suffix1|suffix2|...)
      Regexp* x[2];  // x[0] = prefix, x[1] = suffix1|suffix2|...
      x[0] = LiteralString(rune, nrune, runeflags);
      for (int j = start; j < i; j++)
        RemoveLeadingString(sub[j], nrune);
      int nn = FactorAlternationRecursive(sub + start, i - start, altflags,
                                          maxdepth - 1);
      x[1] = AlternateNoFactor(sub + start, nn, altflags);
      sub[out++] = Concat(x, 2, altflags);
    }

    // Prepare for next round (if there is one).
    if (i < n) {
      start = i;
      rune = rune_i;
      nrune = nrune_i;
      runeflags = runeflags_i;
    }
  }
  n = out;

  // Round 2: Factor out common complex prefixes,
  // just the first piece of each concatenation,
  // whatever it is.  This is good enough a lot of the time.
  start = 0;
  out = 0;
  Regexp* first = NULL;
  for (int i = 0; i <= n; i++) {
    // Invariant: what was in sub[0:start] has been Decref'ed
    // and that space has been reused for sub[0:out] (out <= start).
    //
    // Invariant: sub[start:i] consists of regexps that all begin with first.

    Regexp* first_i = NULL;
    if (i < n) {
      first_i = LeadingRegexp(sub[i]);
      if (first != NULL && Regexp::Equal(first, first_i)) {
        continue;
      }
    }

    // Found end of a run with common leading regexp:
    // sub[start:i] all begin with first but sub[i] does not.
    //
    // Factor out common regexp and append factored expression to sub[0:out].
    if (i == start) {
      // Nothing to do - first iteration.
    } else if (i == start+1) {
      // Just one: don't bother factoring.
      sub[out++] = sub[start];
    } else {
      // Construct factored form: prefix(suffix1|suffix2|...)
      Regexp* x[2];  // x[0] = prefix, x[1] = suffix1|suffix2|...
      x[0] = first->Incref();
      for (int j = start; j < i; j++)
        sub[j] = RemoveLeadingRegexp(sub[j]);
      int nn = FactorAlternationRecursive(sub + start, i - start, altflags,
                                   maxdepth - 1);
      x[1] = AlternateNoFactor(sub + start, nn, altflags);
      sub[out++] = Concat(x, 2, altflags);
    }

    // Prepare for next round (if there is one).
    if (i < n) {
      start = i;
      first = first_i;
    }
  }
  n = out;

  // Round 3: Collapse runs of single literals into character classes.
  start = 0;
  out = 0;
  for (int i = 0; i <= n; i++) {
    // Invariant: what was in sub[0:start] has been Decref'ed
    // and that space has been reused for sub[0:out] (out <= start).
    //
    // Invariant: sub[start:i] consists of regexps that are either
    // literal runes or character classes.

    if (i < n &&
        (sub[i]->op() == kRegexpLiteral ||
         sub[i]->op() == kRegexpCharClass))
      continue;

    // sub[i] is not a char or char class;
    // emit char class for sub[start:i]...
    if (i == start) {
      // Nothing to do.
    } else if (i == start+1) {
      sub[out++] = sub[start];
    } else {
      // Make new char class.
      CharClassBuilder ccb;
      for (int j = start; j < i; j++) {
        Regexp* re = sub[j];
        if (re->op() == kRegexpCharClass) {
          CharClass* cc = re->cc();
          for (CharClass::iterator it = cc->begin(); it != cc->end(); ++it)
            ccb.AddRange(it->lo, it->hi);
        } else if (re->op() == kRegexpLiteral) {
          ccb.AddRangeFlags(re->rune(), re->rune(), re->parse_flags());
        } else {
          LOG(DFATAL) << "RE2: unexpected op: " << re->op() << " "
                      << re->ToString();
        }
        re->Decref();
      }
      sub[out++] = NewCharClass(ccb.GetCharClass(), altflags);
    }

    // ... and then emit sub[i].
    if (i < n)
      sub[out++] = sub[i];
    start = i+1;
  }
  n = out;

  // Round 4: Collapse runs of empty matches into single empty match.
  start = 0;
  out = 0;
  for (int i = 0; i < n; i++) {
    if (i + 1 < n &&
        sub[i]->op() == kRegexpEmptyMatch &&
        sub[i+1]->op() == kRegexpEmptyMatch) {
      sub[i]->Decref();
      continue;
    }
    sub[out++] = sub[i];
  }
  n = out;

  return n;
}

// Collapse the regexps on top of the stack, down to the
// first marker, into a new op node (op == kRegexpAlternate
// or op == kRegexpConcat).
void Regexp::ParseState::DoCollapse(RegexpOp op) {
  // Scan backward to marker, counting children of composite.
  int n = 0;
  Regexp* next = NULL;
  Regexp* sub;
  for (sub = stacktop_; sub != NULL && !IsMarker(sub->op()); sub = next) {
    next = sub->down_;
    if (sub->op_ == op)
      n += sub->nsub_;
    else
      n++;
  }

  // If there's just one child, leave it alone.
  // (Concat of one thing is that one thing; alternate of one thing is same.)
  if (stacktop_ != NULL && stacktop_->down_ == next)
    return;

  // Construct op (alternation or concatenation), flattening op of op.
  Regexp** subs = new Regexp*[n];
  next = NULL;
  int i = n;
  for (sub = stacktop_; sub != NULL && !IsMarker(sub->op()); sub = next) {
    next = sub->down_;
    if (sub->op_ == op) {
      Regexp** sub_subs = sub->sub();
      for (int k = sub->nsub_ - 1; k >= 0; k--)
        subs[--i] = sub_subs[k]->Incref();
      sub->Decref();
    } else {
      subs[--i] = FinishRegexp(sub);
    }
  }

  Regexp* re = ConcatOrAlternate(op, subs, n, flags_, true);
  delete[] subs;
  re->simple_ = re->ComputeSimple();
  re->down_ = next;
  stacktop_ = re;
}

// Finishes the current concatenation,
// collapsing it into a single regexp on the stack.
void Regexp::ParseState::DoConcatenation() {
  Regexp* r1 = stacktop_;
  if (r1 == NULL || IsMarker(r1->op())) {
    // empty concatenation is special case
    Regexp* re = new Regexp(kRegexpEmptyMatch, flags_);
    PushRegexp(re);
  }
  DoCollapse(kRegexpConcat);
}

// Finishes the current alternation,
// collapsing it to a single regexp on the stack.
void Regexp::ParseState::DoAlternation() {
  DoVerticalBar();
  // Now stack top is kVerticalBar.
  Regexp* r1 = stacktop_;
  stacktop_ = r1->down_;
  r1->Decref();
  DoCollapse(kRegexpAlternate);
}

// Incremental conversion of concatenated literals into strings.
// If top two elements on stack are both literal or string,
// collapse into single string.
// Don't walk down the stack -- the parser calls this frequently
// enough that below the bottom two is known to be collapsed.
// Only called when another regexp is about to be pushed
// on the stack, so that the topmost literal is not being considered.
// (Otherwise ab* would turn into (ab)*.)
// If r >= 0, consider pushing a literal r on the stack.
// Return whether that happened.
bool Regexp::ParseState::MaybeConcatString(int r, ParseFlags flags) {
  Regexp* re1;
  Regexp* re2;
  if ((re1 = stacktop_) == NULL || (re2 = re1->down_) == NULL)
    return false;

  if (re1->op_ != kRegexpLiteral && re1->op_ != kRegexpLiteralString)
    return false;
  if (re2->op_ != kRegexpLiteral && re2->op_ != kRegexpLiteralString)
    return false;
  if ((re1->parse_flags_ & FoldCase) != (re2->parse_flags_ & FoldCase))
    return false;

  if (re2->op_ == kRegexpLiteral) {
    // convert into string
    Rune rune = re2->rune_;
    re2->op_ = kRegexpLiteralString;
    re2->nrunes_ = 0;
    re2->runes_ = NULL;
    re2->AddRuneToString(rune);
  }

  // push re1 into re2.
  if (re1->op_ == kRegexpLiteral) {
    re2->AddRuneToString(re1->rune_);
  } else {
    for (int i = 0; i < re1->nrunes_; i++)
      re2->AddRuneToString(re1->runes_[i]);
    re1->nrunes_ = 0;
    delete[] re1->runes_;
    re1->runes_ = NULL;
  }

  // reuse re1 if possible
  if (r >= 0) {
    re1->op_ = kRegexpLiteral;
    re1->rune_ = r;
    re1->parse_flags_ = flags;
    return true;
  }

  stacktop_ = re2;
  re1->Decref();
  return false;
}

// Lexing routines.

// Parses a decimal integer, storing it in *n.
// Sets *s to span the remainder of the string.
// Sets *out_re to the regexp for the class.
static bool ParseInteger(StringPiece* s, int* np) {
  if (s->size() == 0 || !isdigit((*s)[0] & 0xFF))
    return false;
  // Disallow leading zeros.
  if (s->size() >= 2 && (*s)[0] == '0' && isdigit((*s)[1] & 0xFF))
    return false;
  int n = 0;
  int c;
  while (s->size() > 0 && isdigit(c = (*s)[0] & 0xFF)) {
    // Avoid overflow.
    if (n >= 100000000)
      return false;
    n = n*10 + c - '0';
    s->remove_prefix(1);  // digit
  }
  *np = n;
  return true;
}

// Parses a repetition suffix like {1,2} or {2} or {2,}.
// Sets *s to span the remainder of the string on success.
// Sets *lo and *hi to the given range.
// In the case of {2,}, the high number is unbounded;
// sets *hi to -1 to signify this.
// {,2} is NOT a valid suffix.
// The Maybe in the name signifies that the regexp parse
// doesn't fail even if ParseRepetition does, so the StringPiece
// s must NOT be edited unless MaybeParseRepetition returns true.
static bool MaybeParseRepetition(StringPiece* sp, int* lo, int* hi) {
  StringPiece s = *sp;
  if (s.size() == 0 || s[0] != '{')
    return false;
  s.remove_prefix(1);  // '{'
  if (!ParseInteger(&s, lo))
    return false;
  if (s.size() == 0)
    return false;
  if (s[0] == ',') {
    s.remove_prefix(1);  // ','
    if (s.size() == 0)
      return false;
    if (s[0] == '}') {
      // {2,} means at least 2
      *hi = -1;
    } else {
      // {2,4} means 2, 3, or 4.
      if (!ParseInteger(&s, hi))
        return false;
    }
  } else {
    // {2} means exactly two
    *hi = *lo;
  }
  if (s.size() == 0 || s[0] != '}')
    return false;
  s.remove_prefix(1);  // '}'
  *sp = s;
  return true;
}

// Removes the next Rune from the StringPiece and stores it in *r.
// Returns number of bytes removed from sp.
// Behaves as though there is a terminating NUL at the end of sp.
// Argument order is backwards from usual Google style
// but consistent with chartorune.
static int StringPieceToRune(Rune *r, StringPiece *sp, RegexpStatus* status) {
  int n;
  if (fullrune(sp->data(), sp->size())) {
    n = chartorune(r, sp->data());
    if (!(n == 1 && *r == Runeerror)) {  // no decoding error
      sp->remove_prefix(n);
      return n;
    }
  }

  status->set_code(kRegexpBadUTF8);
  status->set_error_arg(NULL);
  return -1;
}

// Return whether name is valid UTF-8.
// If not, set status to kRegexpBadUTF8.
static bool IsValidUTF8(const StringPiece& s, RegexpStatus* status) {
  StringPiece t = s;
  Rune r;
  while (t.size() > 0) {
    if (StringPieceToRune(&r, &t, status) < 0)
      return false;
  }
  return true;
}

// Is c a hex digit?
static int IsHex(int c) {
  return ('0' <= c && c <= '9') ||
         ('A' <= c && c <= 'F') ||
         ('a' <= c && c <= 'f');
}

// Convert hex digit to value.
static int UnHex(int c) {
  if ('0' <= c && c <= '9')
    return c - '0';
  if ('A' <= c && c <= 'F')
    return c - 'A' + 10;
  if ('a' <= c && c <= 'f')
    return c - 'a' + 10;
  LOG(DFATAL) << "Bad hex digit " << c;
  return 0;
}

// Parse an escape sequence (e.g., \n, \{).
// Sets *s to span the remainder of the string.
// Sets *rp to the named character.
static bool ParseEscape(StringPiece* s, Rune* rp,
                        RegexpStatus* status, int rune_max) {
  const char* begin = s->begin();
  if (s->size() < 1 || (*s)[0] != '\\') {
    // Should not happen - caller always checks.
    status->set_code(kRegexpInternalError);
    status->set_error_arg(NULL);
    return false;
  }
  if (s->size() < 2) {
    status->set_code(kRegexpTrailingBackslash);
    status->set_error_arg(NULL);
    return false;
  }
  Rune c, c1;
  s->remove_prefix(1);  // backslash
  if (StringPieceToRune(&c, s, status) < 0)
    return false;
  int code;
  switch (c) {
    default:
      if (c < Runeself && !isalpha(c) && !isdigit(c)) {
        // Escaped non-word characters are always themselves.
        // PCRE is not quite so rigorous: it accepts things like
        // \q, but we don't.  We once rejected \_, but too many
        // programs and people insist on using it, so allow \_.
        *rp = c;
        return true;
      }
      goto BadEscape;

    // Octal escapes.
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
      // Single non-zero octal digit is a backreference; not supported.
      if (s->size() == 0 || (*s)[0] < '0' || (*s)[0] > '7')
        goto BadEscape;
      // fall through
    case '0':
      // consume up to three octal digits; already have one.
      code = c - '0';
      if (s->size() > 0 && '0' <= (c = (*s)[0]) && c <= '7') {
        code = code * 8 + c - '0';
        s->remove_prefix(1);  // digit
        if (s->size() > 0) {
          c = (*s)[0];
          if ('0' <= c && c <= '7') {
            code = code * 8 + c - '0';
            s->remove_prefix(1);  // digit
          }
        }
      }
      *rp = code;
      return true;

    // Hexadecimal escapes
    case 'x':
      if (s->size() == 0)
        goto BadEscape;
      if (StringPieceToRune(&c, s, status) < 0)
        return false;
      if (c == '{') {
        // Any number of digits in braces.
        // Update n as we consume the string, so that
        // the whole thing gets shown in the error message.
        // Perl accepts any text at all; it ignores all text
        // after the first non-hex digit.  We require only hex digits,
        // and at least one.
        if (StringPieceToRune(&c, s, status) < 0)
          return false;
        int nhex = 0;
        code = 0;
        while (IsHex(c)) {
          nhex++;
          code = code * 16 + UnHex(c);
          if (code > rune_max)
            goto BadEscape;
          if (s->size() == 0)
            goto BadEscape;
          if (StringPieceToRune(&c, s, status) < 0)
            return false;
        }
        if (c != '}' || nhex == 0)
          goto BadEscape;
        *rp = code;
        return true;
      }
      // Easy case: two hex digits.
      if (s->size() == 0)
        goto BadEscape;
      if (StringPieceToRune(&c1, s, status) < 0)
        return false;
      if (!IsHex(c) || !IsHex(c1))
        goto BadEscape;
      *rp = UnHex(c) * 16 + UnHex(c1);
      return true;

    // C escapes.
    case 'n':
      *rp = '\n';
      return true;
    case 'r':
      *rp = '\r';
      return true;
    case 't':
      *rp = '\t';
      return true;

    // Less common C escapes.
    case 'a':
      *rp = '\a';
      return true;
    case 'f':
      *rp = '\f';
      return true;
    case 'v':
      *rp = '\v';
      return true;

    // This code is disabled to avoid misparsing
    // the Perl word-boundary \b as a backspace
    // when in POSIX regexp mode.  Surprisingly,
    // in Perl, \b means word-boundary but [\b]
    // means backspace.  We don't support that:
    // if you want a backspace embed a literal
    // backspace character or use \x08.
    //
    // case 'b':
    //   *rp = '\b';
    //   return true;
  }

  LOG(DFATAL) << "Not reached in ParseEscape.";

BadEscape:
  // Unrecognized escape sequence.
  status->set_code(kRegexpBadEscape);
  status->set_error_arg(StringPiece(begin, s->data() - begin));
  return false;
}

// Add a range to the character class, but exclude newline if asked.
// Also handle case folding.
void CharClassBuilder::AddRangeFlags(
    Rune lo, Rune hi, Regexp::ParseFlags parse_flags) {

  // Take out \n if the flags say so.
  bool cutnl = !(parse_flags & Regexp::ClassNL) ||
               (parse_flags & Regexp::NeverNL);
  if (cutnl && lo <= '\n' && '\n' <= hi) {
    if (lo < '\n')
      AddRangeFlags(lo, '\n' - 1, parse_flags);
    if (hi > '\n')
      AddRangeFlags('\n' + 1, hi, parse_flags);
    return;
  }

  // If folding case, add fold-equivalent characters too.
  if (parse_flags & Regexp::FoldCase)
    AddFoldedRange(this, lo, hi, 0);
  else
    AddRange(lo, hi);
}

// Look for a group with the given name.
static UGroup* LookupGroup(const StringPiece& name,
                           UGroup *groups, int ngroups) {
  // Simple name lookup.
  for (int i = 0; i < ngroups; i++)
    if (StringPiece(groups[i].name) == name)
      return &groups[i];
  return NULL;
}

// Fake UGroup containing all Runes
static URange16 any16[] = { { 0, 65535 } };
static URange32 any32[] = { { 65536, Runemax } };
static UGroup anygroup = { "Any", +1, any16, 1, any32, 1 };

// Look for a POSIX group with the given name (e.g., "[:^alpha:]")
static UGroup* LookupPosixGroup(const StringPiece& name) {
  return LookupGroup(name, posix_groups, num_posix_groups);
}

static UGroup* LookupPerlGroup(const StringPiece& name) {
  return LookupGroup(name, perl_groups, num_perl_groups);
}

// Look for a Unicode group with the given name (e.g., "Han")
static UGroup* LookupUnicodeGroup(const StringPiece& name) {
  // Special case: "Any" means any.
  if (name == StringPiece("Any"))
    return &anygroup;
  return LookupGroup(name, unicode_groups, num_unicode_groups);
}

// Add a UGroup or its negation to the character class.
static void AddUGroup(CharClassBuilder *cc, UGroup *g, int sign,
                      Regexp::ParseFlags parse_flags) {
  if (sign == +1) {
    for (int i = 0; i < g->nr16; i++) {
      cc->AddRangeFlags(g->r16[i].lo, g->r16[i].hi, parse_flags);
    }
    for (int i = 0; i < g->nr32; i++) {
      cc->AddRangeFlags(g->r32[i].lo, g->r32[i].hi, parse_flags);
    }
  } else {
    if (parse_flags & Regexp::FoldCase) {
      // Normally adding a case-folded group means
      // adding all the extra fold-equivalent runes too.
      // But if we're adding the negation of the group,
      // we have to exclude all the runes that are fold-equivalent
      // to what's already missing.  Too hard, so do in two steps.
      CharClassBuilder ccb1;
      AddUGroup(&ccb1, g, +1, parse_flags);
      // If the flags say to take out \n, put it in, so that negating will take it out.
      // Normally AddRangeFlags does this, but we're bypassing AddRangeFlags.
      bool cutnl = !(parse_flags & Regexp::ClassNL) ||
                   (parse_flags & Regexp::NeverNL);
      if (cutnl) {
        ccb1.AddRange('\n', '\n');
      }
      ccb1.Negate();
      cc->AddCharClass(&ccb1);
      return;
    }
    int next = 0;
    for (int i = 0; i < g->nr16; i++) {
      if (next < g->r16[i].lo)
        cc->AddRangeFlags(next, g->r16[i].lo - 1, parse_flags);
      next = g->r16[i].hi + 1;
    }
    for (int i = 0; i < g->nr32; i++) {
      if (next < g->r32[i].lo)
        cc->AddRangeFlags(next, g->r32[i].lo - 1, parse_flags);
      next = g->r32[i].hi + 1;
    }
    if (next <= Runemax)
      cc->AddRangeFlags(next, Runemax, parse_flags);
  }
}

// Maybe parse a Perl character class escape sequence.
// Only recognizes the Perl character classes (\d \s \w \D \S \W),
// not the Perl empty-string classes (\b \B \A \Z \z).
// On success, sets *s to span the remainder of the string
// and returns the corresponding UGroup.
// The StringPiece must *NOT* be edited unless the call succeeds.
UGroup* MaybeParsePerlCCEscape(StringPiece* s, Regexp::ParseFlags parse_flags) {
  if (!(parse_flags & Regexp::PerlClasses))
    return NULL;
  if (s->size() < 2 || (*s)[0] != '\\')
    return NULL;
  // Could use StringPieceToRune, but there aren't
  // any non-ASCII Perl group names.
  StringPiece name(s->begin(), 2);
  UGroup *g = LookupPerlGroup(name);
  if (g == NULL)
    return NULL;
  s->remove_prefix(name.size());
  return g;
}

enum ParseStatus {
  kParseOk,  // Did some parsing.
  kParseError,  // Found an error.
  kParseNothing,  // Decided not to parse.
};

// Maybe parses a Unicode character group like \p{Han} or \P{Han}
// (the latter is a negated group).
ParseStatus ParseUnicodeGroup(StringPiece* s, Regexp::ParseFlags parse_flags,
                              CharClassBuilder *cc,
                              RegexpStatus* status) {
  // Decide whether to parse.
  if (!(parse_flags & Regexp::UnicodeGroups))
    return kParseNothing;
  if (s->size() < 2 || (*s)[0] != '\\')
    return kParseNothing;
  Rune c = (*s)[1];
  if (c != 'p' && c != 'P')
    return kParseNothing;

  // Committed to parse.  Results:
  int sign = +1;  // -1 = negated char class
  if (c == 'P')
    sign = -1;
  StringPiece seq = *s;  // \p{Han} or \pL
  StringPiece name;  // Han or L
  s->remove_prefix(2);  // '\\', 'p'

  if (!StringPieceToRune(&c, s, status))
    return kParseError;
  if (c != '{') {
    // Name is the bit of string we just skipped over for c.
    const char* p = seq.begin() + 2;
    name = StringPiece(p, s->begin() - p);
  } else {
    // Name is in braces. Look for closing }
    int end = s->find('}', 0);
    if (end == s->npos) {
      if (!IsValidUTF8(seq, status))
        return kParseError;
      status->set_code(kRegexpBadCharRange);
      status->set_error_arg(seq);
      return kParseError;
    }
    name = StringPiece(s->begin(), end);  // without '}'
    s->remove_prefix(end + 1);  // with '}'
    if (!IsValidUTF8(name, status))
      return kParseError;
  }

  // Chop seq where s now begins.
  seq = StringPiece(seq.begin(), s->begin() - seq.begin());

  // Look up group
  if (name.size() > 0 && name[0] == '^') {
    sign = -sign;
    name.remove_prefix(1);  // '^'
  }
  UGroup *g = LookupUnicodeGroup(name);
  if (g == NULL) {
    status->set_code(kRegexpBadCharRange);
    status->set_error_arg(seq);
    return kParseError;
  }

  AddUGroup(cc, g, sign, parse_flags);
  return kParseOk;
}

// Parses a character class name like [:alnum:].
// Sets *s to span the remainder of the string.
// Adds the ranges corresponding to the class to ranges.
static ParseStatus ParseCCName(StringPiece* s, Regexp::ParseFlags parse_flags,
                               CharClassBuilder *cc,
                               RegexpStatus* status) {
  // Check begins with [:
  const char* p = s->data();
  const char* ep = s->data() + s->size();
  if (ep - p < 2 || p[0] != '[' || p[1] != ':')
    return kParseNothing;

  // Look for closing :].
  const char* q;
  for (q = p+2; q <= ep-2 && (*q != ':' || *(q+1) != ']'); q++)
    ;

  // If no closing :], then ignore.
  if (q > ep-2)
    return kParseNothing;

  // Got it.  Check that it's valid.
  q += 2;
  StringPiece name(p, q-p);

  UGroup *g = LookupPosixGroup(name);
  if (g == NULL) {
    status->set_code(kRegexpBadCharRange);
    status->set_error_arg(name);
    return kParseError;
  }

  s->remove_prefix(name.size());
  AddUGroup(cc, g, g->sign, parse_flags);
  return kParseOk;
}

// Parses a character inside a character class.
// There are fewer special characters here than in the rest of the regexp.
// Sets *s to span the remainder of the string.
// Sets *rp to the character.
bool Regexp::ParseState::ParseCCCharacter(StringPiece* s, Rune *rp,
                                          const StringPiece& whole_class,
                                          RegexpStatus* status) {
  if (s->size() == 0) {
    status->set_code(kRegexpMissingBracket);
    status->set_error_arg(whole_class);
    return false;
  }

  // Allow regular escape sequences even though
  // many need not be escaped in this context.
  if (s->size() >= 1 && (*s)[0] == '\\')
    return ParseEscape(s, rp, status, rune_max_);

  // Otherwise take the next rune.
  return StringPieceToRune(rp, s, status) >= 0;
}

// Parses a character class character, or, if the character
// is followed by a hyphen, parses a character class range.
// For single characters, rr->lo == rr->hi.
// Sets *s to span the remainder of the string.
// Sets *rp to the character.
bool Regexp::ParseState::ParseCCRange(StringPiece* s, RuneRange* rr,
                                      const StringPiece& whole_class,
                                      RegexpStatus* status) {
  StringPiece os = *s;
  if (!ParseCCCharacter(s, &rr->lo, whole_class, status))
    return false;
  // [a-] means (a|-), so check for final ].
  if (s->size() >= 2 && (*s)[0] == '-' && (*s)[1] != ']') {
    s->remove_prefix(1);  // '-'
    if (!ParseCCCharacter(s, &rr->hi, whole_class, status))
      return false;
    if (rr->hi < rr->lo) {
      status->set_code(kRegexpBadCharRange);
      status->set_error_arg(StringPiece(os.data(), s->data() - os.data()));
      return false;
    }
  } else {
    rr->hi = rr->lo;
  }
  return true;
}

// Parses a possibly-negated character class expression like [^abx-z[:digit:]].
// Sets *s to span the remainder of the string.
// Sets *out_re to the regexp for the class.
bool Regexp::ParseState::ParseCharClass(StringPiece* s,
                                        Regexp** out_re,
                                        RegexpStatus* status) {
  StringPiece whole_class = *s;
  if (s->size() == 0 || (*s)[0] != '[') {
    // Caller checked this.
    status->set_code(kRegexpInternalError);
    status->set_error_arg(NULL);
    return false;
  }
  bool negated = false;
  Regexp* re = new Regexp(kRegexpCharClass, flags_ & ~FoldCase);
  re->ccb_ = new CharClassBuilder;
  s->remove_prefix(1);  // '['
  if (s->size() > 0 && (*s)[0] == '^') {
    s->remove_prefix(1);  // '^'
    negated = true;
    if (!(flags_ & ClassNL) || (flags_ & NeverNL)) {
      // If NL can't match implicitly, then pretend
      // negated classes include a leading \n.
      re->ccb_->AddRange('\n', '\n');
    }
  }
  bool first = true;  // ] is okay as first char in class
  while (s->size() > 0 && ((*s)[0] != ']' || first)) {
    // - is only okay unescaped as first or last in class.
    // Except that Perl allows - anywhere.
    if ((*s)[0] == '-' && !first && !(flags_&PerlX) &&
        (s->size() == 1 || (*s)[1] != ']')) {
      StringPiece t = *s;
      t.remove_prefix(1);  // '-'
      Rune r;
      int n = StringPieceToRune(&r, &t, status);
      if (n < 0) {
        re->Decref();
        return false;
      }
      status->set_code(kRegexpBadCharRange);
      status->set_error_arg(StringPiece(s->data(), 1+n));
      re->Decref();
      return false;
    }
    first = false;

    // Look for [:alnum:] etc.
    if (s->size() > 2 && (*s)[0] == '[' && (*s)[1] == ':') {
      switch (ParseCCName(s, flags_, re->ccb_, status)) {
        case kParseOk:
          continue;
        case kParseError:
          re->Decref();
          return false;
        case kParseNothing:
          break;
      }
    }

    // Look for Unicode character group like \p{Han}
    if (s->size() > 2 &&
        (*s)[0] == '\\' &&
        ((*s)[1] == 'p' || (*s)[1] == 'P')) {
      switch (ParseUnicodeGroup(s, flags_, re->ccb_, status)) {
        case kParseOk:
          continue;
        case kParseError:
          re->Decref();
          return false;
        case kParseNothing:
          break;
      }
    }

    // Look for Perl character class symbols (extension).
    UGroup *g = MaybeParsePerlCCEscape(s, flags_);
    if (g != NULL) {
      AddUGroup(re->ccb_, g, g->sign, flags_);
      continue;
    }

    // Otherwise assume single character or simple range.
    RuneRange rr;
    if (!ParseCCRange(s, &rr, whole_class, status)) {
      re->Decref();
      return false;
    }
    // AddRangeFlags is usually called in response to a class like
    // \p{Foo} or [[:foo:]]; for those, it filters \n out unless
    // Regexp::ClassNL is set.  In an explicit range or singleton
    // like we just parsed, we do not filter \n out, so set ClassNL
    // in the flags.
    re->ccb_->AddRangeFlags(rr.lo, rr.hi, flags_ | Regexp::ClassNL);
  }
  if (s->size() == 0) {
    status->set_code(kRegexpMissingBracket);
    status->set_error_arg(whole_class);
    re->Decref();
    return false;
  }
  s->remove_prefix(1);  // ']'

  if (negated)
    re->ccb_->Negate();
  re->ccb_->RemoveAbove(rune_max_);

  *out_re = re;
  return true;
}

// Is this a valid capture name?  [A-Za-z0-9_]+
// PCRE limits names to 32 bytes.
// Python rejects names starting with digits.
// We don't enforce either of those.
static bool IsValidCaptureName(const StringPiece& name) {
  if (name.size() == 0)
    return false;
  for (int i = 0; i < name.size(); i++) {
    int c = name[i];
    if (('0' <= c && c <= '9') ||
        ('a' <= c && c <= 'z') ||
        ('A' <= c && c <= 'Z') ||
        c == '_')
      continue;
    return false;
  }
  return true;
}

// Parses a Perl flag setting or non-capturing group or both,
// like (?i) or (?: or (?i:.  Removes from s, updates parse state.
// The caller must check that s begins with "(?".
// Returns true on success.  If the Perl flag is not
// well-formed or not supported, sets status_ and returns false.
bool Regexp::ParseState::ParsePerlFlags(StringPiece* s) {
  StringPiece t = *s;

  // Caller is supposed to check this.
  if (!(flags_ & PerlX) || t.size() < 2 || t[0] != '(' || t[1] != '?') {
    LOG(DFATAL) << "Bad call to ParseState::ParsePerlFlags";
    status_->set_code(kRegexpInternalError);
    return false;
  }

  t.remove_prefix(2);  // "(?"

  // Check for named captures, first introduced in Python's regexp library.
  // As usual, there are three slightly different syntaxes:
  //
  //   (?P<name>expr)   the original, introduced by Python
  //   (?<name>expr)    the .NET alteration, adopted by Perl 5.10
  //   (?'name'expr)    another .NET alteration, adopted by Perl 5.10
  //
  // Perl 5.10 gave in and implemented the Python version too,
  // but they claim that the last two are the preferred forms.
  // PCRE and languages based on it (specifically, PHP and Ruby)
  // support all three as well.  EcmaScript 4 uses only the Python form.
  //
  // In both the open source world (via Code Search) and the
  // Google source tree, (?P<expr>name) is the dominant form,
  // so that's the one we implement.  One is enough.
  if (t.size() > 2 && t[0] == 'P' && t[1] == '<') {
    // Pull out name.
    int end = t.find('>', 2);
    if (end == t.npos) {
      if (!IsValidUTF8(*s, status_))
        return false;
      status_->set_code(kRegexpBadNamedCapture);
      status_->set_error_arg(*s);
      return false;
    }

    // t is "P<name>...", t[end] == '>'
    StringPiece capture(t.begin()-2, end+3);  // "(?P<name>"
    StringPiece name(t.begin()+2, end-2);     // "name"
    if (!IsValidUTF8(name, status_))
      return false;
    if (!IsValidCaptureName(name)) {
      status_->set_code(kRegexpBadNamedCapture);
      status_->set_error_arg(capture);
      return false;
    }

    if (!DoLeftParen(name)) {
      // DoLeftParen's failure set status_.
      return false;
    }

    s->remove_prefix(capture.end() - s->begin());
    return true;
  }

  bool negated = false;
  bool sawflags = false;
  int nflags = flags_;
  Rune c;
  for (bool done = false; !done; ) {
    if (t.size() == 0)
      goto BadPerlOp;
    if (StringPieceToRune(&c, &t, status_) < 0)
      return false;
    switch (c) {
      default:
        goto BadPerlOp;

      // Parse flags.
      case 'i':
        sawflags = true;
        if (negated)
          nflags &= ~FoldCase;
        else
          nflags |= FoldCase;
        break;

      case 'm':  // opposite of our OneLine
        sawflags = true;
        if (negated)
          nflags |= OneLine;
        else
          nflags &= ~OneLine;
        break;

      case 's':
        sawflags = true;
        if (negated)
          nflags &= ~DotNL;
        else
          nflags |= DotNL;
        break;

      case 'U':
        sawflags = true;
        if (negated)
          nflags &= ~NonGreedy;
        else
          nflags |= NonGreedy;
        break;

      // Negation
      case '-':
        if (negated)
          goto BadPerlOp;
        negated = true;
        sawflags = false;
        break;

      // Open new group.
      case ':':
        if (!DoLeftParenNoCapture()) {
          // DoLeftParenNoCapture's failure set status_.
          return false;
        }
        done = true;
        break;

      // Finish flags.
      case ')':
        done = true;
        break;
    }
  }

  if (negated && !sawflags)
    goto BadPerlOp;

  flags_ = static_cast<Regexp::ParseFlags>(nflags);
  *s = t;
  return true;

BadPerlOp:
  status_->set_code(kRegexpBadPerlOp);
  status_->set_error_arg(StringPiece(s->begin(), t.begin() - s->begin()));
  return false;
}

// Converts latin1 (assumed to be encoded as Latin1 bytes)
// into UTF8 encoding in string.
// Can't use EncodingUtils::EncodeLatin1AsUTF8 because it is
// deprecated and because it rejects code points 0x80-0x9F.
void ConvertLatin1ToUTF8(const StringPiece& latin1, string* utf) {
  char buf[UTFmax];

  utf->clear();
  for (int i = 0; i < latin1.size(); i++) {
    Rune r = latin1[i] & 0xFF;
    int n = runetochar(buf, &r);
    utf->append(buf, n);
  }
}

// Parses the regular expression given by s,
// returning the corresponding Regexp tree.
// The caller must Decref the return value when done with it.
// Returns NULL on error.
Regexp* Regexp::Parse(const StringPiece& s, ParseFlags global_flags,
                      RegexpStatus* status) {
  // Make status non-NULL (easier on everyone else).
  RegexpStatus xstatus;
  if (status == NULL)
    status = &xstatus;

  ParseState ps(global_flags, s, status);
  StringPiece t = s;

  // Convert regexp to UTF-8 (easier on the rest of the parser).
  if (global_flags & Latin1) {
    string* tmp = new string;
    ConvertLatin1ToUTF8(t, tmp);
    status->set_tmp(tmp);
    t = *tmp;
  }

  if (global_flags & Literal) {
    // Special parse loop for literal string.
    while (t.size() > 0) {
      Rune r;
      if (StringPieceToRune(&r, &t, status) < 0)
        return NULL;
      if (!ps.PushLiteral(r))
        return NULL;
    }
    return ps.DoFinish();
  }

  StringPiece lastunary = NULL;
  while (t.size() > 0) {
    StringPiece isunary = NULL;
    switch (t[0]) {
      default: {
        Rune r;
        if (StringPieceToRune(&r, &t, status) < 0)
          return NULL;
        if (!ps.PushLiteral(r))
          return NULL;
        break;
      }

      case '(':
        // "(?" introduces Perl escape.
        if ((ps.flags() & PerlX) && (t.size() >= 2 && t[1] == '?')) {
          // Flag changes and non-capturing groups.
          if (!ps.ParsePerlFlags(&t))
            return NULL;
          break;
        }
        if (ps.flags() & NeverCapture) {
          if (!ps.DoLeftParenNoCapture())
            return NULL;
        } else {
          if (!ps.DoLeftParen(NULL))
            return NULL;
        }
        t.remove_prefix(1);  // '('
        break;

      case '|':
        if (!ps.DoVerticalBar())
          return NULL;
        t.remove_prefix(1);  // '|'
        break;

      case ')':
        if (!ps.DoRightParen())
          return NULL;
        t.remove_prefix(1);  // ')'
        break;

      case '^':  // Beginning of line.
        if (!ps.PushCarat())
          return NULL;
        t.remove_prefix(1);  // '^'
        break;

      case '$':  // End of line.
        if (!ps.PushDollar())
          return NULL;
        t.remove_prefix(1);  // '$'
        break;

      case '.':  // Any character (possibly except newline).
        if (!ps.PushDot())
          return NULL;
        t.remove_prefix(1);  // '.'
        break;

      case '[': {  // Character class.
        Regexp* re;
        if (!ps.ParseCharClass(&t, &re, status))
          return NULL;
        if (!ps.PushRegexp(re))
          return NULL;
        break;
      }

      case '*': {  // Zero or more.
        RegexpOp op;
        op = kRegexpStar;
        goto Rep;
      case '+':  // One or more.
        op = kRegexpPlus;
        goto Rep;
      case '?':  // Zero or one.
        op = kRegexpQuest;
        goto Rep;
      Rep:
        StringPiece opstr = t;
        bool nongreedy = false;
        t.remove_prefix(1);  // '*' or '+' or '?'
        if (ps.flags() & PerlX) {
          if (t.size() > 0 && t[0] == '?') {
            nongreedy = true;
            t.remove_prefix(1);  // '?'
          }
          if (lastunary.size() > 0) {
            // In Perl it is not allowed to stack repetition operators:
            //   a** is a syntax error, not a double-star.
            // (and a++ means something else entirely, which we don't support!)
            status->set_code(kRegexpRepeatOp);
            status->set_error_arg(StringPiece(lastunary.begin(),
                                              t.begin() - lastunary.begin()));
            return NULL;
          }
        }
        opstr.set(opstr.data(), t.data() - opstr.data());
        if (!ps.PushRepeatOp(op, opstr, nongreedy))
          return NULL;
        isunary = opstr;
        break;
      }

      case '{': {  // Counted repetition.
        int lo, hi;
        StringPiece opstr = t;
        if (!MaybeParseRepetition(&t, &lo, &hi)) {
          // Treat like a literal.
          if (!ps.PushLiteral('{'))
            return NULL;
          t.remove_prefix(1);  // '{'
          break;
        }
        bool nongreedy = false;
        if (ps.flags() & PerlX) {
          if (t.size() > 0 && t[0] == '?') {
            nongreedy = true;
            t.remove_prefix(1);  // '?'
          }
          if (lastunary.size() > 0) {
            // Not allowed to stack repetition operators.
            status->set_code(kRegexpRepeatOp);
            status->set_error_arg(StringPiece(lastunary.begin(),
                                              t.begin() - lastunary.begin()));
            return NULL;
          }
        }
        opstr.set(opstr.data(), t.data() - opstr.data());
        if (!ps.PushRepetition(lo, hi, opstr, nongreedy))
          return NULL;
        isunary = opstr;
        break;
      }

      case '\\': {  // Escaped character or Perl sequence.
        // \b and \B: word boundary or not
        if ((ps.flags() & Regexp::PerlB) &&
            t.size() >= 2 && (t[1] == 'b' || t[1] == 'B')) {
          if (!ps.PushWordBoundary(t[1] == 'b'))
            return NULL;
          t.remove_prefix(2);  // '\\', 'b'
          break;
        }

        if ((ps.flags() & Regexp::PerlX) && t.size() >= 2) {
          if (t[1] == 'A') {
            if (!ps.PushSimpleOp(kRegexpBeginText))
              return NULL;
            t.remove_prefix(2);  // '\\', 'A'
            break;
          }
          if (t[1] == 'z') {
            if (!ps.PushSimpleOp(kRegexpEndText))
              return NULL;
            t.remove_prefix(2);  // '\\', 'z'
            break;
          }
          // Do not recognize \Z, because this library can't
          // implement the exact Perl/PCRE semantics.
          // (This library treats "(?-m)$" as \z, even though
          // in Perl and PCRE it is equivalent to \Z.)

          if (t[1] == 'C') {  // \C: any byte [sic]
            if (!ps.PushSimpleOp(kRegexpAnyByte))
              return NULL;
            t.remove_prefix(2);  // '\\', 'C'
            break;
          }

          if (t[1] == 'Q') {  // \Q ... \E: the ... is always literals
            t.remove_prefix(2);  // '\\', 'Q'
            while (t.size() > 0) {
              if (t.size() >= 2 && t[0] == '\\' && t[1] == 'E') {
                t.remove_prefix(2);  // '\\', 'E'
                break;
              }
              Rune r;
              if (StringPieceToRune(&r, &t, status) < 0)
                return NULL;
              if (!ps.PushLiteral(r))
                return NULL;
            }
            break;
          }
        }

        if (t.size() >= 2 && (t[1] == 'p' || t[1] == 'P')) {
          Regexp* re = new Regexp(kRegexpCharClass, ps.flags() & ~FoldCase);
          re->ccb_ = new CharClassBuilder;
          switch (ParseUnicodeGroup(&t, ps.flags(), re->ccb_, status)) {
            case kParseOk:
              if (!ps.PushRegexp(re))
                return NULL;
              goto Break2;
            case kParseError:
              re->Decref();
              return NULL;
            case kParseNothing:
              re->Decref();
              break;
          }
        }

        UGroup *g = MaybeParsePerlCCEscape(&t, ps.flags());
        if (g != NULL) {
          Regexp* re = new Regexp(kRegexpCharClass, ps.flags() & ~FoldCase);
          re->ccb_ = new CharClassBuilder;
          AddUGroup(re->ccb_, g, g->sign, ps.flags());
          if (!ps.PushRegexp(re))
            return NULL;
          break;
        }

        Rune r;
        if (!ParseEscape(&t, &r, status, ps.rune_max()))
          return NULL;
        if (!ps.PushLiteral(r))
          return NULL;
        break;
      }
    }
  Break2:
    lastunary = isunary;
  }
  return ps.DoFinish();
}

}  // namespace re2
