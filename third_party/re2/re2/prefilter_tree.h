// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// The PrefilterTree class is used to form an AND-OR tree of strings
// that would trigger each regexp. The 'prefilter' of each regexp is
// added tp PrefilterTree, and then PrefilterTree is used to find all
// the unique strings across the prefilters. During search, by using
// matches from a string matching engine, PrefilterTree deduces the
// set of regexps that are to be triggered. The 'string matching
// engine' itself is outside of this class, and the caller can use any
// favorite engine. PrefilterTree provides a set of strings (called
// atoms) that the user of this class should use to do the string
// matching.
//
#ifndef RE2_PREFILTER_TREE_H_
#define RE2_PREFILTER_TREE_H_

#include <map>

#include "util/util.h"
#include "util/sparse_array.h"

namespace re2 {

typedef SparseArray<int> IntMap;
typedef std::map<int, int> StdIntMap;

class Prefilter;

class PrefilterTree {
 public:
  PrefilterTree();
  ~PrefilterTree();

  // Adds the prefilter for the next regexp. Note that we assume that
  // Add called sequentially for all regexps. All Add calls
  // must precede Compile.
  void Add(Prefilter* prefilter);

  // The Compile returns a vector of string in atom_vec.
  // Call this after all the prefilters are added through Add.
  // No calls to Add after Compile are allowed.
  // The caller should use the returned set of strings to do string matching.
  // Each time a string matches, the corresponding index then has to be
  // and passed to RegexpsGivenStrings below.
  void Compile(vector<string>* atom_vec);

  // Given the indices of the atoms that matched, returns the indexes
  // of regexps that should be searched.  The matched_atoms should
  // contain all the ids of string atoms that were found to match the
  // content. The caller can use any string match engine to perform
  // this function. This function is thread safe.
  void RegexpsGivenStrings(const vector<int>& matched_atoms,
                           vector<int>* regexps) const;

  // Print debug prefilter. Also prints unique ids associated with
  // nodes of the prefilter of the regexp.
  void PrintPrefilter(int regexpid);


  // Each unique node has a corresponding Entry that helps in
  // passing the matching trigger information along the tree.
  struct Entry {
   public:
    // How many children should match before this node triggers the
    // parent. For an atom and an OR node, this is 1 and for an AND
    // node, it is the number of unique children.
    int propagate_up_at_count;

    // When this node is ready to trigger the parent, what are the indices
    // of the parent nodes to trigger. The reason there may be more than
    // one is because of sharing. For example (abc | def) and (xyz | def)
    // are two different nodes, but they share the atom 'def'. So when
    // 'def' matches, it triggers two parents, corresponding to the two
    // different OR nodes.
    StdIntMap* parents;

    // When this node is ready to trigger the parent, what are the
    // regexps that are triggered.
    vector<int> regexps;
  };

 private:
  // This function assigns unique ids to various parts of the
  // prefilter, by looking at if these nodes are already in the
  // PrefilterTree.
  void AssignUniqueIds(vector<string>* atom_vec);

  // Given the matching atoms, find the regexps to be triggered.
  void PropagateMatch(const vector<int>& atom_ids,
                      IntMap* regexps) const;

  // Returns the prefilter node that has the same NodeString as this
  // node. For the canonical node, returns node.
  Prefilter* CanonicalNode(Prefilter* node);

  // A string that uniquely identifies the node. Assumes that the
  // children of node has already been assigned unique ids.
  string NodeString(Prefilter* node) const;

  // Recursively constructs a readable prefilter string.
  string DebugNodeString(Prefilter* node) const;

  // Used for debugging.
  void PrintDebugInfo();

  // These are all the nodes formed by Compile. Essentially, there is
  // one node for each unique atom and each unique AND/OR node.
  vector<Entry> entries_;

  // Map node string to canonical Prefilter node.
  map<string, Prefilter*> node_map_;

  // indices of regexps that always pass through the filter (since we
  // found no required literals in these regexps).
  vector<int> unfiltered_;

  // vector of Prefilter for all regexps.
  vector<Prefilter*> prefilter_vec_;

  // Atom index in returned strings to entry id mapping.
  vector<int> atom_index_to_id_;

  // Has the prefilter tree been compiled.
  bool compiled_;

  DISALLOW_EVIL_CONSTRUCTORS(PrefilterTree);
};

}  // namespace

#endif  // RE2_PREFILTER_TREE_H_
