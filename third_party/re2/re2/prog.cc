// Copyright 2007 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Compiled regular expression representation.
// Tested by compile_test.cc

#include "util/util.h"
#include "util/sparse_set.h"
#include "re2/prog.h"
#include "re2/stringpiece.h"

namespace re2 {

// Constructors per Inst opcode

void Prog::Inst::InitAlt(uint32 out, uint32 out1) {
  DCHECK_EQ(out_opcode_, 0);
  set_out_opcode(out, kInstAlt);
  out1_ = out1;
}

void Prog::Inst::InitByteRange(int lo, int hi, int foldcase, uint32 out) {
  DCHECK_EQ(out_opcode_, 0);
  set_out_opcode(out, kInstByteRange);
  lo_ = lo & 0xFF;
  hi_ = hi & 0xFF;
  foldcase_ = foldcase;
}

void Prog::Inst::InitCapture(int cap, uint32 out) {
  DCHECK_EQ(out_opcode_, 0);
  set_out_opcode(out, kInstCapture);
  cap_ = cap;
}

void Prog::Inst::InitEmptyWidth(EmptyOp empty, uint32 out) {
  DCHECK_EQ(out_opcode_, 0);
  set_out_opcode(out, kInstEmptyWidth);
  empty_ = empty;
}

void Prog::Inst::InitMatch(int32 id) {
  DCHECK_EQ(out_opcode_, 0);
  set_opcode(kInstMatch);
  match_id_ = id;
}

void Prog::Inst::InitNop(uint32 out) {
  DCHECK_EQ(out_opcode_, 0);
  set_opcode(kInstNop);
}

void Prog::Inst::InitFail() {
  DCHECK_EQ(out_opcode_, 0);
  set_opcode(kInstFail);
}

string Prog::Inst::Dump() {
  switch (opcode()) {
    default:
      return StringPrintf("opcode %d", static_cast<int>(opcode()));

    case kInstAlt:
      return StringPrintf("alt -> %d | %d", out(), out1_);

    case kInstAltMatch:
      return StringPrintf("altmatch -> %d | %d", out(), out1_);

    case kInstByteRange:
      return StringPrintf("byte%s [%02x-%02x] -> %d",
                          foldcase_ ? "/i" : "",
                          lo_, hi_, out());

    case kInstCapture:
      return StringPrintf("capture %d -> %d", cap_, out());

    case kInstEmptyWidth:
      return StringPrintf("emptywidth %#x -> %d",
                          static_cast<int>(empty_), out());

    case kInstMatch:
      return StringPrintf("match! %d", match_id());

    case kInstNop:
      return StringPrintf("nop -> %d", out());

    case kInstFail:
      return StringPrintf("fail");
  }
}

Prog::Prog()
  : anchor_start_(false),
    anchor_end_(false),
    reversed_(false),
    did_onepass_(false),
    start_(0),
    start_unanchored_(0),
    size_(0),
    byte_inst_count_(0),
    bytemap_range_(0),
    flags_(0),
    onepass_statesize_(0),
    inst_(NULL),
    dfa_first_(NULL),
    dfa_longest_(NULL),
    dfa_mem_(0),
    delete_dfa_(NULL),
    unbytemap_(NULL),
    onepass_nodes_(NULL),
    onepass_start_(NULL) {
}

Prog::~Prog() {
  if (delete_dfa_) {
    if (dfa_first_)
      delete_dfa_(dfa_first_);
    if (dfa_longest_)
      delete_dfa_(dfa_longest_);
  }
  delete[] onepass_nodes_;
  delete[] inst_;
  delete[] unbytemap_;
}

typedef SparseSet Workq;

static inline void AddToQueue(Workq* q, int id) {
  if (id != 0)
    q->insert(id);
}

static string ProgToString(Prog* prog, Workq* q) {
  string s;

  for (Workq::iterator i = q->begin(); i != q->end(); ++i) {
    int id = *i;
    Prog::Inst* ip = prog->inst(id);
    StringAppendF(&s, "%d. %s\n", id, ip->Dump().c_str());
    AddToQueue(q, ip->out());
    if (ip->opcode() == kInstAlt || ip->opcode() == kInstAltMatch)
      AddToQueue(q, ip->out1());
  }
  return s;
}

string Prog::Dump() {
  string map;
  if (false) {  // Debugging
    int lo = 0;
    StringAppendF(&map, "byte map:\n");
    for (int i = 0; i < bytemap_range_; i++) {
      StringAppendF(&map, "\t%d. [%02x-%02x]\n", i, lo, unbytemap_[i]);
      lo = unbytemap_[i] + 1;
    }
    StringAppendF(&map, "\n");
  }

  Workq q(size_);
  AddToQueue(&q, start_);
  return map + ProgToString(this, &q);
}

string Prog::DumpUnanchored() {
  Workq q(size_);
  AddToQueue(&q, start_unanchored_);
  return ProgToString(this, &q);
}

static bool IsMatch(Prog*, Prog::Inst*);

// Peep-hole optimizer.
void Prog::Optimize() {
  Workq q(size_);

  // Eliminate nops.  Most are taken out during compilation
  // but a few are hard to avoid.
  q.clear();
  AddToQueue(&q, start_);
  for (Workq::iterator i = q.begin(); i != q.end(); ++i) {
    int id = *i;

    Inst* ip = inst(id);
    int j = ip->out();
    Inst* jp;
    while (j != 0 && (jp=inst(j))->opcode() == kInstNop) {
      j = jp->out();
    }
    ip->set_out(j);
    AddToQueue(&q, ip->out());

    if (ip->opcode() == kInstAlt) {
      j = ip->out1();
      while (j != 0 && (jp=inst(j))->opcode() == kInstNop) {
        j = jp->out();
      }
      ip->out1_ = j;
      AddToQueue(&q, ip->out1());
    }
  }

  // Insert kInstAltMatch instructions
  // Look for
  //   ip: Alt -> j | k
  //	  j: ByteRange [00-FF] -> ip
  //    k: Match
  // or the reverse (the above is the greedy one).
  // Rewrite Alt to AltMatch.
  q.clear();
  AddToQueue(&q, start_);
  for (Workq::iterator i = q.begin(); i != q.end(); ++i) {
    int id = *i;
    Inst* ip = inst(id);
    AddToQueue(&q, ip->out());
    if (ip->opcode() == kInstAlt)
      AddToQueue(&q, ip->out1());

    if (ip->opcode() == kInstAlt) {
      Inst* j = inst(ip->out());
      Inst* k = inst(ip->out1());
      if (j->opcode() == kInstByteRange && j->out() == id &&
          j->lo() == 0x00 && j->hi() == 0xFF &&
          IsMatch(this, k)) {
        ip->set_opcode(kInstAltMatch);
        continue;
      }
      if (IsMatch(this, j) &&
          k->opcode() == kInstByteRange && k->out() == id &&
          k->lo() == 0x00 && k->hi() == 0xFF) {
        ip->set_opcode(kInstAltMatch);
      }
    }
  }
}

// Is ip a guaranteed match at end of text, perhaps after some capturing?
static bool IsMatch(Prog* prog, Prog::Inst* ip) {
  for (;;) {
    switch (ip->opcode()) {
      default:
        LOG(DFATAL) << "Unexpected opcode in IsMatch: " << ip->opcode();
        return false;

      case kInstAlt:
      case kInstAltMatch:
      case kInstByteRange:
      case kInstFail:
      case kInstEmptyWidth:
        return false;

      case kInstCapture:
      case kInstNop:
        ip = prog->inst(ip->out());
        break;

      case kInstMatch:
        return true;
    }
  }
}

uint32 Prog::EmptyFlags(const StringPiece& text, const char* p) {
  int flags = 0;

  // ^ and \A
  if (p == text.begin())
    flags |= kEmptyBeginText | kEmptyBeginLine;
  else if (p[-1] == '\n')
    flags |= kEmptyBeginLine;

  // $ and \z
  if (p == text.end())
    flags |= kEmptyEndText | kEmptyEndLine;
  else if (p < text.end() && p[0] == '\n')
    flags |= kEmptyEndLine;

  // \b and \B
  if (p == text.begin() && p == text.end()) {
    // no word boundary here
  } else if (p == text.begin()) {
    if (IsWordChar(p[0]))
      flags |= kEmptyWordBoundary;
  } else if (p == text.end()) {
    if (IsWordChar(p[-1]))
      flags |= kEmptyWordBoundary;
  } else {
    if (IsWordChar(p[-1]) != IsWordChar(p[0]))
      flags |= kEmptyWordBoundary;
  }
  if (!(flags & kEmptyWordBoundary))
    flags |= kEmptyNonWordBoundary;

  return flags;
}

void Prog::MarkByteRange(int lo, int hi) {
  CHECK_GE(lo, 0);
  CHECK_GE(hi, 0);
  CHECK_LE(lo, 255);
  CHECK_LE(hi, 255);
  if (lo > 0)
    byterange_.Set(lo - 1);
  byterange_.Set(hi);
}

void Prog::ComputeByteMap() {
  // Fill in bytemap with byte classes for prog_.
  // Ranges of bytes that are treated as indistinguishable
  // by the regexp program are mapped to a single byte class.
  // The vector prog_->byterange() marks the end of each
  // such range.
  const Bitmap<256>& v = byterange();

  COMPILE_ASSERT(8*sizeof(v.Word(0)) == 32, wordsize);
  uint8 n = 0;
  uint32 bits = 0;
  for (int i = 0; i < 256; i++) {
    if ((i&31) == 0)
      bits = v.Word(i >> 5);
    bytemap_[i] = n;
    n += bits & 1;
    bits >>= 1;
  }
  bytemap_range_ = bytemap_[255] + 1;
  unbytemap_ = new uint8[bytemap_range_];
  for (int i = 0; i < 256; i++)
    unbytemap_[bytemap_[i]] = i;

  if (0) {  // For debugging: use trivial byte map.
    for (int i = 0; i < 256; i++) {
      bytemap_[i] = i;
      unbytemap_[i] = i;
    }
    bytemap_range_ = 256;
    LOG(INFO) << "Using trivial bytemap.";
  }
}

}  // namespace re2

