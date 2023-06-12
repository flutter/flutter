// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';

int _defaultCompare(a, b) {
  return a.compareTo(b);
}

/// A [Set] of items stored in a binary tree according to [comparator].
/// Supports bidirectional iteration.
abstract class TreeSet<V> extends IterableBase<V> implements Set<V> {
  /// Create a new [TreeSet] with an ordering defined by [comparator] or the
  /// default `(a, b) => a.compareTo(b)`.
  factory TreeSet({Comparator<V> comparator = _defaultCompare}) {
    return AvlTreeSet(comparator: comparator);
  }

  TreeSet._(this.comparator);

  final Comparator<V> comparator;

  @override
  int get length;

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  /// Returns an [BidirectionalIterator] that iterates over this tree.
  @override
  BidirectionalIterator<V> get iterator;

  /// Returns an [BidirectionalIterator] that iterates over this tree, in
  /// reverse.
  BidirectionalIterator<V> get reverseIterator;

  /// Returns an [BidirectionalIterator] that starts at [anchor].  By default,
  /// the iterator includes the anchor with the first movement; set [inclusive]
  /// to false if you want to exclude the anchor. Set [reversed] to true to
  /// change the direction of of moveNext and movePrevious.
  ///
  /// Note: This iterator allows you to walk the entire set. It does not
  /// present a subview.
  BidirectionalIterator<V> fromIterator(V anchor,
      {bool reversed = false, bool inclusive = true});

  /// Search the tree for the matching [object] or the [nearestOption]
  /// if missing.  See [TreeSearch].
  V nearest(V object, {TreeSearch nearestOption = TreeSearch.NEAREST});

  @override
  Set<T> cast<T>();

  // TODO(codefu): toString or not toString, that is the question.
}

/// Controls the results for [TreeSet.searchNearest]()
enum TreeSearch {
  /// If result not found, always chose the smaller element
  LESS_THAN,

  /// If result not found, chose the nearest based on comparison
  NEAREST,

  /// If result not found, always chose the greater element
  GREATER_THAN
}

/// A node in the [TreeSet].
abstract class _TreeNode<V> {
  /// TreeNodes are always allocated as leafs.
  _TreeNode({required this.object});

  _TreeNode<V> get left;
  bool get hasLeft;

  _TreeNode<V> get right;
  bool get hasRight;

  // TODO(codefu): Remove need for [parent]; this is just an implementation
  // note.
  _TreeNode<V> get parent;
  bool get hasParent;

  V object;

  /// Return the minimum node for the subtree
  _TreeNode<V> get minimumNode {
    var node = this;
    while (node.hasLeft) {
      node = node.left;
    }
    return node;
  }

  /// Return the maximum node for the subtree
  _TreeNode<V> get maximumNode {
    var node = this;
    while (node.hasRight) {
      node = node.right;
    }
    return node;
  }

  /// Return the next greatest element (or null)
  _TreeNode<V>? get successor {
    var node = this;
    if (node.hasRight) {
      return node.right.minimumNode;
    }
    while (
        node.hasParent && node.parent.hasRight && node == node.parent.right) {
      node = node.parent;
    }
    return node.hasParent ? node.parent : null;
  }

  /// Return the next smaller element (or null)
  _TreeNode<V>? get predecessor {
    var node = this;
    if (node.hasLeft) {
      return node.left.maximumNode;
    }
    while (node.hasParent && node.parent.hasLeft && node.parent.left == node) {
      node = node.parent;
    }
    return node.hasParent ? node.parent : null;
  }
}

/// AVL implementation of a self-balancing binary tree. Optimized for lookup
/// operations.
///
/// Notes: Adapted from "Introduction to Algorithms", second edition,
///        by Thomas H. Cormen, Charles E. Leiserson,
///           Ronald L. Rivest, Clifford Stein.
///        chapter 13.2
class AvlTreeSet<V> extends TreeSet<V> {
  AvlTreeSet({Comparator<V> comparator = _defaultCompare})
      : super._(comparator);

  int _length = 0;
  AvlNode<V>? _root;
  // Modification count to the tree, monotonically increasing
  int _modCount = 0;

  @override
  int get length => _length;

  /// Add the element to the tree.
  @override
  bool add(V element) {
    if (_root == null) {
      AvlNode<V> node = AvlNode<V>(object: element);
      _root = node;
      ++_length;
      ++_modCount;
      return true;
    }

    AvlNode<V> x = _root!;
    while (true) {
      int compare = comparator(element, x.object);
      if (compare == 0) {
        return false;
      } else if (compare < 0) {
        if (!x.hasLeft) {
          AvlNode<V> node = AvlNode<V>(object: element).._parent = x;
          x
            .._left = node
            .._balanceFactor -= 1;
          break;
        }
        x = x.left;
      } else {
        if (!x.hasRight) {
          AvlNode<V> node = AvlNode<V>(object: element).._parent = x;
          x
            .._right = node
            .._balanceFactor += 1;
          break;
        }
        x = x.right;
      }
    }

    ++_modCount;

    // AVL balancing act (for height balanced trees)
    // Now that we've inserted, we've unbalanced some trees, we need
    //  to follow the tree back up to the _root double checking that the tree
    //  is still balanced and _maybe_ perform a single or double rotation.
    //  Note: Left additions == -1, Right additions == +1
    //  Balanced Node = { -1, 0, 1 }, out of balance = { -2, 2 }
    //  Single rotation when Parent & Child share signed balance,
    //  Double rotation when sign differs!
    AvlNode<V> node = x;
    while (node._balanceFactor != 0 && node.hasParent) {
      // Find out which side of the parent we're on
      if (node.parent._left == node) {
        node.parent._balanceFactor -= 1;
      } else {
        node.parent._balanceFactor += 1;
      }

      node = node.parent;
      if (node._balanceFactor == 2) {
        // Heavy on the right side - Test for which rotation to perform
        if (node.right._balanceFactor == 1) {
          // Single (left) rotation; this will balance everything to zero
          _rotateLeft(node);
          node._balanceFactor = node.parent._balanceFactor = 0;
          node = node.parent;
        } else {
          // Double (Right/Left) rotation
          // node will now be old node.right.left
          _rotateRightLeft(node);
          node = node.parent; // Update to new parent (old grandchild)
          if (node._balanceFactor == 1) {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = -1;
          } else if (node._balanceFactor == 0) {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = 0;
          } else {
            node.right._balanceFactor = 1;
            node.left._balanceFactor = 0;
          }
          node._balanceFactor = 0;
        }
        break; // out of loop, we're balanced
      } else if (node._balanceFactor == -2) {
        // Heavy on the left side - Test for which rotation to perform
        if (node.left._balanceFactor == -1) {
          _rotateRight(node);
          node._balanceFactor = node.parent._balanceFactor = 0;
          node = node.parent;
        } else {
          // Double (Left/Right) rotation
          // node will now be old node.left.right
          _rotateLeftRight(node);
          node = node.parent;
          if (node._balanceFactor == -1) {
            node.right._balanceFactor = 1;
            node.left._balanceFactor = 0;
          } else if (node._balanceFactor == 0) {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = 0;
          } else {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = -1;
          }
          node._balanceFactor = 0;
        }
        break; // out of loop, we're balanced
      }
    } // end of while (balancing)
    _length++;
    return true;
  }

  /// Test to see if an element is stored in the tree
  AvlNode<V>? _getNode(V element) {
    AvlNode<V>? x = _root;
    while (x != null) {
      int compare = comparator(element, x.object);
      if (compare == 0) {
        // This only means our node matches; we need to search for the exact
        // element. We could have been glutons and used a hashmap to back.
        return x;
      } else if (compare < 0) {
        x = x._left;
      } else {
        x = x._right;
      }
    }
    return null;
  }

  /// This function will right rotate/pivot N with its left child, placing
  /// it on the right of its left child.
  ///
  ///          N                      Y
  ///         / \                    / \
  ///        Y   A                  Z   N
  ///       / \          ==>       / \ / \
  ///      Z   B                  D  CB   A
  ///     / \
  ///    D   C
  ///
  /// Assertion: must have a left element
  void _rotateRight(AvlNode<V> node) {
    AvlNode<V>? y = node.left;

    // turn Y's right subtree(B) into N's left subtree.
    node._left = y._right;
    if (node.hasLeft) {
      node.left._parent = node;
    }
    y._parent = node._parent;
    if (y.hasParent) {
      if (node.parent._left == node) {
        node.parent._left = y;
      } else {
        node.parent._right = y;
      }
    } else {
      _root = y;
    }
    y._right = node;
    node._parent = y;
  }

  /// This function will left rotate/pivot N with its right child, placing
  /// it on the left of its right child.
  ///
  ///      N                      Y
  ///     / \                    / \
  ///    A   Y                  N   Z
  ///       / \      ==>       / \ / \
  ///      B   Z              A  BC   D
  ///         / \
  ///        C   D
  ///
  /// Assertion: must have a right element
  void _rotateLeft(AvlNode<V> node) {
    AvlNode<V>? y = node.right;

    // turn Y's left subtree(B) into N's right subtree.
    node._right = y._left;
    if (node.hasRight) {
      node.right._parent = node;
    }
    y._parent = node._parent;
    if (y.hasParent) {
      if (node.parent._left == node) {
        y.parent._left = y;
      } else {
        y.parent._right = y;
      }
    } else {
      _root = y;
    }
    y._left = node;
    node._parent = y;
  }

  /// This function will double rotate node with right/left operations.
  /// node is S.
  ///
  ///      S                      G
  ///     / \                    / \
  ///    A   C                  S   C
  ///       / \      ==>       / \ / \
  ///      G   B              A  DC   B
  ///     / \
  ///    D   C
  void _rotateRightLeft(AvlNode<V> node) {
    _rotateRight(node.right);
    _rotateLeft(node);
  }

  /// This function will double rotate node with left/right operations.
  /// node is S.
  ///
  ///        S                      G
  ///       / \                    / \
  ///      C   A                  C   S
  ///     / \          ==>       / \ / \
  ///    B   G                  B  CD   A
  ///       / \
  ///      C   D
  void _rotateLeftRight(AvlNode<V> node) {
    _rotateLeft(node.left);
    _rotateRight(node);
  }

  @override
  bool addAll(Iterable<V> items) {
    bool modified = false;
    for (final item in items) {
      if (add(item)) {
        modified = true;
      }
    }
    return modified;
  }

  @override
  AvlTreeSet<T> cast<T>() {
    // TODO(codefu): Dart 2.0 requires this method to be implemented.
    throw UnimplementedError('cast');
  }

  @override
  void clear() {
    _length = 0;
    _root = null;
    ++_modCount;
  }

  @override
  bool containsAll(Iterable<Object?> items) {
    for (final item in items) {
      if (!contains(item)) return false;
    }
    return true;
  }

  @override
  bool remove(Object? item) {
    if (item is! V) return false;

    AvlNode<V>? x = _getNode(item);
    if (x != null) {
      _removeNode(x);
      return true;
    }
    return false;
  }

  void _removeNode(AvlNode<V> node) {
    AvlNode<V>? y;
    AvlNode<V>? w;

    ++_modCount;
    --_length;

    // note: if you read wikipedia, it states remove the node if its a leaf,
    // otherwise, replace it with its predecessor or successor. We're not.
    if (!node.hasRight || !node.right.hasLeft) {
      // simple solutions
      if (node.hasRight) {
        y = node.right;
        y._parent = node._parent;
        y._balanceFactor = node._balanceFactor - 1;
        y._left = node._left;
        if (y.hasLeft) {
          y.left._parent = y;
        }
      } else if (node.hasLeft) {
        y = node.left;
        y._parent = node._parent;
        y._balanceFactor = node._balanceFactor + 1;
      } else {
        y = null;
      }
      if (_root == node) {
        _root = y;
      } else if (node.parent._left == node) {
        node.parent._left = y;
        if (y == null) {
          // account for leaf deletions changing the balance
          node.parent._balanceFactor += 1;
          y = node.parent; // start searching from here;
        }
      } else {
        node.parent._right = y;
        if (y == null) {
          node.parent._balanceFactor -= 1;
          y = node.parent;
        }
      }
      w = y;
    } else {
      // This node is not a leaf; we should find the successor node, swap
      //it with this* and then update the balance factors.
      y = node.successor as AvlNode<V>;
      y._left = node._left;
      if (y.hasLeft) {
        y.left._parent = y;
      }

      w = y.parent;
      w._left = y._right;
      if (w.hasLeft) {
        w.left._parent = w;
      }
      // known: we're removing from the left
      w._balanceFactor += 1;

      // known due to test for n->r->l above
      y._right = node._right;
      y.right._parent = y;
      y._balanceFactor = node._balanceFactor;

      y._parent = node._parent;
      if (_root == node) {
        _root = y;
      } else if (node.parent._left == node) {
        node.parent._left = y;
      } else {
        node.parent._right = y;
      }
    }

    // Safe to kill node now; its free to go.
    node._balanceFactor = 0;
    node._left = node._right = node._parent = null;

    // Re-balance to the top, ending early if OK
    _rebalance(w);
  }

  void _rebalance(AvlNode<V>? node) {
    while (node != null) {
      if (node._balanceFactor == -1 || node._balanceFactor == 1) {
        // The height of node hasn't changed; done!
        break;
      }
      if (node._balanceFactor == 2) {
        // Heavy on the right side; figure out which rotation to perform
        if (node.right._balanceFactor == -1) {
          _rotateRightLeft(node);
          node = node.parent; // old grand-child!
          if (node._balanceFactor == 1) {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = -1;
          } else if (node._balanceFactor == 0) {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = 0;
          } else {
            node.right._balanceFactor = 1;
            node.left._balanceFactor = 0;
          }
          node._balanceFactor = 0;
        } else {
          // single left-rotation
          _rotateLeft(node);
          if (node.parent._balanceFactor == 0) {
            node.parent._balanceFactor = -1;
            node._balanceFactor = 1;
            break;
          } else {
            node.parent._balanceFactor = 0;
            node._balanceFactor = 0;
            node = node.parent;
            continue;
          }
        }
      } else if (node._balanceFactor == -2) {
        // Heavy on the left
        if (node.left._balanceFactor == 1) {
          _rotateLeftRight(node);
          node = node.parent; // old grand-child!
          if (node._balanceFactor == -1) {
            node.right._balanceFactor = 1;
            node.left._balanceFactor = 0;
          } else if (node._balanceFactor == 0) {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = 0;
          } else {
            node.right._balanceFactor = 0;
            node.left._balanceFactor = -1;
          }
          node._balanceFactor = 0;
        } else {
          _rotateRight(node);
          if (node.parent._balanceFactor == 0) {
            node.parent._balanceFactor = 1;
            node._balanceFactor = -1;
            break;
          } else {
            node.parent._balanceFactor = 0;
            node._balanceFactor = 0;
            node = node.parent;
            continue;
          }
        }
      }

      // continue up the tree for testing
      if (node.hasParent) {
        // The concept of balance here is reverse from addition; since
        // we are taking away weight from one side or the other (thus
        // the balance changes in favor of the other side)
        if (node.parent.hasLeft && node.parent.left == node) {
          node.parent._balanceFactor += 1;
        } else {
          node.parent._balanceFactor -= 1;
        }
      }
      node = node.hasParent ? node.parent : null;
    }
  }

  /// See [Set.removeAll]
  @override
  void removeAll(Iterable items) {
    items.forEach(remove);
  }

  /// See [Set.retainAll]
  @override
  void retainAll(Iterable<Object?> elements) {
    List<V> chosen = <V>[];
    for (final target in elements) {
      if (target is V && contains(target)) {
        chosen.add(target);
      }
    }
    clear();
    addAll(chosen);
  }

  /// See [Set.retainWhere]
  @override
  void retainWhere(bool test(V element)) {
    List<V> chosen = [];
    for (final target in this) {
      if (test(target)) {
        chosen.add(target);
      }
    }
    clear();
    addAll(chosen);
  }

  /// See [Set.removeWhere]
  @override
  void removeWhere(bool test(V element)) {
    List<V> damned = [];
    for (final target in this) {
      if (test(target)) {
        damned.add(target);
      }
    }
    removeAll(damned);
  }

  /// See [IterableBase.first]
  @override
  V get first {
    _TreeNode<V>? min = _root?.minimumNode;
    if (min != null) {
      return min.object;
    }
    throw StateError('No first element');
  }

  /// See [IterableBase.last]
  @override
  V get last {
    _TreeNode<V>? max = _root?.maximumNode;
    if (max != null) {
      return max.object;
    }
    throw StateError('No last element');
  }

  /// See [Set.lookup]
  @override
  V? lookup(Object? element) {
    if (element is! V || _root == null) return null;
    AvlNode<V>? x = _root;
    int compare = 0;
    while (x != null) {
      compare = comparator(element, x.object);
      if (compare == 0) {
        return x.object;
      } else if (compare < 0) {
        x = x._left;
      } else {
        x = x._right;
      }
    }
    return null;
  }

  @override
  V nearest(V object, {TreeSearch nearestOption = TreeSearch.NEAREST}) {
    AvlNode<V>? found = _searchNearest(object, option: nearestOption);
    if (found != null) {
      return found.object;
    }
    throw StateError('No nearest element');
  }

  /// Search the tree for the matching element, or the 'nearest' node.
  /// NOTE: [BinaryTree.comparator] needs to have finer granularity than -1,0,1
  /// in order for this to return something that's meaningful.
  AvlNode<V>? _searchNearest(V? element,
      {TreeSearch option = TreeSearch.NEAREST}) {
    if (element == null || _root == null) {
      return null;
    }
    AvlNode<V>? x = _root;
    late AvlNode<V> previous;
    int compare = 0;
    while (x != null) {
      previous = x;
      compare = comparator(element, x.object);
      if (compare == 0) {
        return x;
      } else if (compare < 0) {
        x = x._left;
      } else {
        x = x._right;
      }
    }

    if (option == TreeSearch.GREATER_THAN) {
      return (compare < 0 ? previous : previous.successor) as AvlNode<V>?;
    } else if (option == TreeSearch.LESS_THAN) {
      return (compare < 0 ? previous.predecessor : previous) as AvlNode<V>?;
    }
    // Default: nearest absolute value
    // Fell off the tree looking for the exact match; now we need
    // to find the nearest element.
    x = (compare < 0 ? previous.predecessor : previous.successor)
        as AvlNode<V>?;
    if (x == null) {
      return previous;
    }
    int otherCompare = comparator(element, x.object);
    if (compare < 0) {
      return compare.abs() < otherCompare ? previous : x;
    }
    return otherCompare.abs() < compare ? x : previous;
  }

  //
  // [IterableBase]<V> Methods
  //

  /// See [IterableBase.iterator]
  @override
  BidirectionalIterator<V> get iterator => _AvlTreeIterator._(this);

  /// See [TreeSet.reverseIterator]
  @override
  BidirectionalIterator<V> get reverseIterator =>
      _AvlTreeIterator._(this, reversed: true);

  /// See [TreeSet.fromIterator]
  @override
  BidirectionalIterator<V> fromIterator(V anchor,
          {bool reversed = false, bool inclusive = true}) =>
      _AvlTreeIterator<V>._(this,
          anchorObject: anchor, reversed: reversed, inclusive: inclusive);

  /// See [IterableBase.contains]
  @override
  bool contains(Object? object) {
    if (object is! V) {
      return false;
    }
    return _getNode(object) != null;
  }

  //
  // [Set] methods
  //

  /// See [Set.intersection]
  @override
  Set<V> intersection(Set<Object?> other) {
    TreeSet<V> set = TreeSet(comparator: comparator);

    // Optimized for sorted sets
    if (other is TreeSet<V>) {
      var i1 = iterator;
      var i2 = other.iterator;
      var hasMore1 = i1.moveNext();
      var hasMore2 = i2.moveNext();
      while (hasMore1 && hasMore2) {
        var c = comparator(i1.current, i2.current);
        if (c == 0) {
          set.add(i1.current);
          hasMore1 = i1.moveNext();
          hasMore2 = i2.moveNext();
        } else if (c < 0) {
          hasMore1 = i1.moveNext();
        } else {
          hasMore2 = i2.moveNext();
        }
      }
      return set;
    }

    // Non-optimized version.
    for (final target in this) {
      if (other.contains(target)) {
        set.add(target);
      }
    }
    return set;
  }

  /// See [Set.union]
  @override
  Set<V> union(Set<V> other) {
    TreeSet<V> set = TreeSet(comparator: comparator);

    if (other is TreeSet) {
      Iterator<V> i1 = iterator;
      var i2 = other.iterator;
      var hasMore1 = i1.moveNext();
      var hasMore2 = i2.moveNext();
      while (hasMore1 && hasMore2) {
        var c = comparator(i1.current, i2.current);
        if (c == 0) {
          set.add(i1.current);
          hasMore1 = i1.moveNext();
          hasMore2 = i2.moveNext();
        } else if (c < 0) {
          set.add(i1.current);
          hasMore1 = i1.moveNext();
        } else {
          set.add(i2.current);
          hasMore2 = i2.moveNext();
        }
      }
      if (hasMore1 || hasMore2) {
        i1 = hasMore1 ? i1 : i2;
        do {
          set.add(i1.current);
        } while (i1.moveNext());
      }
      return set;
    }

    // Non-optimized version.
    return set
      ..addAll(this)
      ..addAll(other);
  }

  /// See [Set.difference]
  @override
  Set<V> difference(Set<Object?> other) {
    TreeSet<V> set = TreeSet(comparator: comparator);

    if (other is TreeSet) {
      var i1 = iterator;
      var i2 = other.iterator;
      var hasMore1 = i1.moveNext();
      var hasMore2 = i2.moveNext();
      while (hasMore1 && hasMore2) {
        var c = comparator(i1.current, i2.current);
        if (c == 0) {
          hasMore1 = i1.moveNext();
          hasMore2 = i2.moveNext();
        } else if (c < 0) {
          set.add(i1.current);
          hasMore1 = i1.moveNext();
        } else {
          hasMore2 = i2.moveNext();
        }
      }
      if (hasMore1) {
        do {
          set.add(i1.current);
        } while (i1.moveNext());
      }
      return set;
    }

    // Non-optimized version.
    for (final target in this) {
      if (!other.contains(target)) {
        set.add(target);
      }
    }
    return set;
  }
}

AvlNode<V>? debugGetNode<V>(AvlTreeSet<V> treeset, V object) {
  return treeset._getNode(object);
}

typedef _IteratorMove = bool Function();

/// This iterator either starts at the beginning or end (see [TreeSet.iterator]
/// and [TreeSet.reverseIterator]) or from an anchor point in the set (see
/// [TreeSet.fromIterator]). When using fromIterator, the initial anchor point
/// is included in the first movement (either [moveNext] or [movePrevious]) but
/// can optionally be excluded in the constructor.
class _AvlTreeIterator<V> implements BidirectionalIterator<V> {
  _AvlTreeIterator._(this.tree,
      {this.reversed = false, this.inclusive = true, this.anchorObject})
      : _modCountGuard = tree._modCount {
    if (anchorObject == null || tree.isEmpty) {
      // If the anchor is far left or right, we're just a normal iterator.
      state = reversed ? RIGHT : LEFT;
      _moveNext = reversed ? _movePreviousNormal : _moveNextNormal;
      _movePrevious = reversed ? _moveNextNormal : _movePreviousNormal;
      return;
    }

    state = WALK;
    // Else we've got an anchor we have to worry about initializing from.
    // This isn't known till the caller actually performs a previous/next.
    _moveNext = () {
      _current = tree._searchNearest(anchorObject,
          option: reversed ? TreeSearch.LESS_THAN : TreeSearch.GREATER_THAN);
      _moveNext = reversed ? _movePreviousNormal : _moveNextNormal;
      _movePrevious = reversed ? _moveNextNormal : _movePreviousNormal;
      if (_current == null) {
        state = reversed ? LEFT : RIGHT;
      } else if (tree.comparator(_current!.object, anchorObject!) == 0 &&
          !inclusive) {
        _moveNext();
      }
      return state == WALK;
    };

    _movePrevious = () {
      _current = tree._searchNearest(anchorObject,
          option: reversed ? TreeSearch.GREATER_THAN : TreeSearch.LESS_THAN);
      _moveNext = reversed ? _movePreviousNormal : _moveNextNormal;
      _movePrevious = reversed ? _moveNextNormal : _movePreviousNormal;
      if (_current == null) {
        state = reversed ? RIGHT : LEFT;
      } else if (tree.comparator(_current!.object, anchorObject!) == 0 &&
          !inclusive) {
        _movePrevious();
      }
      return state == WALK;
    };
  }

  static const LEFT = -1;
  static const WALK = 0;
  static const RIGHT = 1;

  final bool reversed;
  final AvlTreeSet<V> tree;
  final int _modCountGuard;
  final V? anchorObject;
  final bool inclusive;

  late _IteratorMove _moveNext;
  late _IteratorMove _movePrevious;

  late int state;
  _TreeNode<V>? _current;

  @override
  V get current {
    // Prior to NNBD, this returned null when iteration was complete. In order
    // to avoid a hard breaking change, we return "null as V" in that case so
    // that if strong checking is not enabled or V is nullable, the existing
    // behavior is preserved.
    if (state == WALK && _current != null) {
      return _current?.object as V;
    }
    return null as V;
  }

  @override
  bool moveNext() => _moveNext();

  @override
  bool movePrevious() => _movePrevious();

  bool _moveNextNormal() {
    if (_modCountGuard != tree._modCount) {
      throw ConcurrentModificationError(tree);
    }
    if (state == RIGHT || tree.isEmpty) return false;
    switch (state) {
      case LEFT:
        _current = tree._root!.minimumNode;
        state = WALK;
        return true;
      case WALK:
      default:
        _current = _current!.successor;
        if (_current == null) {
          state = RIGHT;
        }
        return state == WALK;
    }
  }

  bool _movePreviousNormal() {
    if (_modCountGuard != tree._modCount) {
      throw ConcurrentModificationError(tree);
    }
    if (state == LEFT || tree.isEmpty) return false;
    switch (state) {
      case RIGHT:
        _current = tree._root!.maximumNode;
        state = WALK;
        return true;
      case WALK:
      default:
        _current = _current!.predecessor;
        if (_current == null) {
          state = LEFT;
        }
        return state == WALK;
    }
  }
}

/// Private class used to track element insertions in the [TreeSet].
class AvlNode<V> extends _TreeNode<V> {
  AvlNode({required V object}) : super(object: object);

  AvlNode<V>? _left;
  AvlNode<V>? _right;
  // TODO(codefu): Remove need for [parent]; this is just an implementation note
  AvlNode<V>? _parent;
  int _balanceFactor = 0;

  @override
  AvlNode<V> get left => _left!;

  @override
  bool get hasLeft => _left != null;

  @override
  AvlNode<V> get right => _right!;

  @override
  bool get hasRight => _right != null;

  @override
  AvlNode<V> get parent => _parent!;

  @override
  bool get hasParent => _parent != null;

  int get balance => _balanceFactor;

  @override
  String toString() => '(b:$balance o: $object l:$hasLeft r:$hasRight)';
}
