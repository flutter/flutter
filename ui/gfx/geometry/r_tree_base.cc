// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/r_tree_base.h"

#include <algorithm>

#include "base/logging.h"


// Helpers --------------------------------------------------------------------

namespace {

// Returns a Vector2d to allow us to do arithmetic on the result such as
// computing distances between centers.
gfx::Vector2d CenterOfRect(const gfx::Rect& rect) {
  return rect.OffsetFromOrigin() +
      gfx::Vector2d(rect.width() / 2, rect.height() / 2);
}

}

namespace gfx {


// RTreeBase::NodeBase --------------------------------------------------------

RTreeBase::NodeBase::~NodeBase() {
}

void RTreeBase::NodeBase::RecomputeBoundsUpToRoot() {
  RecomputeLocalBounds();
  if (parent_)
    parent_->RecomputeBoundsUpToRoot();
}

RTreeBase::NodeBase::NodeBase(const Rect& rect, NodeBase* parent)
    : rect_(rect),
      parent_(parent) {
}

void RTreeBase::NodeBase::RecomputeLocalBounds() {
}

// RTreeBase::RecordBase ------------------------------------------------------

RTreeBase::RecordBase::RecordBase(const Rect& rect) : NodeBase(rect, NULL) {
}

RTreeBase::RecordBase::~RecordBase() {
}

void RTreeBase::RecordBase::AppendIntersectingRecords(
    const Rect& query_rect, Records* matches_out) const {
  if (rect().Intersects(query_rect))
    matches_out->push_back(this);
}

void RTreeBase::RecordBase::AppendAllRecords(Records* matches_out) const {
  matches_out->push_back(this);
}

scoped_ptr<RTreeBase::NodeBase>
RTreeBase::RecordBase::RemoveAndReturnLastChild() {
  return scoped_ptr<NodeBase>();
}

int RTreeBase::RecordBase::Level() const {
  return -1;
}


// RTreeBase::Node ------------------------------------------------------------

RTreeBase::Node::Node() : NodeBase(Rect(), NULL), level_(0) {
}

RTreeBase::Node::~Node() {
}

scoped_ptr<RTreeBase::Node> RTreeBase::Node::ConstructParent() {
  DCHECK(!parent());
  scoped_ptr<Node> new_parent(new Node(level_ + 1));
  new_parent->AddChild(scoped_ptr<NodeBase>(this));
  return new_parent.Pass();
}

void RTreeBase::Node::AppendIntersectingRecords(
    const Rect& query_rect, Records* matches_out) const {
  // Check own bounding box for intersection, can cull all children if no
  // intersection.
  if (!rect().Intersects(query_rect))
    return;

  // Conversely if we are completely contained within the query rect we can
  // confidently skip all bounds checks for ourselves and all our children.
  if (query_rect.Contains(rect())) {
    AppendAllRecords(matches_out);
    return;
  }

  // We intersect the query rect but we are not are not contained within it.
  // We must query each of our children in turn.
  for (Nodes::const_iterator i = children_.begin(); i != children_.end(); ++i)
    (*i)->AppendIntersectingRecords(query_rect, matches_out);
}

void RTreeBase::Node::AppendAllRecords(Records* matches_out) const {
  for (Nodes::const_iterator i = children_.begin(); i != children_.end(); ++i)
    (*i)->AppendAllRecords(matches_out);
}

void RTreeBase::Node::RemoveNodesForReinsert(size_t number_to_remove,
                                             Nodes* nodes) {
  DCHECK_LE(number_to_remove, children_.size());

  std::partial_sort(children_.begin(),
                    children_.begin() + number_to_remove,
                    children_.end(),
                    &RTreeBase::Node::CompareCenterDistanceFromParent);

  // Move the lowest-distance nodes to the returned vector.
  nodes->insert(
      nodes->end(), children_.begin(), children_.begin() + number_to_remove);
  children_.weak_erase(children_.begin(), children_.begin() + number_to_remove);
}

scoped_ptr<RTreeBase::NodeBase> RTreeBase::Node::RemoveChild(
    NodeBase* child_node, Nodes* orphans) {
  DCHECK_EQ(this, child_node->parent());

  scoped_ptr<NodeBase> orphan(child_node->RemoveAndReturnLastChild());
  while (orphan) {
    orphans->push_back(orphan.release());
    orphan = child_node->RemoveAndReturnLastChild();
  }

  Nodes::iterator i = std::find(children_.begin(), children_.end(), child_node);
  DCHECK(i != children_.end());
  children_.weak_erase(i);

  return scoped_ptr<NodeBase>(child_node);
}

scoped_ptr<RTreeBase::NodeBase> RTreeBase::Node::RemoveAndReturnLastChild() {
  if (children_.empty())
    return scoped_ptr<NodeBase>();

  scoped_ptr<NodeBase> last_child(children_.back());
  children_.weak_erase(children_.end() - 1);
  last_child->set_parent(NULL);
  return last_child.Pass();
}

RTreeBase::Node* RTreeBase::Node::ChooseSubtree(NodeBase* node) {
  DCHECK(node);
  // Should never be called on a node at equal or lower level in the tree than
  // the node to insert.
  DCHECK_GT(level_, node->Level());

  // If we are a parent of nodes on the provided node level, we are done.
  if (level_ == node->Level() + 1)
    return this;

  // Precompute a vector of expanded rects, used by both LeastOverlapIncrease
  // and LeastAreaEnlargement.
  Rects expanded_rects;
  expanded_rects.reserve(children_.size());
  for (Nodes::iterator i = children_.begin(); i != children_.end(); ++i)
    expanded_rects.push_back(UnionRects(node->rect(), (*i)->rect()));

  Node* best_candidate = NULL;
  // For parents of leaf nodes, we pick the node that will cause the least
  // increase in overlap by the addition of this new node. This may detect a
  // tie, in which case it will return NULL.
  if (level_ == 1)
    best_candidate = LeastOverlapIncrease(node->rect(), expanded_rects);

  // For non-parents of leaf nodes, or for parents of leaf nodes with ties in
  // overlap increase, we choose the subtree with least area enlargement caused
  // by the addition of the new node.
  if (!best_candidate)
    best_candidate = LeastAreaEnlargement(node->rect(), expanded_rects);

  DCHECK(best_candidate);
  return best_candidate->ChooseSubtree(node);
}

size_t RTreeBase::Node::AddChild(scoped_ptr<NodeBase> node) {
  DCHECK(node);
  // Sanity-check that the level of the child being added is one less than ours.
  DCHECK_EQ(level_ - 1, node->Level());
  node->set_parent(this);
  set_rect(UnionRects(rect(), node->rect()));
  children_.push_back(node.release());
  return children_.size();
}

scoped_ptr<RTreeBase::NodeBase> RTreeBase::Node::Split(size_t min_children,
                                                       size_t max_children) {
  // We should have too many children to begin with.
  DCHECK_EQ(max_children + 1, children_.size());

  // Determine if we should split along the horizontal or vertical axis.
  std::vector<NodeBase*> vertical_sort(children_.get());
  std::vector<NodeBase*> horizontal_sort(children_.get());
  std::sort(vertical_sort.begin(),
            vertical_sort.end(),
            &RTreeBase::Node::CompareVertical);
  std::sort(horizontal_sort.begin(),
            horizontal_sort.end(),
            &RTreeBase::Node::CompareHorizontal);

  Rects low_vertical_bounds;
  Rects low_horizontal_bounds;
  BuildLowBounds(vertical_sort,
                 horizontal_sort,
                 &low_vertical_bounds,
                 &low_horizontal_bounds);

  Rects high_vertical_bounds;
  Rects high_horizontal_bounds;
  BuildHighBounds(vertical_sort,
                  horizontal_sort,
                  &high_vertical_bounds,
                  &high_horizontal_bounds);

  // Choose |end_index| such that both Nodes after the split will have
  // min_children <= children_.size() <= max_children.
  size_t end_index = std::min(max_children, children_.size() - min_children);
  bool is_vertical_split =
      SmallestMarginSum(min_children,
                        end_index,
                        low_horizontal_bounds,
                        high_horizontal_bounds) <
      SmallestMarginSum(min_children,
                        end_index,
                        low_vertical_bounds,
                        high_vertical_bounds);

  // Choose split index along chosen axis and perform the split.
  const Rects& low_bounds(
      is_vertical_split ? low_vertical_bounds : low_horizontal_bounds);
  const Rects& high_bounds(
      is_vertical_split ? high_vertical_bounds : high_horizontal_bounds);
  size_t split_index =
      ChooseSplitIndex(min_children, end_index, low_bounds, high_bounds);

  const std::vector<NodeBase*>& sort(
      is_vertical_split ? vertical_sort : horizontal_sort);
  return DivideChildren(low_bounds, high_bounds, sort, split_index);
}

int RTreeBase::Node::Level() const {
  return level_;
}

RTreeBase::Node::Node(int level) : NodeBase(Rect(), NULL), level_(level) {
}

// static
bool RTreeBase::Node::CompareVertical(const NodeBase* a, const NodeBase* b) {
  const Rect& a_rect = a->rect();
  const Rect& b_rect = b->rect();
  return (a_rect.y() < b_rect.y()) ||
         ((a_rect.y() == b_rect.y()) && (a_rect.height() < b_rect.height()));
}

// static
bool RTreeBase::Node::CompareHorizontal(const NodeBase* a, const NodeBase* b) {
  const Rect& a_rect = a->rect();
  const Rect& b_rect = b->rect();
  return (a_rect.x() < b_rect.x()) ||
         ((a_rect.x() == b_rect.x()) && (a_rect.width() < b_rect.width()));
}

// static
bool RTreeBase::Node::CompareCenterDistanceFromParent(const NodeBase* a,
                                                      const NodeBase* b) {
  const NodeBase* p = a->parent();

  DCHECK(p);
  DCHECK_EQ(p, b->parent());

  Vector2d p_center = CenterOfRect(p->rect());
  Vector2d a_center = CenterOfRect(a->rect());
  Vector2d b_center = CenterOfRect(b->rect());

  // We don't bother with square roots because we are only comparing the two
  // values for sorting purposes.
  return (a_center - p_center).LengthSquared() <
         (b_center - p_center).LengthSquared();
}

// static
void RTreeBase::Node::BuildLowBounds(
    const std::vector<NodeBase*>& vertical_sort,
    const std::vector<NodeBase*>& horizontal_sort,
    Rects* vertical_bounds,
    Rects* horizontal_bounds) {
  Rect vertical_bounds_rect;
  vertical_bounds->reserve(vertical_sort.size());
  for (std::vector<NodeBase*>::const_iterator i = vertical_sort.begin();
       i != vertical_sort.end();
       ++i) {
    vertical_bounds_rect.Union((*i)->rect());
    vertical_bounds->push_back(vertical_bounds_rect);
  }

  Rect horizontal_bounds_rect;
  horizontal_bounds->reserve(horizontal_sort.size());
  for (std::vector<NodeBase*>::const_iterator i = horizontal_sort.begin();
       i != horizontal_sort.end();
       ++i) {
    horizontal_bounds_rect.Union((*i)->rect());
    horizontal_bounds->push_back(horizontal_bounds_rect);
  }
}

// static
void RTreeBase::Node::BuildHighBounds(
    const std::vector<NodeBase*>& vertical_sort,
    const std::vector<NodeBase*>& horizontal_sort,
    Rects* vertical_bounds,
    Rects* horizontal_bounds) {
  Rect vertical_bounds_rect;
  vertical_bounds->reserve(vertical_sort.size());
  for (std::vector<NodeBase*>::const_reverse_iterator i =
           vertical_sort.rbegin();
       i != vertical_sort.rend();
       ++i) {
    vertical_bounds_rect.Union((*i)->rect());
    vertical_bounds->push_back(vertical_bounds_rect);
  }
  std::reverse(vertical_bounds->begin(), vertical_bounds->end());

  Rect horizontal_bounds_rect;
  horizontal_bounds->reserve(horizontal_sort.size());
  for (std::vector<NodeBase*>::const_reverse_iterator i =
           horizontal_sort.rbegin();
       i != horizontal_sort.rend();
       ++i) {
    horizontal_bounds_rect.Union((*i)->rect());
    horizontal_bounds->push_back(horizontal_bounds_rect);
  }
  std::reverse(horizontal_bounds->begin(), horizontal_bounds->end());
}

size_t RTreeBase::Node::ChooseSplitIndex(size_t start_index,
                                         size_t end_index,
                                         const Rects& low_bounds,
                                         const Rects& high_bounds) {
  DCHECK_EQ(low_bounds.size(), high_bounds.size());

  int smallest_overlap_area = UnionRects(
      low_bounds[start_index], high_bounds[start_index]).size().GetArea();
  int smallest_combined_area = low_bounds[start_index].size().GetArea() +
      high_bounds[start_index].size().GetArea();
  size_t optimal_split_index = start_index;
  for (size_t p = start_index + 1; p < end_index; ++p) {
    const int overlap_area =
        UnionRects(low_bounds[p], high_bounds[p]).size().GetArea();
    const int combined_area =
        low_bounds[p].size().GetArea() + high_bounds[p].size().GetArea();
    if ((overlap_area < smallest_overlap_area) ||
        ((overlap_area == smallest_overlap_area) &&
         (combined_area < smallest_combined_area))) {
      smallest_overlap_area = overlap_area;
      smallest_combined_area = combined_area;
      optimal_split_index = p;
    }
  }

  // optimal_split_index currently points at the last element in the first set,
  // so advance it by 1 to point at the first element in the second set.
  return optimal_split_index + 1;
}

// static
int RTreeBase::Node::SmallestMarginSum(size_t start_index,
                                       size_t end_index,
                                       const Rects& low_bounds,
                                       const Rects& high_bounds) {
  DCHECK_EQ(low_bounds.size(), high_bounds.size());
  DCHECK_LT(start_index, low_bounds.size());
  DCHECK_LE(start_index, end_index);
  DCHECK_LE(end_index, low_bounds.size());
  Rects::const_iterator i(low_bounds.begin() + start_index);
  Rects::const_iterator j(high_bounds.begin() + start_index);
  int smallest_sum = i->width() + i->height() + j->width() + j->height();
  for (; i != (low_bounds.begin() + end_index); ++i, ++j) {
    smallest_sum = std::min(
        smallest_sum, i->width() + i->height() + j->width() + j->height());
  }

  return smallest_sum;
}

void RTreeBase::Node::RecomputeLocalBounds() {
  Rect bounds;
  for (size_t i = 0; i < children_.size(); ++i)
    bounds.Union(children_[i]->rect());

  set_rect(bounds);
}

int RTreeBase::Node::OverlapIncreaseToAdd(const Rect& rect,
                                          const NodeBase* candidate_node,
                                          const Rect& expanded_rect) const {
  DCHECK(candidate_node);

  // Early-out when |rect| is contained completely within |candidate|.
  if (candidate_node->rect().Contains(rect))
    return 0;

  int total_original_overlap = 0;
  int total_expanded_overlap = 0;

  // Now calculate overlap with all other rects in this node.
  for (Nodes::const_iterator it = children_.begin();
       it != children_.end(); ++it) {
    // Skip calculating overlap with the candidate rect.
    if ((*it) == candidate_node)
      continue;
    NodeBase* overlap_node = (*it);
    total_original_overlap += IntersectRects(
        candidate_node->rect(), overlap_node->rect()).size().GetArea();
    Rect expanded_overlap_rect = expanded_rect;
    expanded_overlap_rect.Intersect(overlap_node->rect());
    total_expanded_overlap += expanded_overlap_rect.size().GetArea();
  }

  return total_expanded_overlap - total_original_overlap;
}

scoped_ptr<RTreeBase::NodeBase> RTreeBase::Node::DivideChildren(
    const Rects& low_bounds,
    const Rects& high_bounds,
    const std::vector<NodeBase*>& sorted_children,
    size_t split_index) {
  DCHECK_EQ(low_bounds.size(), high_bounds.size());
  DCHECK_EQ(low_bounds.size(), sorted_children.size());
  DCHECK_LT(split_index, low_bounds.size());
  DCHECK_GT(split_index, 0U);

  scoped_ptr<Node> sibling(new Node(level_));
  sibling->set_parent(parent());
  set_rect(low_bounds[split_index - 1]);
  sibling->set_rect(high_bounds[split_index]);

  // Our own children_ vector is unsorted, so we wipe it out and divide the
  // sorted bounds rects between ourselves and our sibling.
  children_.weak_clear();
  children_.insert(children_.end(),
                   sorted_children.begin(),
                   sorted_children.begin() + split_index);
  sibling->children_.insert(sibling->children_.end(),
                            sorted_children.begin() + split_index,
                            sorted_children.end());

  for (size_t i = 0; i < sibling->children_.size(); ++i)
    sibling->children_[i]->set_parent(sibling.get());

  return sibling.Pass();
}

RTreeBase::Node* RTreeBase::Node::LeastOverlapIncrease(
    const Rect& node_rect,
    const Rects& expanded_rects) {
  NodeBase* best_node = children_.front();
  int least_overlap_increase =
      OverlapIncreaseToAdd(node_rect, children_[0], expanded_rects[0]);
  for (size_t i = 1; i < children_.size(); ++i) {
    int overlap_increase =
        OverlapIncreaseToAdd(node_rect, children_[i], expanded_rects[i]);
    if (overlap_increase < least_overlap_increase) {
      least_overlap_increase = overlap_increase;
      best_node = children_[i];
    } else if (overlap_increase == least_overlap_increase) {
      // If we are tied at zero there is no possible better overlap increase,
      // so we can report a tie early.
      if (overlap_increase == 0)
        return NULL;

      best_node = NULL;
    }
  }

  // Ensure that our children are always Nodes and not Records.
  DCHECK_GE(level_, 1);
  return static_cast<Node*>(best_node);
}

RTreeBase::Node* RTreeBase::Node::LeastAreaEnlargement(
    const Rect& node_rect,
    const Rects& expanded_rects) {
  DCHECK(!children_.empty());
  DCHECK_EQ(children_.size(), expanded_rects.size());

  NodeBase* best_node = children_.front();
  int least_area_enlargement =
      expanded_rects[0].size().GetArea() - best_node->rect().size().GetArea();
  for (size_t i = 1; i < children_.size(); ++i) {
    NodeBase* candidate_node = children_[i];
    int area_change = expanded_rects[i].size().GetArea() -
                      candidate_node->rect().size().GetArea();
    DCHECK_GE(area_change, 0);
    if (area_change < least_area_enlargement) {
      best_node = candidate_node;
      least_area_enlargement = area_change;
    } else if (area_change == least_area_enlargement &&
        candidate_node->rect().size().GetArea() <
            best_node->rect().size().GetArea()) {
      // Ties are broken by choosing the entry with the least area.
      best_node = candidate_node;
    }
  }

  // Ensure that our children are always Nodes and not Records.
  DCHECK_GE(level_, 1);
  return static_cast<Node*>(best_node);
}


// RTreeBase ------------------------------------------------------------------

RTreeBase::RTreeBase(size_t min_children, size_t max_children)
    : root_(new Node()),
      min_children_(min_children),
      max_children_(max_children) {
  DCHECK_GE(min_children_, 2U);
  DCHECK_LE(min_children_, max_children_ / 2U);
}

RTreeBase::~RTreeBase() {
}

void RTreeBase::InsertNode(
    scoped_ptr<NodeBase> node, int* highest_reinsert_level) {
  // Find the most appropriate parent to insert node into.
  Node* parent = root_->ChooseSubtree(node.get());
  DCHECK(parent);
  // Verify ChooseSubtree returned a Node at the correct level.
  DCHECK_EQ(parent->Level(), node->Level() + 1);
  Node* insert_parent = static_cast<Node*>(parent);
  NodeBase* needs_bounds_recomputed = insert_parent->parent();
  Nodes reinserts;
  // Attempt to insert the Node, if this overflows the Node we must handle it.
  while (insert_parent &&
         insert_parent->AddChild(node.Pass()) > max_children_) {
    // If we have yet to re-insert nodes at this level during this data insert,
    // and we're not at the root, R*-Tree calls for re-insertion of some of the
    // nodes, resulting in a better balance on the tree.
    if (insert_parent->parent() &&
        insert_parent->Level() > *highest_reinsert_level) {
      insert_parent->RemoveNodesForReinsert(max_children_ / 3, &reinserts);
      // Adjust highest_reinsert_level to this level.
      *highest_reinsert_level = insert_parent->Level();
      // RemoveNodesForReinsert() does not recompute bounds, so mark it.
      needs_bounds_recomputed = insert_parent;
      break;
    }

    // Split() will create a sibling to insert_parent both of which will have
    // valid bounds, but this invalidates their parent's bounds.
    node = insert_parent->Split(min_children_, max_children_);
    insert_parent = static_cast<Node*>(insert_parent->parent());
    needs_bounds_recomputed = insert_parent;
  }

  // If we have a Node to insert, and we hit the root of the current tree,
  // we create a new root which is the parent of the current root and the
  // insert_node. Note that we must release() the |root_| since
  // ConstructParent() will take ownership of it.
  if (!insert_parent && node) {
    root_ = root_.release()->ConstructParent();
    root_->AddChild(node.Pass());
  }

  // Recompute bounds along insertion path.
  if (needs_bounds_recomputed)
    needs_bounds_recomputed->RecomputeBoundsUpToRoot();

  // Complete re-inserts, if any. The algorithm only allows for one invocation
  // of RemoveNodesForReinsert() per level of the tree in an overall call to
  // Insert().
  while (!reinserts.empty()) {
    Nodes::iterator last_element = reinserts.end() - 1;
    NodeBase* temp_ptr(*last_element);
    reinserts.weak_erase(last_element);
    InsertNode(make_scoped_ptr(temp_ptr), highest_reinsert_level);
  }
}

scoped_ptr<RTreeBase::NodeBase> RTreeBase::RemoveNode(NodeBase* node) {
  // We need to remove this node from its parent.
  Node* parent = static_cast<Node*>(node->parent());
  // Record nodes are never allowed as the root, so we should always have a
  // parent.
  DCHECK(parent);
  // Should always be a leaf that had the record.
  DCHECK_EQ(0, parent->Level());

  Nodes orphans;
  scoped_ptr<NodeBase> removed_node(parent->RemoveChild(node, &orphans));

  // It's possible that by removing |node| from |parent| we have made |parent|
  // have less than the minimum number of children, in which case we will need
  // to remove and delete |parent| while reinserting any other children that it
  // had. We traverse up the tree doing this until we remove a child from a
  // parent that still has greater than or equal to the minimum number of Nodes.
  while (parent->count() < min_children_) {
    NodeBase* child = parent;
    parent = static_cast<Node*>(parent->parent());

    // If we've hit the root, stop.
    if (!parent)
      break;

    parent->RemoveChild(child, &orphans);
  }

  // If we stopped deleting nodes up the tree before encountering the root,
  // we'll need to fix up the bounds from the first parent we didn't delete
  // up to the root.
  if (parent)
    parent->RecomputeBoundsUpToRoot();
  else
    root_->RecomputeBoundsUpToRoot();

  while (!orphans.empty()) {
    Nodes::iterator last_element = orphans.end() - 1;
    NodeBase* temp_ptr(*last_element);
    orphans.weak_erase(last_element);
    int starting_level = -1;
    InsertNode(make_scoped_ptr(temp_ptr), &starting_level);
  }

  return removed_node.Pass();
}

void RTreeBase::PruneRootIfNecessary() {
  if (root()->count() == 1 && root()->Level() > 0) {
    // Awkward reset(cast(release)) pattern here because there's no better way
    // to downcast the scoped_ptr from RemoveAndReturnLastChild() from NodeBase
    // to Node.
    root_.reset(
        static_cast<Node*>(root_->RemoveAndReturnLastChild().release()));
  }
}

void RTreeBase::ResetRoot() {
  root_.reset(new Node());
}

}  // namespace gfx
