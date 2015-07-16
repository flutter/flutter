// Copyright 2007 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Compiled representation of regular expressions.
// See regexp.h for the Regexp class, which represents a regular
// expression symbolically.

#ifndef RE2_PROG_H__
#define RE2_PROG_H__

#include "util/util.h"
#include "re2/re2.h"

namespace re2 {

// Simple fixed-size bitmap.
template<int Bits>
class Bitmap {
 public:
  Bitmap() { Reset(); }
  int Size() { return Bits; }

  void Reset() {
    for (int i = 0; i < Words; i++)
      w_[i] = 0;
  }
  bool Get(int k) const {
    return w_[k >> WordLog] & (1<<(k & 31));
  }
  void Set(int k) {
    w_[k >> WordLog] |= 1<<(k & 31);
  }
  void Clear(int k) {
    w_[k >> WordLog] &= ~(1<<(k & 31));
  }
  uint32 Word(int i) const {
    return w_[i];
  }

 private:
  static const int WordLog = 5;
  static const int Words = (Bits+31)/32;
  uint32 w_[Words];
  DISALLOW_EVIL_CONSTRUCTORS(Bitmap);
};


// Opcodes for Inst
enum InstOp {
  kInstAlt = 0,      // choose between out_ and out1_
  kInstAltMatch,     // Alt: out_ is [00-FF] and back, out1_ is match; or vice versa.
  kInstByteRange,    // next (possible case-folded) byte must be in [lo_, hi_]
  kInstCapture,      // capturing parenthesis number cap_
  kInstEmptyWidth,   // empty-width special (^ $ ...); bit(s) set in empty_
  kInstMatch,        // found a match!
  kInstNop,          // no-op; occasionally unavoidable
  kInstFail,         // never match; occasionally unavoidable
};

// Bit flags for empty-width specials
enum EmptyOp {
  kEmptyBeginLine        = 1<<0,      // ^ - beginning of line
  kEmptyEndLine          = 1<<1,      // $ - end of line
  kEmptyBeginText        = 1<<2,      // \A - beginning of text
  kEmptyEndText          = 1<<3,      // \z - end of text
  kEmptyWordBoundary     = 1<<4,      // \b - word boundary
  kEmptyNonWordBoundary  = 1<<5,      // \B - not \b
  kEmptyAllFlags         = (1<<6)-1,
};

class Regexp;

class DFA;
struct OneState;

// Compiled form of regexp program.
class Prog {
 public:
  Prog();
  ~Prog();

  // Single instruction in regexp program.
  class Inst {
   public:
    Inst() : out_opcode_(0), out1_(0) { }

    // Constructors per opcode
    void InitAlt(uint32 out, uint32 out1);
    void InitByteRange(int lo, int hi, int foldcase, uint32 out);
    void InitCapture(int cap, uint32 out);
    void InitEmptyWidth(EmptyOp empty, uint32 out);
    void InitMatch(int id);
    void InitNop(uint32 out);
    void InitFail();

    // Getters
    int id(Prog* p) { return this - p->inst_; }
    InstOp opcode() { return static_cast<InstOp>(out_opcode_&7); }
    int out()     { return out_opcode_>>3; }
    int out1()    { DCHECK(opcode() == kInstAlt || opcode() == kInstAltMatch); return out1_; }
    int cap()       { DCHECK_EQ(opcode(), kInstCapture); return cap_; }
    int lo()        { DCHECK_EQ(opcode(), kInstByteRange); return lo_; }
    int hi()        { DCHECK_EQ(opcode(), kInstByteRange); return hi_; }
    int foldcase()  { DCHECK_EQ(opcode(), kInstByteRange); return foldcase_; }
    int match_id()  { DCHECK_EQ(opcode(), kInstMatch); return match_id_; }
    EmptyOp empty() { DCHECK_EQ(opcode(), kInstEmptyWidth); return empty_; }
    bool greedy(Prog *p) {
      DCHECK_EQ(opcode(), kInstAltMatch);
      return p->inst(out())->opcode() == kInstByteRange;
    }

    // Does this inst (an kInstByteRange) match c?
    inline bool Matches(int c) {
      DCHECK_EQ(opcode(), kInstByteRange);
      if (foldcase_ && 'A' <= c && c <= 'Z')
        c += 'a' - 'A';
      return lo_ <= c && c <= hi_;
    }

    // Returns string representation for debugging.
    string Dump();

    // Maximum instruction id.
    // (Must fit in out_opcode_, and PatchList steals another bit.)
    static const int kMaxInst = (1<<28) - 1;

   private:
    void set_opcode(InstOp opcode) {
      out_opcode_ = (out()<<3) | opcode;
    }

    void set_out(int out) {
      out_opcode_ = (out<<3) | opcode();
    }

    void set_out_opcode(int out, InstOp opcode) {
      out_opcode_ = (out<<3) | opcode;
    }

    uint32 out_opcode_;  // 29 bits of out, 3 (low) bits opcode
    union {              // additional instruction arguments:
      uint32 out1_;      // opcode == kInstAlt
                         //   alternate next instruction

      int32 cap_;        // opcode == kInstCapture
                         //   Index of capture register (holds text
                         //   position recorded by capturing parentheses).
                         //   For \n (the submatch for the nth parentheses),
                         //   the left parenthesis captures into register 2*n
                         //   and the right one captures into register 2*n+1.

      int32 match_id_;   // opcode == kInstMatch
                         //   Match ID to identify this match (for re2::Set).

      struct {           // opcode == kInstByteRange
        uint8 lo_;       //   byte range is lo_-hi_ inclusive
        uint8 hi_;       //
        uint8 foldcase_; //   convert A-Z to a-z before checking range.
      };

      EmptyOp empty_;    // opcode == kInstEmptyWidth
                         //   empty_ is bitwise OR of kEmpty* flags above.
    };

    friend class Compiler;
    friend struct PatchList;
    friend class Prog;

    DISALLOW_EVIL_CONSTRUCTORS(Inst);
  };

  // Whether to anchor the search.
  enum Anchor {
    kUnanchored,  // match anywhere
    kAnchored,    // match only starting at beginning of text
  };

  // Kind of match to look for (for anchor != kFullMatch)
  //
  // kLongestMatch mode finds the overall longest
  // match but still makes its submatch choices the way
  // Perl would, not in the way prescribed by POSIX.
  // The POSIX rules are much more expensive to implement,
  // and no one has needed them.
  //
  // kFullMatch is not strictly necessary -- we could use
  // kLongestMatch and then check the length of the match -- but
  // the matching code can run faster if it knows to consider only
  // full matches.
  enum MatchKind {
    kFirstMatch,     // like Perl, PCRE
    kLongestMatch,   // like egrep or POSIX
    kFullMatch,      // match only entire text; implies anchor==kAnchored
    kManyMatch       // for SearchDFA, records set of matches
  };

  Inst *inst(int id) { return &inst_[id]; }
  int start() { return start_; }
  int start_unanchored() { return start_unanchored_; }
  void set_start(int start) { start_ = start; }
  void set_start_unanchored(int start) { start_unanchored_ = start; }
  int64 size() { return size_; }
  bool reversed() { return reversed_; }
  void set_reversed(bool reversed) { reversed_ = reversed; }
  int64 byte_inst_count() { return byte_inst_count_; }
  const Bitmap<256>& byterange() { return byterange_; }
  void set_dfa_mem(int64 dfa_mem) { dfa_mem_ = dfa_mem; }
  int64 dfa_mem() { return dfa_mem_; }
  int flags() { return flags_; }
  void set_flags(int flags) { flags_ = flags; }
  bool anchor_start() { return anchor_start_; }
  void set_anchor_start(bool b) { anchor_start_ = b; }
  bool anchor_end() { return anchor_end_; }
  void set_anchor_end(bool b) { anchor_end_ = b; }
  int bytemap_range() { return bytemap_range_; }
  const uint8* bytemap() { return bytemap_; }

  // Returns string representation of program for debugging.
  string Dump();
  string DumpUnanchored();

  // Record that at some point in the prog, the bytes in the range
  // lo-hi (inclusive) are treated as different from bytes outside the range.
  // Tracking this lets the DFA collapse commonly-treated byte ranges
  // when recording state pointers, greatly reducing its memory footprint.
  void MarkByteRange(int lo, int hi);

  // Returns the set of kEmpty flags that are in effect at
  // position p within context.
  static uint32 EmptyFlags(const StringPiece& context, const char* p);

  // Returns whether byte c is a word character: ASCII only.
  // Used by the implementation of \b and \B.
  // This is not right for Unicode, but:
  //   - it's hard to get right in a byte-at-a-time matching world
  //     (the DFA has only one-byte lookahead).
  //   - even if the lookahead were possible, the Progs would be huge.
  // This crude approximation is the same one PCRE uses.
  static bool IsWordChar(uint8 c) {
    return ('A' <= c && c <= 'Z') ||
           ('a' <= c && c <= 'z') ||
           ('0' <= c && c <= '9') ||
           c == '_';
  }

  // Execution engines.  They all search for the regexp (run the prog)
  // in text, which is in the larger context (used for ^ $ \b etc).
  // Anchor and kind control the kind of search.
  // Returns true if match found, false if not.
  // If match found, fills match[0..nmatch-1] with submatch info.
  // match[0] is overall match, match[1] is first set of parens, etc.
  // If a particular submatch is not matched during the regexp match,
  // it is set to NULL.
  //
  // Matching text == StringPiece(NULL, 0) is treated as any other empty
  // string, but note that on return, it will not be possible to distinguish
  // submatches that matched that empty string from submatches that didn't
  // match anything.  Either way, match[i] == NULL.

  // Search using NFA: can find submatches but kind of slow.
  bool SearchNFA(const StringPiece& text, const StringPiece& context,
                 Anchor anchor, MatchKind kind,
                 StringPiece* match, int nmatch);

  // Search using DFA: much faster than NFA but only finds
  // end of match and can use a lot more memory.
  // Returns whether a match was found.
  // If the DFA runs out of memory, sets *failed to true and returns false.
  // If matches != NULL and kind == kManyMatch and there is a match,
  // SearchDFA fills matches with the match IDs of the final matching state.
  bool SearchDFA(const StringPiece& text, const StringPiece& context,
                 Anchor anchor, MatchKind kind,
                 StringPiece* match0, bool* failed,
                 vector<int>* matches);

  // Build the entire DFA for the given match kind.  FOR TESTING ONLY.
  // Usually the DFA is built out incrementally, as needed, which
  // avoids lots of unnecessary work.  This function is useful only
  // for testing purposes.  Returns number of states.
  int BuildEntireDFA(MatchKind kind);

  // Compute byte map.
  void ComputeByteMap();

  // Run peep-hole optimizer on program.
  void Optimize();

  // One-pass NFA: only correct if IsOnePass() is true,
  // but much faster than NFA (competitive with PCRE)
  // for those expressions.
  bool IsOnePass();
  bool SearchOnePass(const StringPiece& text, const StringPiece& context,
                     Anchor anchor, MatchKind kind,
                     StringPiece* match, int nmatch);

  // Bit-state backtracking.  Fast on small cases but uses memory
  // proportional to the product of the program size and the text size.
  bool SearchBitState(const StringPiece& text, const StringPiece& context,
                      Anchor anchor, MatchKind kind,
                      StringPiece* match, int nmatch);

  static const int kMaxOnePassCapture = 5;  // $0 through $4

  // Backtracking search: the gold standard against which the other
  // implementations are checked.  FOR TESTING ONLY.
  // It allocates a ton of memory to avoid running forever.
  // It is also recursive, so can't use in production (will overflow stacks).
  // The name "Unsafe" here is supposed to be a flag that
  // you should not be using this function.
  bool UnsafeSearchBacktrack(const StringPiece& text,
                             const StringPiece& context,
                             Anchor anchor, MatchKind kind,
                             StringPiece* match, int nmatch);

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
  bool PossibleMatchRange(string* min, string* max, int maxlen);

  // Compiles a collection of regexps to Prog.  Each regexp will have
  // its own Match instruction recording the index in the vector.
  static Prog* CompileSet(const RE2::Options& options, RE2::Anchor anchor,
                          Regexp* re);

 private:
  friend class Compiler;

  DFA* GetDFA(MatchKind kind);

  bool anchor_start_;       // regexp has explicit start anchor
  bool anchor_end_;         // regexp has explicit end anchor
  bool reversed_;           // whether program runs backward over input
  bool did_onepass_;        // has IsOnePass been called?

  int start_;               // entry point for program
  int start_unanchored_;    // unanchored entry point for program
  int size_;                // number of instructions
  int byte_inst_count_;     // number of kInstByteRange instructions
  int bytemap_range_;       // bytemap_[x] < bytemap_range_
  int flags_;               // regexp parse flags
  int onepass_statesize_;   // byte size of each OneState* node

  Inst* inst_;              // pointer to instruction array

  Mutex dfa_mutex_;    // Protects dfa_first_, dfa_longest_
  DFA* volatile dfa_first_;     // DFA cached for kFirstMatch
  DFA* volatile dfa_longest_;   // DFA cached for kLongestMatch and kFullMatch
  int64 dfa_mem_;      // Maximum memory for DFAs.
  void (*delete_dfa_)(DFA* dfa);

  Bitmap<256> byterange_;    // byterange.Get(x) true if x ends a
                             // commonly-treated byte range.
  uint8 bytemap_[256];       // map from input bytes to byte classes
  uint8 *unbytemap_;         // bytemap_[unbytemap_[x]] == x

  uint8* onepass_nodes_;     // data for OnePass nodes
  OneState* onepass_start_;  // start node for OnePass program

  DISALLOW_EVIL_CONSTRUCTORS(Prog);
};

}  // namespace re2

#endif  // RE2_PROG_H__
