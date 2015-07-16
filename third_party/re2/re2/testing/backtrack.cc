// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Tested by search_test.cc, exhaustive_test.cc, tester.cc
//
// Prog::BadSearchBacktrack is a backtracking regular expression search,
// except that it remembers where it has been, trading a lot of
// memory for a lot of time. It exists only for testing purposes.
//
// Let me repeat that.
//
// THIS CODE SHOULD NEVER BE USED IN PRODUCTION:
//   - It uses a ton of memory.
//   - It uses a ton of stack.
//   - It uses CHECK and LOG(FATAL).
//   - It implements unanchored search by repeated anchored search.
//
// On the other hand, it is very simple and a good reference
// implementation for the more complicated regexp packages.
//
// In BUILD, this file is linked into the ":testing" library,
// not the main library, in order to make it harder to pick up
// accidentally.

#include "util/util.h"
#include "re2/prog.h"
#include "re2/regexp.h"

namespace re2 {

// Backtracker holds the state for a backtracking search.
//
// Excluding the search parameters, the main search state
// is just the "capture registers", which record, for the
// current execution, the string position at which each
// parenthesis was passed.  cap_[0] and cap_[1] are the
// left and right parenthesis in $0, cap_[2] and cap_[3] in $1, etc.
//
// To avoid infinite loops during backtracking on expressions
// like (a*)*, the visited_[] bitmap marks the (state, string-position)
// pairs that have already been explored and are thus not worth
// re-exploring if we get there via another path.  Modern backtracking
// libraries engineer their program representation differently, to make
// such infinite loops possible to avoid without keeping a giant visited_
// bitmap, but visited_ works fine for a reference implementation
// and it has the nice benefit of making the search run in linear time.
class Backtracker {
 public:
  explicit Backtracker(Prog* prog);
  ~Backtracker();

  bool Search(const StringPiece& text, const StringPiece& context,
              bool anchored, bool longest,
              StringPiece* submatch, int nsubmatch);

 private:
  // Explores from instruction ip at string position p looking for a match.
  // Returns true if found (so that caller can stop trying other possibilities).
  bool Visit(int id, const char* p);

  // Search parameters
  Prog* prog_;              // program being run
  StringPiece text_;        // text being searched
  StringPiece context_;     // greater context of text being searched
  bool anchored_;           // whether search is anchored at text.begin()
  bool longest_;            // whether search wants leftmost-longest match
  bool endmatch_;           // whether search must end at text.end()
  StringPiece *submatch_;   // submatches to fill in
  int nsubmatch_;           //   # of submatches to fill in

  // Search state
  const char* cap_[64];     // capture registers
  uint32 *visited_;         // bitmap: (Inst*, char*) pairs already backtracked
  int nvisited_;            //   # of words in bitmap
};

Backtracker::Backtracker(Prog* prog)
  : prog_(prog),
    anchored_(false),
    longest_(false),
    endmatch_(false),
    submatch_(NULL),
    nsubmatch_(0),
    visited_(NULL),
    nvisited_(0) {
}

Backtracker::~Backtracker() {
  delete[] visited_;
}

// Runs a backtracking search.
bool Backtracker::Search(const StringPiece& text, const StringPiece& context,
                         bool anchored, bool longest,
                         StringPiece* submatch, int nsubmatch) {
  text_ = text;
  context_ = context;
  if (context_.begin() == NULL)
    context_ = text;
  if (prog_->anchor_start() && text.begin() > context_.begin())
    return false;
  if (prog_->anchor_end() && text.end() < context_.end())
    return false;
  anchored_ = anchored | prog_->anchor_start();
  longest_ = longest | prog_->anchor_end();
  endmatch_ = prog_->anchor_end();
  submatch_ = submatch;
  nsubmatch_ = nsubmatch;
  CHECK(2*nsubmatch_ < arraysize(cap_));
  memset(cap_, 0, sizeof cap_);

  // We use submatch_[0] for our own bookkeeping,
  // so it had better exist.
  StringPiece sp0;
  if (nsubmatch < 1) {
    submatch_ = &sp0;
    nsubmatch_ = 1;
  }
  submatch_[0] = NULL;

  // Allocate new visited_ bitmap -- size is proportional
  // to text, so have to reallocate on each call to Search.
  delete[] visited_;
  nvisited_ = (prog_->size()*(text.size()+1) + 31)/32;
  visited_ = new uint32[nvisited_];
  memset(visited_, 0, nvisited_*sizeof visited_[0]);

  // Anchored search must start at text.begin().
  if (anchored_) {
    cap_[0] = text.begin();
    return Visit(prog_->start(), text.begin());
  }

  // Unanchored search, starting from each possible text position.
  // Notice that we have to try the empty string at the end of
  // the text, so the loop condition is p <= text.end(), not p < text.end().
  for (const char* p = text.begin(); p <= text.end(); p++) {
    cap_[0] = p;
    if (Visit(prog_->start(), p))  // Match must be leftmost; done.
      return true;
  }
  return false;
}

// Explores from instruction ip at string position p looking for a match.
// Return true if found (so that caller can stop trying other possibilities).
bool Backtracker::Visit(int id, const char* p) {
  // Check bitmap.  If we've already explored from here,
  // either it didn't match or it did but we're hoping for a better match.
  // Either way, don't go down that road again.
  CHECK(p <= text_.end());
  int n = id*(text_.size()+1) + (p - text_.begin());
  CHECK_LT(n/32, nvisited_);
  if (visited_[n/32] & (1 << (n&31)))
    return false;
  visited_[n/32] |= 1 << (n&31);

  // Pick out byte at current position.  If at end of string,
  // have to explore in hope of finishing a match.  Use impossible byte -1.
  int c = -1;
  if (p < text_.end())
    c = *p & 0xFF;

  Prog::Inst* ip = prog_->inst(id);
  switch (ip->opcode()) {
    default:
      LOG(FATAL) << "Unexpected opcode: " << (int)ip->opcode();
      return false;  // not reached

    case kInstAlt:
    case kInstAltMatch:
      // Try both possible next states: out is preferred to out1.
      if (Visit(ip->out(), p)) {
        if (longest_)
          Visit(ip->out1(), p);
        return true;
      }
      return Visit(ip->out1(), p);

    case kInstByteRange:
      if (ip->Matches(c))
        return Visit(ip->out(), p+1);
      return false;

    case kInstCapture:
      if (0 <= ip->cap() && ip->cap() < arraysize(cap_)) {
        // Capture p to register, but save old value.
        const char* q = cap_[ip->cap()];
        cap_[ip->cap()] = p;
        bool ret = Visit(ip->out(), p);
        // Restore old value as we backtrack.
        cap_[ip->cap()] = q;
        return ret;
      }
      return Visit(ip->out(), p);

    case kInstEmptyWidth:
      if (ip->empty() & ~Prog::EmptyFlags(context_, p))
        return false;
      return Visit(ip->out(), p);

    case kInstNop:
      return Visit(ip->out(), p);

    case kInstMatch:
      // We found a match.  If it's the best so far, record the
      // parameters in the caller's submatch_ array.
      if (endmatch_ && p != context_.end())
        return false;
      cap_[1] = p;
      if (submatch_[0].data() == NULL ||           // First match so far ...
          (longest_ && p > submatch_[0].end())) {  // ... or better match
        for (int i = 0; i < nsubmatch_; i++)
          submatch_[i] = StringPiece(cap_[2*i], cap_[2*i+1] - cap_[2*i]);
      }
      return true;

    case kInstFail:
      return false;
  }
}

// Runs a backtracking search.
bool Prog::UnsafeSearchBacktrack(const StringPiece& text,
                                 const StringPiece& context,
                                 Anchor anchor,
                                 MatchKind kind,
                                 StringPiece* match,
                                 int nmatch) {
  // If full match, we ask for an anchored longest match
  // and then check that match[0] == text.
  // So make sure match[0] exists.
  StringPiece sp0;
  if (kind == kFullMatch) {
    anchor = kAnchored;
    if (nmatch < 1) {
      match = &sp0;
      nmatch = 1;
    }
  }

  // Run the search.
  Backtracker b(this);
  bool anchored = anchor == kAnchored;
  bool longest = kind != kFirstMatch;
  if (!b.Search(text, context, anchored, longest, match, nmatch))
    return false;
  if (kind == kFullMatch && match[0].end() != text.end())
    return false;
  return true;
}

}  // namespace re2
