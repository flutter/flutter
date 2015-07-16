// Copyright 2003-2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef RE2_RE2_H
#define RE2_RE2_H

// C++ interface to the re2 regular-expression library.
// RE2 supports Perl-style regular expressions (with extensions like
// \d, \w, \s, ...).
//
// -----------------------------------------------------------------------
// REGEXP SYNTAX:
//
// This module uses the re2 library and hence supports
// its syntax for regular expressions, which is similar to Perl's with
// some of the more complicated things thrown away.  In particular,
// backreferences and generalized assertions are not available, nor is \Z.
//
// See http://code.google.com/p/re2/wiki/Syntax for the syntax
// supported by RE2, and a comparison with PCRE and PERL regexps.
//
// For those not familiar with Perl's regular expressions,
// here are some examples of the most commonly used extensions:
//
//   "hello (\\w+) world"  -- \w matches a "word" character
//   "version (\\d+)"      -- \d matches a digit
//   "hello\\s+world"      -- \s matches any whitespace character
//   "\\b(\\w+)\\b"        -- \b matches non-empty string at word boundary
//   "(?i)hello"           -- (?i) turns on case-insensitive matching
//   "/\\*(.*?)\\*/"       -- .*? matches . minimum no. of times possible
//
// -----------------------------------------------------------------------
// MATCHING INTERFACE:
//
// The "FullMatch" operation checks that supplied text matches a
// supplied pattern exactly.
//
// Example: successful match
//    CHECK(RE2::FullMatch("hello", "h.*o"));
//
// Example: unsuccessful match (requires full match):
//    CHECK(!RE2::FullMatch("hello", "e"));
//
// -----------------------------------------------------------------------
// UTF-8 AND THE MATCHING INTERFACE:
//
// By default, the pattern and input text are interpreted as UTF-8.
// The RE2::Latin1 option causes them to be interpreted as Latin-1.
//
// Example:
//    CHECK(RE2::FullMatch(utf8_string, RE2(utf8_pattern)));
//    CHECK(RE2::FullMatch(latin1_string, RE2(latin1_pattern, RE2::Latin1)));
//
// -----------------------------------------------------------------------
// MATCHING WITH SUB-STRING EXTRACTION:
//
// You can supply extra pointer arguments to extract matched subpieces.
//
// Example: extracts "ruby" into "s" and 1234 into "i"
//    int i;
//    string s;
//    CHECK(RE2::FullMatch("ruby:1234", "(\\w+):(\\d+)", &s, &i));
//
// Example: fails because string cannot be stored in integer
//    CHECK(!RE2::FullMatch("ruby", "(.*)", &i));
//
// Example: fails because there aren't enough sub-patterns:
//    CHECK(!RE2::FullMatch("ruby:1234", "\\w+:\\d+", &s));
//
// Example: does not try to extract any extra sub-patterns
//    CHECK(RE2::FullMatch("ruby:1234", "(\\w+):(\\d+)", &s));
//
// Example: does not try to extract into NULL
//    CHECK(RE2::FullMatch("ruby:1234", "(\\w+):(\\d+)", NULL, &i));
//
// Example: integer overflow causes failure
//    CHECK(!RE2::FullMatch("ruby:1234567891234", "\\w+:(\\d+)", &i));
//
// NOTE(rsc): Asking for substrings slows successful matches quite a bit.
// This may get a little faster in the future, but right now is slower
// than PCRE.  On the other hand, failed matches run *very* fast (faster
// than PCRE), as do matches without substring extraction.
//
// -----------------------------------------------------------------------
// PARTIAL MATCHES
//
// You can use the "PartialMatch" operation when you want the pattern
// to match any substring of the text.
//
// Example: simple search for a string:
//      CHECK(RE2::PartialMatch("hello", "ell"));
//
// Example: find first number in a string
//      int number;
//      CHECK(RE2::PartialMatch("x*100 + 20", "(\\d+)", &number));
//      CHECK_EQ(number, 100);
//
// -----------------------------------------------------------------------
// PRE-COMPILED REGULAR EXPRESSIONS
//
// RE2 makes it easy to use any string as a regular expression, without
// requiring a separate compilation step.
//
// If speed is of the essence, you can create a pre-compiled "RE2"
// object from the pattern and use it multiple times.  If you do so,
// you can typically parse text faster than with sscanf.
//
// Example: precompile pattern for faster matching:
//    RE2 pattern("h.*o");
//    while (ReadLine(&str)) {
//      if (RE2::FullMatch(str, pattern)) ...;
//    }
//
// -----------------------------------------------------------------------
// SCANNING TEXT INCREMENTALLY
//
// The "Consume" operation may be useful if you want to repeatedly
// match regular expressions at the front of a string and skip over
// them as they match.  This requires use of the "StringPiece" type,
// which represents a sub-range of a real string.
//
// Example: read lines of the form "var = value" from a string.
//      string contents = ...;          // Fill string somehow
//      StringPiece input(contents);    // Wrap a StringPiece around it
//
//      string var;
//      int value;
//      while (RE2::Consume(&input, "(\\w+) = (\\d+)\n", &var, &value)) {
//        ...;
//      }
//
// Each successful call to "Consume" will set "var/value", and also
// advance "input" so it points past the matched text.  Note that if the
// regular expression matches an empty string, input will advance
// by 0 bytes.  If the regular expression being used might match
// an empty string, the loop body must check for this case and either
// advance the string or break out of the loop.
//
// The "FindAndConsume" operation is similar to "Consume" but does not
// anchor your match at the beginning of the string.  For example, you
// could extract all words from a string by repeatedly calling
//     RE2::FindAndConsume(&input, "(\\w+)", &word)
//
// -----------------------------------------------------------------------
// USING VARIABLE NUMBER OF ARGUMENTS
//
// The above operations require you to know the number of arguments
// when you write the code.  This is not always possible or easy (for
// example, the regular expression may be calculated at run time).
// You can use the "N" version of the operations when the number of
// match arguments are determined at run time.
//
// Example:
//   const RE2::Arg* args[10];
//   int n;
//   // ... populate args with pointers to RE2::Arg values ...
//   // ... set n to the number of RE2::Arg objects ...
//   bool match = RE2::FullMatchN(input, pattern, args, n);
//
// The last statement is equivalent to
//
//   bool match = RE2::FullMatch(input, pattern,
//                               *args[0], *args[1], ..., *args[n - 1]);
//
// -----------------------------------------------------------------------
// PARSING HEX/OCTAL/C-RADIX NUMBERS
//
// By default, if you pass a pointer to a numeric value, the
// corresponding text is interpreted as a base-10 number.  You can
// instead wrap the pointer with a call to one of the operators Hex(),
// Octal(), or CRadix() to interpret the text in another base.  The
// CRadix operator interprets C-style "0" (base-8) and "0x" (base-16)
// prefixes, but defaults to base-10.
//
// Example:
//   int a, b, c, d;
//   CHECK(RE2::FullMatch("100 40 0100 0x40", "(.*) (.*) (.*) (.*)",
//         RE2::Octal(&a), RE2::Hex(&b), RE2::CRadix(&c), RE2::CRadix(&d));
// will leave 64 in a, b, c, and d.


#include <stdint.h>
#include <map>
#include <string>
#include "re2/stringpiece.h"
#include "re2/variadic_function.h"

namespace re2 {

using std::string;
using std::map;
class Mutex;
class Prog;
class Regexp;

// The following enum should be used only as a constructor argument to indicate
// that the variable has static storage class, and that the constructor should
// do nothing to its state.  It indicates to the reader that it is legal to
// declare a static instance of the class, provided the constructor is given
// the LINKER_INITIALIZED argument.  Normally, it is unsafe to declare a
// static variable that has a constructor or a destructor because invocation
// order is undefined.  However, IF the type can be initialized by filling with
// zeroes (which the loader does for static variables), AND the type's
// destructor does nothing to the storage, then a constructor for static
// initialization can be declared as
//       explicit MyClass(LinkerInitialized x) {}
// and invoked as
//       static MyClass my_variable_name(LINKER_INITIALIZED);
enum LinkerInitialized { LINKER_INITIALIZED };

// Interface for regular expression matching.  Also corresponds to a
// pre-compiled regular expression.  An "RE2" object is safe for
// concurrent use by multiple threads.
class RE2 {
 public:
  // We convert user-passed pointers into special Arg objects
  class Arg;
  class Options;

  // Defined in set.h.
  class Set;

  enum ErrorCode {
    NoError = 0,

    // Unexpected error
    ErrorInternal,

    // Parse errors
    ErrorBadEscape,          // bad escape sequence
    ErrorBadCharClass,       // bad character class
    ErrorBadCharRange,       // bad character class range
    ErrorMissingBracket,     // missing closing ]
    ErrorMissingParen,       // missing closing )
    ErrorTrailingBackslash,  // trailing \ at end of regexp
    ErrorRepeatArgument,     // repeat argument missing, e.g. "*"
    ErrorRepeatSize,         // bad repetition argument
    ErrorRepeatOp,           // bad repetition operator
    ErrorBadPerlOp,          // bad perl operator
    ErrorBadUTF8,            // invalid UTF-8 in regexp
    ErrorBadNamedCapture,    // bad named capture group
    ErrorPatternTooLarge,    // pattern too large (compile failed)
  };

  // Predefined common options.
  // If you need more complicated things, instantiate
  // an Option class, possibly passing one of these to
  // the Option constructor, change the settings, and pass that
  // Option class to the RE2 constructor.
  enum CannedOptions {
    DefaultOptions = 0,
    Latin1, // treat input as Latin-1 (default UTF-8)
    POSIX_SYNTAX, // POSIX syntax, leftmost-longest match
    Quiet // do not log about regexp parse errors
  };

  // Need to have the const char* and const string& forms for implicit
  // conversions when passing string literals to FullMatch and PartialMatch.
  // Otherwise the StringPiece form would be sufficient.
#ifndef SWIG
  RE2(const char* pattern);
  RE2(const string& pattern);
#endif
  RE2(const StringPiece& pattern);
  RE2(const StringPiece& pattern, const Options& option);
  ~RE2();

  // Returns whether RE2 was created properly.
  bool ok() const { return error_code() == NoError; }

  // The string specification for this RE2.  E.g.
  //   RE2 re("ab*c?d+");
  //   re.pattern();    // "ab*c?d+"
  const string& pattern() const { return pattern_; }

  // If RE2 could not be created properly, returns an error string.
  // Else returns the empty string.
  const string& error() const { return *error_; }

  // If RE2 could not be created properly, returns an error code.
  // Else returns RE2::NoError (== 0).
  ErrorCode error_code() const { return error_code_; }

  // If RE2 could not be created properly, returns the offending
  // portion of the regexp.
  const string& error_arg() const { return error_arg_; }

  // Returns the program size, a very approximate measure of a regexp's "cost".
  // Larger numbers are more expensive than smaller numbers.
  int ProgramSize() const;

  // Returns the underlying Regexp; not for general use.
  // Returns entire_regexp_ so that callers don't need
  // to know about prefix_ and prefix_foldcase_.
  re2::Regexp* Regexp() const { return entire_regexp_; }

  /***** The useful part: the matching interface *****/

  // Matches "text" against "pattern".  If pointer arguments are
  // supplied, copies matched sub-patterns into them.
  //
  // You can pass in a "const char*" or a "string" for "text".
  // You can pass in a "const char*" or a "string" or a "RE2" for "pattern".
  //
  // The provided pointer arguments can be pointers to any scalar numeric
  // type, or one of:
  //    string          (matched piece is copied to string)
  //    StringPiece     (StringPiece is mutated to point to matched piece)
  //    T               (where "bool T::ParseFrom(const char*, int)" exists)
  //    (void*)NULL     (the corresponding matched sub-pattern is not copied)
  //
  // Returns true iff all of the following conditions are satisfied:
  //   a. "text" matches "pattern" exactly
  //   b. The number of matched sub-patterns is >= number of supplied pointers
  //   c. The "i"th argument has a suitable type for holding the
  //      string captured as the "i"th sub-pattern.  If you pass in
  //      NULL for the "i"th argument, or pass fewer arguments than
  //      number of sub-patterns, "i"th captured sub-pattern is
  //      ignored.
  //
  // CAVEAT: An optional sub-pattern that does not exist in the
  // matched string is assigned the empty string.  Therefore, the
  // following will return false (because the empty string is not a
  // valid number):
  //    int number;
  //    RE2::FullMatch("abc", "[a-z]+(\\d+)?", &number);
  static bool FullMatchN(const StringPiece& text, const RE2& re,
                         const Arg* const args[], int argc);
  static const VariadicFunction2<
      bool, const StringPiece&, const RE2&, Arg, RE2::FullMatchN> FullMatch;

  // Exactly like FullMatch(), except that "pattern" is allowed to match
  // a substring of "text".
  static bool PartialMatchN(const StringPiece& text, const RE2& re, // 3..16 args
                            const Arg* const args[], int argc);
  static const VariadicFunction2<
      bool, const StringPiece&, const RE2&, Arg, RE2::PartialMatchN> PartialMatch;

  // Like FullMatch() and PartialMatch(), except that pattern has to
  // match a prefix of "text", and "input" is advanced past the matched
  // text.  Note: "input" is modified iff this routine returns true.
  static bool ConsumeN(StringPiece* input, const RE2& pattern, // 3..16 args
                       const Arg* const args[], int argc);
  static const VariadicFunction2<
      bool, StringPiece*, const RE2&, Arg, RE2::ConsumeN> Consume;

  // Like Consume(..), but does not anchor the match at the beginning of the
  // string.  That is, "pattern" need not start its match at the beginning of
  // "input".  For example, "FindAndConsume(s, "(\\w+)", &word)" finds the next
  // word in "s" and stores it in "word".
  static bool FindAndConsumeN(StringPiece* input, const RE2& pattern,
                             const Arg* const args[], int argc);
  static const VariadicFunction2<
      bool, StringPiece*, const RE2&, Arg, RE2::FindAndConsumeN> FindAndConsume;

  // Replace the first match of "pattern" in "str" with "rewrite".
  // Within "rewrite", backslash-escaped digits (\1 to \9) can be
  // used to insert text matching corresponding parenthesized group
  // from the pattern.  \0 in "rewrite" refers to the entire matching
  // text.  E.g.,
  //
  //   string s = "yabba dabba doo";
  //   CHECK(RE2::Replace(&s, "b+", "d"));
  //
  // will leave "s" containing "yada dabba doo"
  //
  // Returns true if the pattern matches and a replacement occurs,
  // false otherwise.
  static bool Replace(string *str,
                      const RE2& pattern,
                      const StringPiece& rewrite);

  // Like Replace(), except replaces successive non-overlapping occurrences
  // of the pattern in the string with the rewrite. E.g.
  //
  //   string s = "yabba dabba doo";
  //   CHECK(RE2::GlobalReplace(&s, "b+", "d"));
  //
  // will leave "s" containing "yada dada doo"
  // Replacements are not subject to re-matching.
  //
  // Because GlobalReplace only replaces non-overlapping matches,
  // replacing "ana" within "banana" makes only one replacement, not two.
  //
  // Returns the number of replacements made.
  static int GlobalReplace(string *str,
                           const RE2& pattern,
                           const StringPiece& rewrite);

  // Like Replace, except that if the pattern matches, "rewrite"
  // is copied into "out" with substitutions.  The non-matching
  // portions of "text" are ignored.
  //
  // Returns true iff a match occurred and the extraction happened
  // successfully;  if no match occurs, the string is left unaffected.
  static bool Extract(const StringPiece &text,
                      const RE2& pattern,
                      const StringPiece &rewrite,
                      string *out);

  // Escapes all potentially meaningful regexp characters in
  // 'unquoted'.  The returned string, used as a regular expression,
  // will exactly match the original string.  For example,
  //           1.5-2.0?
  // may become:
  //           1\.5\-2\.0\?
  static string QuoteMeta(const StringPiece& unquoted);

  // Computes range for any strings matching regexp. The min and max can in
  // some cases be arbitrarily precise, so the caller gets to specify the
  // maximum desired length of string returned.
  //
  // Assuming PossibleMatchRange(&min, &max, N) returns successfully, any
  // string s that is an anchored match for this regexp satisfies
  //   min <= s && s <= max.
  //
  // Note that PossibleMatchRange() will only consider the first copy of an
  // infinitely repeated element (i.e., any regexp element followed by a '*' or
  // '+' operator). Regexps with "{N}" constructions are not affected, as those
  // do not compile down to infinite repetitions.
  //
  // Returns true on success, false on error.
  bool PossibleMatchRange(string* min, string* max, int maxlen) const;

  // Generic matching interface

  // Type of match.
  enum Anchor {
    UNANCHORED,         // No anchoring
    ANCHOR_START,       // Anchor at start only
    ANCHOR_BOTH,        // Anchor at start and end
  };

  // Return the number of capturing subpatterns, or -1 if the
  // regexp wasn't valid on construction.  The overall match ($0)
  // does not count: if the regexp is "(a)(b)", returns 2.
  int NumberOfCapturingGroups() const;


  // Return a map from names to capturing indices.
  // The map records the index of the leftmost group
  // with the given name.
  // Only valid until the re is deleted.
  const map<string, int>& NamedCapturingGroups() const;

  // Return a map from capturing indices to names.
  // The map has no entries for unnamed groups.
  // Only valid until the re is deleted.
  const map<int, string>& CapturingGroupNames() const;

  // General matching routine.
  // Match against text starting at offset startpos
  // and stopping the search at offset endpos.
  // Returns true if match found, false if not.
  // On a successful match, fills in match[] (up to nmatch entries)
  // with information about submatches.
  // I.e. matching RE2("(foo)|(bar)baz") on "barbazbla" will return true,
  // setting match[0] = "barbaz", match[1] = NULL, match[2] = "bar",
  // match[3] = NULL, ..., up to match[nmatch-1] = NULL.
  //
  // Don't ask for more match information than you will use:
  // runs much faster with nmatch == 1 than nmatch > 1, and
  // runs even faster if nmatch == 0.
  // Doesn't make sense to use nmatch > 1 + NumberOfCapturingGroups(),
  // but will be handled correctly.
  //
  // Passing text == StringPiece(NULL, 0) will be handled like any other
  // empty string, but note that on return, it will not be possible to tell
  // whether submatch i matched the empty string or did not match:
  // either way, match[i] == NULL.
  bool Match(const StringPiece& text,
             int startpos,
             int endpos,
             Anchor anchor,
             StringPiece *match,
             int nmatch) const;

  // Check that the given rewrite string is suitable for use with this
  // regular expression.  It checks that:
  //   * The regular expression has enough parenthesized subexpressions
  //     to satisfy all of the \N tokens in rewrite
  //   * The rewrite string doesn't have any syntax errors.  E.g.,
  //     '\' followed by anything other than a digit or '\'.
  // A true return value guarantees that Replace() and Extract() won't
  // fail because of a bad rewrite string.
  bool CheckRewriteString(const StringPiece& rewrite, string* error) const;

  // Returns the maximum submatch needed for the rewrite to be done by
  // Replace(). E.g. if rewrite == "foo \\2,\\1", returns 2.
  static int MaxSubmatch(const StringPiece& rewrite);

  // Append the "rewrite" string, with backslash subsitutions from "vec",
  // to string "out".
  // Returns true on success.  This method can fail because of a malformed
  // rewrite string.  CheckRewriteString guarantees that the rewrite will
  // be sucessful.
  bool Rewrite(string *out,
               const StringPiece &rewrite,
               const StringPiece* vec,
               int veclen) const;

  // Constructor options
  class Options {
   public:
    // The options are (defaults in parentheses):
    //
    //   utf8             (true)  text and pattern are UTF-8; otherwise Latin-1
    //   posix_syntax     (false) restrict regexps to POSIX egrep syntax
    //   longest_match    (false) search for longest match, not first match
    //   log_errors       (true)  log syntax and execution errors to ERROR
    //   max_mem          (see below)  approx. max memory footprint of RE2
    //   literal          (false) interpret string as literal, not regexp
    //   never_nl         (false) never match \n, even if it is in regexp
    //   never_capture    (false) parse all parens as non-capturing
    //   case_sensitive   (true)  match is case-sensitive (regexp can override
    //                              with (?i) unless in posix_syntax mode)
    //
    // The following options are only consulted when posix_syntax == true.
    // (When posix_syntax == false these features are always enabled and
    // cannot be turned off.)
    //   perl_classes     (false) allow Perl's \d \s \w \D \S \W
    //   word_boundary    (false) allow Perl's \b \B (word boundary and not)
    //   one_line         (false) ^ and $ only match beginning and end of text
    //
    // The max_mem option controls how much memory can be used
    // to hold the compiled form of the regexp (the Prog) and
    // its cached DFA graphs.  Code Search placed limits on the number
    // of Prog instructions and DFA states: 10,000 for both.
    // In RE2, those limits would translate to about 240 KB per Prog
    // and perhaps 2.5 MB per DFA (DFA state sizes vary by regexp; RE2 does a
    // better job of keeping them small than Code Search did).
    // Each RE2 has two Progs (one forward, one reverse), and each Prog
    // can have two DFAs (one first match, one longest match).
    // That makes 4 DFAs:
    //
    //   forward, first-match    - used for UNANCHORED or ANCHOR_LEFT searches
    //                               if opt.longest_match() == false
    //   forward, longest-match  - used for all ANCHOR_BOTH searches,
    //                               and the other two kinds if
    //                               opt.longest_match() == true
    //   reverse, first-match    - never used
    //   reverse, longest-match  - used as second phase for unanchored searches
    //
    // The RE2 memory budget is statically divided between the two
    // Progs and then the DFAs: two thirds to the forward Prog
    // and one third to the reverse Prog.  The forward Prog gives half
    // of what it has left over to each of its DFAs.  The reverse Prog
    // gives it all to its longest-match DFA.
    //
    // Once a DFA fills its budget, it flushes its cache and starts over.
    // If this happens too often, RE2 falls back on the NFA implementation.

    // For now, make the default budget something close to Code Search.
#ifndef WIN32
    static const int kDefaultMaxMem = 8<<20;
#endif

    enum Encoding {
      EncodingUTF8 = 1,
      EncodingLatin1
    };

    Options();
    /*implicit*/ Options(CannedOptions);

    Encoding encoding() const { return encoding_; }
    void set_encoding(Encoding encoding) { encoding_ = encoding; }

    // Legacy interface to encoding.
    // TODO(rsc): Remove once clients have been converted.
    bool utf8() const { return encoding_ == EncodingUTF8; }
    void set_utf8(bool b) {
      if (b) {
        encoding_ = EncodingUTF8;
      } else {
        encoding_ = EncodingLatin1;
      }
    }

    bool posix_syntax() const { return posix_syntax_; }
    void set_posix_syntax(bool b) { posix_syntax_ = b; }

    bool longest_match() const { return longest_match_; }
    void set_longest_match(bool b) { longest_match_ = b; }

    bool log_errors() const { return log_errors_; }
    void set_log_errors(bool b) { log_errors_ = b; }

    int max_mem() const { return max_mem_; }
    void set_max_mem(int m) { max_mem_ = m; }

    bool literal() const { return literal_; }
    void set_literal(bool b) { literal_ = b; }

    bool never_nl() const { return never_nl_; }
    void set_never_nl(bool b) { never_nl_ = b; }

    bool never_capture() const { return never_capture_; }
    void set_never_capture(bool b) { never_capture_ = b; }

    bool case_sensitive() const { return case_sensitive_; }
    void set_case_sensitive(bool b) { case_sensitive_ = b; }

    bool perl_classes() const { return perl_classes_; }
    void set_perl_classes(bool b) { perl_classes_ = b; }

    bool word_boundary() const { return word_boundary_; }
    void set_word_boundary(bool b) { word_boundary_ = b; }

    bool one_line() const { return one_line_; }
    void set_one_line(bool b) { one_line_ = b; }

    void Copy(const Options& src) {
      encoding_ = src.encoding_;
      posix_syntax_ = src.posix_syntax_;
      longest_match_ = src.longest_match_;
      log_errors_ = src.log_errors_;
      max_mem_ = src.max_mem_;
      literal_ = src.literal_;
      never_nl_ = src.never_nl_;
      never_capture_ = src.never_capture_;
      case_sensitive_ = src.case_sensitive_;
      perl_classes_ = src.perl_classes_;
      word_boundary_ = src.word_boundary_;
      one_line_ = src.one_line_;
    }

    int ParseFlags() const;

   private:
    Encoding encoding_;
    bool posix_syntax_;
    bool longest_match_;
    bool log_errors_;
    int64_t max_mem_;
    bool literal_;
    bool never_nl_;
    bool never_capture_;
    bool case_sensitive_;
    bool perl_classes_;
    bool word_boundary_;
    bool one_line_;

    //DISALLOW_EVIL_CONSTRUCTORS(Options);
    Options(const Options&);
    void operator=(const Options&);
  };

  // Returns the options set in the constructor.
  const Options& options() const { return options_; };

  // Argument converters; see below.
  static inline Arg CRadix(short* x);
  static inline Arg CRadix(unsigned short* x);
  static inline Arg CRadix(int* x);
  static inline Arg CRadix(unsigned int* x);
  static inline Arg CRadix(long* x);
  static inline Arg CRadix(unsigned long* x);
  static inline Arg CRadix(long long* x);
  static inline Arg CRadix(unsigned long long* x);

  static inline Arg Hex(short* x);
  static inline Arg Hex(unsigned short* x);
  static inline Arg Hex(int* x);
  static inline Arg Hex(unsigned int* x);
  static inline Arg Hex(long* x);
  static inline Arg Hex(unsigned long* x);
  static inline Arg Hex(long long* x);
  static inline Arg Hex(unsigned long long* x);

  static inline Arg Octal(short* x);
  static inline Arg Octal(unsigned short* x);
  static inline Arg Octal(int* x);
  static inline Arg Octal(unsigned int* x);
  static inline Arg Octal(long* x);
  static inline Arg Octal(unsigned long* x);
  static inline Arg Octal(long long* x);
  static inline Arg Octal(unsigned long long* x);

 private:
  void Init(const StringPiece& pattern, const Options& options);

  bool DoMatch(const StringPiece& text,
                   Anchor anchor,
                   int* consumed,
                   const Arg* const args[],
                   int n) const;

  re2::Prog* ReverseProg() const;

  mutable Mutex*           mutex_;
  string                   pattern_;       // string regular expression
  Options                  options_;       // option flags
  string        prefix_;           // required prefix (before regexp_)
  bool          prefix_foldcase_;  // prefix is ASCII case-insensitive
  re2::Regexp*  entire_regexp_;    // parsed regular expression
  re2::Regexp*  suffix_regexp_;    // parsed regular expression, prefix removed
  re2::Prog*    prog_;             // compiled program for regexp
  mutable re2::Prog* rprog_;       // reverse program for regexp
  bool                     is_one_pass_;   // can use prog_->SearchOnePass?
  mutable const string*    error_;         // Error indicator
                                           // (or points to empty string)
  mutable ErrorCode        error_code_;    // Error code
  mutable string           error_arg_;     // Fragment of regexp showing error
  mutable int              num_captures_;  // Number of capturing groups

  // Map from capture names to indices
  mutable const map<string, int>* named_groups_;

  // Map from capture indices to names
  mutable const map<int, string>* group_names_;

  //DISALLOW_EVIL_CONSTRUCTORS(RE2);
  RE2(const RE2&);
  void operator=(const RE2&);
};

/***** Implementation details *****/

// Hex/Octal/Binary?

// Special class for parsing into objects that define a ParseFrom() method
template <class T>
class _RE2_MatchObject {
 public:
  static inline bool Parse(const char* str, int n, void* dest) {
    if (dest == NULL) return true;
    T* object = reinterpret_cast<T*>(dest);
    return object->ParseFrom(str, n);
  }
};

class RE2::Arg {
 public:
  // Empty constructor so we can declare arrays of RE2::Arg
  Arg();

  // Constructor specially designed for NULL arguments
  Arg(void*);

  typedef bool (*Parser)(const char* str, int n, void* dest);

// Type-specific parsers
#define MAKE_PARSER(type,name) \
  Arg(type* p) : arg_(p), parser_(name) { } \
  Arg(type* p, Parser parser) : arg_(p), parser_(parser) { } \


  MAKE_PARSER(char,               parse_char);
  MAKE_PARSER(signed char,        parse_char);
  MAKE_PARSER(unsigned char,      parse_uchar);
  MAKE_PARSER(short,              parse_short);
  MAKE_PARSER(unsigned short,     parse_ushort);
  MAKE_PARSER(int,                parse_int);
  MAKE_PARSER(unsigned int,       parse_uint);
  MAKE_PARSER(long,               parse_long);
  MAKE_PARSER(unsigned long,      parse_ulong);
  MAKE_PARSER(long long,          parse_longlong);
  MAKE_PARSER(unsigned long long, parse_ulonglong);
  MAKE_PARSER(float,              parse_float);
  MAKE_PARSER(double,             parse_double);
  MAKE_PARSER(string,             parse_string);
  MAKE_PARSER(StringPiece,        parse_stringpiece);

#undef MAKE_PARSER

  // Generic constructor
  template <class T> Arg(T*, Parser parser);
  // Generic constructor template
  template <class T> Arg(T* p)
    : arg_(p), parser_(_RE2_MatchObject<T>::Parse) {
  }

  // Parse the data
  bool Parse(const char* str, int n) const;

 private:
  void*         arg_;
  Parser        parser_;

  static bool parse_null          (const char* str, int n, void* dest);
  static bool parse_char          (const char* str, int n, void* dest);
  static bool parse_uchar         (const char* str, int n, void* dest);
  static bool parse_float         (const char* str, int n, void* dest);
  static bool parse_double        (const char* str, int n, void* dest);
  static bool parse_string        (const char* str, int n, void* dest);
  static bool parse_stringpiece   (const char* str, int n, void* dest);

#define DECLARE_INTEGER_PARSER(name)                                        \
 private:                                                                   \
  static bool parse_ ## name(const char* str, int n, void* dest);           \
  static bool parse_ ## name ## _radix(                                     \
    const char* str, int n, void* dest, int radix);                         \
 public:                                                                    \
  static bool parse_ ## name ## _hex(const char* str, int n, void* dest);   \
  static bool parse_ ## name ## _octal(const char* str, int n, void* dest); \
  static bool parse_ ## name ## _cradix(const char* str, int n, void* dest)

  DECLARE_INTEGER_PARSER(short);
  DECLARE_INTEGER_PARSER(ushort);
  DECLARE_INTEGER_PARSER(int);
  DECLARE_INTEGER_PARSER(uint);
  DECLARE_INTEGER_PARSER(long);
  DECLARE_INTEGER_PARSER(ulong);
  DECLARE_INTEGER_PARSER(longlong);
  DECLARE_INTEGER_PARSER(ulonglong);

#undef DECLARE_INTEGER_PARSER
};

inline RE2::Arg::Arg() : arg_(NULL), parser_(parse_null) { }
inline RE2::Arg::Arg(void* p) : arg_(p), parser_(parse_null) { }

inline bool RE2::Arg::Parse(const char* str, int n) const {
  return (*parser_)(str, n, arg_);
}

// This part of the parser, appropriate only for ints, deals with bases
#define MAKE_INTEGER_PARSER(type, name) \
  inline RE2::Arg RE2::Hex(type* ptr) { \
    return RE2::Arg(ptr, RE2::Arg::parse_ ## name ## _hex); } \
  inline RE2::Arg RE2::Octal(type* ptr) { \
    return RE2::Arg(ptr, RE2::Arg::parse_ ## name ## _octal); } \
  inline RE2::Arg RE2::CRadix(type* ptr) { \
    return RE2::Arg(ptr, RE2::Arg::parse_ ## name ## _cradix); }

MAKE_INTEGER_PARSER(short,              short);
MAKE_INTEGER_PARSER(unsigned short,     ushort);
MAKE_INTEGER_PARSER(int,                int);
MAKE_INTEGER_PARSER(unsigned int,       uint);
MAKE_INTEGER_PARSER(long,               long);
MAKE_INTEGER_PARSER(unsigned long,      ulong);
MAKE_INTEGER_PARSER(long long,          longlong);
MAKE_INTEGER_PARSER(unsigned long long, ulonglong);

#undef MAKE_INTEGER_PARSER

}  // namespace re2

using re2::RE2;

#endif /* RE2_RE2_H */
