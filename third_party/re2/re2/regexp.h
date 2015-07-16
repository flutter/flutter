// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// --- SPONSORED LINK --------------------------------------------------
// If you want to use this library for regular expression matching,
// you should use re2/re2.h, which provides a class RE2 that
// mimics the PCRE interface provided by PCRE's C++ wrappers.
// This header describes the low-level interface used to implement RE2
// and may change in backwards-incompatible ways from time to time.
// In contrast, RE2's interface will not.
// ---------------------------------------------------------------------

// Regular expression library: parsing, execution, and manipulation
// of regular expressions.
//
// Any operation that traverses the Regexp structures should be written
// using Regexp::Walker (see walker-inl.h), not recursively, because deeply nested
// regular expressions such as x++++++++++++++++++++... might cause recursive
// traversals to overflow the stack.
//
// It is the caller's responsibility to provide appropriate mutual exclusion
// around manipulation of the regexps.  RE2 does this.
//
// PARSING
//
// Regexp::Parse parses regular expressions encoded in UTF-8.
// The default syntax is POSIX extended regular expressions,
// with the following changes:
//
//   1.  Backreferences (optional in POSIX EREs) are not supported.
//         (Supporting them precludes the use of DFA-based
//          matching engines.)
//
//   2.  Collating elements and collation classes are not supported.
//         (No one has needed or wanted them.)
//
// The exact syntax accepted can be modified by passing flags to
// Regexp::Parse.  In particular, many of the basic Perl additions
// are available.  The flags are documented below (search for LikePerl).
//
// If parsed with the flag Regexp::Latin1, both the regular expression
// and the input to the matching routines are assumed to be encoded in
// Latin-1, not UTF-8.
//
// EXECUTION
//
// Once Regexp has parsed a regular expression, it provides methods
// to search text using that regular expression.  These methods are
// implemented via calling out to other regular expression libraries.
// (Let's call them the sublibraries.)
//
// To call a sublibrary, Regexp does not simply prepare a
// string version of the regular expression and hand it to the
// sublibrary.  Instead, Regexp prepares, from its own parsed form, the
// corresponding internal representation used by the sublibrary.
// This has the drawback of needing to know the internal representation
// used by the sublibrary, but it has two important benefits:
//
//   1. The syntax and meaning of regular expressions is guaranteed
//      to be that used by Regexp's parser, not the syntax expected
//      by the sublibrary.  Regexp might accept a restricted or
//      expanded syntax for regular expressions as compared with
//      the sublibrary.  As long as Regexp can translate from its
//      internal form into the sublibrary's, clients need not know
//      exactly which sublibrary they are using.
//
//   2. The sublibrary parsers are bypassed.  For whatever reason,
//      sublibrary regular expression parsers often have security
//      problems.  For example, plan9grep's regular expression parser
//      has a buffer overflow in its handling of large character
//      classes, and PCRE's parser has had buffer overflow problems
//      in the past.  Security-team requires sandboxing of sublibrary
//      regular expression parsers.  Avoiding the sublibrary parsers
//      avoids the sandbox.
//
// The execution methods we use now are provided by the compiled form,
// Prog, described in prog.h
//
// MANIPULATION
//
// Unlike other regular expression libraries, Regexp makes its parsed
// form accessible to clients, so that client code can analyze the
// parsed regular expressions.

#ifndef RE2_REGEXP_H__
#define RE2_REGEXP_H__

#include "util/util.h"
#include "re2/stringpiece.h"

namespace re2 {

// Keep in sync with string list kOpcodeNames[] in testing/dump.cc
enum RegexpOp {
  // Matches no strings.
  kRegexpNoMatch = 1,

  // Matches empty string.
  kRegexpEmptyMatch,

  // Matches rune_.
  kRegexpLiteral,

  // Matches runes_.
  kRegexpLiteralString,

  // Matches concatenation of sub_[0..nsub-1].
  kRegexpConcat,
  // Matches union of sub_[0..nsub-1].
  kRegexpAlternate,

  // Matches sub_[0] zero or more times.
  kRegexpStar,
  // Matches sub_[0] one or more times.
  kRegexpPlus,
  // Matches sub_[0] zero or one times.
  kRegexpQuest,

  // Matches sub_[0] at least min_ times, at most max_ times.
  // max_ == -1 means no upper limit.
  kRegexpRepeat,

  // Parenthesized (capturing) subexpression.  Index is cap_.
  // Optionally, capturing name is name_.
  kRegexpCapture,

  // Matches any character.
  kRegexpAnyChar,

  // Matches any byte [sic].
  kRegexpAnyByte,

  // Matches empty string at beginning of line.
  kRegexpBeginLine,
  // Matches empty string at end of line.
  kRegexpEndLine,

  // Matches word boundary "\b".
  kRegexpWordBoundary,
  // Matches not-a-word boundary "\B".
  kRegexpNoWordBoundary,

  // Matches empty string at beginning of text.
  kRegexpBeginText,
  // Matches empty string at end of text.
  kRegexpEndText,

  // Matches character class given by cc_.
  kRegexpCharClass,

  // Forces match of entire expression right now,
  // with match ID match_id_ (used by RE2::Set).
  kRegexpHaveMatch,

  kMaxRegexpOp = kRegexpHaveMatch,
};

// Keep in sync with string list in regexp.cc
enum RegexpStatusCode {
  // No error
  kRegexpSuccess = 0,

  // Unexpected error
  kRegexpInternalError,

  // Parse errors
  kRegexpBadEscape,          // bad escape sequence
  kRegexpBadCharClass,       // bad character class
  kRegexpBadCharRange,       // bad character class range
  kRegexpMissingBracket,     // missing closing ]
  kRegexpMissingParen,       // missing closing )
  kRegexpTrailingBackslash,  // at end of regexp
  kRegexpRepeatArgument,     // repeat argument missing, e.g. "*"
  kRegexpRepeatSize,         // bad repetition argument
  kRegexpRepeatOp,           // bad repetition operator
  kRegexpBadPerlOp,          // bad perl operator
  kRegexpBadUTF8,            // invalid UTF-8 in regexp
  kRegexpBadNamedCapture,    // bad named capture
};

// Error status for certain operations.
class RegexpStatus {
 public:
  RegexpStatus() : code_(kRegexpSuccess), tmp_(NULL) {}
  ~RegexpStatus() { delete tmp_; }

  void set_code(enum RegexpStatusCode code) { code_ = code; }
  void set_error_arg(const StringPiece& error_arg) { error_arg_ = error_arg; }
  void set_tmp(string* tmp) { delete tmp_; tmp_ = tmp; }
  enum RegexpStatusCode code() const { return code_; }
  const StringPiece& error_arg() const { return error_arg_; }
  bool ok() const { return code() == kRegexpSuccess; }

  // Copies state from status.
  void Copy(const RegexpStatus& status);

  // Returns text equivalent of code, e.g.:
  //   "Bad character class"
  static string CodeText(enum RegexpStatusCode code);

  // Returns text describing error, e.g.:
  //   "Bad character class: [z-a]"
  string Text() const;

 private:
  enum RegexpStatusCode code_;  // Kind of error
  StringPiece error_arg_;       // Piece of regexp containing syntax error.
  string* tmp_;                 // Temporary storage, possibly where error_arg_ is.

  DISALLOW_EVIL_CONSTRUCTORS(RegexpStatus);
};

// Walker to implement Simplify.
class SimplifyWalker;

// Compiled form; see prog.h
class Prog;

struct RuneRange {
  RuneRange() : lo(0), hi(0) { }
  RuneRange(int l, int h) : lo(l), hi(h) { }
  Rune lo;
  Rune hi;
};

// Less-than on RuneRanges treats a == b if they overlap at all.
// This lets us look in a set to find the range covering a particular Rune.
struct RuneRangeLess {
  bool operator()(const RuneRange& a, const RuneRange& b) const {
    return a.hi < b.lo;
  }
};

class CharClassBuilder;

class CharClass {
 public:
  void Delete();

  typedef RuneRange* iterator;
  iterator begin() { return ranges_; }
  iterator end() { return ranges_ + nranges_; }

  int size() { return nrunes_; }
  bool empty() { return nrunes_ == 0; }
  bool full() { return nrunes_ == Runemax+1; }
  bool FoldsASCII() { return folds_ascii_; }

  bool Contains(Rune r);
  CharClass* Negate();

 private:
  CharClass();  // not implemented
  ~CharClass();  // not implemented
  static CharClass* New(int maxranges);

  friend class CharClassBuilder;

  bool folds_ascii_;
  int nrunes_;
  RuneRange *ranges_;
  int nranges_;
  DISALLOW_EVIL_CONSTRUCTORS(CharClass);
};

class Regexp {
 public:

  // Flags for parsing.  Can be ORed together.
  enum ParseFlags {
    NoParseFlags = 0,
    FoldCase     = 1<<0,   // Fold case during matching (case-insensitive).
    Literal      = 1<<1,   // Treat s as literal string instead of a regexp.
    ClassNL      = 1<<2,   // Allow char classes like [^a-z] and \D and \s
                           // and [[:space:]] to match newline.
    DotNL        = 1<<3,   // Allow . to match newline.
    MatchNL      = ClassNL | DotNL,
    OneLine      = 1<<4,   // Treat ^ and $ as only matching at beginning and
                           // end of text, not around embedded newlines.
                           // (Perl's default)
    Latin1       = 1<<5,   // Regexp and text are in Latin1, not UTF-8.
    NonGreedy    = 1<<6,   // Repetition operators are non-greedy by default.
    PerlClasses  = 1<<7,   // Allow Perl character classes like \d.
    PerlB        = 1<<8,   // Allow Perl's \b and \B.
    PerlX        = 1<<9,   // Perl extensions:
                           //   non-capturing parens - (?: )
                           //   non-greedy operators - *? +? ?? {}?
                           //   flag edits - (?i) (?-i) (?i: )
                           //     i - FoldCase
                           //     m - !OneLine
                           //     s - DotNL
                           //     U - NonGreedy
                           //   line ends: \A \z
                           //   \Q and \E to disable/enable metacharacters
                           //   (?P<name>expr) for named captures
                           //   \C to match any single byte
    UnicodeGroups = 1<<10, // Allow \p{Han} for Unicode Han group
                           //   and \P{Han} for its negation.
    NeverNL      = 1<<11,  // Never match NL, even if the regexp mentions
                           //   it explicitly.
    NeverCapture = 1<<12,  // Parse all parens as non-capturing.

    // As close to Perl as we can get.
    LikePerl     = ClassNL | OneLine | PerlClasses | PerlB | PerlX |
                   UnicodeGroups,

    // Internal use only.
    WasDollar    = 1<<15,  // on kRegexpEndText: was $ in regexp text
  };

  // Get.  No set, Regexps are logically immutable once created.
  RegexpOp op() { return static_cast<RegexpOp>(op_); }
  int nsub() { return nsub_; }
  bool simple() { return simple_; }
  enum ParseFlags parse_flags() { return static_cast<ParseFlags>(parse_flags_); }
  int Ref();  // For testing.

  Regexp** sub() {
    if(nsub_ <= 1)
      return &subone_;
    else
      return submany_;
  }

  int min() { DCHECK_EQ(op_, kRegexpRepeat); return min_; }
  int max() { DCHECK_EQ(op_, kRegexpRepeat); return max_; }
  Rune rune() { DCHECK_EQ(op_, kRegexpLiteral); return rune_; }
  CharClass* cc() { DCHECK_EQ(op_, kRegexpCharClass); return cc_; }
  int cap() { DCHECK_EQ(op_, kRegexpCapture); return cap_; }
  const string* name() { DCHECK_EQ(op_, kRegexpCapture); return name_; }
  Rune* runes() { DCHECK_EQ(op_, kRegexpLiteralString); return runes_; }
  int nrunes() { DCHECK_EQ(op_, kRegexpLiteralString); return nrunes_; }
  int match_id() { DCHECK_EQ(op_, kRegexpHaveMatch); return match_id_; }

  // Increments reference count, returns object as convenience.
  Regexp* Incref();

  // Decrements reference count and deletes this object if count reaches 0.
  void Decref();

  // Parses string s to produce regular expression, returned.
  // Caller must release return value with re->Decref().
  // On failure, sets *status (if status != NULL) and returns NULL.
  static Regexp* Parse(const StringPiece& s, ParseFlags flags,
                       RegexpStatus* status);

  // Returns a _new_ simplified version of the current regexp.
  // Does not edit the current regexp.
  // Caller must release return value with re->Decref().
  // Simplified means that counted repetition has been rewritten
  // into simpler terms and all Perl/POSIX features have been
  // removed.  The result will capture exactly the same
  // subexpressions the original did, unless formatted with ToString.
  Regexp* Simplify();
  friend class SimplifyWalker;

  // Parses the regexp src and then simplifies it and sets *dst to the
  // string representation of the simplified form.  Returns true on success.
  // Returns false and sets *status (if status != NULL) on parse error.
  static bool SimplifyRegexp(const StringPiece& src, ParseFlags flags,
                             string* dst,
                             RegexpStatus* status);

  // Returns the number of capturing groups in the regexp.
  int NumCaptures();
  friend class NumCapturesWalker;

  // Returns a map from names to capturing group indices,
  // or NULL if the regexp contains no named capture groups.
  // The caller is responsible for deleting the map.
  map<string, int>* NamedCaptures();

  // Returns a map from capturing group indices to capturing group
  // names or NULL if the regexp contains no named capture groups. The
  // caller is responsible for deleting the map.
  map<int, string>* CaptureNames();

  // Returns a string representation of the current regexp,
  // using as few parentheses as possible.
  string ToString();

  // Convenience functions.  They consume the passed reference,
  // so in many cases you should use, e.g., Plus(re->Incref(), flags).
  // They do not consume allocated arrays like subs or runes.
  static Regexp* Plus(Regexp* sub, ParseFlags flags);
  static Regexp* Star(Regexp* sub, ParseFlags flags);
  static Regexp* Quest(Regexp* sub, ParseFlags flags);
  static Regexp* Concat(Regexp** subs, int nsubs, ParseFlags flags);
  static Regexp* Alternate(Regexp** subs, int nsubs, ParseFlags flags);
  static Regexp* Capture(Regexp* sub, ParseFlags flags, int cap);
  static Regexp* Repeat(Regexp* sub, ParseFlags flags, int min, int max);
  static Regexp* NewLiteral(Rune rune, ParseFlags flags);
  static Regexp* NewCharClass(CharClass* cc, ParseFlags flags);
  static Regexp* LiteralString(Rune* runes, int nrunes, ParseFlags flags);
  static Regexp* HaveMatch(int match_id, ParseFlags flags);

  // Like Alternate but does not factor out common prefixes.
  static Regexp* AlternateNoFactor(Regexp** subs, int nsubs, ParseFlags flags);

  // Debugging function.  Returns string format for regexp
  // that makes structure clear.  Does NOT use regexp syntax.
  string Dump();

  // Helper traversal class, defined fully in walker-inl.h.
  template<typename T> class Walker;

  // Compile to Prog.  See prog.h
  // Reverse prog expects to be run over text backward.
  // Construction and execution of prog will
  // stay within approximately max_mem bytes of memory.
  // If max_mem <= 0, a reasonable default is used.
  Prog* CompileToProg(int64 max_mem);
  Prog* CompileToReverseProg(int64 max_mem);

  // Whether to expect this library to find exactly the same answer as PCRE
  // when running this regexp.  Most regexps do mimic PCRE exactly, but a few
  // obscure cases behave differently.  Technically this is more a property
  // of the Prog than the Regexp, but the computation is much easier to do
  // on the Regexp.  See mimics_pcre.cc for the exact conditions.
  bool MimicsPCRE();

  // Benchmarking function.
  void NullWalk();

  // Whether every match of this regexp must be anchored and
  // begin with a non-empty fixed string (perhaps after ASCII
  // case-folding).  If so, returns the prefix and the sub-regexp that
  // follows it.
  bool RequiredPrefix(string* prefix, bool *foldcase, Regexp** suffix);

 private:
  // Constructor allocates vectors as appropriate for operator.
  explicit Regexp(RegexpOp op, ParseFlags parse_flags);

  // Use Decref() instead of delete to release Regexps.
  // This is private to catch deletes at compile time.
  ~Regexp();
  void Destroy();
  bool QuickDestroy();

  // Helpers for Parse.  Listed here so they can edit Regexps.
  class ParseState;
  friend class ParseState;
  friend bool ParseCharClass(StringPiece* s, Regexp** out_re,
                             RegexpStatus* status);

  // Helper for testing [sic].
  friend bool RegexpEqualTestingOnly(Regexp*, Regexp*);

  // Computes whether Regexp is already simple.
  bool ComputeSimple();

  // Constructor that generates a concatenation or alternation,
  // enforcing the limit on the number of subexpressions for
  // a particular Regexp.
  static Regexp* ConcatOrAlternate(RegexpOp op, Regexp** subs, int nsubs,
                                   ParseFlags flags, bool can_factor);

  // Returns the leading string that re starts with.
  // The returned Rune* points into a piece of re,
  // so it must not be used after the caller calls re->Decref().
  static Rune* LeadingString(Regexp* re, int* nrune, ParseFlags* flags);

  // Removes the first n leading runes from the beginning of re.
  // Edits re in place.
  static void RemoveLeadingString(Regexp* re, int n);

  // Returns the leading regexp in re's top-level concatenation.
  // The returned Regexp* points at re or a sub-expression of re,
  // so it must not be used after the caller calls re->Decref().
  static Regexp* LeadingRegexp(Regexp* re);

  // Removes LeadingRegexp(re) from re and returns the remainder.
  // Might edit re in place.
  static Regexp* RemoveLeadingRegexp(Regexp* re);

  // Simplifies an alternation of literal strings by factoring out
  // common prefixes.
  static int FactorAlternation(Regexp** sub, int nsub, ParseFlags flags);
  static int FactorAlternationRecursive(Regexp** sub, int nsub,
                                        ParseFlags flags, int maxdepth);

  // Is a == b?  Only efficient on regexps that have not been through
  // Simplify yet - the expansion of a kRegexpRepeat will make this
  // take a long time.  Do not call on such regexps, hence private.
  static bool Equal(Regexp* a, Regexp* b);

  // Allocate space for n sub-regexps.
  void AllocSub(int n) {
    if (n < 0 || static_cast<uint16>(n) != n)
      LOG(FATAL) << "Cannot AllocSub " << n;
    if (n > 1)
      submany_ = new Regexp*[n];
    nsub_ = n;
  }

  // Add Rune to LiteralString
  void AddRuneToString(Rune r);

  // Swaps this with that, in place.
  void Swap(Regexp *that);

  // Operator.  See description of operators above.
  // uint8 instead of RegexpOp to control space usage.
  uint8 op_;

  // Is this regexp structure already simple
  // (has it been returned by Simplify)?
  // uint8 instead of bool to control space usage.
  uint8 simple_;

  // Flags saved from parsing and used during execution.
  // (Only FoldCase is used.)
  // uint16 instead of ParseFlags to control space usage.
  uint16 parse_flags_;

  // Reference count.  Exists so that SimplifyRegexp can build
  // regexp structures that are dags rather than trees to avoid
  // exponential blowup in space requirements.
  // uint16 to control space usage.
  // The standard regexp routines will never generate a
  // ref greater than the maximum repeat count (100),
  // but even so, Incref and Decref consult an overflow map
  // when ref_ reaches kMaxRef.
  uint16 ref_;
  static const uint16 kMaxRef = 0xffff;

  // Subexpressions.
  // uint16 to control space usage.
  // Concat and Alternate handle larger numbers of subexpressions
  // by building concatenation or alternation trees.
  // Other routines should call Concat or Alternate instead of
  // filling in sub() by hand.
  uint16 nsub_;
  static const uint16 kMaxNsub = 0xffff;
  union {
    Regexp** submany_;  // if nsub_ > 1
    Regexp* subone_;  // if nsub_ == 1
  };

  // Extra space for parse and teardown stacks.
  Regexp* down_;

  // Arguments to operator.  See description of operators above.
  union {
    struct {  // Repeat
      int max_;
      int min_;
    };
    struct {  // Capture
      int cap_;
      string* name_;
    };
    struct {  // LiteralString
      int nrunes_;
      Rune* runes_;
    };
    struct {  // CharClass
      // These two could be in separate union members,
      // but it wouldn't save any space (there are other two-word structs)
      // and keeping them separate avoids confusion during parsing.
      CharClass* cc_;
      CharClassBuilder* ccb_;
    };
    Rune rune_;  // Literal
    int match_id_;  // HaveMatch
    void *the_union_[2];  // as big as any other element, for memset
  };

  DISALLOW_EVIL_CONSTRUCTORS(Regexp);
};

// Character class set: contains non-overlapping, non-abutting RuneRanges.
typedef set<RuneRange, RuneRangeLess> RuneRangeSet;

class CharClassBuilder {
 public:
  CharClassBuilder();

  typedef RuneRangeSet::iterator iterator;
  iterator begin() { return ranges_.begin(); }
  iterator end() { return ranges_.end(); }

  int size() { return nrunes_; }
  bool empty() { return nrunes_ == 0; }
  bool full() { return nrunes_ == Runemax+1; }

  bool Contains(Rune r);
  bool FoldsASCII();
  bool AddRange(Rune lo, Rune hi);  // returns whether class changed
  CharClassBuilder* Copy();
  void AddCharClass(CharClassBuilder* cc);
  void Negate();
  void RemoveAbove(Rune r);
  CharClass* GetCharClass();
  void AddRangeFlags(Rune lo, Rune hi, Regexp::ParseFlags parse_flags);

 private:
  static const uint32 AlphaMask = (1<<26) - 1;
  uint32 upper_;  // bitmap of A-Z
  uint32 lower_;  // bitmap of a-z
  int nrunes_;
  RuneRangeSet ranges_;
  DISALLOW_EVIL_CONSTRUCTORS(CharClassBuilder);
};

// Tell g++ that bitwise ops on ParseFlags produce ParseFlags.
inline Regexp::ParseFlags operator|(Regexp::ParseFlags a, Regexp::ParseFlags b)
{
  return static_cast<Regexp::ParseFlags>(static_cast<int>(a) | static_cast<int>(b));
}

inline Regexp::ParseFlags operator^(Regexp::ParseFlags a, Regexp::ParseFlags b)
{
  return static_cast<Regexp::ParseFlags>(static_cast<int>(a) ^ static_cast<int>(b));
}

inline Regexp::ParseFlags operator&(Regexp::ParseFlags a, Regexp::ParseFlags b)
{
  return static_cast<Regexp::ParseFlags>(static_cast<int>(a) & static_cast<int>(b));
}

inline Regexp::ParseFlags operator~(Regexp::ParseFlags a)
{
  return static_cast<Regexp::ParseFlags>(~static_cast<int>(a));
}



}  // namespace re2

#endif  // RE2_REGEXP_H__
