// Copyright 2007 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Compile regular expression to Prog.
//
// Prog and Inst are defined in prog.h.
// This file's external interface is just Regexp::CompileToProg.
// The Compiler class defined in this file is private.

#include "re2/prog.h"
#include "re2/re2.h"
#include "re2/regexp.h"
#include "re2/walker-inl.h"

namespace re2 {

// List of pointers to Inst* that need to be filled in (patched).
// Because the Inst* haven't been filled in yet,
// we can use the Inst* word to hold the list's "next" pointer.
// It's kind of sleazy, but it works well in practice.
// See http://swtch.com/~rsc/regexp/regexp1.html for inspiration.
//
// Because the out and out1 fields in Inst are no longer pointers,
// we can't use pointers directly here either.  Instead, p refers
// to inst_[p>>1].out (p&1 == 0) or inst_[p>>1].out1 (p&1 == 1).
// p == 0 represents the NULL list.  This is okay because instruction #0
// is always the fail instruction, which never appears on a list.

struct PatchList {
  uint32 p;

  // Returns patch list containing just p.
  static PatchList Mk(uint32 p);

  // Patches all the entries on l to have value v.
  // Caller must not ever use patch list again.
  static void Patch(Prog::Inst *inst0, PatchList l, uint32 v);

  // Deref returns the next pointer pointed at by p.
  static PatchList Deref(Prog::Inst *inst0, PatchList l);

  // Appends two patch lists and returns result.
  static PatchList Append(Prog::Inst *inst0, PatchList l1, PatchList l2);
};

static PatchList nullPatchList = { 0 };

// Returns patch list containing just p.
PatchList PatchList::Mk(uint32 p) {
  PatchList l;
  l.p = p;
  return l;
}

// Returns the next pointer pointed at by l.
PatchList PatchList::Deref(Prog::Inst* inst0, PatchList l) {
  Prog::Inst* ip = &inst0[l.p>>1];
  if (l.p&1)
    l.p = ip->out1();
  else
    l.p = ip->out();
  return l;
}

// Patches all the entries on l to have value v.
void PatchList::Patch(Prog::Inst *inst0, PatchList l, uint32 val) {
  while (l.p != 0) {
    Prog::Inst* ip = &inst0[l.p>>1];
    if (l.p&1) {
      l.p = ip->out1();
      ip->out1_ = val;
    } else {
      l.p = ip->out();
      ip->set_out(val);
    }
  }
}

// Appends two patch lists and returns result.
PatchList PatchList::Append(Prog::Inst* inst0, PatchList l1, PatchList l2) {
  if (l1.p == 0)
    return l2;
  if (l2.p == 0)
    return l1;

  PatchList l = l1;
  for (;;) {
    PatchList next = PatchList::Deref(inst0, l);
    if (next.p == 0)
      break;
    l = next;
  }

  Prog::Inst* ip = &inst0[l.p>>1];
  if (l.p&1)
    ip->out1_ = l2.p;
  else
    ip->set_out(l2.p);

  return l1;
}

// Compiled program fragment.
struct Frag {
  uint32 begin;
  PatchList end;

  Frag() : begin(0) { end.p = 0; }  // needed so Frag can go in vector
  Frag(uint32 begin, PatchList end) : begin(begin), end(end) {}
};

static Frag NullFrag() {
  return Frag();
}

// Input encodings.
enum Encoding {
  kEncodingUTF8 = 1,  // UTF-8 (0-10FFFF)
  kEncodingLatin1,    // Latin1 (0-FF)
};

class Compiler : public Regexp::Walker<Frag> {
 public:
  explicit Compiler();
  ~Compiler();

  // Compiles Regexp to a new Prog.
  // Caller is responsible for deleting Prog when finished with it.
  // If reversed is true, compiles for walking over the input
  // string backward (reverses all concatenations).
  static Prog *Compile(Regexp* re, bool reversed, int64 max_mem);

  // Compiles alternation of all the re to a new Prog.
  // Each re has a match with an id equal to its index in the vector.
  static Prog* CompileSet(const RE2::Options& options, RE2::Anchor anchor,
                          Regexp* re);

  // Interface for Regexp::Walker, which helps traverse the Regexp.
  // The walk is purely post-recursive: given the machines for the
  // children, PostVisit combines them to create the machine for
  // the current node.  The child_args are Frags.
  // The Compiler traverses the Regexp parse tree, visiting
  // each node in depth-first order.  It invokes PreVisit before
  // visiting the node's children and PostVisit after visiting
  // the children.
  Frag PreVisit(Regexp* re, Frag parent_arg, bool* stop);
  Frag PostVisit(Regexp* re, Frag parent_arg, Frag pre_arg, Frag* child_args,
                 int nchild_args);
  Frag ShortVisit(Regexp* re, Frag parent_arg);
  Frag Copy(Frag arg);

  // Given fragment a, returns a+ or a+?; a* or a*?; a? or a??
  Frag Plus(Frag a, bool nongreedy);
  Frag Star(Frag a, bool nongreedy);
  Frag Quest(Frag a, bool nongreedy);

  // Given fragment a, returns (a) capturing as \n.
  Frag Capture(Frag a, int n);

  // Given fragments a and b, returns ab; a|b
  Frag Cat(Frag a, Frag b);
  Frag Alt(Frag a, Frag b);

  // Returns a fragment that can't match anything.
  Frag NoMatch();

  // Returns a fragment that matches the empty string.
  Frag Match(int32 id);

  // Returns a no-op fragment.
  Frag Nop();

  // Returns a fragment matching the byte range lo-hi.
  Frag ByteRange(int lo, int hi, bool foldcase);

  // Returns a fragment matching an empty-width special op.
  Frag EmptyWidth(EmptyOp op);

  // Adds n instructions to the program.
  // Returns the index of the first one.
  // Returns -1 if no more instructions are available.
  int AllocInst(int n);

  // Deletes unused instructions.
  void Trim();

  // Rune range compiler.

  // Begins a new alternation.
  void BeginRange();

  // Adds a fragment matching the rune range lo-hi.
  void AddRuneRange(Rune lo, Rune hi, bool foldcase);
  void AddRuneRangeLatin1(Rune lo, Rune hi, bool foldcase);
  void AddRuneRangeUTF8(Rune lo, Rune hi, bool foldcase);
  void Add_80_10ffff();

  // New suffix that matches the byte range lo-hi, then goes to next.
  int RuneByteSuffix(uint8 lo, uint8 hi, bool foldcase, int next);
  int UncachedRuneByteSuffix(uint8 lo, uint8 hi, bool foldcase, int next);

  // Adds a suffix to alternation.
  void AddSuffix(int id);

  // Returns the alternation of all the added suffixes.
  Frag EndRange();

  // Single rune.
  Frag Literal(Rune r, bool foldcase);

  void Setup(Regexp::ParseFlags, int64, RE2::Anchor);
  Prog* Finish();

  // Returns .* where dot = any byte
  Frag DotStar();

 private:
  Prog* prog_;         // Program being built.
  bool failed_;        // Did we give up compiling?
  Encoding encoding_;  // Input encoding
  bool reversed_;      // Should program run backward over text?

  int max_inst_;       // Maximum number of instructions.

  Prog::Inst* inst_;   // Pointer to first instruction.
  int inst_len_;       // Number of instructions used.
  int inst_cap_;       // Number of instructions allocated.

  int64 max_mem_;      // Total memory budget.

  map<uint64, int> rune_cache_;
  Frag rune_range_;

  RE2::Anchor anchor_;  // anchor mode for RE2::Set

  DISALLOW_EVIL_CONSTRUCTORS(Compiler);
};

Compiler::Compiler() {
  prog_ = new Prog();
  failed_ = false;
  encoding_ = kEncodingUTF8;
  reversed_ = false;
  inst_ = NULL;
  inst_len_ = 0;
  inst_cap_ = 0;
  max_inst_ = 1;  // make AllocInst for fail instruction okay
  max_mem_ = 0;
  int fail = AllocInst(1);
  inst_[fail].InitFail();
  max_inst_ = 0;  // Caller must change
}

Compiler::~Compiler() {
  delete prog_;
  delete[] inst_;
}

int Compiler::AllocInst(int n) {
  if (failed_ || inst_len_ + n > max_inst_) {
    failed_ = true;
    return -1;
  }

  if (inst_len_ + n > inst_cap_) {
    if (inst_cap_ == 0)
      inst_cap_ = 8;
    while (inst_len_ + n > inst_cap_)
      inst_cap_ *= 2;
    Prog::Inst* ip = new Prog::Inst[inst_cap_];
    memmove(ip, inst_, inst_len_ * sizeof ip[0]);
    memset(ip + inst_len_, 0, (inst_cap_ - inst_len_) * sizeof ip[0]);
    delete[] inst_;
    inst_ = ip;
  }
  int id = inst_len_;
  inst_len_ += n;
  return id;
}

void Compiler::Trim() {
  if (inst_len_ < inst_cap_) {
    Prog::Inst* ip = new Prog::Inst[inst_len_];
    memmove(ip, inst_, inst_len_ * sizeof ip[0]);
    delete[] inst_;
    inst_ = ip;
    inst_cap_ = inst_len_;
  }
}

// These routines are somewhat hard to visualize in text --
// see http://swtch.com/~rsc/regexp/regexp1.html for
// pictures explaining what is going on here.

// Returns an unmatchable fragment.
Frag Compiler::NoMatch() {
  return Frag(0, nullPatchList);
}

// Is a an unmatchable fragment?
static bool IsNoMatch(Frag a) {
  return a.begin == 0;
}

// Given fragments a and b, returns fragment for ab.
Frag Compiler::Cat(Frag a, Frag b) {
  if (IsNoMatch(a) || IsNoMatch(b))
    return NoMatch();

  // Elide no-op.
  Prog::Inst* begin = &inst_[a.begin];
  if (begin->opcode() == kInstNop &&
      a.end.p == (a.begin << 1) &&
      begin->out() == 0) {
    PatchList::Patch(inst_, a.end, b.begin);  // in case refs to a somewhere
    return b;
  }

  // To run backward over string, reverse all concatenations.
  if (reversed_) {
    PatchList::Patch(inst_, b.end, a.begin);
    return Frag(b.begin, a.end);
  }

  PatchList::Patch(inst_, a.end, b.begin);
  return Frag(a.begin, b.end);
}

// Given fragments for a and b, returns fragment for a|b.
Frag Compiler::Alt(Frag a, Frag b) {
  // Special case for convenience in loops.
  if (IsNoMatch(a))
    return b;
  if (IsNoMatch(b))
    return a;

  int id = AllocInst(1);
  if (id < 0)
    return NoMatch();

  inst_[id].InitAlt(a.begin, b.begin);
  return Frag(id, PatchList::Append(inst_, a.end, b.end));
}

// When capturing submatches in like-Perl mode, a kOpAlt Inst
// treats out_ as the first choice, out1_ as the second.
//
// For *, +, and ?, if out_ causes another repetition,
// then the operator is greedy.  If out1_ is the repetition
// (and out_ moves forward), then the operator is non-greedy.

// Given a fragment a, returns a fragment for a* or a*? (if nongreedy)
Frag Compiler::Star(Frag a, bool nongreedy) {
  int id = AllocInst(1);
  if (id < 0)
    return NoMatch();
  inst_[id].InitAlt(0, 0);
  PatchList::Patch(inst_, a.end, id);
  if (nongreedy) {
    inst_[id].out1_ = a.begin;
    return Frag(id, PatchList::Mk(id << 1));
  } else {
    inst_[id].set_out(a.begin);
    return Frag(id, PatchList::Mk((id << 1) | 1));
  }
}

// Given a fragment for a, returns a fragment for a+ or a+? (if nongreedy)
Frag Compiler::Plus(Frag a, bool nongreedy) {
  // a+ is just a* with a different entry point.
  Frag f = Star(a, nongreedy);
  return Frag(a.begin, f.end);
}

// Given a fragment for a, returns a fragment for a? or a?? (if nongreedy)
Frag Compiler::Quest(Frag a, bool nongreedy) {
  int id = AllocInst(1);
  if (id < 0)
    return NoMatch();
  PatchList pl;
  if (nongreedy) {
    inst_[id].InitAlt(0, a.begin);
    pl = PatchList::Mk(id << 1);
  } else {
    inst_[id].InitAlt(a.begin, 0);
    pl = PatchList::Mk((id << 1) | 1);
  }
  return Frag(id, PatchList::Append(inst_, pl, a.end));
}

// Returns a fragment for the byte range lo-hi.
Frag Compiler::ByteRange(int lo, int hi, bool foldcase) {
  int id = AllocInst(1);
  if (id < 0)
    return NoMatch();
  inst_[id].InitByteRange(lo, hi, foldcase, 0);
  prog_->byte_inst_count_++;
  prog_->MarkByteRange(lo, hi);
  if (foldcase && lo <= 'z' && hi >= 'a') {
    if (lo < 'a')
      lo = 'a';
    if (hi > 'z')
      hi = 'z';
    if (lo <= hi)
      prog_->MarkByteRange(lo + 'A' - 'a', hi + 'A' - 'a');
  }
  return Frag(id, PatchList::Mk(id << 1));
}

// Returns a no-op fragment.  Sometimes unavoidable.
Frag Compiler::Nop() {
  int id = AllocInst(1);
  if (id < 0)
    return NoMatch();
  inst_[id].InitNop(0);
  return Frag(id, PatchList::Mk(id << 1));
}

// Returns a fragment that signals a match.
Frag Compiler::Match(int32 match_id) {
  int id = AllocInst(1);
  if (id < 0)
    return NoMatch();
  inst_[id].InitMatch(match_id);
  return Frag(id, nullPatchList);
}

// Returns a fragment matching a particular empty-width op (like ^ or $)
Frag Compiler::EmptyWidth(EmptyOp empty) {
  int id = AllocInst(1);
  if (id < 0)
    return NoMatch();
  inst_[id].InitEmptyWidth(empty, 0);
  if (empty & (kEmptyBeginLine|kEmptyEndLine))
    prog_->MarkByteRange('\n', '\n');
  if (empty & (kEmptyWordBoundary|kEmptyNonWordBoundary)) {
    int j;
    for (int i = 0; i < 256; i = j) {
      for (j = i+1; j < 256 && Prog::IsWordChar(i) == Prog::IsWordChar(j); j++)
        ;
      prog_->MarkByteRange(i, j-1);
    }
  }
  return Frag(id, PatchList::Mk(id << 1));
}

// Given a fragment a, returns a fragment with capturing parens around a.
Frag Compiler::Capture(Frag a, int n) {
  int id = AllocInst(2);
  if (id < 0)
    return NoMatch();
  inst_[id].InitCapture(2*n, a.begin);
  inst_[id+1].InitCapture(2*n+1, 0);
  PatchList::Patch(inst_, a.end, id+1);

  return Frag(id, PatchList::Mk((id+1) << 1));
}

// A Rune is a name for a Unicode code point.
// Returns maximum rune encoded by UTF-8 sequence of length len.
static int MaxRune(int len) {
  int b;  // number of Rune bits in len-byte UTF-8 sequence (len < UTFmax)
  if (len == 1)
    b = 7;
  else
    b = 8-(len+1) + 6*(len-1);
  return (1<<b) - 1;   // maximum Rune for b bits.
}

// The rune range compiler caches common suffix fragments,
// which are very common in UTF-8 (e.g., [80-bf]).
// The fragment suffixes are identified by their start
// instructions.  NULL denotes the eventual end match.
// The Frag accumulates in rune_range_.  Caching common
// suffixes reduces the UTF-8 "." from 32 to 24 instructions,
// and it reduces the corresponding one-pass NFA from 16 nodes to 8.

void Compiler::BeginRange() {
  rune_cache_.clear();
  rune_range_.begin = 0;
  rune_range_.end = nullPatchList;
}

int Compiler::UncachedRuneByteSuffix(uint8 lo, uint8 hi, bool foldcase,
                                     int next) {
  Frag f = ByteRange(lo, hi, foldcase);
  if (next != 0) {
    PatchList::Patch(inst_, f.end, next);
  } else {
    rune_range_.end = PatchList::Append(inst_, rune_range_.end, f.end);
  }
  return f.begin;
}

int Compiler::RuneByteSuffix(uint8 lo, uint8 hi, bool foldcase, int next) {
  // In Latin1 mode, there's no point in caching.
  // In forward UTF-8 mode, only need to cache continuation bytes.
  if (encoding_ == kEncodingLatin1 ||
      (encoding_ == kEncodingUTF8 &&
       !reversed_ &&
       !(0x80 <= lo && hi <= 0xbf))) {
    return UncachedRuneByteSuffix(lo, hi, foldcase, next);
  }

  uint64 key = ((uint64)next << 17) | (lo<<9) | (hi<<1) | (foldcase ? 1ULL : 0ULL);
  map<uint64, int>::iterator it = rune_cache_.find(key);
  if (it != rune_cache_.end())
    return it->second;
  int id = UncachedRuneByteSuffix(lo, hi, foldcase, next);
  rune_cache_[key] = id;
  return id;
}

void Compiler::AddSuffix(int id) {
  if (rune_range_.begin == 0) {
    rune_range_.begin = id;
    return;
  }

  int alt = AllocInst(1);
  if (alt < 0) {
    rune_range_.begin = 0;
    return;
  }
  inst_[alt].InitAlt(rune_range_.begin, id);
  rune_range_.begin = alt;
}

Frag Compiler::EndRange() {
  return rune_range_;
}

// Converts rune range lo-hi into a fragment that recognizes
// the bytes that would make up those runes in the current
// encoding (Latin 1 or UTF-8).
// This lets the machine work byte-by-byte even when
// using multibyte encodings.

void Compiler::AddRuneRange(Rune lo, Rune hi, bool foldcase) {
  switch (encoding_) {
    default:
    case kEncodingUTF8:
      AddRuneRangeUTF8(lo, hi, foldcase);
      break;
    case kEncodingLatin1:
      AddRuneRangeLatin1(lo, hi, foldcase);
      break;
  }
}

void Compiler::AddRuneRangeLatin1(Rune lo, Rune hi, bool foldcase) {
  // Latin1 is easy: runes *are* bytes.
  if (lo > hi || lo > 0xFF)
    return;
  if (hi > 0xFF)
    hi = 0xFF;
  AddSuffix(RuneByteSuffix(lo, hi, foldcase, 0));
}

// Table describing how to make a UTF-8 matching machine
// for the rune range 80-10FFFF (Runeself-Runemax).
// This range happens frequently enough (for example /./ and /[^a-z]/)
// and the rune_cache_ map is slow enough that this is worth
// special handling.  Makes compilation of a small expression
// with a dot in it about 10% faster.
// The * in the comments below mark whole sequences.
static struct ByteRangeProg {
  int next;
  int lo;
  int hi;
} prog_80_10ffff[] = {
  // Two-byte
  { -1, 0x80, 0xBF, },  // 0:  80-BF
  {  0, 0xC2, 0xDF, },  // 1:  C2-DF 80-BF*

  // Three-byte
  {  0, 0xA0, 0xBF, },  // 2:  A0-BF 80-BF
  {  2, 0xE0, 0xE0, },  // 3:  E0 A0-BF 80-BF*
  {  0, 0x80, 0xBF, },  // 4:  80-BF 80-BF
  {  4, 0xE1, 0xEF, },  // 5:  E1-EF 80-BF 80-BF*

  // Four-byte
  {  4, 0x90, 0xBF, },  // 6:  90-BF 80-BF 80-BF
  {  6, 0xF0, 0xF0, },  // 7:  F0 90-BF 80-BF 80-BF*
  {  4, 0x80, 0xBF, },  // 8:  80-BF 80-BF 80-BF
  {  8, 0xF1, 0xF3, },  // 9: F1-F3 80-BF 80-BF 80-BF*
  {  4, 0x80, 0x8F, },  // 10: 80-8F 80-BF 80-BF
  { 10, 0xF4, 0xF4, },  // 11: F4 80-8F 80-BF 80-BF*
};

void Compiler::Add_80_10ffff() {
  int inst[arraysize(prog_80_10ffff)] = { 0 }; // does not need to be initialized; silences gcc warning
  for (int i = 0; i < arraysize(prog_80_10ffff); i++) {
    const ByteRangeProg& p = prog_80_10ffff[i];
    int next = 0;
    if (p.next >= 0)
      next = inst[p.next];
    inst[i] = UncachedRuneByteSuffix(p.lo, p.hi, false, next);
    if ((p.lo & 0xC0) != 0x80)
      AddSuffix(inst[i]);
  }
}

void Compiler::AddRuneRangeUTF8(Rune lo, Rune hi, bool foldcase) {
  if (lo > hi)
    return;

  // Pick off 80-10FFFF as a common special case
  // that can bypass the slow rune_cache_.
  if (lo == 0x80 && hi == 0x10ffff && !reversed_) {
    Add_80_10ffff();
    return;
  }

  // Split range into same-length sized ranges.
  for (int i = 1; i < UTFmax; i++) {
    Rune max = MaxRune(i);
    if (lo <= max && max < hi) {
      AddRuneRangeUTF8(lo, max, foldcase);
      AddRuneRangeUTF8(max+1, hi, foldcase);
      return;
    }
  }

  // ASCII range is always a special case.
  if (hi < Runeself) {
    AddSuffix(RuneByteSuffix(lo, hi, foldcase, 0));
    return;
  }

  // Split range into sections that agree on leading bytes.
  for (int i = 1; i < UTFmax; i++) {
    uint m = (1<<(6*i)) - 1;  // last i bytes of a UTF-8 sequence
    if ((lo & ~m) != (hi & ~m)) {
      if ((lo & m) != 0) {
        AddRuneRangeUTF8(lo, lo|m, foldcase);
        AddRuneRangeUTF8((lo|m)+1, hi, foldcase);
        return;
      }
      if ((hi & m) != m) {
        AddRuneRangeUTF8(lo, (hi&~m)-1, foldcase);
        AddRuneRangeUTF8(hi&~m, hi, foldcase);
        return;
      }
    }
  }

  // Finally.  Generate byte matching equivalent for lo-hi.
  uint8 ulo[UTFmax], uhi[UTFmax];
  int n = runetochar(reinterpret_cast<char*>(ulo), &lo);
  int m = runetochar(reinterpret_cast<char*>(uhi), &hi);
  (void)m;  // USED(m)
  DCHECK_EQ(n, m);

  int id = 0;
  if (reversed_) {
    for (int i = 0; i < n; i++)
      id = RuneByteSuffix(ulo[i], uhi[i], false, id);
  } else {
    for (int i = n-1; i >= 0; i--)
      id = RuneByteSuffix(ulo[i], uhi[i], false, id);
  }
  AddSuffix(id);
}

// Should not be called.
Frag Compiler::Copy(Frag arg) {
  // We're using WalkExponential; there should be no copying.
  LOG(DFATAL) << "Compiler::Copy called!";
  failed_ = true;
  return NoMatch();
}

// Visits a node quickly; called once WalkExponential has
// decided to cut this walk short.
Frag Compiler::ShortVisit(Regexp* re, Frag) {
  failed_ = true;
  return NoMatch();
}

// Called before traversing a node's children during the walk.
Frag Compiler::PreVisit(Regexp* re, Frag, bool* stop) {
  // Cut off walk if we've already failed.
  if (failed_)
    *stop = true;

  return NullFrag();  // not used by caller
}

Frag Compiler::Literal(Rune r, bool foldcase) {
  switch (encoding_) {
    default:
      return NullFrag();

    case kEncodingLatin1:
      return ByteRange(r, r, foldcase);

    case kEncodingUTF8: {
      if (r < Runeself)  // Make common case fast.
        return ByteRange(r, r, foldcase);
      uint8 buf[UTFmax];
      int n = runetochar(reinterpret_cast<char*>(buf), &r);
      Frag f = ByteRange((uint8)buf[0], buf[0], false);
      for (int i = 1; i < n; i++)
        f = Cat(f, ByteRange((uint8)buf[i], buf[i], false));
      return f;
    }
  }
}

// Called after traversing the node's children during the walk.
// Given their frags, build and return the frag for this re.
Frag Compiler::PostVisit(Regexp* re, Frag, Frag, Frag* child_frags,
                         int nchild_frags) {
  // If a child failed, don't bother going forward, especially
  // since the child_frags might contain Frags with NULLs in them.
  if (failed_)
    return NoMatch();

  // Given the child fragments, return the fragment for this node.
  switch (re->op()) {
    case kRegexpRepeat:
      // Should not see; code at bottom of function will print error
      break;

    case kRegexpNoMatch:
      return NoMatch();

    case kRegexpEmptyMatch:
      return Nop();

    case kRegexpHaveMatch: {
      Frag f = Match(re->match_id());
      // Remember unanchored match to end of string.
      if (anchor_ != RE2::ANCHOR_BOTH)
        f = Cat(DotStar(), Cat(EmptyWidth(kEmptyEndText), f));
      return f;
    }

    case kRegexpConcat: {
      Frag f = child_frags[0];
      for (int i = 1; i < nchild_frags; i++)
        f = Cat(f, child_frags[i]);
      return f;
    }

    case kRegexpAlternate: {
      Frag f = child_frags[0];
      for (int i = 1; i < nchild_frags; i++)
        f = Alt(f, child_frags[i]);
      return f;
    }

    case kRegexpStar:
      return Star(child_frags[0], re->parse_flags()&Regexp::NonGreedy);

    case kRegexpPlus:
      return Plus(child_frags[0], re->parse_flags()&Regexp::NonGreedy);

    case kRegexpQuest:
      return Quest(child_frags[0], re->parse_flags()&Regexp::NonGreedy);

    case kRegexpLiteral:
      return Literal(re->rune(), re->parse_flags()&Regexp::FoldCase);

    case kRegexpLiteralString: {
      // Concatenation of literals.
      if (re->nrunes() == 0)
        return Nop();
      Frag f;
      for (int i = 0; i < re->nrunes(); i++) {
        Frag f1 = Literal(re->runes()[i], re->parse_flags()&Regexp::FoldCase);
        if (i == 0)
          f = f1;
        else
          f = Cat(f, f1);
      }
      return f;
    }

    case kRegexpAnyChar:
      BeginRange();
      AddRuneRange(0, Runemax, false);
      return EndRange();

    case kRegexpAnyByte:
      return ByteRange(0x00, 0xFF, false);

    case kRegexpCharClass: {
      CharClass* cc = re->cc();
      if (cc->empty()) {
        // This can't happen.
        LOG(DFATAL) << "No ranges in char class";
        failed_ = true;
        return NoMatch();
      }

      // ASCII case-folding optimization: if the char class
      // behaves the same on A-Z as it does on a-z,
      // discard any ranges wholly contained in A-Z
      // and mark the other ranges as foldascii.
      // This reduces the size of a program for
      // (?i)abc from 3 insts per letter to 1 per letter.
      bool foldascii = cc->FoldsASCII();

      // Character class is just a big OR of the different
      // character ranges in the class.
      BeginRange();
      for (CharClass::iterator i = cc->begin(); i != cc->end(); ++i) {
        // ASCII case-folding optimization (see above).
        if (foldascii && 'A' <= i->lo && i->hi <= 'Z')
          continue;

        // If this range contains all of A-Za-z or none of it,
        // the fold flag is unnecessary; don't bother.
        bool fold = foldascii;
        if ((i->lo <= 'A' && 'z' <= i->hi) || i->hi < 'A' || 'z' < i->lo)
          fold = false;

        AddRuneRange(i->lo, i->hi, fold);
      }
      return EndRange();
    }

    case kRegexpCapture:
      // If this is a non-capturing parenthesis -- (?:foo) --
      // just use the inner expression.
      if (re->cap() < 0)
        return child_frags[0];
      return Capture(child_frags[0], re->cap());

    case kRegexpBeginLine:
      return EmptyWidth(reversed_ ? kEmptyEndLine : kEmptyBeginLine);

    case kRegexpEndLine:
      return EmptyWidth(reversed_ ? kEmptyBeginLine : kEmptyEndLine);

    case kRegexpBeginText:
      return EmptyWidth(reversed_ ? kEmptyEndText : kEmptyBeginText);

    case kRegexpEndText:
      return EmptyWidth(reversed_ ? kEmptyBeginText : kEmptyEndText);

    case kRegexpWordBoundary:
      return EmptyWidth(kEmptyWordBoundary);

    case kRegexpNoWordBoundary:
      return EmptyWidth(kEmptyNonWordBoundary);
  }
  LOG(DFATAL) << "Missing case in Compiler: " << re->op();
  failed_ = true;
  return NoMatch();
}

// Is this regexp required to start at the beginning of the text?
// Only approximate; can return false for complicated regexps like (\Aa|\Ab),
// but handles (\A(a|b)).  Could use the Walker to write a more exact one.
static bool IsAnchorStart(Regexp** pre, int depth) {
  Regexp* re = *pre;
  Regexp* sub;
  // The depth limit makes sure that we don't overflow
  // the stack on a deeply nested regexp.  As the comment
  // above says, IsAnchorStart is conservative, so returning
  // a false negative is okay.  The exact limit is somewhat arbitrary.
  if (re == NULL || depth >= 4)
    return false;
  switch (re->op()) {
    default:
      break;
    case kRegexpConcat:
      if (re->nsub() > 0) {
        sub = re->sub()[0]->Incref();
        if (IsAnchorStart(&sub, depth+1)) {
          Regexp** subcopy = new Regexp*[re->nsub()];
          subcopy[0] = sub;  // already have reference
          for (int i = 1; i < re->nsub(); i++)
            subcopy[i] = re->sub()[i]->Incref();
          *pre = Regexp::Concat(subcopy, re->nsub(), re->parse_flags());
          delete[] subcopy;
          re->Decref();
          return true;
        }
        sub->Decref();
      }
      break;
    case kRegexpCapture:
      sub = re->sub()[0]->Incref();
      if (IsAnchorStart(&sub, depth+1)) {
        *pre = Regexp::Capture(sub, re->parse_flags(), re->cap());
        re->Decref();
        return true;
      }
      sub->Decref();
      break;
    case kRegexpBeginText:
      *pre = Regexp::LiteralString(NULL, 0, re->parse_flags());
      re->Decref();
      return true;
  }
  return false;
}

// Is this regexp required to start at the end of the text?
// Only approximate; can return false for complicated regexps like (a\z|b\z),
// but handles ((a|b)\z).  Could use the Walker to write a more exact one.
static bool IsAnchorEnd(Regexp** pre, int depth) {
  Regexp* re = *pre;
  Regexp* sub;
  // The depth limit makes sure that we don't overflow
  // the stack on a deeply nested regexp.  As the comment
  // above says, IsAnchorEnd is conservative, so returning
  // a false negative is okay.  The exact limit is somewhat arbitrary.
  if (re == NULL || depth >= 4)
    return false;
  switch (re->op()) {
    default:
      break;
    case kRegexpConcat:
      if (re->nsub() > 0) {
        sub = re->sub()[re->nsub() - 1]->Incref();
        if (IsAnchorEnd(&sub, depth+1)) {
          Regexp** subcopy = new Regexp*[re->nsub()];
          subcopy[re->nsub() - 1] = sub;  // already have reference
          for (int i = 0; i < re->nsub() - 1; i++)
            subcopy[i] = re->sub()[i]->Incref();
          *pre = Regexp::Concat(subcopy, re->nsub(), re->parse_flags());
          delete[] subcopy;
          re->Decref();
          return true;
        }
        sub->Decref();
      }
      break;
    case kRegexpCapture:
      sub = re->sub()[0]->Incref();
      if (IsAnchorEnd(&sub, depth+1)) {
        *pre = Regexp::Capture(sub, re->parse_flags(), re->cap());
        re->Decref();
        return true;
      }
      sub->Decref();
      break;
    case kRegexpEndText:
      *pre = Regexp::LiteralString(NULL, 0, re->parse_flags());
      re->Decref();
      return true;
  }
  return false;
}

void Compiler::Setup(Regexp::ParseFlags flags, int64 max_mem,
                     RE2::Anchor anchor) {
  prog_->set_flags(flags);

  if (flags & Regexp::Latin1)
    encoding_ = kEncodingLatin1;
  max_mem_ = max_mem;
  if (max_mem <= 0) {
    max_inst_ = 100000;  // more than enough
  } else if (max_mem <= sizeof(Prog)) {
    // No room for anything.
    max_inst_ = 0;
  } else {
    int64 m = (max_mem - sizeof(Prog)) / sizeof(Prog::Inst);
    // Limit instruction count so that inst->id() fits nicely in an int.
    // SparseArray also assumes that the indices (inst->id()) are ints.
    // The call to WalkExponential uses 2*max_inst_ below,
    // and other places in the code use 2 or 3 * prog->size().
    // Limiting to 2^24 should avoid overflow in those places.
    // (The point of allowing more than 32 bits of memory is to
    // have plenty of room for the DFA states, not to use it up
    // on the program.)
    if (m >= 1<<24)
      m = 1<<24;

    // Inst imposes its own limit (currently bigger than 2^24 but be safe).
    if (m > Prog::Inst::kMaxInst)
      m = Prog::Inst::kMaxInst;

    max_inst_ = m;
  }

  anchor_ = anchor;
}

// Compiles re, returning program.
// Caller is responsible for deleting prog_.
// If reversed is true, compiles a program that expects
// to run over the input string backward (reverses all concatenations).
// The reversed flag is also recorded in the returned program.
Prog* Compiler::Compile(Regexp* re, bool reversed, int64 max_mem) {
  Compiler c;

  c.Setup(re->parse_flags(), max_mem, RE2::ANCHOR_BOTH /* unused */);
  c.reversed_ = reversed;

  // Simplify to remove things like counted repetitions
  // and character classes like \d.
  Regexp* sre = re->Simplify();
  if (sre == NULL)
    return NULL;

  // Record whether prog is anchored, removing the anchors.
  // (They get in the way of other optimizations.)
  bool is_anchor_start = IsAnchorStart(&sre, 0);
  bool is_anchor_end = IsAnchorEnd(&sre, 0);

  // Generate fragment for entire regexp.
  Frag f = c.WalkExponential(sre, NullFrag(), 2*c.max_inst_);
  sre->Decref();
  if (c.failed_)
    return NULL;

  // Success!  Finish by putting Match node at end, and record start.
  // Turn off c.reversed_ (if it is set) to force the remaining concatenations
  // to behave normally.
  c.reversed_ = false;
  Frag all = c.Cat(f, c.Match(0));
  c.prog_->set_start(all.begin);

  if (reversed) {
    c.prog_->set_anchor_start(is_anchor_end);
    c.prog_->set_anchor_end(is_anchor_start);
  } else {
    c.prog_->set_anchor_start(is_anchor_start);
    c.prog_->set_anchor_end(is_anchor_end);
  }

  // Also create unanchored version, which starts with a .*? loop.
  if (c.prog_->anchor_start()) {
    c.prog_->set_start_unanchored(c.prog_->start());
  } else {
    Frag unanchored = c.Cat(c.DotStar(), all);
    c.prog_->set_start_unanchored(unanchored.begin);
  }

  c.prog_->set_reversed(reversed);

  // Hand ownership of prog_ to caller.
  return c.Finish();
}

Prog* Compiler::Finish() {
  if (failed_)
    return NULL;

  if (prog_->start() == 0 && prog_->start_unanchored() == 0) {
    // No possible matches; keep Fail instruction only.
    inst_len_ = 1;
  }

  // Trim instruction to minimum array and transfer to Prog.
  Trim();
  prog_->inst_ = inst_;
  prog_->size_ = inst_len_;
  inst_ = NULL;

  // Compute byte map.
  prog_->ComputeByteMap();

  prog_->Optimize();

  // Record remaining memory for DFA.
  if (max_mem_ <= 0) {
    prog_->set_dfa_mem(1<<20);
  } else {
    int64 m = max_mem_ - sizeof(Prog) - inst_len_*sizeof(Prog::Inst);
    if (m < 0)
      m = 0;
    prog_->set_dfa_mem(m);
  }

  Prog* p = prog_;
  prog_ = NULL;
  return p;
}

// Converts Regexp to Prog.
Prog* Regexp::CompileToProg(int64 max_mem) {
  return Compiler::Compile(this, false, max_mem);
}

Prog* Regexp::CompileToReverseProg(int64 max_mem) {
  return Compiler::Compile(this, true, max_mem);
}

Frag Compiler::DotStar() {
  return Star(ByteRange(0x00, 0xff, false), true);
}

// Compiles RE set to Prog.
Prog* Compiler::CompileSet(const RE2::Options& options, RE2::Anchor anchor,
                           Regexp* re) {
  Compiler c;

  Regexp::ParseFlags pf = static_cast<Regexp::ParseFlags>(options.ParseFlags());
  c.Setup(pf, options.max_mem(), anchor);

  // Compile alternation of fragments.
  Frag all = c.WalkExponential(re, NullFrag(), 2*c.max_inst_);
  re->Decref();
  if (c.failed_)
    return NULL;

  if (anchor == RE2::UNANCHORED) {
    // The trailing .* was added while handling kRegexpHaveMatch.
    // We just have to add the leading one.
    all = c.Cat(c.DotStar(), all);
  }

  c.prog_->set_start(all.begin);
  c.prog_->set_start_unanchored(all.begin);
  c.prog_->set_anchor_start(true);
  c.prog_->set_anchor_end(true);

  Prog* prog = c.Finish();
  if (prog == NULL)
    return NULL;

  // Make sure DFA has enough memory to operate,
  // since we're not going to fall back to the NFA.
  bool failed;
  StringPiece sp = "hello, world";
  prog->SearchDFA(sp, sp, Prog::kAnchored, Prog::kManyMatch,
                  NULL, &failed, NULL);
  if (failed) {
    delete prog;
    return NULL;
  }

  return prog;
}

Prog* Prog::CompileSet(const RE2::Options& options, RE2::Anchor anchor,
                       Regexp* re) {
  return Compiler::CompileSet(options, anchor, re);
}

}  // namespace re2
