// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Test character class manipulations.

#include "util/test.h"
#include "re2/regexp.h"

namespace re2 {

struct CCTest {
  struct {
    Rune lo;
    Rune hi;
  } add[10];
  int remove;
  struct {
    Rune lo;
    Rune hi;
  } final[10];
};

static CCTest tests[] = {
  { { { 10, 20 }, {-1} }, -1,
    { { 10, 20 }, {-1} } },

  { { { 10, 20 }, { 20, 30 }, {-1} }, -1,
    { { 10, 30 }, {-1} } },

  { { { 10, 20 }, { 30, 40 }, { 20, 30 }, {-1} }, -1,
    { { 10, 40 }, {-1} } },

  { { { 0, 50 }, { 20, 30 }, {-1} }, -1,
    { { 0, 50 }, {-1} } },

  { { { 10, 11 }, { 13, 14 }, { 16, 17 }, { 19, 20 }, { 22, 23 }, {-1} }, -1,
    { { 10, 11 }, { 13, 14 }, { 16, 17 }, { 19, 20 }, { 22, 23 }, {-1} } },

  { { { 13, 14 }, { 10, 11 }, { 22, 23 }, { 19, 20 }, { 16, 17 }, {-1} }, -1,
    { { 10, 11 }, { 13, 14 }, { 16, 17 }, { 19, 20 }, { 22, 23 }, {-1} } },

  { { { 13, 14 }, { 10, 11 }, { 22, 23 }, { 19, 20 }, { 16, 17 }, {-1} }, -1,
    { { 10, 11 }, { 13, 14 }, { 16, 17 }, { 19, 20 }, { 22, 23 }, {-1} } },

  { { { 13, 14 }, { 10, 11 }, { 22, 23 }, { 19, 20 }, { 16, 17 }, { 5, 25 }, {-1} }, -1,
    { { 5, 25 }, {-1} } },

  { { { 13, 14 }, { 10, 11 }, { 22, 23 }, { 19, 20 }, { 16, 17 }, { 12, 21 }, {-1} }, -1,
    { { 10, 23 }, {-1} } },

  // These check boundary cases during negation.
  { { { 0, Runemax }, {-1} }, -1,
    { { 0, Runemax }, {-1} } },

  { { { 0, 50 }, {-1} }, -1,
    { { 0, 50 }, {-1} } },

  { { { 50, Runemax }, {-1} }, -1,
    { { 50, Runemax }, {-1} } },

  // Check RemoveAbove.
  { { { 50, Runemax }, {-1} }, 255,
    { { 50, 255 }, {-1} } },

  { { { 50, Runemax }, {-1} }, 65535,
    { { 50, 65535 }, {-1} } },

  { { { 50, Runemax }, {-1} }, Runemax,
    { { 50, Runemax }, {-1} } },

  { { { 50, 60 }, { 250, 260 }, { 350, 360 }, {-1} }, 255,
    { { 50, 60 }, { 250, 255 }, {-1} } },

  { { { 50, 60 }, {-1} }, 255,
    { { 50, 60 }, {-1} } },

  { { { 350, 360 }, {-1} }, 255,
    { {-1} } },

  { { {-1} }, 255,
    { {-1} } },
};

template<class CharClass>
static void Broke(const char *desc, const CCTest* t, CharClass* cc) {
  if (t == NULL) {
    printf("\t%s:", desc);
  } else {
    printf("\n");
    printf("CharClass added: [%s]", desc);
    for (int k = 0; t->add[k].lo >= 0; k++)
      printf(" %d-%d", t->add[k].lo, t->add[k].hi);
    printf("\n");
    if (t->remove >= 0)
      printf("Removed > %d\n", t->remove);
    printf("\twant:");
    for (int k = 0; t->final[k].lo >= 0; k++)
      printf(" %d-%d", t->final[k].lo, t->final[k].hi);
    printf("\n");
    printf("\thave:");
  }

  for (typename CharClass::iterator it = cc->begin(); it != cc->end(); ++it)
    printf(" %d-%d", it->lo, it->hi);
  printf("\n");
}

bool ShouldContain(CCTest *t, int x) {
  for (int j = 0; t->final[j].lo >= 0; j++)
    if (t->final[j].lo <= x && x <= t->final[j].hi)
      return true;
  return false;
}

// Helpers to make templated CorrectCC work with both CharClass and CharClassBuilder.

CharClass* Negate(CharClass *cc) {
  return cc->Negate();
}

void Delete(CharClass* cc) {
  cc->Delete();
}

CharClassBuilder* Negate(CharClassBuilder* cc) {
  CharClassBuilder* ncc = cc->Copy();
  ncc->Negate();
  return ncc;
}

void Delete(CharClassBuilder* cc) {
  delete cc;
}

template<class CharClass>
bool CorrectCC(CharClass *cc, CCTest *t, const char *desc) {
  typename CharClass::iterator it = cc->begin();
  int size = 0;
  for (int j = 0; t->final[j].lo >= 0; j++, ++it) {
    if (it == cc->end() ||
        it->lo != t->final[j].lo ||
        it->hi != t->final[j].hi) {
      Broke(desc, t, cc);
      return false;
    }
    size += it->hi - it->lo + 1;
  }
  if (it != cc->end()) {
    Broke(desc, t, cc);
    return false;
  }
  if (cc->size() != size) {
    Broke(desc, t, cc);
    printf("wrong size: want %d have %d\n", size, cc->size());
    return false;
  }

  for (int j = 0; j < 101; j++) {
    if (j == 100)
      j = Runemax;
    if (ShouldContain(t, j) != cc->Contains(j)) {
      Broke(desc, t, cc);
      printf("want contains(%d)=%d, got %d\n",
             j, ShouldContain(t, j), cc->Contains(j));
      return false;
    }
  }

  CharClass* ncc = Negate(cc);
  for (int j = 0; j < 101; j++) {
    if (j == 100)
      j = Runemax;
    if (ShouldContain(t, j) == ncc->Contains(j)) {
      Broke(desc, t, cc);
      Broke("ncc", NULL, ncc);
      printf("want ncc contains(%d)!=%d, got %d\n",
             j, ShouldContain(t, j), ncc->Contains(j));
      Delete(ncc);
      return false;
    }
    if (ncc->size() != Runemax+1 - cc->size()) {
      Broke(desc, t, cc);
      Broke("ncc", NULL, ncc);
      printf("ncc size should be %d is %d\n",
             Runemax+1 - cc->size(), ncc->size());
      Delete(ncc);
      return false;
    }
  }
  Delete(ncc);
  return true;
}

TEST(TestCharClassBuilder, Adds) {
  int nfail = 0;
  for (int i = 0; i < arraysize(tests); i++) {
    CharClassBuilder ccb;
    CCTest* t = &tests[i];
    for (int j = 0; t->add[j].lo >= 0; j++)
      ccb.AddRange(t->add[j].lo, t->add[j].hi);
    if (t->remove >= 0)
      ccb.RemoveAbove(t->remove);
    if (!CorrectCC(&ccb, t, "before copy (CharClassBuilder)"))
      nfail++;
    CharClass* cc = ccb.GetCharClass();
    if (!CorrectCC(cc, t, "before copy (CharClass)"))
      nfail++;
    cc->Delete();

    CharClassBuilder *ccb1 = ccb.Copy();
    if (!CorrectCC(ccb1, t, "after copy (CharClassBuilder)"))
      nfail++;
    cc = ccb.GetCharClass();
    if (!CorrectCC(cc, t, "after copy (CharClass)"))
      nfail++;
    cc->Delete();
    delete ccb1;
  }
  EXPECT_EQ(nfail, 0);
}

}  // namespace re2
