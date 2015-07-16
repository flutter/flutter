// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Tested by search_test.cc, exhaustive_test.cc, tester.cc

// Prog::SearchBitState is a regular expression search with submatch
// tracking for small regular expressions and texts.  Like
// testing/backtrack.cc, it allocates a bit vector with (length of
// text) * (length of prog) bits, to make sure it never explores the
// same (character position, instruction) state multiple times.  This
// limits the search to run in time linear in the length of the text.
//
// Unlike testing/backtrack.cc, SearchBitState is not recursive
// on the text.
//
// SearchBitState is a fast replacement for the NFA code on small
// regexps and texts when SearchOnePass cannot be used.

#include "re2/prog.h"
#include "re2/regexp.h"

namespace re2 {

struct Job {
  int id;
  int arg;
  const char* p;
};

class BitState {
 public:
  explicit BitState(Prog* prog);
  ~BitState();

  // The usual Search prototype.
  // Can only call Search once per BitState.
  bool Search(const StringPiece& text, const StringPiece& context,
              bool anchored, bool longest,
              StringPiece* submatch, int nsubmatch);

 private:
  inline bool ShouldVisit(int id, const char* p);
  void Push(int id, const char* p, int arg);
  bool GrowStack();
  bool TrySearch(int id, const char* p);

  // Search parameters
  Prog* prog_;              // program being run
  StringPiece text_;        // text being searched
  StringPiece context_;     // greater context of text being searched
  bool anchored_;           // whether search is anchored at text.begin()
  bool longest_;            // whether search wants leftmost-longest match
  bool endmatch_;           // whether match must end at text.end()
  StringPiece *submatch_;   // submatches to fill in
  int nsubmatch_;           //   # of submatches to fill in

  // Search state
  const char** cap_;        // capture registers
  int ncap_;

  static const int VisitedBits = 32;
  uint32 *visited_;         // bitmap: (Inst*, char*) pairs already backtracked
  int nvisited_;            //   # of words in bitmap

  Job *job_;                // stack of text positions to explore
  int njob_;
  int maxjob_;
};

BitState::BitState(Prog* prog)
  : prog_(prog),
    anchored_(false),
    longest_(false),
    endmatch_(false),
    submatch_(NULL),
    nsubmatch_(0),
    cap_(NULL),
    ncap_(0),
    visited_(NULL),
    nvisited_(0),
    job_(NULL),
    njob_(0),
    maxjob_(0) {
}

BitState::~BitState() {
  delete[] visited_;
  delete[] job_;
  delete[] cap_;
}

// Should the search visit the pair ip, p?
// If so, remember that it was visited so that the next time,
// we don't repeat the visit.
bool BitState::ShouldVisit(int id, const char* p) {
  uint n = id * (text_.size() + 1) + (p - text_.begin());
  if (visited_[n/VisitedBits] & (1 << (n & (VisitedBits-1))))
    return false;
  visited_[n/VisitedBits] |= 1 << (n & (VisitedBits-1));
  return true;
}

// Grow the stack.
bool BitState::GrowStack() {
  // VLOG(0) << "Reallocate.";
  maxjob_ *= 2;
  Job* newjob = new Job[maxjob_];
  memmove(newjob, job_, njob_*sizeof job_[0]);
  delete[] job_;
  job_ = newjob;
  if (njob_ >= maxjob_) {
    LOG(DFATAL) << "Job stack overflow.";
    return false;
  }
  return true;
}

// Push the triple (id, p, arg) onto the stack, growing it if necessary.
void BitState::Push(int id, const char* p, int arg) {
  if (njob_ >= maxjob_) {
    if (!GrowStack())
      return;
  }
  int op = prog_->inst(id)->opcode();
  if (op == kInstFail)
    return;

  // Only check ShouldVisit when arg == 0.
  // When arg > 0, we are continuing a previous visit.
  if (arg == 0 && !ShouldVisit(id, p))
    return;

  Job* j = &job_[njob_++];
  j->id = id;
  j->p = p;
  j->arg = arg;
}

// Try a search from instruction id0 in state p0.
// Return whether it succeeded.
bool BitState::TrySearch(int id0, const char* p0) {
  bool matched = false;
  const char* end = text_.end();
  njob_ = 0;
  Push(id0, p0, 0);
  while (njob_ > 0) {
    // Pop job off stack.
    --njob_;
    int id = job_[njob_].id;
    const char* p = job_[njob_].p;
    int arg = job_[njob_].arg;

    // Optimization: rather than push and pop,
    // code that is going to Push and continue
    // the loop simply updates ip, p, and arg
    // and jumps to CheckAndLoop.  We have to
    // do the ShouldVisit check that Push
    // would have, but we avoid the stack
    // manipulation.
    if (0) {
    CheckAndLoop:
      if (!ShouldVisit(id, p))
        continue;
    }

    // Visit ip, p.
    // VLOG(0) << "Job: " << ip->id() << " "
    //         << (p - text_.begin()) << " " << arg;
    Prog::Inst* ip = prog_->inst(id);
    switch (ip->opcode()) {
      case kInstFail:
      default:
        LOG(DFATAL) << "Unexpected opcode: " << ip->opcode() << " arg " << arg;
        return false;

      case kInstAlt:
        // Cannot just
        //   Push(ip->out1(), p, 0);
        //   Push(ip->out(), p, 0);
        // If, during the processing of ip->out(), we encounter
        // ip->out1() via another path, we want to process it then.
        // Pushing it here will inhibit that.  Instead, re-push
        // ip with arg==1 as a reminder to push ip->out1() later.
        switch (arg) {
          case 0:
            Push(id, p, 1);  // come back when we're done
            id = ip->out();
            goto CheckAndLoop;

          case 1:
            // Finished ip->out(); try ip->out1().
            arg = 0;
            id = ip->out1();
            goto CheckAndLoop;
        }
        LOG(DFATAL) << "Bad arg in kInstCapture: " << arg;
        continue;

      case kInstAltMatch:
        // One opcode is byte range; the other leads to match.
        if (ip->greedy(prog_)) {
          // out1 is the match
          Push(ip->out1(), p, 0);
          id = ip->out1();
          p = end;
          goto CheckAndLoop;
        }
        // out is the match - non-greedy
        Push(ip->out(), end, 0);
        id = ip->out();
        goto CheckAndLoop;

      case kInstByteRange: {
        int c = -1;
        if (p < end)
          c = *p & 0xFF;
        if (ip->Matches(c)) {
          id = ip->out();
          p++;
          goto CheckAndLoop;
        }
        continue;
      }

      case kInstCapture:
        switch (arg) {
          case 0:
            if (0 <= ip->cap() && ip->cap() < ncap_) {
              // Capture p to register, but save old value.
              Push(id, cap_[ip->cap()], 1);  // come back when we're done
              cap_[ip->cap()] = p;
            }
            // Continue on.
            id = ip->out();
            goto CheckAndLoop;
          case 1:
            // Finished ip->out(); restore the old value.
            cap_[ip->cap()] = p;
            continue;
        }
        LOG(DFATAL) << "Bad arg in kInstCapture: " << arg;
        continue;

      case kInstEmptyWidth:
        if (ip->empty() & ~Prog::EmptyFlags(context_, p))
          continue;
        id = ip->out();
        goto CheckAndLoop;

      case kInstNop:
        id = ip->out();
        goto CheckAndLoop;

      case kInstMatch: {
        if (endmatch_ && p != text_.end())
          continue;

        // VLOG(0) << "Found match.";
        // We found a match.  If the caller doesn't care
        // where the match is, no point going further.
        if (nsubmatch_ == 0)
          return true;

        // Record best match so far.
        // Only need to check end point, because this entire
        // call is only considering one start position.
        matched = true;
        cap_[1] = p;
        if (submatch_[0].data() == NULL ||
            (longest_ && p > submatch_[0].end())) {
          for (int i = 0; i < nsubmatch_; i++)
            submatch_[i] = StringPiece(cap_[2*i], cap_[2*i+1] - cap_[2*i]);
        }

        // If going for first match, we're done.
        if (!longest_)
          return true;

        // If we used the entire text, no longer match is possible.
        if (p == text_.end())
          return true;

        // Otherwise, continue on in hope of a longer match.
        continue;
      }
    }
  }
  return matched;
}

// Search text (within context) for prog_.
bool BitState::Search(const StringPiece& text, const StringPiece& context,
                      bool anchored, bool longest,
                      StringPiece* submatch, int nsubmatch) {
  // Search parameters.
  text_ = text;
  context_ = context;
  if (context_.begin() == NULL)
    context_ = text;
  if (prog_->anchor_start() && context_.begin() != text.begin())
    return false;
  if (prog_->anchor_end() && context_.end() != text.end())
    return false;
  anchored_ = anchored || prog_->anchor_start();
  longest_ = longest || prog_->anchor_end();
  endmatch_ = prog_->anchor_end();
  submatch_ = submatch;
  nsubmatch_ = nsubmatch;
  for (int i = 0; i < nsubmatch_; i++)
    submatch_[i] = NULL;

  // Allocate scratch space.
  nvisited_ = (prog_->size() * (text.size()+1) + VisitedBits-1) / VisitedBits;
  visited_ = new uint32[nvisited_];
  memset(visited_, 0, nvisited_*sizeof visited_[0]);
  // VLOG(0) << "nvisited_ = " << nvisited_;

  ncap_ = 2*nsubmatch;
  if (ncap_ < 2)
    ncap_ = 2;
  cap_ = new const char*[ncap_];
  memset(cap_, 0, ncap_*sizeof cap_[0]);

  maxjob_ = 256;
  job_ = new Job[maxjob_];

  // Anchored search must start at text.begin().
  if (anchored_) {
    cap_[0] = text.begin();
    return TrySearch(prog_->start(), text.begin());
  }

  // Unanchored search, starting from each possible text position.
  // Notice that we have to try the empty string at the end of
  // the text, so the loop condition is p <= text.end(), not p < text.end().
  // This looks like it's quadratic in the size of the text,
  // but we are not clearing visited_ between calls to TrySearch,
  // so no work is duplicated and it ends up still being linear.
  for (const char* p = text.begin(); p <= text.end(); p++) {
    cap_[0] = p;
    if (TrySearch(prog_->start(), p))  // Match must be leftmost; done.
      return true;
  }
  return false;
}

// Bit-state search.
bool Prog::SearchBitState(const StringPiece& text,
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
  BitState b(this);
  bool anchored = anchor == kAnchored;
  bool longest = kind != kFirstMatch;
  if (!b.Search(text, context, anchored, longest, match, nmatch))
    return false;
  if (kind == kFullMatch && match[0].end() != text.end())
    return false;
  return true;
}

}  // namespace re2
