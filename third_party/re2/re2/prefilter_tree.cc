// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/util.h"
#include "util/flags.h"
#include "re2/prefilter.h"
#include "re2/prefilter_tree.h"
#include "re2/re2.h"

#ifdef WIN32
#include <stdio.h>
#define snprintf _snprintf
#endif

DEFINE_int32(filtered_re2_min_atom_len,
             3,
             "Strings less than this length are not stored as atoms");

namespace re2 {

PrefilterTree::PrefilterTree()
    : compiled_(false) {
}

PrefilterTree::~PrefilterTree() {
  for (int i = 0; i < prefilter_vec_.size(); i++)
    delete prefilter_vec_[i];

  for (int i = 0; i < entries_.size(); i++)
    delete entries_[i].parents;
}

// Functions used for adding and Compiling prefilters to the
// PrefilterTree.
static bool KeepPart(Prefilter* prefilter, int level) {
  if (prefilter == NULL)
    return false;

  switch (prefilter->op()) {
    default:
      LOG(DFATAL) << "Unexpected op in KeepPart: "
                  << prefilter->op();
      return false;

    case Prefilter::ALL:
      return false;

    case Prefilter::ATOM:
      return prefilter->atom().size() >=
          FLAGS_filtered_re2_min_atom_len;

    case Prefilter::AND: {
      int j = 0;
      vector<Prefilter*>* subs = prefilter->subs();
      for (int i = 0; i < subs->size(); i++)
        if (KeepPart((*subs)[i], level + 1))
          (*subs)[j++] = (*subs)[i];
        else
          delete (*subs)[i];

      subs->resize(j);
      return j > 0;
    }

    case Prefilter::OR:
      for (int i = 0; i < prefilter->subs()->size(); i++)
        if (!KeepPart((*prefilter->subs())[i], level + 1))
          return false;
      return true;
  }
}

void PrefilterTree::Add(Prefilter *f) {
  if (compiled_) {
    LOG(DFATAL) << "Add after Compile.";
    return;
  }
  if (f != NULL && !KeepPart(f, 0)) {
    delete f;
    f = NULL;
  }

  prefilter_vec_.push_back(f);
}

void PrefilterTree::Compile(vector<string>* atom_vec) {
  if (compiled_) {
    LOG(DFATAL) << "Compile after Compile.";
    return;
  }

  // We do this check to support some legacy uses of
  // PrefilterTree that call Compile before adding any regexps,
  // and expect Compile not to have effect.
  if (prefilter_vec_.empty())
    return;

  compiled_ = true;

  AssignUniqueIds(atom_vec);

  // Identify nodes that are too common among prefilters and are
  // triggering too many parents. Then get rid of them if possible.
  // Note that getting rid of a prefilter node simply means they are
  // no longer necessary for their parent to trigger; that is, we do
  // not miss out on any regexps triggering by getting rid of a
  // prefilter node.
  for (int i = 0; i < entries_.size(); i++) {
    StdIntMap* parents = entries_[i].parents;
    if (parents->size() > 8) {
      // This one triggers too many things. If all the parents are AND
      // nodes and have other things guarding them, then get rid of
      // this trigger. TODO(vsri): Adjust the threshold appropriately,
      // make it a function of total number of nodes?
      bool have_other_guard = true;
      for (StdIntMap::iterator it = parents->begin();
           it != parents->end(); ++it) {
        have_other_guard = have_other_guard &&
            (entries_[it->first].propagate_up_at_count > 1);
      }

      if (have_other_guard) {
        for (StdIntMap::iterator it = parents->begin();
             it != parents->end(); ++it)
          entries_[it->first].propagate_up_at_count -= 1;

        parents->clear();  // Forget the parents
      }
    }
  }

  PrintDebugInfo();
}

Prefilter* PrefilterTree::CanonicalNode(Prefilter* node) {
  string node_string = NodeString(node);
  map<string, Prefilter*>::iterator iter = node_map_.find(node_string);
  if (iter == node_map_.end())
    return NULL;
  return (*iter).second;
}

static string Itoa(int n) {
  char buf[100];
  snprintf(buf, sizeof buf, "%d", n);
  return string(buf);
}

string PrefilterTree::NodeString(Prefilter* node) const {
  // Adding the operation disambiguates AND/OR/atom nodes.
  string s = Itoa(node->op()) + ":";
  if (node->op() == Prefilter::ATOM) {
    s += node->atom();
  } else {
    for (int i = 0; i < node->subs()->size() ; i++) {
      if (i > 0)
        s += ',';
      s += Itoa((*node->subs())[i]->unique_id());
    }
  }
  return s;
}

void PrefilterTree::AssignUniqueIds(vector<string>* atom_vec) {
  atom_vec->clear();

  // Build vector of all filter nodes, sorted topologically
  // from top to bottom in v.
  vector<Prefilter*> v;

  // Add the top level nodes of each regexp prefilter.
  for (int i = 0; i < prefilter_vec_.size(); i++) {
    Prefilter* f = prefilter_vec_[i];
    if (f == NULL)
      unfiltered_.push_back(i);

    // We push NULL also on to v, so that we maintain the
    // mapping of index==regexpid for level=0 prefilter nodes.
    v.push_back(f);
  }

  // Now add all the descendant nodes.
  for (int i = 0; i < v.size(); i++) {
    Prefilter* f = v[i];
    if (f == NULL)
      continue;
    if (f->op() == Prefilter::AND || f->op() == Prefilter::OR) {
      const vector<Prefilter*>& subs = *f->subs();
      for (int j = 0; j < subs.size(); j++)
        v.push_back(subs[j]);
    }
  }

  // Identify unique nodes.
  int unique_id = 0;
  for (int i = v.size() - 1; i >= 0; i--) {
    Prefilter *node = v[i];
    if (node == NULL)
      continue;
    node->set_unique_id(-1);
    Prefilter* canonical = CanonicalNode(node);
    if (canonical == NULL) {
      // Any further nodes that have the same node string
      // will find this node as the canonical node.
      node_map_[NodeString(node)] = node;
      if (node->op() == Prefilter::ATOM) {
        atom_vec->push_back(node->atom());
        atom_index_to_id_.push_back(unique_id);
      }
      node->set_unique_id(unique_id++);
    } else {
      node->set_unique_id(canonical->unique_id());
    }
  }
  entries_.resize(node_map_.size());

  // Create parent StdIntMap for the entries.
  for (int i = v.size()  - 1; i >= 0; i--) {
    Prefilter* prefilter = v[i];
    if (prefilter == NULL)
      continue;

    if (CanonicalNode(prefilter) != prefilter)
      continue;

    Entry* entry = &entries_[prefilter->unique_id()];
    entry->parents = new StdIntMap();
  }

  // Fill the entries.
  for (int i = v.size()  - 1; i >= 0; i--) {
    Prefilter* prefilter = v[i];
    if (prefilter == NULL)
      continue;

    if (CanonicalNode(prefilter) != prefilter)
      continue;

    Entry* entry = &entries_[prefilter->unique_id()];

    switch (prefilter->op()) {
      default:
      case Prefilter::ALL:
        LOG(DFATAL) << "Unexpected op: " << prefilter->op();
        return;

      case Prefilter::ATOM:
        entry->propagate_up_at_count = 1;
        break;

      case Prefilter::OR:
      case Prefilter::AND: {
        std::set<int> uniq_child;
        for (int j = 0; j < prefilter->subs()->size() ; j++) {
          Prefilter* child = (*prefilter->subs())[j];
          Prefilter* canonical = CanonicalNode(child);
          if (canonical == NULL) {
            LOG(DFATAL) << "Null canonical node";
            return;
          }
          int child_id = canonical->unique_id();
          uniq_child.insert(child_id);
          // To the child, we want to add to parent indices.
          Entry* child_entry = &entries_[child_id];
          if (child_entry->parents->find(prefilter->unique_id()) ==
              child_entry->parents->end())
            (*child_entry->parents)[prefilter->unique_id()] = 1;
        }
        entry->propagate_up_at_count =
            prefilter->op() == Prefilter::AND ? uniq_child.size() : 1;

        break;
      }
    }
  }

  // For top level nodes, populate regexp id.
  for (int i = 0; i < prefilter_vec_.size(); i++) {
    if (prefilter_vec_[i] == NULL)
      continue;
    int id = CanonicalNode(prefilter_vec_[i])->unique_id();
    DCHECK_LE(0, id);
    Entry* entry = &entries_[id];
    entry->regexps.push_back(i);
  }
}

// Functions for triggering during search.
void PrefilterTree::RegexpsGivenStrings(
    const vector<int>& matched_atoms,
    vector<int>* regexps) const {
  regexps->clear();
  if (!compiled_) {
    LOG(WARNING) << "Compile() not called";
    for (int i = 0; i < prefilter_vec_.size(); ++i)
      regexps->push_back(i);
  } else {
    if (!prefilter_vec_.empty()) {
      IntMap regexps_map(prefilter_vec_.size());
      vector<int> matched_atom_ids;
      for (int j = 0; j < matched_atoms.size(); j++) {
        matched_atom_ids.push_back(atom_index_to_id_[matched_atoms[j]]);
        VLOG(10) << "Atom id:" << atom_index_to_id_[matched_atoms[j]];
      }
      PropagateMatch(matched_atom_ids, &regexps_map);
      for (IntMap::iterator it = regexps_map.begin();
           it != regexps_map.end();
           ++it)
        regexps->push_back(it->index());

      regexps->insert(regexps->end(), unfiltered_.begin(), unfiltered_.end());
    }
  }
  sort(regexps->begin(), regexps->end());
}

void PrefilterTree::PropagateMatch(const vector<int>& atom_ids,
                                   IntMap* regexps) const {
  IntMap count(entries_.size());
  IntMap work(entries_.size());
  for (int i = 0; i < atom_ids.size(); i++)
    work.set(atom_ids[i], 1);
  for (IntMap::iterator it = work.begin(); it != work.end(); ++it) {
    const Entry& entry = entries_[it->index()];
    VLOG(10) << "Processing: " << it->index();
    // Record regexps triggered.
    for (int i = 0; i < entry.regexps.size(); i++) {
      VLOG(10) << "Regexp triggered: " << entry.regexps[i];
      regexps->set(entry.regexps[i], 1);
    }
    int c;
    // Pass trigger up to parents.
    for (StdIntMap::iterator it = entry.parents->begin();
         it != entry.parents->end();
         ++it) {
      int j = it->first;
      const Entry& parent = entries_[j];
      VLOG(10) << " parent= " << j << " trig= " << parent.propagate_up_at_count;
      // Delay until all the children have succeeded.
      if (parent.propagate_up_at_count > 1) {
        if (count.has_index(j)) {
          c = count.get_existing(j) + 1;
          count.set_existing(j, c);
        } else {
          c = 1;
          count.set_new(j, c);
        }
        if (c < parent.propagate_up_at_count)
          continue;
      }
      VLOG(10) << "Triggering: " << j;
      // Trigger the parent.
      work.set(j, 1);
    }
  }
}

// Debugging help.
void PrefilterTree::PrintPrefilter(int regexpid) {
  LOG(INFO) << DebugNodeString(prefilter_vec_[regexpid]);
}

void PrefilterTree::PrintDebugInfo() {
  VLOG(10) << "#Unique Atoms: " << atom_index_to_id_.size();
  VLOG(10) << "#Unique Nodes: " << entries_.size();

  for (int i = 0; i < entries_.size(); ++i) {
    StdIntMap* parents = entries_[i].parents;
    const vector<int>& regexps = entries_[i].regexps;
    VLOG(10) << "EntryId: " << i
            << " N: " << parents->size() << " R: " << regexps.size();
    for (StdIntMap::iterator it = parents->begin(); it != parents->end(); ++it)
      VLOG(10) << it->first;
  }
  VLOG(10) << "Map:";
  for (map<string, Prefilter*>::const_iterator iter = node_map_.begin();
       iter != node_map_.end(); ++iter)
    VLOG(10) << "NodeId: " << (*iter).second->unique_id()
            << " Str: " << (*iter).first;
}

string PrefilterTree::DebugNodeString(Prefilter* node) const {
  string node_string = "";

  if (node->op() == Prefilter::ATOM) {
    DCHECK(!node->atom().empty());
    node_string += node->atom();
  } else {
    // Adding the operation disambiguates AND and OR nodes.
    node_string +=  node->op() == Prefilter::AND ? "AND" : "OR";
    node_string += "(";
    for (int i = 0; i < node->subs()->size() ; i++) {
      if (i > 0)
        node_string += ',';
      node_string += Itoa((*node->subs())[i]->unique_id());
      node_string += ":";
      node_string += DebugNodeString((*node->subs())[i]);
    }
    node_string += ")";
  }
  return node_string;
}

}  // namespace re2
