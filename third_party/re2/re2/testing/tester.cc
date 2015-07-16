// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Regular expression engine tester -- test all the implementations against each other.

#include "util/util.h"
#include "util/flags.h"
#include "re2/testing/tester.h"
#include "re2/prog.h"
#include "re2/re2.h"
#include "re2/regexp.h"

DEFINE_bool(dump_prog, false, "dump regexp program");
DEFINE_bool(log_okay, false, "log successful runs");
DEFINE_bool(dump_rprog, false, "dump reversed regexp program");

DEFINE_int32(max_regexp_failures, 100,
             "maximum number of regexp test failures (-1 = unlimited)");

DEFINE_string(regexp_engines, "", "pattern to select regexp engines to test");

namespace re2 {

enum {
  kMaxSubmatch = 1+16,  // $0...$16
};

const char* engine_types[kEngineMax] = {
  "Backtrack",
  "NFA",
  "DFA",
  "DFA1",
  "OnePass",
  "BitState",
  "RE2",
  "RE2a",
  "RE2b",
  "PCRE",
};

// Returns the name string for the type t.
static string EngineString(Engine t) {
  if (t < 0 || t >= arraysize(engine_types) || engine_types[t] == NULL) {
    return StringPrintf("type%d", static_cast<int>(t));
  }
  return engine_types[t];
}

// Returns bit mask of engines to use.
static uint32 Engines() {
  static uint32 cached_engines;
  static bool did_parse;

  if (did_parse)
    return cached_engines;

  if (FLAGS_regexp_engines.empty()) {
    cached_engines = ~0;
  } else {
    for (Engine i = static_cast<Engine>(0); i < kEngineMax; i++)
      if (strstr(EngineString(i).c_str(), FLAGS_regexp_engines.c_str()))
        cached_engines |= 1<<i;
  }

  if (cached_engines == 0)
    LOG(INFO) << "Warning: no engines enabled.";
  if (!UsingPCRE)
    cached_engines &= ~(1<<kEnginePCRE);
  for (Engine i = static_cast<Engine>(0); i < kEngineMax; i++) {
    if (cached_engines & (1<<i))
      LOG(INFO) << EngineString(i) << " enabled";
  }
  did_parse = true;
  return cached_engines;
}

// The result of running a match.
struct TestInstance::Result {
  bool skipped;         // test skipped: wasn't applicable
  bool matched;         // found a match
  bool untrusted;       // don't really trust the answer
  bool have_submatch;   // computed all submatch info
  bool have_submatch0;  // computed just submatch[0]
  StringPiece submatch[kMaxSubmatch];
};

typedef TestInstance::Result Result;

// Formats a single capture range s in text in the form (a,b)
// where a and b are the starting and ending offsets of s in text.
static string FormatCapture(const StringPiece& text, const StringPiece& s) {
  if (s.begin() == NULL)
    return "(?,?)";
  return StringPrintf("(%d,%d)",
                      static_cast<int>(s.begin() - text.begin()),
                      static_cast<int>(s.end() - text.begin()));
}

// Returns whether text contains non-ASCII (>= 0x80) bytes.
static bool NonASCII(const StringPiece& text) {
  for (int i = 0; i < text.size(); i++)
    if ((uint8)text[i] >= 0x80)
      return true;
  return false;
}

// Returns string representation of match kind.
static string FormatKind(Prog::MatchKind kind) {
  switch (kind) {
    case Prog::kFullMatch:
      return "full match";
    case Prog::kLongestMatch:
      return "longest match";
    case Prog::kFirstMatch:
      return "first match";
    case Prog::kManyMatch:
      return "many match";
  }
  return "???";
}

// Returns string representation of anchor kind.
static string FormatAnchor(Prog::Anchor anchor) {
  switch (anchor) {
    case Prog::kAnchored:
      return "anchored";
    case Prog::kUnanchored:
      return "unanchored";
  }
  return "???";
}

struct ParseMode {
  Regexp::ParseFlags parse_flags;
  string desc;
};

static const Regexp::ParseFlags single_line =
  Regexp::LikePerl;
static const Regexp::ParseFlags multi_line =
  static_cast<Regexp::ParseFlags>(Regexp::LikePerl & ~Regexp::OneLine);

static ParseMode parse_modes[] = {
  { single_line,                   "single-line"          },
  { single_line|Regexp::Latin1,    "single-line, latin1"  },
  { multi_line,                    "multiline"            },
  { multi_line|Regexp::NonGreedy,  "multiline, nongreedy" },
  { multi_line|Regexp::Latin1,     "multiline, latin1"    },
};

static string FormatMode(Regexp::ParseFlags flags) {
  for (int i = 0; i < arraysize(parse_modes); i++)
    if (parse_modes[i].parse_flags == flags)
      return parse_modes[i].desc;
  return StringPrintf("%#x", static_cast<uint>(flags));
}

// Constructs and saves all the matching engines that
// will be required for the given tests.
TestInstance::TestInstance(const StringPiece& regexp_str, Prog::MatchKind kind,
                           Regexp::ParseFlags flags)
  : regexp_str_(regexp_str),
    kind_(kind),
    flags_(flags),
    error_(false),
    regexp_(NULL),
    num_captures_(0),
    prog_(NULL),
    rprog_(NULL),
    re_(NULL),
    re2_(NULL) {

  VLOG(1) << CEscape(regexp_str);

  // Compile regexp to prog.
  // Always required - needed for backtracking (reference implementation).
  RegexpStatus status;
  regexp_ = Regexp::Parse(regexp_str, flags, &status);
  if (regexp_ == NULL) {
    LOG(INFO) << "Cannot parse: " << CEscape(regexp_str_)
              << " mode: " << FormatMode(flags);
    error_ = true;
    return;
  }
  num_captures_ = regexp_->NumCaptures();
  prog_ = regexp_->CompileToProg(0);
  if (prog_ == NULL) {
    LOG(INFO) << "Cannot compile: " << CEscape(regexp_str_);
    error_ = true;
    return;
  }
  if (FLAGS_dump_prog) {
    LOG(INFO) << "Prog for "
              << " regexp "
              << CEscape(regexp_str_)
              << " (" << FormatKind(kind_)
              << ", " << FormatMode(flags_)
              << ")\n"
              << prog_->Dump();
  }

  // Compile regexp to reversed prog.  Only needed for DFA engines.
  if (Engines() & ((1<<kEngineDFA)|(1<<kEngineDFA1))) {
    rprog_ = regexp_->CompileToReverseProg(0);
    if (rprog_ == NULL) {
      LOG(INFO) << "Cannot reverse compile: " << CEscape(regexp_str_);
      error_ = true;
      return;
    }
    if (FLAGS_dump_rprog)
      LOG(INFO) << rprog_->Dump();
  }

  // Create re string that will be used for RE and RE2.
  string re = regexp_str.as_string();
  // Accomodate flags.
  // Regexp::Latin1 will be accomodated below.
  if (!(flags & Regexp::OneLine))
    re = "(?m)" + re;
  if (flags & Regexp::NonGreedy)
    re = "(?U)" + re;
  if (flags & Regexp::DotNL)
    re = "(?s)" + re;

  // Compile regexp to RE2.
  if (Engines() & ((1<<kEngineRE2)|(1<<kEngineRE2a)|(1<<kEngineRE2b))) {
    RE2::Options options;
    if (flags & Regexp::Latin1)
      options.set_encoding(RE2::Options::EncodingLatin1);
    if (kind_ == Prog::kLongestMatch)
      options.set_longest_match(true);
    re2_ = new RE2(re, options);
    if (!re2_->error().empty()) {
      LOG(INFO) << "Cannot RE2: " << CEscape(re);
      error_ = true;
      return;
    }
  }

  // Compile regexp to RE.
  // PCRE as exposed by the RE interface isn't always usable.
  // 1. It disagrees about handling of empty-string reptitions
  //    like matching (a*)* against "b".  PCRE treats the (a*) as
  //    occurring once, while we treat it as occurring not at all.
  // 2. It treats $ as this weird thing meaning end of string
  //    or before the \n at the end of the string.
  // 3. It doesn't implement POSIX leftmost-longest matching.
  // MimicsPCRE() detects 1 and 2.
  if ((Engines() & (1<<kEnginePCRE)) && regexp_->MimicsPCRE() &&
      kind_ != Prog::kLongestMatch) {
    PCRE_Options o;
    o.set_option(PCRE::UTF8);
    if (flags & Regexp::Latin1)
      o.set_option(PCRE::None);
    // PCRE has interface bug keeping us from finding $0, so
    // add one more layer of parens.
    re_ = new PCRE("("+re+")", o);
    if (!re_->error().empty()) {
      LOG(INFO) << "Cannot PCRE: " << CEscape(re);
      error_ = true;
      return;
    }
  }
}

TestInstance::~TestInstance() {
  if (regexp_)
    regexp_->Decref();
  delete prog_;
  delete rprog_;
  delete re_;
  delete re2_;
}

// Runs a single search using the named engine type.
// This interface hides all the irregularities of the various
// engine interfaces from the rest of this file.
void TestInstance::RunSearch(Engine type,
                             const StringPiece& orig_text,
                             const StringPiece& orig_context,
                             Prog::Anchor anchor,
                             Result *result) {
  memset(result, 0, sizeof *result);
  if (regexp_ == NULL) {
    result->skipped = true;
    return;
  }
  int nsubmatch = 1 + num_captures_;  // NumCaptures doesn't count $0
  if (nsubmatch > kMaxSubmatch)
    nsubmatch = kMaxSubmatch;

  StringPiece text = orig_text;
  StringPiece context = orig_context;

  switch (type) {
    default:
      LOG(FATAL) << "Bad RunSearch type: " << (int)type;

    case kEngineBacktrack:
      if (prog_ == NULL) {
        result->skipped = true;
        break;
      }
      result->matched =
        prog_->UnsafeSearchBacktrack(text, context, anchor, kind_,
                                     result->submatch, nsubmatch);
      result->have_submatch = true;
      break;

    case kEngineNFA:
      if (prog_ == NULL) {
        result->skipped = true;
        break;
      }
      result->matched =
        prog_->SearchNFA(text, context, anchor, kind_,
                        result->submatch, nsubmatch);
      result->have_submatch = true;
      break;

    case kEngineDFA:
      if (prog_ == NULL) {
        result->skipped = true;
        break;
      }
      result->matched = prog_->SearchDFA(text, context, anchor, kind_, NULL,
                                         &result->skipped, NULL);
      break;

    case kEngineDFA1:
      if (prog_ == NULL || rprog_ == NULL) {
        result->skipped = true;
        break;
      }
      result->matched =
        prog_->SearchDFA(text, context, anchor, kind_, result->submatch,
                         &result->skipped, NULL);
      // If anchored, no need for second run,
      // but do it anyway to find more bugs.
      if (result->matched) {
        if (!rprog_->SearchDFA(result->submatch[0], context,
                               Prog::kAnchored, Prog::kLongestMatch,
                               result->submatch,
                               &result->skipped, NULL)) {
          LOG(ERROR) << "Reverse DFA inconsistency: " << CEscape(regexp_str_)
                     << " on " << CEscape(text);
          result->matched = false;
        }
      }
      result->have_submatch0 = true;
      break;

    case kEngineOnePass:
      if (prog_ == NULL ||
          anchor == Prog::kUnanchored ||
          !prog_->IsOnePass() ||
          nsubmatch > Prog::kMaxOnePassCapture) {
        result->skipped = true;
        break;
      }
      result->matched = prog_->SearchOnePass(text, context, anchor, kind_,
                                      result->submatch, nsubmatch);
      result->have_submatch = true;
      break;

    case kEngineBitState:
      if (prog_ == NULL) {
        result->skipped = true;
        break;
      }
      result->matched = prog_->SearchBitState(text, context, anchor, kind_,
                                              result->submatch, nsubmatch);
      result->have_submatch = true;
      break;

    case kEngineRE2:
    case kEngineRE2a:
    case kEngineRE2b: {
      if (!re2_ || text.end() != context.end()) {
        result->skipped = true;
        break;
      }

      RE2::Anchor re_anchor;
      if (anchor == Prog::kAnchored)
        re_anchor = RE2::ANCHOR_START;
      else
        re_anchor = RE2::UNANCHORED;
      if (kind_ == Prog::kFullMatch)
        re_anchor = RE2::ANCHOR_BOTH;

      result->matched = re2_->Match(context,
                                    text.begin() - context.begin(),
                                    text.end() - context.begin(),
                                    re_anchor, result->submatch, nsubmatch);
      result->have_submatch = nsubmatch > 0;
      break;
    }

    case kEnginePCRE: {
      if (!re_ || text.begin() != context.begin() ||
          text.end() != context.end()) {
        result->skipped = true;
        break;
      }

      const PCRE::Arg **argptr = new const PCRE::Arg*[nsubmatch];
      PCRE::Arg *a = new PCRE::Arg[nsubmatch];
      for (int i = 0; i < nsubmatch; i++) {
        a[i] = PCRE::Arg(&result->submatch[i]);
        argptr[i] = &a[i];
      }
      int consumed;
      PCRE::Anchor pcre_anchor;
      if (anchor == Prog::kAnchored)
        pcre_anchor = PCRE::ANCHOR_START;
      else
        pcre_anchor = PCRE::UNANCHORED;
      if (kind_ == Prog::kFullMatch)
        pcre_anchor = PCRE::ANCHOR_BOTH;
      re_->ClearHitLimit();
      result->matched =
        re_->DoMatch(text,
                     pcre_anchor,
                     &consumed,
                     argptr, nsubmatch);
      if (re_->HitLimit()) {
        result->untrusted = true;
        delete[] argptr;
        delete[] a;
        break;
      }
      result->have_submatch = true;

      // Work around RE interface bug: PCRE returns -1 as the
      // offsets for an unmatched subexpression, and RE should
      // turn that into StringPiece(NULL) but in fact it uses
      // StringPiece(text.begin() - 1, 0).  Oops.
      for (int i = 0; i < nsubmatch; i++)
        if (result->submatch[i].begin() == text.begin() - 1)
          result->submatch[i] = NULL;
      delete[] argptr;
      delete[] a;
      break;
    }
  }

  if (!result->matched)
    memset(result->submatch, 0, sizeof result->submatch);
}

// Checks whether r is okay given that correct is the right answer.
// Specifically, r's answers have to match (but it doesn't have to
// claim to have all the answers).
static bool ResultOkay(const Result& r, const Result& correct) {
  if (r.skipped)
    return true;
  if (r.matched != correct.matched)
    return false;
  if (r.have_submatch || r.have_submatch0) {
    for (int i = 0; i < kMaxSubmatch; i++) {
      if (correct.submatch[i].begin() != r.submatch[i].begin() ||
          correct.submatch[i].size() != r.submatch[i].size())
        return false;
      if (!r.have_submatch)
        break;
    }
  }
  return true;
}

// Runs a single test.
bool TestInstance::RunCase(const StringPiece& text, const StringPiece& context,
                           Prog::Anchor anchor) {
  // Backtracking is the gold standard.
  Result correct;
  RunSearch(kEngineBacktrack, text, context, anchor, &correct);
  if (correct.skipped) {
    if (regexp_ == NULL)
      return true;
    LOG(ERROR) << "Skipped backtracking! " << CEscape(regexp_str_)
               << " " << FormatMode(flags_);
    return false;
  }
  VLOG(1) << "Try: regexp " << CEscape(regexp_str_)
          << " text " << CEscape(text)
          << " (" << FormatKind(kind_)
          << ", " << FormatAnchor(anchor)
          << ", " << FormatMode(flags_)
          << ")";

  // Compare the others.
  bool all_okay = true;
  for (Engine i = kEngineBacktrack+1; i < kEngineMax; i++) {
    if (!(Engines() & (1<<i)))
      continue;

    Result r;
    RunSearch(i, text, context, anchor, &r);
    if (ResultOkay(r, correct)) {
      if (FLAGS_log_okay)
        LogMatch(r.skipped ? "Skipped: " : "Okay: ", i, text, context, anchor);
      continue;
    }

    // We disagree with PCRE on the meaning of some Unicode matches.
    // In particular, we treat all non-ASCII UTF-8 as word characters.
    // We also treat "empty" character sets like [^\w\W] as being
    // impossible to match, while PCRE apparently excludes some code
    // points (e.g., 0x0080) from both \w and \W.
    if (i == kEnginePCRE && NonASCII(text))
      continue;

    if (!r.untrusted)
      all_okay = false;

    LogMatch(r.untrusted ? "(Untrusted) Mismatch: " : "Mismatch: ", i, text,
             context, anchor);
    if (r.matched != correct.matched) {
      if (r.matched) {
        LOG(INFO) << "   Should not match (but does).";
      } else {
        LOG(INFO) << "   Should match (but does not).";
        continue;
      }
    }
    for (int i = 0; i < 1+num_captures_; i++) {
      if (r.submatch[i].begin() != correct.submatch[i].begin() ||
          r.submatch[i].end() != correct.submatch[i].end()) {
        LOG(INFO) <<
          StringPrintf("   $%d: should be %s is %s",
                       i,
                       FormatCapture(text, correct.submatch[i]).c_str(),
                       FormatCapture(text, r.submatch[i]).c_str());
      } else {
        LOG(INFO) <<
          StringPrintf("   $%d: %s ok", i,
                       FormatCapture(text, r.submatch[i]).c_str());
      }
    }
  }

  if (!all_okay) {
    if (FLAGS_max_regexp_failures > 0 && --FLAGS_max_regexp_failures == 0)
      LOG(QFATAL) << "Too many regexp failures.";
  }

  return all_okay;
}

void TestInstance::LogMatch(const char* prefix, Engine e,
                            const StringPiece& text, const StringPiece& context,
                            Prog::Anchor anchor) {
  LOG(INFO) << prefix
    << EngineString(e)
    << " regexp "
    << CEscape(regexp_str_)
    << " "
    << CEscape(regexp_->ToString())
    << " text "
    << CEscape(text)
    << " ("
    << text.begin() - context.begin()
    << ","
    << text.end() - context.begin()
    << ") of context "
    << CEscape(context)
    << " (" << FormatKind(kind_)
    << ", " << FormatAnchor(anchor)
    << ", " << FormatMode(flags_)
    << ")";
}

static Prog::MatchKind kinds[] = {
  Prog::kFirstMatch,
  Prog::kLongestMatch,
  Prog::kFullMatch,
};

// Test all possible match kinds and parse modes.
Tester::Tester(const StringPiece& regexp) {
  error_ = false;
  for (int i = 0; i < arraysize(kinds); i++) {
    for (int j = 0; j < arraysize(parse_modes); j++) {
      TestInstance* t = new TestInstance(regexp, kinds[i],
                                         parse_modes[j].parse_flags);
      error_ |= t->error();
      v_.push_back(t);
    }
  }
}

Tester::~Tester() {
  for (int i = 0; i < v_.size(); i++)
    delete v_[i];
}

bool Tester::TestCase(const StringPiece& text, const StringPiece& context,
                         Prog::Anchor anchor) {
  bool okay = true;
  for (int i = 0; i < v_.size(); i++)
    okay &= (!v_[i]->error() && v_[i]->RunCase(text, context, anchor));
  return okay;
}

static Prog::Anchor anchors[] = {
  Prog::kAnchored,
  Prog::kUnanchored
};

bool Tester::TestInput(const StringPiece& text) {
  bool okay = TestInputInContext(text, text);
  if (text.size() > 0) {
    StringPiece sp;
    sp = text;
    sp.remove_prefix(1);
    okay &= TestInputInContext(sp, text);
    sp = text;
    sp.remove_suffix(1);
    okay &= TestInputInContext(sp, text);
  }
  return okay;
}

bool Tester::TestInputInContext(const StringPiece& text,
                                const StringPiece& context) {
  bool okay = true;
  for (int i = 0; i < arraysize(anchors); i++)
    okay &= TestCase(text, context, anchors[i]);
  return okay;
}

bool TestRegexpOnText(const StringPiece& regexp,
                      const StringPiece& text) {
  Tester t(regexp);
  return t.TestInput(text);
}

}  // namespace re2
