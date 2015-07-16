// Copyright 2003-2009 Google Inc.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// This is a variant of PCRE's pcrecpp.cc, originally written at Google.
// The main changes are the addition of the HitLimit method and
// compilation as PCRE in namespace re2.

#include <errno.h>
#include "util/util.h"
#include "util/flags.h"
#include "util/pcre.h"

#ifdef WIN32
#define strtoll _strtoi64
#define strtoull _strtoui64
#endif

#define PCREPORT(level) LOG(level)

// Default PCRE limits.
// Defaults chosen to allow a plausible amount of CPU and
// not exceed main thread stacks.  Note that other threads
// often have smaller stacks, and therefore tightening
// regexp_stack_limit may frequently be necessary.
DEFINE_int32(regexp_stack_limit, 256<<10, "default PCRE stack limit (bytes)");
DEFINE_int32(regexp_match_limit, 1000000,
             "default PCRE match limit (function calls)");

namespace re2 {

// Maximum number of args we can set
static const int kMaxArgs = 16;
static const int kVecSize = (1 + kMaxArgs) * 3;  // results + PCRE workspace

// Approximate size of a recursive invocation of PCRE's
// internal "match()" frame.  This varies depending on the
// compiler and architecture, of course, so the constant is
// just a conservative estimate.  To find the exact number,
// run regexp_unittest with --regexp_stack_limit=0 under
// a debugger and look at the frames when it crashes.
// The exact frame size was 656 in production on 2008/02/03.
static const int kPCREFrameSize = 700;

// Special name for missing C++ arguments.
PCRE::Arg PCRE::no_more_args((void*)NULL);

const PCRE::PartialMatchFunctor PCRE::PartialMatch = { };
const PCRE::FullMatchFunctor PCRE::FullMatch = { } ;
const PCRE::ConsumeFunctor PCRE::Consume = { };
const PCRE::FindAndConsumeFunctor PCRE::FindAndConsume = { };

// If a regular expression has no error, its error_ field points here
static const string empty_string;

void PCRE::Init(const char* pattern, Option options, int match_limit,
              int stack_limit, bool report_errors) {
  pattern_ = pattern;
  options_ = options;
  match_limit_ = match_limit;
  stack_limit_ = stack_limit;
  hit_limit_ = false;
  error_ = &empty_string;
  report_errors_ = report_errors;
  re_full_ = NULL;
  re_partial_ = NULL;

  if (options & ~(EnabledCompileOptions | EnabledExecOptions)) {
    error_ = new string("illegal regexp option");
    PCREPORT(ERROR)
        << "Error compiling '" << pattern << "': illegal regexp option";
  } else {
    re_partial_ = Compile(UNANCHORED);
    if (re_partial_ != NULL) {
      re_full_ = Compile(ANCHOR_BOTH);
    }
  }
}

PCRE::PCRE(const char* pattern) {
  Init(pattern, None, 0, 0, true);
}
PCRE::PCRE(const char* pattern, Option option) {
  Init(pattern, option, 0, 0, true);
}
PCRE::PCRE(const string& pattern) {
  Init(pattern.c_str(), None, 0, 0, true);
}
PCRE::PCRE(const string& pattern, Option option) {
  Init(pattern.c_str(), option, 0, 0, true);
}
PCRE::PCRE(const string& pattern, const PCRE_Options& re_option) {
  Init(pattern.c_str(), re_option.option(), re_option.match_limit(),
       re_option.stack_limit(), re_option.report_errors());
}

PCRE::PCRE(const char *pattern, const PCRE_Options& re_option) {
  Init(pattern, re_option.option(), re_option.match_limit(),
       re_option.stack_limit(), re_option.report_errors());
}

PCRE::~PCRE() {
  if (re_full_ != NULL)         pcre_free(re_full_);
  if (re_partial_ != NULL)      pcre_free(re_partial_);
  if (error_ != &empty_string)  delete error_;
}

pcre* PCRE::Compile(Anchor anchor) {
  // Special treatment for anchoring.  This is needed because at
  // runtime pcre only provides an option for anchoring at the
  // beginning of a string.
  //
  // There are three types of anchoring we want:
  //    UNANCHORED      Compile the original pattern, and use
  //                    a pcre unanchored match.
  //    ANCHOR_START    Compile the original pattern, and use
  //                    a pcre anchored match.
  //    ANCHOR_BOTH     Tack a "\z" to the end of the original pattern
  //                    and use a pcre anchored match.

  const char* error;
  int eoffset;
  pcre* re;
  if (anchor != ANCHOR_BOTH) {
    re = pcre_compile(pattern_.c_str(),
                      (options_ & EnabledCompileOptions),
                      &error, &eoffset, NULL);
  } else {
    // Tack a '\z' at the end of PCRE.  Parenthesize it first so that
    // the '\z' applies to all top-level alternatives in the regexp.
    string wrapped = "(?:";  // A non-counting grouping operator
    wrapped += pattern_;
    wrapped += ")\\z";
    re = pcre_compile(wrapped.c_str(),
                      (options_ & EnabledCompileOptions),
                      &error, &eoffset, NULL);
  }
  if (re == NULL) {
    if (error_ == &empty_string) error_ = new string(error);
    PCREPORT(ERROR) << "Error compiling '" << pattern_ << "': " << error;
  }
  return re;
}

/***** Convenience interfaces *****/

bool PCRE::FullMatchFunctor::operator ()(const StringPiece& text,
                                       const PCRE& re,
                                       const Arg& a0,
                                       const Arg& a1,
                                       const Arg& a2,
                                       const Arg& a3,
                                       const Arg& a4,
                                       const Arg& a5,
                                       const Arg& a6,
                                       const Arg& a7,
                                       const Arg& a8,
                                       const Arg& a9,
                                       const Arg& a10,
                                       const Arg& a11,
                                       const Arg& a12,
                                       const Arg& a13,
                                       const Arg& a14,
                                       const Arg& a15) const {
  const Arg* args[kMaxArgs];
  int n = 0;
  if (&a0 == &no_more_args)  goto done; args[n++] = &a0;
  if (&a1 == &no_more_args)  goto done; args[n++] = &a1;
  if (&a2 == &no_more_args)  goto done; args[n++] = &a2;
  if (&a3 == &no_more_args)  goto done; args[n++] = &a3;
  if (&a4 == &no_more_args)  goto done; args[n++] = &a4;
  if (&a5 == &no_more_args)  goto done; args[n++] = &a5;
  if (&a6 == &no_more_args)  goto done; args[n++] = &a6;
  if (&a7 == &no_more_args)  goto done; args[n++] = &a7;
  if (&a8 == &no_more_args)  goto done; args[n++] = &a8;
  if (&a9 == &no_more_args)  goto done; args[n++] = &a9;
  if (&a10 == &no_more_args) goto done; args[n++] = &a10;
  if (&a11 == &no_more_args) goto done; args[n++] = &a11;
  if (&a12 == &no_more_args) goto done; args[n++] = &a12;
  if (&a13 == &no_more_args) goto done; args[n++] = &a13;
  if (&a14 == &no_more_args) goto done; args[n++] = &a14;
  if (&a15 == &no_more_args) goto done; args[n++] = &a15;
done:

  int consumed;
  int vec[kVecSize];
  return re.DoMatchImpl(text, ANCHOR_BOTH, &consumed, args, n, vec, kVecSize);
}

bool PCRE::PartialMatchFunctor::operator ()(const StringPiece& text,
                                          const PCRE& re,
                                          const Arg& a0,
                                          const Arg& a1,
                                          const Arg& a2,
                                          const Arg& a3,
                                          const Arg& a4,
                                          const Arg& a5,
                                          const Arg& a6,
                                          const Arg& a7,
                                          const Arg& a8,
                                          const Arg& a9,
                                          const Arg& a10,
                                          const Arg& a11,
                                          const Arg& a12,
                                          const Arg& a13,
                                          const Arg& a14,
                                          const Arg& a15) const {
  const Arg* args[kMaxArgs];
  int n = 0;
  if (&a0 == &no_more_args)  goto done; args[n++] = &a0;
  if (&a1 == &no_more_args)  goto done; args[n++] = &a1;
  if (&a2 == &no_more_args)  goto done; args[n++] = &a2;
  if (&a3 == &no_more_args)  goto done; args[n++] = &a3;
  if (&a4 == &no_more_args)  goto done; args[n++] = &a4;
  if (&a5 == &no_more_args)  goto done; args[n++] = &a5;
  if (&a6 == &no_more_args)  goto done; args[n++] = &a6;
  if (&a7 == &no_more_args)  goto done; args[n++] = &a7;
  if (&a8 == &no_more_args)  goto done; args[n++] = &a8;
  if (&a9 == &no_more_args)  goto done; args[n++] = &a9;
  if (&a10 == &no_more_args) goto done; args[n++] = &a10;
  if (&a11 == &no_more_args) goto done; args[n++] = &a11;
  if (&a12 == &no_more_args) goto done; args[n++] = &a12;
  if (&a13 == &no_more_args) goto done; args[n++] = &a13;
  if (&a14 == &no_more_args) goto done; args[n++] = &a14;
  if (&a15 == &no_more_args) goto done; args[n++] = &a15;
done:

  int consumed;
  int vec[kVecSize];
  return re.DoMatchImpl(text, UNANCHORED, &consumed, args, n, vec, kVecSize);
}

bool PCRE::ConsumeFunctor::operator ()(StringPiece* input,
                                     const PCRE& pattern,
                                     const Arg& a0,
                                     const Arg& a1,
                                     const Arg& a2,
                                     const Arg& a3,
                                     const Arg& a4,
                                     const Arg& a5,
                                     const Arg& a6,
                                     const Arg& a7,
                                     const Arg& a8,
                                     const Arg& a9,
                                     const Arg& a10,
                                     const Arg& a11,
                                     const Arg& a12,
                                     const Arg& a13,
                                     const Arg& a14,
                                     const Arg& a15) const {
  const Arg* args[kMaxArgs];
  int n = 0;
  if (&a0 == &no_more_args)  goto done; args[n++] = &a0;
  if (&a1 == &no_more_args)  goto done; args[n++] = &a1;
  if (&a2 == &no_more_args)  goto done; args[n++] = &a2;
  if (&a3 == &no_more_args)  goto done; args[n++] = &a3;
  if (&a4 == &no_more_args)  goto done; args[n++] = &a4;
  if (&a5 == &no_more_args)  goto done; args[n++] = &a5;
  if (&a6 == &no_more_args)  goto done; args[n++] = &a6;
  if (&a7 == &no_more_args)  goto done; args[n++] = &a7;
  if (&a8 == &no_more_args)  goto done; args[n++] = &a8;
  if (&a9 == &no_more_args)  goto done; args[n++] = &a9;
  if (&a10 == &no_more_args) goto done; args[n++] = &a10;
  if (&a11 == &no_more_args) goto done; args[n++] = &a11;
  if (&a12 == &no_more_args) goto done; args[n++] = &a12;
  if (&a13 == &no_more_args) goto done; args[n++] = &a13;
  if (&a14 == &no_more_args) goto done; args[n++] = &a14;
  if (&a15 == &no_more_args) goto done; args[n++] = &a15;
done:

  int consumed;
  int vec[kVecSize];
  if (pattern.DoMatchImpl(*input, ANCHOR_START, &consumed,
                          args, n, vec, kVecSize)) {
    input->remove_prefix(consumed);
    return true;
  } else {
    return false;
  }
}

bool PCRE::FindAndConsumeFunctor::operator ()(StringPiece* input,
                                            const PCRE& pattern,
                                            const Arg& a0,
                                            const Arg& a1,
                                            const Arg& a2,
                                            const Arg& a3,
                                            const Arg& a4,
                                            const Arg& a5,
                                            const Arg& a6,
                                            const Arg& a7,
                                            const Arg& a8,
                                            const Arg& a9,
                                            const Arg& a10,
                                            const Arg& a11,
                                            const Arg& a12,
                                            const Arg& a13,
                                            const Arg& a14,
                                            const Arg& a15) const {
  const Arg* args[kMaxArgs];
  int n = 0;
  if (&a0 == &no_more_args)  goto done; args[n++] = &a0;
  if (&a1 == &no_more_args)  goto done; args[n++] = &a1;
  if (&a2 == &no_more_args)  goto done; args[n++] = &a2;
  if (&a3 == &no_more_args)  goto done; args[n++] = &a3;
  if (&a4 == &no_more_args)  goto done; args[n++] = &a4;
  if (&a5 == &no_more_args)  goto done; args[n++] = &a5;
  if (&a6 == &no_more_args)  goto done; args[n++] = &a6;
  if (&a7 == &no_more_args)  goto done; args[n++] = &a7;
  if (&a8 == &no_more_args)  goto done; args[n++] = &a8;
  if (&a9 == &no_more_args)  goto done; args[n++] = &a9;
  if (&a10 == &no_more_args) goto done; args[n++] = &a10;
  if (&a11 == &no_more_args) goto done; args[n++] = &a11;
  if (&a12 == &no_more_args) goto done; args[n++] = &a12;
  if (&a13 == &no_more_args) goto done; args[n++] = &a13;
  if (&a14 == &no_more_args) goto done; args[n++] = &a14;
  if (&a15 == &no_more_args) goto done; args[n++] = &a15;
done:

  int consumed;
  int vec[kVecSize];
  if (pattern.DoMatchImpl(*input, UNANCHORED, &consumed,
                          args, n, vec, kVecSize)) {
    input->remove_prefix(consumed);
    return true;
  } else {
    return false;
  }
}

bool PCRE::Replace(string *str,
                 const PCRE& pattern,
                 const StringPiece& rewrite) {
  int vec[kVecSize];
  int matches = pattern.TryMatch(*str, 0, UNANCHORED, true, vec, kVecSize);
  if (matches == 0)
    return false;

  string s;
  if (!pattern.Rewrite(&s, rewrite, *str, vec, matches))
    return false;

  assert(vec[0] >= 0);
  assert(vec[1] >= 0);
  str->replace(vec[0], vec[1] - vec[0], s);
  return true;
}

int PCRE::GlobalReplace(string *str,
                      const PCRE& pattern,
                      const StringPiece& rewrite) {
  int count = 0;
  int vec[kVecSize];
  string out;
  int start = 0;
  bool last_match_was_empty_string = false;

  for (; start <= str->length();) {
    // If the previous match was for the empty string, we shouldn't
    // just match again: we'll match in the same way and get an
    // infinite loop.  Instead, we do the match in a special way:
    // anchored -- to force another try at the same position --
    // and with a flag saying that this time, ignore empty matches.
    // If this special match returns, that means there's a non-empty
    // match at this position as well, and we can continue.  If not,
    // we do what perl does, and just advance by one.
    // Notice that perl prints '@@@' for this;
    //    perl -le '$_ = "aa"; s/b*|aa/@/g; print'
    int matches;
    if (last_match_was_empty_string) {
      matches = pattern.TryMatch(*str, start, ANCHOR_START, false,
                                 vec, kVecSize);
      if (matches <= 0) {
        if (start < str->length())
          out.push_back((*str)[start]);
        start++;
        last_match_was_empty_string = false;
        continue;
      }
    } else {
      matches = pattern.TryMatch(*str, start, UNANCHORED, true, vec, kVecSize);
      if (matches <= 0)
        break;
    }
    int matchstart = vec[0], matchend = vec[1];
    assert(matchstart >= start);
    assert(matchend >= matchstart);

    out.append(*str, start, matchstart - start);
    pattern.Rewrite(&out, rewrite, *str, vec, matches);
    start = matchend;
    count++;
    last_match_was_empty_string = (matchstart == matchend);
  }

  if (count == 0)
    return 0;

  if (start < str->length())
    out.append(*str, start, str->length() - start);
  swap(out, *str);
  return count;
}

bool PCRE::Extract(const StringPiece &text,
                 const PCRE& pattern,
                 const StringPiece &rewrite,
                 string *out) {
  int vec[kVecSize];
  int matches = pattern.TryMatch(text, 0, UNANCHORED, true, vec, kVecSize);
  if (matches == 0)
    return false;
  out->clear();
  return pattern.Rewrite(out, rewrite, text, vec, matches);
}

string PCRE::QuoteMeta(const StringPiece& unquoted) {
  string result;
  result.reserve(unquoted.size() << 1);

  // Escape any ascii character not in [A-Za-z_0-9].
  //
  // Note that it's legal to escape a character even if it has no
  // special meaning in a regular expression -- so this function does
  // that.  (This also makes it identical to the perl function of the
  // same name except for the null-character special case;
  // see `perldoc -f quotemeta`.)
  for (int ii = 0; ii < unquoted.length(); ++ii) {
    // Note that using 'isalnum' here raises the benchmark time from
    // 32ns to 58ns:
    if ((unquoted[ii] < 'a' || unquoted[ii] > 'z') &&
        (unquoted[ii] < 'A' || unquoted[ii] > 'Z') &&
        (unquoted[ii] < '0' || unquoted[ii] > '9') &&
        unquoted[ii] != '_' &&
        // If this is the part of a UTF8 or Latin1 character, we need
        // to copy this byte without escaping.  Experimentally this is
        // what works correctly with the regexp library.
        !(unquoted[ii] & 128)) {
      if (unquoted[ii] == '\0') {  // Special handling for null chars.
        // Can't use "\\0" since the next character might be a digit.
        result += "\\x00";
        continue;
      }
      result += '\\';
    }
    result += unquoted[ii];
  }

  return result;
}

/***** Actual matching and rewriting code *****/

bool PCRE::HitLimit() {
  return hit_limit_;
}

void PCRE::ClearHitLimit() {
  hit_limit_ = 0;
}

int PCRE::TryMatch(const StringPiece& text,
                 int startpos,
                 Anchor anchor,
                 bool empty_ok,
                 int *vec,
                 int vecsize) const {
  pcre* re = (anchor == ANCHOR_BOTH) ? re_full_ : re_partial_;
  if (re == NULL) {
    PCREPORT(ERROR) << "Matching against invalid re: " << *error_;
    return 0;
  }

  int match_limit = match_limit_;
  if (match_limit <= 0) {
    match_limit = FLAGS_regexp_match_limit;
  }

  int stack_limit = stack_limit_;
  if (stack_limit <= 0) {
    stack_limit = FLAGS_regexp_stack_limit;
  }

  pcre_extra extra = { 0 };
  if (match_limit > 0) {
    extra.flags |= PCRE_EXTRA_MATCH_LIMIT;
    extra.match_limit = match_limit;
  }
  if (stack_limit > 0) {
    extra.flags |= PCRE_EXTRA_MATCH_LIMIT_RECURSION;
    extra.match_limit_recursion = stack_limit / kPCREFrameSize;
  }

  int options = 0;
  if (anchor != UNANCHORED)
    options |= PCRE_ANCHORED;
  if (!empty_ok)
    options |= PCRE_NOTEMPTY;

  int rc = pcre_exec(re,              // The regular expression object
                     &extra,
                     (text.data() == NULL) ? "" : text.data(),
                     text.size(),
                     startpos,
                     options,
                     vec,
                     vecsize);

  // Handle errors
  if (rc == 0) {
    // pcre_exec() returns 0 as a special case when the number of
    // capturing subpatterns exceeds the size of the vector.
    // When this happens, there is a match and the output vector
    // is filled, but we miss out on the positions of the extra subpatterns.
    rc = vecsize / 2;
  } else if (rc < 0) {
    switch (rc) {
      case PCRE_ERROR_NOMATCH:
        return 0;
      case PCRE_ERROR_MATCHLIMIT:
        // Writing to hit_limit is not safe if multiple threads
        // are using the PCRE, but the flag is only intended
        // for use by unit tests anyway, so we let it go.
        hit_limit_ = true;
        PCREPORT(WARNING) << "Exceeded match limit of " << match_limit
                        << " when matching '" << pattern_ << "'"
                        << " against text that is " << text.size() << " bytes.";
        return 0;
      case PCRE_ERROR_RECURSIONLIMIT:
        // See comment about hit_limit above.
        hit_limit_ = true;
        PCREPORT(WARNING) << "Exceeded stack limit of " << stack_limit
                        << " when matching '" << pattern_ << "'"
                        << " against text that is " << text.size() << " bytes.";
        return 0;
      default:
        // There are other return codes from pcre.h :
        // PCRE_ERROR_NULL           (-2)
        // PCRE_ERROR_BADOPTION      (-3)
        // PCRE_ERROR_BADMAGIC       (-4)
        // PCRE_ERROR_UNKNOWN_NODE   (-5)
        // PCRE_ERROR_NOMEMORY       (-6)
        // PCRE_ERROR_NOSUBSTRING    (-7)
        // ...
        PCREPORT(ERROR) << "Unexpected return code: " << rc
                      << " when matching '" << pattern_ << "'"
                      << ", re=" << re
                      << ", text=" << text
                      << ", vec=" << vec
                      << ", vecsize=" << vecsize;
        return 0;
    }
  }

  return rc;
}

bool PCRE::DoMatchImpl(const StringPiece& text,
                     Anchor anchor,
                     int* consumed,
                     const Arg* const* args,
                     int n,
                     int* vec,
                     int vecsize) const {
  assert((1 + n) * 3 <= vecsize);  // results + PCRE workspace
  int matches = TryMatch(text, 0, anchor, true, vec, vecsize);
  assert(matches >= 0);  // TryMatch never returns negatives
  if (matches == 0)
    return false;

  *consumed = vec[1];

  if (n == 0 || args == NULL) {
    // We are not interested in results
    return true;
  }
  if (NumberOfCapturingGroups() < n) {
    // PCRE has fewer capturing groups than number of arg pointers passed in
    return false;
  }

  // If we got here, we must have matched the whole pattern.
  // We do not need (can not do) any more checks on the value of 'matches' here
  // -- see the comment for TryMatch.
  for (int i = 0; i < n; i++) {
    const int start = vec[2*(i+1)];
    const int limit = vec[2*(i+1)+1];
    if (!args[i]->Parse(text.data() + start, limit-start)) {
      // TODO: Should we indicate what the error was?
      return false;
    }
  }

  return true;
}

bool PCRE::DoMatch(const StringPiece& text,
                 Anchor anchor,
                 int* consumed,
                 const Arg* const args[],
                 int n) const {
  assert(n >= 0);
  size_t const vecsize = (1 + n) * 3;  // results + PCRE workspace
                                       // (as for kVecSize)
  int *vec = new int[vecsize];
  bool b = DoMatchImpl(text, anchor, consumed, args, n, vec, vecsize);
  delete[] vec;
  return b;
}

bool PCRE::Rewrite(string *out, const StringPiece &rewrite,
                 const StringPiece &text, int *vec, int veclen) const {
  int number_of_capturing_groups = NumberOfCapturingGroups();
  for (const char *s = rewrite.data(), *end = s + rewrite.size();
       s < end; s++) {
    int c = *s;
    if (c == '\\') {
      c = *++s;
      if (isdigit(c)) {
        int n = (c - '0');
        if (n >= veclen) {
          if (n <= number_of_capturing_groups) {
            // unmatched optional capturing group. treat
            // its value as empty string; i.e., nothing to append.
          } else {
            PCREPORT(ERROR) << "requested group " << n
                          << " in regexp " << rewrite.data();
            return false;
          }
        }
        int start = vec[2 * n];
        if (start >= 0)
          out->append(text.data() + start, vec[2 * n + 1] - start);
      } else if (c == '\\') {
        out->push_back('\\');
      } else {
        PCREPORT(ERROR) << "invalid rewrite pattern: " << rewrite.data();
        return false;
      }
    } else {
      out->push_back(c);
    }
  }
  return true;
}

bool PCRE::CheckRewriteString(const StringPiece& rewrite, string* error) const {
  int max_token = -1;
  for (const char *s = rewrite.data(), *end = s + rewrite.size();
       s < end; s++) {
    int c = *s;
    if (c != '\\') {
      continue;
    }
    if (++s == end) {
      *error = "Rewrite schema error: '\\' not allowed at end.";
      return false;
    }
    c = *s;
    if (c == '\\') {
      continue;
    }
    if (!isdigit(c)) {
      *error = "Rewrite schema error: "
               "'\\' must be followed by a digit or '\\'.";
      return false;
    }
    int n = (c - '0');
    if (max_token < n) {
      max_token = n;
    }
  }

  if (max_token > NumberOfCapturingGroups()) {
    SStringPrintf(error, "Rewrite schema requests %d matches, "
                  "but the regexp only has %d parenthesized subexpressions.",
                  max_token, NumberOfCapturingGroups());
    return false;
  }
  return true;
}


// Return the number of capturing subpatterns, or -1 if the
// regexp wasn't valid on construction.
int PCRE::NumberOfCapturingGroups() const {
  if (re_partial_ == NULL) return -1;

  int result;
  CHECK(pcre_fullinfo(re_partial_,       // The regular expression object
                      NULL,              // We did not study the pattern
                      PCRE_INFO_CAPTURECOUNT,
                      &result) == 0);
  return result;
}


/***** Parsers for various types *****/

bool PCRE::Arg::parse_null(const char* str, int n, void* dest) {
  // We fail if somebody asked us to store into a non-NULL void* pointer
  return (dest == NULL);
}

bool PCRE::Arg::parse_string(const char* str, int n, void* dest) {
  if (dest == NULL) return true;
  reinterpret_cast<string*>(dest)->assign(str, n);
  return true;
}

bool PCRE::Arg::parse_stringpiece(const char* str, int n, void* dest) {
  if (dest == NULL) return true;
  reinterpret_cast<StringPiece*>(dest)->set(str, n);
  return true;
}

bool PCRE::Arg::parse_char(const char* str, int n, void* dest) {
  if (n != 1) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<char*>(dest)) = str[0];
  return true;
}

bool PCRE::Arg::parse_uchar(const char* str, int n, void* dest) {
  if (n != 1) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<unsigned char*>(dest)) = str[0];
  return true;
}

// Largest number spec that we are willing to parse
static const int kMaxNumberLength = 32;

// PCREQUIPCRES "buf" must have length at least kMaxNumberLength+1
// PCREQUIPCRES "n > 0"
// Copies "str" into "buf" and null-terminates if necessary.
// Returns one of:
//      a. "str" if no termination is needed
//      b. "buf" if the string was copied and null-terminated
//      c. "" if the input was invalid and has no hope of being parsed
static const char* TerminateNumber(char* buf, const char* str, int n) {
  if ((n > 0) && isspace(*str)) {
    // We are less forgiving than the strtoxxx() routines and do not
    // allow leading spaces.
    return "";
  }

  // See if the character right after the input text may potentially
  // look like a digit.
  if (isdigit(str[n]) ||
      ((str[n] >= 'a') && (str[n] <= 'f')) ||
      ((str[n] >= 'A') && (str[n] <= 'F'))) {
    if (n > kMaxNumberLength) return ""; // Input too big to be a valid number
    memcpy(buf, str, n);
    buf[n] = '\0';
    return buf;
  } else {
    // We can parse right out of the supplied string, so return it.
    return str;
  }
}

bool PCRE::Arg::parse_long_radix(const char* str,
                               int n,
                               void* dest,
                               int radix) {
  if (n == 0) return false;
  char buf[kMaxNumberLength+1];
  str = TerminateNumber(buf, str, n);
  char* end;
  errno = 0;
  long r = strtol(str, &end, radix);
  if (end != str + n) return false;   // Leftover junk
  if (errno) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<long*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_ulong_radix(const char* str,
                                int n,
                                void* dest,
                                int radix) {
  if (n == 0) return false;
  char buf[kMaxNumberLength+1];
  str = TerminateNumber(buf, str, n);
  if (str[0] == '-') {
   // strtoul() will silently accept negative numbers and parse
   // them.  This module is more strict and treats them as errors.
   return false;
  }

  char* end;
  errno = 0;
  unsigned long r = strtoul(str, &end, radix);
  if (end != str + n) return false;   // Leftover junk
  if (errno) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<unsigned long*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_short_radix(const char* str,
                                int n,
                                void* dest,
                                int radix) {
  long r;
  if (!parse_long_radix(str, n, &r, radix)) return false; // Could not parse
  if ((short)r != r) return false;       // Out of range
  if (dest == NULL) return true;
  *(reinterpret_cast<short*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_ushort_radix(const char* str,
                                 int n,
                                 void* dest,
                                 int radix) {
  unsigned long r;
  if (!parse_ulong_radix(str, n, &r, radix)) return false; // Could not parse
  if ((ushort)r != r) return false;                      // Out of range
  if (dest == NULL) return true;
  *(reinterpret_cast<unsigned short*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_int_radix(const char* str,
                              int n,
                              void* dest,
                              int radix) {
  long r;
  if (!parse_long_radix(str, n, &r, radix)) return false; // Could not parse
  if ((int)r != r) return false;         // Out of range
  if (dest == NULL) return true;
  *(reinterpret_cast<int*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_uint_radix(const char* str,
                               int n,
                               void* dest,
                               int radix) {
  unsigned long r;
  if (!parse_ulong_radix(str, n, &r, radix)) return false; // Could not parse
  if ((uint)r != r) return false;                       // Out of range
  if (dest == NULL) return true;
  *(reinterpret_cast<unsigned int*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_longlong_radix(const char* str,
                                   int n,
                                   void* dest,
                                   int radix) {
  if (n == 0) return false;
  char buf[kMaxNumberLength+1];
  str = TerminateNumber(buf, str, n);
  char* end;
  errno = 0;
  int64 r = strtoll(str, &end, radix);
  if (end != str + n) return false;   // Leftover junk
  if (errno) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<int64*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_ulonglong_radix(const char* str,
                                    int n,
                                    void* dest,
                                    int radix) {
  if (n == 0) return false;
  char buf[kMaxNumberLength+1];
  str = TerminateNumber(buf, str, n);
  if (str[0] == '-') {
    // strtoull() will silently accept negative numbers and parse
    // them.  This module is more strict and treats them as errors.
    return false;
  }
  char* end;
  errno = 0;
  uint64 r = strtoull(str, &end, radix);
  if (end != str + n) return false;   // Leftover junk
  if (errno) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<uint64*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_double(const char* str, int n, void* dest) {
  if (n == 0) return false;
  static const int kMaxLength = 200;
  char buf[kMaxLength];
  if (n >= kMaxLength) return false;
  memcpy(buf, str, n);
  buf[n] = '\0';
  errno = 0;
  char* end;
  double r = strtod(buf, &end);
  if (end != buf + n) {
#ifdef COMPILER_MSVC
    // Microsoft's strtod() doesn't handle inf and nan, so we have to
    // handle it explicitly.  Speed is not important here because this
    // code is only called in unit tests.
    bool pos = true;
    const char* i = buf;
    if ('-' == *i) {
      pos = false;
      ++i;
    } else if ('+' == *i) {
      ++i;
    }
    if (0 == stricmp(i, "inf") || 0 == stricmp(i, "infinity")) {
      r = numeric_limits<double>::infinity();
      if (!pos)
        r = -r;
    } else if (0 == stricmp(i, "nan")) {
      r = numeric_limits<double>::quiet_NaN();
    } else {
      return false;
    }
#else
    return false;   // Leftover junk
#endif
  }
  if (errno) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<double*>(dest)) = r;
  return true;
}

bool PCRE::Arg::parse_float(const char* str, int n, void* dest) {
  double r;
  if (!parse_double(str, n, &r)) return false;
  if (dest == NULL) return true;
  *(reinterpret_cast<float*>(dest)) = static_cast<float>(r);
  return true;
}


#define DEFINE_INTEGER_PARSERS(name)                                        \
  bool PCRE::Arg::parse_##name(const char* str, int n, void* dest) {          \
    return parse_##name##_radix(str, n, dest, 10);                          \
  }                                                                         \
  bool PCRE::Arg::parse_##name##_hex(const char* str, int n, void* dest) {    \
    return parse_##name##_radix(str, n, dest, 16);                          \
  }                                                                         \
  bool PCRE::Arg::parse_##name##_octal(const char* str, int n, void* dest) {  \
    return parse_##name##_radix(str, n, dest, 8);                           \
  }                                                                         \
  bool PCRE::Arg::parse_##name##_cradix(const char* str, int n, void* dest) { \
    return parse_##name##_radix(str, n, dest, 0);                           \
  }

DEFINE_INTEGER_PARSERS(short);
DEFINE_INTEGER_PARSERS(ushort);
DEFINE_INTEGER_PARSERS(int);
DEFINE_INTEGER_PARSERS(uint);
DEFINE_INTEGER_PARSERS(long);
DEFINE_INTEGER_PARSERS(ulong);
DEFINE_INTEGER_PARSERS(longlong);
DEFINE_INTEGER_PARSERS(ulonglong);

#undef DEFINE_INTEGER_PARSERS

}  // namespace re2
