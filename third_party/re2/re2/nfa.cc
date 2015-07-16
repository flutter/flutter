// Copyright 2006-2007 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Tested by search_test.cc.
//
// Prog::SearchNFA, an NFA search.
// This is an actual NFA like the theorists talk about,
// not the pseudo-NFA found in backtracking regexp implementations.
//
// IMPLEMENTATION
//
// This algorithm is a variant of one that appeared in Rob Pike's sam editor,
// which is a variant of the one described in Thompson's 1968 CACM paper.
// See http://swtch.com/~rsc/regexp/ for various history.  The main feature
// over the DFA implementation is that it tracks submatch boundaries.
//
// When the choice of submatch boundaries is ambiguous, this particular
// implementation makes the same choices that traditional backtracking
// implementations (in particular, Perl and PCRE) do.
// Note that unlike in Perl and PCRE, this algorithm *cannot* take exponential
// time in the length of the input.
//
// Like Thompson's original machine and like the DFA implementation, this
// implementation notices a match only once it is one byte past it.

#include "re2/prog.h"
#include "re2/regexp.h"
#include "util/sparse_array.h"
#include "util/sparse_set.h"

namespace re2 {

class NFA {
 public:
  NFA(Prog* prog);
  ~NFA();

  // Searches for a matching string.
  //   * If anchored is true, only considers matches starting at offset.
  //     Otherwise finds lefmost match at or after offset.
  //   * If longest is true, returns the longest match starting
  //     at the chosen start point.  Otherwise returns the so-called
  //     left-biased match, the one traditional backtracking engines
  //     (like Perl and PCRE) find.
  // Records submatch boundaries in submatch[1..nsubmatch-1].
  // Submatch[0] is the entire match.  When there is a choice in
  // which text matches each subexpression, the submatch boundaries
  // are chosen to match what a backtracking implementation would choose.
  bool Search(const StringPiece& text, const StringPiece& context,
              bool anchored, bool longest,
              StringPiece* submatch, int nsubmatch);

  static const int Debug = 0;

 private:
  struct Thread {
    union {
      int id;
      Thread* next;  // when on free list
    };
    const char** capture;
  };

  // State for explicit stack in AddToThreadq.
  struct AddState {
    int id;           // Inst to process
    int j;
    const char* cap_j;  // if j>=0, set capture[j] = cap_j before processing ip

    AddState()
      : id(0), j(-1), cap_j(NULL) {}
    explicit AddState(int id)
      : id(id), j(-1), cap_j(NULL) {}
    AddState(int id, const char* cap_j, int j)
      : id(id), j(j), cap_j(cap_j) {}
  };

  // Threadq is a list of threads.  The list is sorted by the order
  // in which Perl would explore that particular state -- the earlier
  // choices appear earlier in the list.
  typedef SparseArray<Thread*> Threadq;

  inline Thread* AllocThread();
  inline void FreeThread(Thread*);

  // Add id (or its children, following unlabeled arrows)
  // to the workqueue q with associated capture info.
  void AddToThreadq(Threadq* q, int id, int flag,
                    const char* p, const char** capture);

  // Run runq on byte c, appending new states to nextq.
  // Updates matched_ and match_ as new, better matches are found.
  // p is position of the next byte (the one after c)
  // in the input string, used when processing capturing parens.
  // flag is the bitwise or of Bol, Eol, etc., specifying whether
  // ^, $ and \b match the current input point (after c).
  inline int Step(Threadq* runq, Threadq* nextq, int c, int flag, const char* p);

  // Returns text version of capture information, for debugging.
  string FormatCapture(const char** capture);

  inline void CopyCapture(const char** dst, const char** src);

  // Computes whether all matches must begin with the same first
  // byte, and if so, returns that byte.  If not, returns -1.
  int ComputeFirstByte();

  Prog* prog_;          // underlying program
  int start_;           // start instruction in program
  int ncapture_;        // number of submatches to track
  bool longest_;        // whether searching for longest match
  bool endmatch_;       // whether match must end at text.end()
  const char* btext_;   // beginning of text being matched (for FormatSubmatch)
  const char* etext_;   // end of text being matched (for endmatch_)
  Threadq q0_, q1_;     // pre-allocated for Search.
  const char** match_;  // best match so far
  bool matched_;        // any match so far?
  AddState* astack_;    // pre-allocated for AddToThreadq
  int nastack_;
  int first_byte_;      // required first byte for match, or -1 if none

  Thread* free_threads_;  // free list

  DISALLOW_EVIL_CONSTRUCTORS(NFA);
};

NFA::NFA(Prog* prog) {
  prog_ = prog;
  start_ = prog->start();
  ncapture_ = 0;
  longest_ = false;
  endmatch_ = false;
  btext_ = NULL;
  etext_ = NULL;
  q0_.resize(prog_->size());
  q1_.resize(prog_->size());
  nastack_ = 2*prog_->size();
  astack_ = new AddState[nastack_];
  match_ = NULL;
  matched_ = false;
  free_threads_ = NULL;
  first_byte_ = ComputeFirstByte();
}

NFA::~NFA() {
  delete[] match_;
  delete[] astack_;
  Thread* next;
  for (Thread* t = free_threads_; t; t = next) {
    next = t->next;
    delete[] t->capture;
    delete t;
  }
}

void NFA::FreeThread(Thread *t) {
  if (t == NULL)
    return;
  t->next = free_threads_;
  free_threads_ = t;
}

NFA::Thread* NFA::AllocThread() {
  Thread* t = free_threads_;
  if (t == NULL) {
    t = new Thread;
    t->capture = new const char*[ncapture_];
    return t;
  }
  free_threads_ = t->next;
  return t;
}

void NFA::CopyCapture(const char** dst, const char** src) {
  for (int i = 0; i < ncapture_; i+=2) {
    dst[i] = src[i];
    dst[i+1] = src[i+1];
  }
}

// Follows all empty arrows from id0 and enqueues all the states reached.
// The bits in flag (Bol, Eol, etc.) specify whether ^, $ and \b match.
// The pointer p is the current input position, and m is the
// current set of match boundaries.
void NFA::AddToThreadq(Threadq* q, int id0, int flag,
                       const char* p, const char** capture) {
  if (id0 == 0)
    return;

  // Astack_ is pre-allocated to avoid resize operations.
  // It has room for 2*prog_->size() entries, which is enough:
  // Each inst in prog can be processed at most once,
  // pushing at most two entries on stk.

  int nstk = 0;
  AddState* stk = astack_;
  stk[nstk++] = AddState(id0);

  while (nstk > 0) {
    DCHECK_LE(nstk, nastack_);
    const AddState& a = stk[--nstk];
    if (a.j >= 0)
      capture[a.j] = a.cap_j;

    int id = a.id;
    if (id == 0)
      continue;
    if (q->has_index(id)) {
      if (Debug)
        fprintf(stderr, "  [%d%s]\n", id, FormatCapture(capture).c_str());
      continue;
    }

    // Create entry in q no matter what.  We might fill it in below,
    // or we might not.  Even if not, it is necessary to have it,
    // so that we don't revisit id0 during the recursion.
    q->set_new(id, NULL);

    Thread** tp = &q->find(id)->second;
    int j;
    Thread* t;
    Prog::Inst* ip = prog_->inst(id);
    switch (ip->opcode()) {
    default:
      LOG(DFATAL) << "unhandled " << ip->opcode() << " in AddToThreadq";
      break;

    case kInstFail:
      break;

    case kInstAltMatch:
      // Save state; will pick up at next byte.
      t = AllocThread();
      t->id = id;
      CopyCapture(t->capture, capture);
      *tp = t;
      // fall through

    case kInstAlt:
      // Explore alternatives.
      stk[nstk++] = AddState(ip->out1());
      stk[nstk++] = AddState(ip->out());
      break;

    case kInstNop:
      // Continue on.
      stk[nstk++] = AddState(ip->out());
      break;

    case kInstCapture:
      if ((j=ip->cap()) < ncapture_) {
        // Push a dummy whose only job is to restore capture[j]
        // once we finish exploring this possibility.
        stk[nstk++] = AddState(0, capture[j], j);

        // Record capture.
        capture[j] = p;
      }
      stk[nstk++] = AddState(ip->out());
      break;

    case kInstMatch:
    case kInstByteRange:
      // Save state; will pick up at next byte.
      t = AllocThread();
      t->id = id;
      CopyCapture(t->capture, capture);
      *tp = t;
      if (Debug)
        fprintf(stderr, " + %d%s [%p]\n", id, FormatCapture(t->capture).c_str(), t);
      break;

    case kInstEmptyWidth:
      // Continue on if we have all the right flag bits.
      if (ip->empty() & ~flag)
        break;
      stk[nstk++] = AddState(ip->out());
      break;
    }
  }
}

// Run runq on byte c, appending new states to nextq.
// Updates match as new, better matches are found.
// p is position of the byte c in the input string,
// used when processing capturing parens.
// flag is the bitwise or of Bol, Eol, etc., specifying whether
// ^, $ and \b match the current input point (after c).
// Frees all the threads on runq.
// If there is a shortcut to the end, returns that shortcut.
int NFA::Step(Threadq* runq, Threadq* nextq, int c, int flag, const char* p) {
  nextq->clear();

  for (Threadq::iterator i = runq->begin(); i != runq->end(); ++i) {
    Thread* t = i->second;
    if (t == NULL)
      continue;

    if (longest_) {
      // Can skip any threads started after our current best match.
      if (matched_ && match_[0] < t->capture[0]) {
        FreeThread(t);
        continue;
      }
    }

    int id = t->id;
    Prog::Inst* ip = prog_->inst(id);

    switch (ip->opcode()) {
      default:
        // Should only see the values handled below.
        LOG(DFATAL) << "Unhandled " << ip->opcode() << " in step";
        break;

      case kInstByteRange:
        if (ip->Matches(c))
          AddToThreadq(nextq, ip->out(), flag, p+1, t->capture);
        break;

      case kInstAltMatch:
        if (i != runq->begin())
          break;
        // The match is ours if we want it.
        if (ip->greedy(prog_) || longest_) {
          CopyCapture((const char**)match_, t->capture);
          FreeThread(t);
          for (++i; i != runq->end(); ++i)
            FreeThread(i->second);
          runq->clear();
          matched_ = true;
          if (ip->greedy(prog_))
            return ip->out1();
          return ip->out();
        }
        break;

      case kInstMatch:
        if (endmatch_ && p != etext_)
          break;

        const char* old = t->capture[1];  // previous end pointer
        t->capture[1] = p;
        if (longest_) {
          // Leftmost-longest mode: save this match only if
          // it is either farther to the left or at the same
          // point but longer than an existing match.
          if (!matched_ || t->capture[0] < match_[0] ||
              (t->capture[0] == match_[0] && t->capture[1] > match_[1]))
            CopyCapture((const char**)match_, t->capture);
        } else {
          // Leftmost-biased mode: this match is by definition
          // better than what we've already found (see next line).
          CopyCapture((const char**)match_, t->capture);

          // Cut off the threads that can only find matches
          // worse than the one we just found: don't run the
          // rest of the current Threadq.
          t->capture[0] = old;
          FreeThread(t);
          for (++i; i != runq->end(); ++i)
            FreeThread(i->second);
          runq->clear();
          matched_ = true;
          return 0;
        }
        t->capture[0] = old;
        matched_ = true;
        break;
    }
    FreeThread(t);
  }
  runq->clear();
  return 0;
}

string NFA::FormatCapture(const char** capture) {
  string s;

  for (int i = 0; i < ncapture_; i+=2) {
    if (capture[i] == NULL)
      StringAppendF(&s, "(?,?)");
    else if (capture[i+1] == NULL)
      StringAppendF(&s, "(%d,?)", (int)(capture[i] - btext_));
    else
      StringAppendF(&s, "(%d,%d)",
                    (int)(capture[i] - btext_),
                    (int)(capture[i+1] - btext_));
  }
  return s;
}

// Returns whether haystack contains needle's memory.
static bool StringPieceContains(const StringPiece haystack, const StringPiece needle) {
  return haystack.begin() <= needle.begin() &&
         haystack.end() >= needle.end();
}

bool NFA::Search(const StringPiece& text, const StringPiece& const_context,
            bool anchored, bool longest,
            StringPiece* submatch, int nsubmatch) {
  if (start_ == 0)
    return false;

  StringPiece context = const_context;
  if (context.begin() == NULL)
    context = text;

  if (!StringPieceContains(context, text)) {
    LOG(FATAL) << "Bad args: context does not contain text "
                << reinterpret_cast<const void*>(context.begin())
                << "+" << context.size() << " "
                << reinterpret_cast<const void*>(text.begin())
                << "+" << text.size();
    return false;
  }

  if (prog_->anchor_start() && context.begin() != text.begin())
    return false;
  if (prog_->anchor_end() && context.end() != text.end())
    return false;
  anchored |= prog_->anchor_start();
  if (prog_->anchor_end()) {
    longest = true;
    endmatch_ = true;
    etext_ = text.end();
  }

  if (nsubmatch < 0) {
    LOG(DFATAL) << "Bad args: nsubmatch=" << nsubmatch;
    return false;
  }

  // Save search parameters.
  ncapture_ = 2*nsubmatch;
  longest_ = longest;

  if (nsubmatch == 0) {
    // We need to maintain match[0], both to distinguish the
    // longest match (if longest is true) and also to tell
    // whether we've seen any matches at all.
    ncapture_ = 2;
  }

  match_ = new const char*[ncapture_];
  matched_ = false;
  memset(match_, 0, ncapture_*sizeof match_[0]);

  // For debugging prints.
  btext_ = context.begin();

  if (Debug) {
    fprintf(stderr, "NFA::Search %s (context: %s) anchored=%d longest=%d\n",
            text.as_string().c_str(), context.as_string().c_str(), anchored,
            longest);
  }

  // Set up search.
  Threadq* runq = &q0_;
  Threadq* nextq = &q1_;
  runq->clear();
  nextq->clear();
  memset(&match_[0], 0, ncapture_*sizeof match_[0]);
  const char* bp = context.begin();
  int c = -1;
  int wasword = 0;

  if (text.begin() > context.begin()) {
    c = text.begin()[-1] & 0xFF;
    wasword = Prog::IsWordChar(c);
  }

  // Loop over the text, stepping the machine.
  for (const char* p = text.begin();; p++) {
    // Check for empty-width specials.
    int flag = 0;

    // ^ and \A
    if (p == context.begin())
      flag |= kEmptyBeginText | kEmptyBeginLine;
    else if (p <= context.end() && p[-1] == '\n')
      flag |= kEmptyBeginLine;

    // $ and \z
    if (p == context.end())
      flag |= kEmptyEndText | kEmptyEndLine;
    else if (p < context.end() && p[0] == '\n')
      flag |= kEmptyEndLine;

    // \b and \B
    int isword = 0;
    if (p < context.end())
      isword = Prog::IsWordChar(p[0] & 0xFF);

    if (isword != wasword)
      flag |= kEmptyWordBoundary;
    else
      flag |= kEmptyNonWordBoundary;

    if (Debug) {
      fprintf(stderr, "%c[%#x/%d/%d]:", p > text.end() ? '$' : p == bp ? '^' : c, flag, isword, wasword);
      for (Threadq::iterator i = runq->begin(); i != runq->end(); ++i) {
        Thread* t = i->second;
        if (t == NULL)
          continue;
        fprintf(stderr, " %d%s", t->id,
                FormatCapture((const char**)t->capture).c_str());
      }
      fprintf(stderr, "\n");
    }

    // Process previous character (waited until now to avoid
    // repeating the flag computation above).
    // This is a no-op the first time around the loop, because
    // runq is empty.
    int id = Step(runq, nextq, c, flag, p-1);
    DCHECK_EQ(runq->size(), 0);
    swap(nextq, runq);
    nextq->clear();
    if (id != 0) {
      // We're done: full match ahead.
      p = text.end();
      for (;;) {
        Prog::Inst* ip = prog_->inst(id);
        switch (ip->opcode()) {
          default:
            LOG(DFATAL) << "Unexpected opcode in short circuit: " << ip->opcode();
            break;

          case kInstCapture:
            match_[ip->cap()] = p;
            id = ip->out();
            continue;

          case kInstNop:
            id = ip->out();
            continue;

          case kInstMatch:
            match_[1] = p;
            matched_ = true;
            break;

          case kInstEmptyWidth:
            if (ip->empty() & ~(kEmptyEndLine|kEmptyEndText)) {
              LOG(DFATAL) << "Unexpected empty-width in short circuit: " << ip->empty();
              break;
            }
            id = ip->out();
            continue;
        }
        break;
      }
      break;
    }

    if (p > text.end())
      break;

    // Start a new thread if there have not been any matches.
    // (No point in starting a new thread if there have been
    // matches, since it would be to the right of the match
    // we already found.)
    if (!matched_ && (!anchored || p == text.begin())) {
      // If there's a required first byte for an unanchored search
      // and we're not in the middle of any possible matches,
      // use memchr to search for the byte quickly.
      if (!anchored && first_byte_ >= 0 && runq->size() == 0 &&
          p < text.end() && (p[0] & 0xFF) != first_byte_) {
        p = reinterpret_cast<const char*>(memchr(p, first_byte_,
                                                 text.end() - p));
        if (p == NULL) {
          p = text.end();
          isword = 0;
        } else {
          isword = Prog::IsWordChar(p[0] & 0xFF);
        }
        flag = Prog::EmptyFlags(context, p);
      }

      // Steal match storage (cleared but unused as of yet)
      // temporarily to hold match boundaries for new thread.
      match_[0] = p;
      AddToThreadq(runq, start_, flag, p, match_);
      match_[0] = NULL;
    }

    // If all the threads have died, stop early.
    if (runq->size() == 0) {
      if (Debug)
        fprintf(stderr, "dead\n");
      break;
    }

    if (p == text.end())
      c = 0;
    else
      c = *p & 0xFF;
    wasword = isword;

    // Will run step(runq, nextq, c, ...) on next iteration.  See above.
  }

  for (Threadq::iterator i = runq->begin(); i != runq->end(); ++i)
    FreeThread(i->second);

  if (matched_) {
    for (int i = 0; i < nsubmatch; i++)
      submatch[i].set(match_[2*i], match_[2*i+1] - match_[2*i]);
    if (Debug)
      fprintf(stderr, "match (%d,%d)\n",
              static_cast<int>(match_[0] - btext_),
              static_cast<int>(match_[1] - btext_));
    return true;
  }
  VLOG(1) << "No matches found";
  return false;
}

// Computes whether all successful matches have a common first byte,
// and if so, returns that byte.  If not, returns -1.
int NFA::ComputeFirstByte() {
  if (start_ == 0)
    return -1;

  int b = -1;  // first byte, not yet computed

  typedef SparseSet Workq;
  Workq q(prog_->size());
  q.insert(start_);
  for (Workq::iterator it = q.begin(); it != q.end(); ++it) {
    int id = *it;
    Prog::Inst* ip = prog_->inst(id);
    switch (ip->opcode()) {
      default:
        LOG(DFATAL) << "unhandled " << ip->opcode() << " in ComputeFirstByte";
        break;

      case kInstMatch:
        // The empty string matches: no first byte.
        return -1;

      case kInstByteRange:
        // Must match only a single byte
        if (ip->lo() != ip->hi())
          return -1;
        if (ip->foldcase() && 'a' <= ip->lo() && ip->lo() <= 'z')
          return -1;
        // If we haven't seen any bytes yet, record it;
        // otherwise must match the one we saw before.
        if (b == -1)
          b = ip->lo();
        else if (b != ip->lo())
          return -1;
        break;

      case kInstNop:
      case kInstCapture:
      case kInstEmptyWidth:
        // Continue on.
        // Ignore ip->empty() flags for kInstEmptyWidth
        // in order to be as conservative as possible
        // (assume all possible empty-width flags are true).
        if (ip->out())
          q.insert(ip->out());
        break;

      case kInstAlt:
      case kInstAltMatch:
        // Explore alternatives.
        if (ip->out())
          q.insert(ip->out());
        if (ip->out1())
          q.insert(ip->out1());
        break;

      case kInstFail:
        break;
    }
  }
  return b;
}

bool
Prog::SearchNFA(const StringPiece& text, const StringPiece& context,
                Anchor anchor, MatchKind kind,
                StringPiece* match, int nmatch) {
  if (NFA::Debug)
    Dump();

  NFA nfa(this);
  StringPiece sp;
  if (kind == kFullMatch) {
    anchor = kAnchored;
    if (nmatch == 0) {
      match = &sp;
      nmatch = 1;
    }
  }
  if (!nfa.Search(text, context, anchor == kAnchored, kind != kFirstMatch, match, nmatch))
    return false;
  if (kind == kFullMatch && match[0].end() != text.end())
    return false;
  return true;
}

}  // namespace re2

