// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/test.h"
#include "re2/filtered_re2.h"
#include "re2/re2.h"

DECLARE_int32(filtered_re2_min_atom_len); // From prefilter_tree.cc

namespace re2 {

struct FilterTestVars {
  vector<string> atoms;
  vector<int> atom_indices;
  vector<int> matches;
  RE2::Options opts;
  FilteredRE2 f;
};

TEST(FilteredRE2Test, EmptyTest) {
  FilterTestVars v;
  v.f.AllMatches("foo", v.atom_indices, &v.matches);
  EXPECT_EQ(0, v.matches.size());
}

TEST(FilteredRE2Test, SmallOrTest) {
  FLAGS_filtered_re2_min_atom_len = 4;

  FilterTestVars v;
  int id;
  v.f.Add("(foo|bar)", v.opts, &id);

  v.f.Compile(&v.atoms);
  EXPECT_EQ(0, v.atoms.size());

  v.f.AllMatches("lemurs bar", v.atom_indices, &v.matches);
  EXPECT_EQ(1, v.matches.size());
  EXPECT_EQ(id, v.matches[0]);
}

TEST(FilteredRE2Test, SmallLatinTest) {
  FLAGS_filtered_re2_min_atom_len = 3;
  FilterTestVars v;
  int id;

  v.opts.set_utf8(false);
  v.f.Add("\xde\xadQ\xbe\xef", v.opts, &id);
  v.f.Compile(&v.atoms);
  EXPECT_EQ(1, v.atoms.size());
  EXPECT_EQ(v.atoms[0], "\xde\xadq\xbe\xef");

  v.atom_indices.push_back(0);
  v.f.AllMatches("foo\xde\xadQ\xbe\xeflemur", v.atom_indices, &v.matches);
  EXPECT_EQ(1, v.matches.size());
  EXPECT_EQ(id, v.matches[0]);
}

struct AtomTest {
  const char* testname;
  // If any test needs more than this many regexps or atoms, increase
  // the size of the corresponding array.
  const char* regexps[20];
  const char* atoms[20];
};

AtomTest atom_tests[] = {
  {
    // This test checks to make sure empty patterns are allowed.
    "CheckEmptyPattern",
    {""},
    {}
  }, {
    // This test checks that all atoms of length greater than min length
    // are found, and no atoms that are of smaller length are found.
    "AllAtomsGtMinLengthFound", {
      "(abc123|def456|ghi789).*mnop[x-z]+",
      "abc..yyy..zz",
      "mnmnpp[a-z]+PPP"
    }, {
      "abc123",
      "def456",
      "ghi789",
      "mnop",
      "abc",
      "yyy",
      "mnmnpp",
      "ppp"
    }
  }, {
    // Test to make sure that any atoms that have another atom as a
    // substring in an OR are removed; that is, only the shortest
    // substring is kept.
    "SubstrAtomRemovesSuperStrInOr", {
      "(abc123|abc|ghi789|abc1234).*[x-z]+",
      "abcd..yyy..yyyzzz",
      "mnmnpp[a-z]+PPP"
    }, {
      "abc",
      "ghi789",
      "abcd",
      "yyy",
      "yyyzzz",
      "mnmnpp",
      "ppp"
    }
  }, {
    // Test character class expansion.
    "CharClassExpansion", {
      "m[a-c][d-f]n.*[x-z]+",
      "[x-y]bcde[ab]"
    }, {
      "madn", "maen", "mafn",
      "mbdn", "mben", "mbfn",
      "mcdn", "mcen", "mcfn",
      "xbcdea", "xbcdeb",
      "ybcdea", "ybcdeb"
    }
  }, {
    // Test upper/lower of non-ASCII.
    "UnicodeLower", {
      "(?i)ΔδΠϖπΣςσ",
      "ΛΜΝΟΠ",
      "ψρστυ",
    }, {
      "δδπππσσσ",
      "λμνοπ",
      "ψρστυ",
    },
  },
};

void AddRegexpsAndCompile(const char* regexps[],
                          int n,
                          struct FilterTestVars* v) {
  for (int i = 0; i < n; i++) {
    int id;
    v->f.Add(regexps[i], v->opts, &id);
  }
  v->f.Compile(&v->atoms);
}

bool CheckExpectedAtoms(const char* atoms[],
                        int n,
                        const char* testname,
                        struct FilterTestVars* v) {
  vector<string> expected;
  for (int i = 0; i < n; i++)
    expected.push_back(atoms[i]);

  bool pass = expected.size() == v->atoms.size();

  sort(v->atoms.begin(), v->atoms.end());
  sort(expected.begin(), expected.end());
  for (int i = 0; pass && i < n; i++)
      pass = pass && expected[i] == v->atoms[i];

  if (!pass) {
    LOG(WARNING) << "Failed " << testname;
    LOG(WARNING) << "Expected #atoms = " << expected.size();
    for (int i = 0; i < expected.size(); i++)
      LOG(WARNING) << expected[i];
    LOG(WARNING) << "Found #atoms = " << v->atoms.size();
    for (int i = 0; i < v->atoms.size(); i++)
      LOG(WARNING) << v->atoms[i];
  }

  return pass;
}

TEST(FilteredRE2Test, AtomTests) {
  FLAGS_filtered_re2_min_atom_len = 3;

  int nfail = 0;
  for (int i = 0; i < arraysize(atom_tests); i++) {
    FilterTestVars v;
    AtomTest* t = &atom_tests[i];
    int natom, nregexp;
    for (nregexp = 0; nregexp < arraysize(t->regexps); nregexp++)
      if (t->regexps[nregexp] == NULL)
        break;
    for (natom = 0; natom < arraysize(t->atoms); natom++)
      if (t->atoms[natom] == NULL)
        break;
    AddRegexpsAndCompile(t->regexps, nregexp, &v);
    if (!CheckExpectedAtoms(t->atoms, natom, t->testname, &v))
      nfail++;
  }
  EXPECT_EQ(0, nfail);
}

void FindAtomIndices(const vector<string> atoms,
                     const vector<string> matched_atoms,
                     vector<int>* atom_indices) {
  atom_indices->clear();
  for (int i = 0; i < matched_atoms.size(); i++) {
    int j = 0;
    for (; j < atoms.size(); j++) {
      if (matched_atoms[i] == atoms[j]) {
        atom_indices->push_back(j);
        break;
      }
      EXPECT_LT(j, atoms.size());
    }
  }
}

TEST(FilteredRE2Test, MatchEmptyPattern) {
  FLAGS_filtered_re2_min_atom_len = 3;

  FilterTestVars v;
  AtomTest* t = &atom_tests[0];
  // We are using the regexps used in one of the atom tests
  // for this test. Adding the EXPECT here to make sure
  // the index we use for the test is for the correct test.
  EXPECT_EQ("CheckEmptyPattern", string(t->testname));
  int nregexp;
  for (nregexp = 0; nregexp < arraysize(t->regexps); nregexp++)
    if (t->regexps[nregexp] == NULL)
      break;
  AddRegexpsAndCompile(t->regexps, nregexp, &v);
  string text = "0123";
  vector<int> atom_ids;
  vector<int> matching_regexps;
  EXPECT_EQ(0, v.f.FirstMatch(text, atom_ids));
}

TEST(FilteredRE2Test, MatchTests) {
  FLAGS_filtered_re2_min_atom_len = 3;

  FilterTestVars v;
  AtomTest* t = &atom_tests[2];
  // We are using the regexps used in one of the atom tests
  // for this test.
  EXPECT_EQ("SubstrAtomRemovesSuperStrInOr", string(t->testname));
  int nregexp;
  for (nregexp = 0; nregexp < arraysize(t->regexps); nregexp++)
    if (t->regexps[nregexp] == NULL)
      break;
  AddRegexpsAndCompile(t->regexps, nregexp, &v);

  string text = "abc121212xyz";
  // atoms = abc
  vector<int> atom_ids;
  vector<string> atoms;
  atoms.push_back("abc");
  FindAtomIndices(v.atoms, atoms, &atom_ids);
  vector<int> matching_regexps;
  v.f.AllMatches(text, atom_ids, &matching_regexps);
  EXPECT_EQ(1, matching_regexps.size());

  text = "abc12312yyyzzz";
  atoms.clear();
  atoms.push_back("abc");
  atoms.push_back("yyy");
  atoms.push_back("yyyzzz");
  FindAtomIndices(v.atoms, atoms, &atom_ids);
  v.f.AllMatches(text, atom_ids, &matching_regexps);
  EXPECT_EQ(1, matching_regexps.size());

  text = "abcd12yyy32yyyzzz";
  atoms.clear();
  atoms.push_back("abc");
  atoms.push_back("abcd");
  atoms.push_back("yyy");
  atoms.push_back("yyyzzz");
  FindAtomIndices(v.atoms, atoms, &atom_ids);
  LOG(INFO) << "S: " << atom_ids.size();
  for (int i = 0; i < atom_ids.size(); i++)
    LOG(INFO) << "i: " << i << " : " << atom_ids[i];
  v.f.AllMatches(text, atom_ids, &matching_regexps);
  EXPECT_EQ(2, matching_regexps.size());
}

}  //  namespace re2
