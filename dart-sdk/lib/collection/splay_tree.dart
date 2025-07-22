// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// A node in a splay tree. It holds the sorting key and the left
/// and right children in the tree.
class _SplayTreeNode<K, Node extends _SplayTreeNode<K, Node>> {
  final K key;

  Node? _left;
  Node? _right;

  _SplayTreeNode(this.key);
}

/// A node in a splay tree based set.
class _SplayTreeSetNode<K> extends _SplayTreeNode<K, _SplayTreeSetNode<K>> {
  _SplayTreeSetNode(K key) : super(key);
}

/// A node in a splay tree based map.
///
/// A [_SplayTreeNode] that also contains a value.
class _SplayTreeMapNode<K, V>
    extends _SplayTreeNode<K, _SplayTreeMapNode<K, V>> {
  V value;
  _SplayTreeMapNode(K key, this.value) : super(key);
}

/// A splay tree is a self-balancing binary search tree.
///
/// It has the additional property that recently accessed elements
/// are expected to be quick to access again.
/// It performs basic operations such as insertion, look-up and
/// removal, in O(log(n)) expected amortized time.
abstract class _SplayTree<K, Node extends _SplayTreeNode<K, Node>> {
  // The root node of the splay tree. It will contain either the last
  // element inserted or the last element looked up.
  abstract Node? _root;

  // Number of elements in the splay tree.
  int _count = 0;

  /// Counter incremented whenever the keys in the map change.
  ///
  /// Used to detect concurrent modifications while iterating.
  int _modificationCount = 0;

  /// Counter incremented whenever the tree structure changes, but keys do not.
  ///
  /// Used to detect that an in-place traversal cannot use
  /// cached information that relies on the tree structure.
  int _splayCount = 0;

  /// The comparator that is used for this splay tree.
  abstract final int Function(K, K) _compare;

  /// The predicate to determine whether a given object is a valid key.
  ///
  /// Used by operations which accept [Object?].
  ///
  /// If [null], the key must just be a [K].
  abstract final bool Function(Object?)? _validKey;

  /// Perform the splay operation for the given key. Moves the node with
  /// the given key to the top of the tree.  If no node has the given
  /// key, the last node on the search path is moved to the top of the
  /// tree. This is the simplified top-down splaying algorithm from:
  /// "Self-adjusting Binary Search Trees" by Sleator and Tarjan.
  ///
  /// Returns the comparison of the key of the new root of the tree to [key].
  /// Returns -1 if the table is empty.
  int _splay(K key) {
    final root = _root;
    if (root == null) {
      // Ensure key is compatible with `_compare`.
      _compare(key, key);
      return -1;
    }

    // The right and newTreeRight variables start out null, and are set
    // after the first move left. The right node is the destination
    // for subsequent left rebalances, and newTreeRight holds the left
    // child of the final tree. The newTreeRight variable is set at most
    // once, after the first move left, and is null iff right is null.
    // The left and newTreeLeft variables play the corresponding role for
    // right rebalances.
    final originalModificationCount = _modificationCount;
    final originalSplayCount = _splayCount;
    Node? right;
    Node? newTreeRight;
    Node? left;
    Node? newTreeLeft;
    var current = root;
    // Hoist the field read out of the loop.
    var compare = _compare;
    int comparison;
    while (true) {
      comparison = compare(current.key, key);
      // Extra sanity checks which can only fail if `_compare` accesses the map.
      assert(
        originalModificationCount == _modificationCount,
        throw ConcurrentModificationError(this),
      );
      assert(
        originalSplayCount == _splayCount,
        throw ConcurrentModificationError(this),
      );

      if (comparison > 0) {
        var currentLeft = current._left;
        if (currentLeft == null) break;
        comparison = compare(currentLeft.key, key);
        if (comparison > 0) {
          // Rotate right.
          current._left = currentLeft._right;
          currentLeft._right = current;
          current = currentLeft;
          currentLeft = current._left;
          if (currentLeft == null) break;
        }
        // Link right.
        if (right == null) {
          // First left rebalance, store the eventual right child.
          newTreeRight = current;
        } else {
          right._left = current;
        }
        right = current;
        current = currentLeft;
      } else if (comparison < 0) {
        var currentRight = current._right;
        if (currentRight == null) break;
        comparison = compare(currentRight.key, key);
        if (comparison < 0) {
          // Rotate left.
          current._right = currentRight._left;
          currentRight._left = current;
          current = currentRight;
          currentRight = current._right;
          if (currentRight == null) break;
        }
        // Link left.
        if (left == null) {
          // First right rebalance, store the eventual left child.
          newTreeLeft = current;
        } else {
          left._right = current;
        }
        left = current;
        current = currentRight;
      } else {
        break;
      }
    }

    // Assemble.
    if (left != null) {
      left._right = current._left;
      current._left = newTreeLeft;
    }
    if (right != null) {
      right._left = current._right;
      current._right = newTreeRight;
    }
    if (!identical(_root, current)) {
      _root = current;
      _splayCount++;
    }
    return comparison;
  }

  // Emulates splaying with a key that is smaller than any in the subtree
  // anchored at [node].
  // and that node is returned. It should replace the reference to [node]
  // in any parent tree or root pointer.
  Node _splayMin(Node node) {
    var current = node;
    var modified = 0;
    while (true) {
      var left = current._left;
      if (left != null) {
        current._left = left._right;
        left._right = current;
        current = left;
        modified = 1;
      } else {
        break;
      }
    }
    _splayCount += modified;
    return current;
  }

  // Emulates splaying with a key that is greater than any in the subtree
  // anchored at [node].
  // After this, the largest element in the tree is the root of the subtree,
  // and that node is returned. It should replace the reference to [node]
  // in any parent tree or root pointer.
  Node _splayMax(Node node) {
    var current = node;
    var modified = 0;
    while (true) {
      var right = current._right;
      if (right != null) {
        current._right = right._left;
        right._left = current;
        current = right;
        modified = 1;
      } else {
        break;
      }
    }
    _splayCount += modified;
    return current;
  }

  /// Removes the root node.
  void _removeRoot() {
    assert(_count > 0);
    final root = _root!;
    final left = root._left;
    final right = root._right;
    if (left == null) {
      _root = right;
    } else if (right == null) {
      _root = left;
    } else {
      // Splay to make sure that the new root has an empty right subtree.
      // Insert the original right subtree as the right subtree of the new root.
      _root = _splayMax(left).._right = right;
    }
    _count--;
    _modificationCount++;
  }

  /// Adds a new root [node] with a key (and value for a map node).
  ///
  /// The [comparison] value is the result of comparing the existing root's key
  /// with the new root node's key.
  void _addNewRoot(Node node, int comparison) {
    final root = _root;
    if (root != null) {
      assert(_count > 0);
      if (comparison < 0) {
        node._left = root;
        node._right = root._right;
        root._right = null;
      } else {
        node._right = root;
        node._left = root._left;
        root._left = null;
      }
    }
    _modificationCount++;
    _count++;
    _root = node;
  }

  Node? get _first {
    var root = _root;
    if (root != null) _root = root = _splayMin(root);
    return root;
  }

  Node? get _last {
    final root = _root;
    if (root == null) return null;
    return _root = _splayMax(root);
  }

  void _clear() {
    _root = null;
    _count = 0;
    _modificationCount++;
  }

  /// Checks if key is a [_validKey] and then splays with it.
  ///
  /// Returns the new root node only if its key is equal to the [key].
  Node? _untypedLookup(Object? key) {
    final isValidKey = _validKey;
    if (isValidKey == null) {
      if (key is! K) return null;
    } else {
      if (!isValidKey(key)) return null;
      key as K;
    }
    if (_splay(key) == 0) return _root;
    return null;
  }
}

int _dynamicCompare(dynamic a, dynamic b) => Comparable.compare(a, b);

int Function(K, K) _defaultCompare<K>() {
  // If K <: Comparable, then we can just use Comparable.compare
  // with no extra casts. (There are will be internal generic downcasts.)
  Object compare = Comparable.compare;
  if (compare is int Function(K, K)) {
    // Ensures K <: Comparable<Object?>.
    return compare;
  }
  // Otherwise wrap and cast the arguments on each call.
  return _dynamicCompare;
}

/// A [Map] of objects that can be ordered relative to each other.
///
/// The map is based on a self-balancing binary tree.
/// It allows most single-entry operations in amortized logarithmic time.
///
/// Keys of the map are compared using the `compare` function passed in
/// the constructor, both for ordering and for equality.
/// If the map contains only the key `a`, then `map.containsKey(b)`
/// will return `true` if and only if `compare(a, b) == 0`,
/// and the value of `a == b` is not even checked.
/// If the compare function is omitted, the objects are assumed to be
/// [Comparable], and are compared using their [Comparable.compareTo] method.
/// Non-comparable objects (including `null`) will not work as keys
/// in that case.
///
/// To allow calling [operator []], [remove] or [containsKey] with objects
/// that are not supported by the `compare` function, an extra `isValidKey`
/// predicate function can be supplied. This function is tested before
/// using the `compare` function on an argument value that may not be a [K]
/// value. If omitted, the `isValidKey` function defaults to testing if the
/// value is a [K].
///
/// **Notice:**
/// Do not modify a map (add or remove keys) while an operation
/// is being performed on that map, for example in functions
/// called during a [forEach] or [putIfAbsent] call,
/// or while iterating the map ([keys], [values] or [entries]).
///
/// Example:
/// ```dart
/// final planetsByMass = SplayTreeMap<double, String>((a, b) => a.compareTo(b));
/// ```
/// To add data to a map, use [operator[]=], [addAll] or [addEntries].
/// ```
/// planetsByMass[0.06] = 'Mercury';
/// planetsByMass
///     .addAll({0.81: 'Venus', 1.0: 'Earth', 0.11: 'Mars', 317.83: 'Jupiter'});
/// ```
/// To check if the map is empty, use [isEmpty] or [isNotEmpty].
/// To find the number of map entries, use [length].
/// ```
/// print(planetsByMass.isEmpty); // false
/// print(planetsByMass.length); // 5
/// ```
/// The [forEach] method calls a function for each key/value entry of the map.
/// ```
/// planetsByMass.forEach((key, value) {
///   print('$key \t $value');
///   // 0.06    Mercury
///   // 0.11    Mars
///   // 0.81    Venus
///   // 1.0     Earth
///   // 317.83  Jupiter
/// });
/// ```
/// To check whether the map has an entry with a specific key, use [containsKey].
/// ```
/// final keyOneExists = planetsByMass.containsKey(1.0); // true
/// final keyFiveExists = planetsByMass.containsKey(5); // false
/// ```
/// To check whether the map has an entry with a specific value,
/// use [containsValue].
/// ```
/// final earthExists = planetsByMass.containsValue('Earth'); // true
/// final plutoExists = planetsByMass.containsValue('Pluto'); // false
/// ```
/// To remove an entry with a specific key, use [remove].
/// ```
/// final removedValue = planetsByMass.remove(1.0);
/// print(removedValue); // Earth
/// ```
/// To remove multiple entries at the same time, based on their keys and values,
/// use [removeWhere].
/// ```
/// planetsByMass.removeWhere((key, value) => key <= 1);
/// print(planetsByMass); // {317.83: Jupiter}
/// ```
/// To conditionally add or modify a value for a specific key, depending on
/// whether there already is an entry with that key,
/// use [putIfAbsent] or [update].
/// ```
/// planetsByMass.update(1, (v) => '', ifAbsent: () => 'Earth');
/// planetsByMass.putIfAbsent(317.83, () => 'Another Jupiter');
/// print(planetsByMass); // {1.0: Earth, 317.83: Jupiter}
/// ```
/// To update the values of all keys, based on the existing key and value,
/// use [updateAll].
/// ```
/// planetsByMass.updateAll((key, value) => 'X');
/// print(planetsByMass); // {1.0: X, 317.83: X}
/// ```
/// To remove all entries and empty the map, use [clear].
/// ```
/// planetsByMass.clear();
/// print(planetsByMass.isEmpty); // false
/// print(planetsByMass); // {}
/// ```
/// **See also:**
/// * [Map], the general interface of key/value pair collections.
/// * [HashMap] is unordered (the order of iteration is not guaranteed).
/// * [LinkedHashMap] iterates in key insertion order.
final class SplayTreeMap<K, V> extends _SplayTree<K, _SplayTreeMapNode<K, V>>
    with MapMixin<K, V> {
  _SplayTreeMapNode<K, V>? _root;

  int Function(K, K) _compare;
  bool Function(Object?)? _validKey;

  SplayTreeMap([
    int Function(K key1, K key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) : _compare = compare ?? _defaultCompare<K>(),
       _validKey = isValidKey;

  /// Creates a [SplayTreeMap] that contains all key/value pairs of [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type.
  /// Example:
  /// ```dart
  /// final baseMap = <int, Object>{3: 'C', 1: 'A', 2: 'B'};
  /// final fromBaseMap = SplayTreeMap<int, String>.from(baseMap);
  /// print(fromBaseMap); // {1: A, 2: B, 3: C}
  /// ```
  factory SplayTreeMap.from(
    Map<Object?, Object?> other, [
    int Function(K key1, K key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) {
    if (other is Map<K, V>) {
      return SplayTreeMap<K, V>.of(other, compare, isValidKey);
    }
    SplayTreeMap<K, V> result = SplayTreeMap<K, V>(compare, isValidKey);
    other.forEach((dynamic k, dynamic v) {
      result[k] = v;
    });
    return result;
  }

  /// Creates a [SplayTreeMap] that contains all key/value pairs of [other].
  /// Example:
  /// ```dart
  /// final baseMap = <int, String>{3: 'A', 2: 'B', 1: 'C', 4: 'D'};
  /// final mapOf = SplayTreeMap<num, Object>.of(baseMap);
  /// print(mapOf); // {1: C, 2: B, 3: A, 4: D}
  /// ```
  factory SplayTreeMap.of(
    Map<K, V> other, [
    int Function(K key1, K key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) => SplayTreeMap<K, V>(compare, isValidKey)..addAll(other);

  /// Creates a [SplayTreeMap] where the keys and values are computed from the
  /// [iterable].
  ///
  /// For each element of the [iterable] this constructor computes a key/value
  /// pair, by applying [key] and [value] respectively.
  ///
  /// The keys of the key/value pairs do not need to be unique. The last
  /// occurrence of a key will simply overwrite any previous value.
  ///
  /// If no functions are specified for [key] and [value], the default is to
  /// use the iterable value itself.
  /// Example:
  /// ```dart
  /// final numbers = [12, 11, 14, 13];
  /// final mapFromIterable =
  ///     SplayTreeMap<int, int>.fromIterable(numbers,
  ///         key: (i) => i, value: (i) => i * i);
  /// print(mapFromIterable); // {11: 121, 12: 144, 13: 169, 14: 196}
  /// ```
  factory SplayTreeMap.fromIterable(
    Iterable iterable, {
    K Function(dynamic element)? key,
    V Function(dynamic element)? value,
    int Function(K key1, K key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  }) {
    SplayTreeMap<K, V> map = SplayTreeMap<K, V>(compare, isValidKey);
    MapBase._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  /// Creates a [SplayTreeMap] associating the given [keys] to [values].
  ///
  /// This constructor iterates over [keys] and [values] and maps each element
  /// of [keys] to the corresponding element of [values].
  ///
  /// If [keys] contains the same object multiple times, the last occurrence
  /// overwrites the previous value.
  ///
  /// It is an error if the two [Iterable]s don't have the same length.
  /// Example:
  /// ```dart
  /// final keys = ['1', '2', '3', '4'];
  /// final values = ['A', 'B', 'C', 'D'];
  /// final mapFromIterables = SplayTreeMap.fromIterables(keys, values);
  /// print(mapFromIterables); // {1: A, 2: B, 3: C, 4: D}
  /// ```
  factory SplayTreeMap.fromIterables(
    Iterable<K> keys,
    Iterable<V> values, [
    int Function(K key1, K key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) {
    SplayTreeMap<K, V> map = SplayTreeMap<K, V>(compare, isValidKey);
    MapBase._fillMapWithIterables(map, keys, values);
    return map;
  }

  V? operator [](Object? key) => _untypedLookup(key)?.value;

  V? remove(Object? key) {
    final root = _untypedLookup(key);
    if (root == null) return null;
    _removeRoot();
    return root.value;
  }

  void operator []=(K key, V value) {
    // Splay on the key to move the last node on the search path for
    // the key to the root of the tree.
    int comparison = _splay(key);
    if (comparison == 0) {
      _root!.value = value;
      return;
    }
    _addNewRoot(_SplayTreeMapNode(key, value), comparison);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int comparison = _splay(key);
    if (comparison == 0) {
      return _root!.value;
    }
    int originalModificationCount = _modificationCount;
    int originalSplayCount = _splayCount;
    V value = ifAbsent();
    if (originalModificationCount != _modificationCount ||
        originalSplayCount != _splayCount) {
      comparison = _splay(key);
      if (comparison == 0) {
        // Key was added by `ifAbsent`, change value.
        _root!.value = value;
        return value;
      }
      // Key is still not there.
    }
    _addNewRoot(_SplayTreeMapNode(key, value), comparison);
    return value;
  }

  V update(K key, V update(V value), {V Function()? ifAbsent}) {
    var comparison = _splay(key);
    if (comparison == 0) {
      final originalModificationCount = _modificationCount;
      final originalSplayCount = _splayCount;
      var newValue = update(_root!.value);
      if (originalModificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      if (originalSplayCount != _splayCount) {
        comparison = _splay(key);
        // Can only fail to find the same key in a tree with the same
        // modification count if a key has changed its comparison since
        // it was added to the tree (which means the tree might no be
        // well-ordered, so much can go wrong).
        if (comparison != 0) throw ConcurrentModificationError(this);
      }
      _root!.value = newValue;
      return newValue;
    }
    if (ifAbsent != null) {
      final originalModificationCount = _modificationCount;
      final originalSplayCount = _splayCount;
      var newValue = ifAbsent();
      if (originalModificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      if (originalSplayCount != _splayCount) {
        comparison = _splay(key);
        // Can only happen if a key changed its comparison since being
        // added to the tree.
        if (comparison == 0) throw ConcurrentModificationError(this);
      }
      _addNewRoot(_SplayTreeMapNode(key, newValue), comparison);
      return newValue;
    }
    throw ArgumentError.value(key, "key", "Key not in map.");
  }

  void updateAll(V update(K key, V value)) {
    var root = _root;
    if (root == null) return;
    var iterator = _SplayTreeMapEntryIterator(this);
    while (iterator.moveNext()) {
      var node = iterator.current;
      var newValue = update(node.key, node.value);
      iterator._replaceValue(newValue);
    }
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  bool get isEmpty {
    return (_root == null);
  }

  bool get isNotEmpty => !isEmpty;

  void forEach(void f(K key, V value)) {
    Iterator<MapEntry<K, V>> nodes = _SplayTreeMapEntryIterator<K, V>(this);
    while (nodes.moveNext()) {
      MapEntry<K, V> node = nodes.current;
      f(node.key, node.value);
    }
  }

  int get length {
    return _count;
  }

  void clear() {
    _clear();
  }

  bool containsKey(Object? key) => _untypedLookup(key) != null;

  bool containsValue(Object? value) {
    int initialSplayCount = _splayCount;
    bool visit(_SplayTreeMapNode<K, V>? node) {
      while (node != null) {
        if (node.value == value) return true;
        if (initialSplayCount != _splayCount) {
          throw ConcurrentModificationError(this);
        }
        if (node._right != null && visit(node._right)) {
          return true;
        }
        node = node._left;
      }
      return false;
    }

    return visit(_root);
  }

  Iterable<K> get keys =>
      _SplayTreeKeyIterable<K, _SplayTreeMapNode<K, V>>(this);

  Iterable<V> get values => _SplayTreeValueIterable<K, V>(this);

  Iterable<MapEntry<K, V>> get entries =>
      _SplayTreeMapEntryIterable<K, V>(this);

  /// The first key in the map.
  ///
  /// Returns `null` if the map is empty.
  K? firstKey() {
    final root = _root;
    if (root == null) return null;
    return (_root = _splayMin(root)).key;
  }

  /// The last key in the map.
  ///
  /// Returns `null` if the map is empty.
  K? lastKey() {
    final root = _root;
    if (root == null) return null;
    return (_root = _splayMax(root)).key;
  }

  /// The last key in the map that is strictly smaller than [key].
  ///
  /// Returns `null` if such a key was not found.
  K? lastKeyBefore(K key) {
    if (key == null) throw ArgumentError(key);
    if (_root == null) return null;
    int comparison = _splay(key);
    if (comparison < 0) return _root!.key;
    _SplayTreeMapNode<K, V>? node = _root!._left;
    if (node == null) return null;
    var nodeRight = node._right;
    while (nodeRight != null) {
      node = nodeRight;
      nodeRight = node._right;
    }
    return node!.key;
  }

  /// Get the first key in the map that is strictly larger than [key]. Returns
  /// `null` if such a key was not found.
  K? firstKeyAfter(K key) {
    if (key == null) throw ArgumentError(key);
    if (_root == null) return null;
    int comparison = _splay(key);
    if (comparison > 0) return _root!.key;
    _SplayTreeMapNode<K, V>? node = _root!._right;
    if (node == null) return null;
    var nodeLeft = node._left;
    while (nodeLeft != null) {
      node = nodeLeft;
      nodeLeft = node._left;
    }
    return node!.key;
  }
}

abstract class _SplayTreeIterator<K, Node extends _SplayTreeNode<K, Node>, T>
    implements Iterator<T> {
  final _SplayTree<K, Node> _tree;

  /// The current node, and all its ancestors in the tree.
  ///
  /// Only valid as long as the original tree isn't reordered.
  final List<Node> _path = [];

  /// Original modification counter of [_tree].
  ///
  /// Incremented on [_tree] when a key is added or removed.
  /// If it changes, iteration is aborted.
  ///
  /// Not final because some iterators may modify the tree knowingly,
  /// and they update the modification count in that case.
  ///
  /// Starts at `null` to represent a fresh, unstarted iterator.
  int? _modificationCount;

  /// Count of splay operations on [_tree] when [_path] was built.
  ///
  /// If the splay count on [_tree] increases, [_path] becomes invalid.
  int _splayCount;

  _SplayTreeIterator(_SplayTree<K, Node> tree)
    : _tree = tree,
      _splayCount = tree._splayCount;

  T get current {
    if (_path.isEmpty) return null as T;
    var node = _path.last;
    return _getValue(node);
  }

  /// Called when the tree structure of the tree has changed.
  ///
  /// This can be caused by a splay operation.
  /// If the key-set changes, iteration is aborted before getting
  /// here, so we know that the keys are the same as before, it's
  /// only the tree nodes that has been reordered.
  void _rebuildPath(K key) {
    _path.clear();
    var comparison = _tree._splay(key);
    if (comparison == 0) {
      _path.add(_tree._root!);
      _splayCount = _tree._splayCount;
      return;
    }
    // Should not be able to happen unless an element changes
    // its comparison order while in the tree.
    throw ConcurrentModificationError(this);
  }

  void _findLeftMostDescendent(Node? node) {
    while (node != null) {
      _path.add(node);
      node = node._left;
    }
  }

  bool moveNext() {
    if (_modificationCount != _tree._modificationCount) {
      if (_modificationCount == null) {
        _modificationCount = _tree._modificationCount;
        var node = _tree._root;
        while (node != null) {
          _path.add(node);
          node = node._left;
        }
        return _path.isNotEmpty;
      }
      throw ConcurrentModificationError(_tree);
    }
    if (_path.isEmpty) return false;
    if (_splayCount != _tree._splayCount) {
      _rebuildPath(_path.last.key);
    }
    var node = _path.last;
    var next = node._right;
    if (next != null) {
      while (next != null) {
        _path.add(next);
        next = next._left;
      }
      return true;
    }
    _path.removeLast();
    while (_path.isNotEmpty && identical(_path.last._right, node)) {
      node = _path.removeLast();
    }
    return _path.isNotEmpty;
  }

  T _getValue(Node node);
}

class _SplayTreeKeyIterable<K, Node extends _SplayTreeNode<K, Node>>
    extends EfficientLengthIterable<K>
    implements HideEfficientLengthIterable<K> {
  _SplayTree<K, Node> _tree;
  _SplayTreeKeyIterable(this._tree);
  int get length => _tree._count;
  bool get isEmpty => _tree._count == 0;
  Iterator<K> get iterator => _SplayTreeKeyIterator<K, Node>(_tree);

  bool contains(Object? element) => _tree._untypedLookup(element) != null;

  Set<K> toSet() {
    SplayTreeSet<K> set = SplayTreeSet<K>(_tree._compare, _tree._validKey);
    var root = _tree._root;
    if (root != null) {
      set._root = set._copyNode<Node>(root);
      set._count = _tree._count;
    }
    return set;
  }
}

class _SplayTreeValueIterable<K, V> extends EfficientLengthIterable<V>
    implements HideEfficientLengthIterable<V> {
  SplayTreeMap<K, V> _map;
  _SplayTreeValueIterable(this._map);
  int get length => _map._count;
  bool get isEmpty => _map._count == 0;
  Iterator<V> get iterator => _SplayTreeValueIterator<K, V>(_map);
}

class _SplayTreeMapEntryIterable<K, V>
    extends EfficientLengthIterable<MapEntry<K, V>>
    implements HideEfficientLengthIterable<MapEntry<K, V>> {
  SplayTreeMap<K, V> _map;
  _SplayTreeMapEntryIterable(this._map);
  int get length => _map._count;
  bool get isEmpty => _map._count == 0;
  Iterator<MapEntry<K, V>> get iterator =>
      _SplayTreeMapEntryIterator<K, V>(_map);
}

class _SplayTreeKeyIterator<K, Node extends _SplayTreeNode<K, Node>>
    extends _SplayTreeIterator<K, Node, K> {
  _SplayTreeKeyIterator(_SplayTree<K, Node> tree) : super(tree);
  K _getValue(Node node) => node.key;
}

class _SplayTreeValueIterator<K, V>
    extends _SplayTreeIterator<K, _SplayTreeMapNode<K, V>, V> {
  _SplayTreeValueIterator(SplayTreeMap<K, V> map) : super(map);
  // SplayTreeMapNode.value is mutable, so cache it when moveNext returns true.
  // Cache it eagerly since the type `V` may be nullable, so we can't tell
  // if `_current` has been assigned yet or not.
  V? _current;
  bool moveNext() {
    var result = super.moveNext();
    _current = result ? _path.last.value : null;
    return result;
  }

  V _getValue(_SplayTreeMapNode<K, V> node) => _current as V;
}

class _SplayTreeMapEntryIterator<K, V>
    extends _SplayTreeIterator<K, _SplayTreeMapNode<K, V>, MapEntry<K, V>> {
  _SplayTreeMapEntryIterator(SplayTreeMap<K, V> map) : super(map);
  // `SplayTreeMapNode.value` is mutable, so cache the value the first time
  // `current` is read. (Avoids doing an allocation if `current` is not read.
  // Unlike `SplayTreeValueIterator`, the type of [current] is known to be
  // non-nullable.)
  MapEntry<K, V>? _current;

  MapEntry<K, V> _getValue(_SplayTreeMapNode<K, V> node) =>
      _current ??= MapEntry<K, V>(node.key, node.value);

  bool moveNext() {
    _current = null;
    return super.moveNext();
  }

  // Replaces the value of the current node.
  //
  // Used by [SplayTreeMap.updateAll].
  void _replaceValue(V value) {
    assert(_path.isNotEmpty);
    if (_modificationCount != _tree._modificationCount) {
      throw ConcurrentModificationError(_tree);
    }
    if (_splayCount != _tree._splayCount) {
      _rebuildPath(_path.last.key);
    }
    _path.last.value = value;
  }
}

/// A [Set] of objects that can be ordered relative to each other.
///
/// The set is based on a self-balancing binary tree. It allows most operations
/// in amortized logarithmic time.
///
/// Elements of the set are compared using the `compare` function passed in
/// the constructor, both for ordering and for equality.
/// If the set contains only an object `a`, then `set.contains(b)`
/// will return `true` if and only if `compare(a, b) == 0`,
/// and the value of `a == b` is not even checked.
/// If the compare function is omitted, the objects are assumed to be
/// [Comparable], and are compared using their [Comparable.compareTo] method.
/// Non-comparable objects (including `null`) will not work as an element
/// in that case.
///
/// **Note:**
/// Do not modify a set (add or remove elements) while an operation
/// is being performed on that set, for example in functions
/// called during a [forEach] or [containsAll] call,
/// or while iterating the set.
///
/// Do not modify elements in a way which changes their equality (and thus their
/// hash code) while they are in the set. Some specialized kinds of sets may be
/// more permissive with regards to equality, in which case they should document
/// their different behavior and restrictions.
///
/// Example:
/// ```dart
/// final planets = SplayTreeSet<String>((a, b) => a.compareTo(b));
/// ```
/// To add data to a set, use [add] or [addAll].
/// ```
/// planets.add('Neptune');
/// planets.addAll({'Venus', 'Mars', 'Earth', 'Jupiter'});
/// print(planets); // {Earth, Jupiter, Mars, Neptune, Venus}
/// ```
/// To check if the set is empty, use [isEmpty] or [isNotEmpty].
/// To find the number of elements in the set, use [length].
/// ```
/// final isEmpty = planets.isEmpty; // false
/// final length = planets.length; // 5
/// ```
/// To check whether the set contains a specific element, use [contains].
/// ```
/// final marsExists = planets.contains('Mars'); // true
/// ```
/// To get element value using index, use [elementAt].
/// ```
/// final elementAt = planets.elementAt(1);
/// print(elementAt); // Jupiter
/// ```
/// To make a copy of set, use [toSet].
/// ```
/// final copySet = planets.toSet(); // a `SplayTreeSet` with the same ordering.
/// print(copySet); // {Earth, Jupiter, Mars, Neptune, Venus}
/// ```
/// To remove an element, use [remove].
/// ```
/// final removedValue = planets.remove('Mars'); // true
/// print(planets); // {Earth, Jupiter, Neptune, Venus}
/// ```
/// To remove multiple elements at the same time, use [removeWhere].
/// ```
/// planets.removeWhere((element) => element.startsWith('J'));
/// print(planets); // {Earth, Neptune, Venus}
/// ```
/// To removes all elements in this set that do not meet a condition,
/// use [retainWhere].
/// ```
/// planets.retainWhere((element) => element.contains('Earth'));
/// print(planets); // {Earth}
/// ```
/// To remove all elements and empty the set, use [clear].
/// ```
/// planets.clear();
/// print(planets.isEmpty); // true
/// print(planets); // {}
/// ```
/// **See also:**
/// * [Set] is a base-class for collection of objects.
/// * [HashSet] the order of the objects in the iterations is not guaranteed.
/// * [LinkedHashSet] objects stored based on insertion order.
final class SplayTreeSet<E> extends _SplayTree<E, _SplayTreeSetNode<E>>
    with Iterable<E>, SetMixin<E> {
  _SplayTreeSetNode<E>? _root;

  int Function(E, E) _compare;
  bool Function(Object?)? _validKey;

  /// Create a new [SplayTreeSet] with the given compare function.
  ///
  /// If the [compare] function is omitted, it defaults to [Comparable.compare],
  /// and the elements must be comparable.
  ///
  /// A provided `compare` function may not work on all objects. It may not even
  /// work on all `E` instances.
  ///
  /// For operations that add elements to the set, the user is supposed to not
  /// pass in objects that don't work with the compare function.
  ///
  /// The methods [contains], [remove], [lookup], [removeAll] or [retainAll]
  /// are typed to accept any object(s), and the [isValidKey] test can used to
  /// filter those objects before handing them to the `compare` function.
  ///
  /// If [isValidKey] is provided, only values satisfying `isValidKey(other)`
  /// are compared using the `compare` method in the methods mentioned above.
  /// If the `isValidKey` function returns false for an object, it is assumed to
  /// not be in the set.
  ///
  /// If omitted, the `isValidKey` function defaults to checking against the
  /// type parameter: `other is E`.
  SplayTreeSet([
    int Function(E key1, E key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) : _compare = compare ?? _defaultCompare<E>(),
       _validKey = isValidKey;

  /// Creates a [SplayTreeSet] that contains all [elements].
  ///
  /// The set works as if created by `SplayTreeSet<E>(compare, isValidKey)`.
  ///
  /// All the [elements] should be instances of [E] and valid arguments to
  /// [compare].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `Set`, for example as:
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Set<SubType> subSet =
  ///     SplayTreeSet<SubType>.from(superSet.whereType<SubType>());
  /// ```
  /// Example:
  /// ```dart
  /// final numbers = <num>[20, 30, 10];
  /// final setFrom = SplayTreeSet<int>.from(numbers);
  /// print(setFrom); // {10, 20, 30}
  /// ```
  factory SplayTreeSet.from(
    Iterable elements, [
    int Function(E key1, E key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) {
    if (elements is Iterable<E>) {
      return SplayTreeSet<E>.of(elements, compare, isValidKey);
    }
    SplayTreeSet<E> result = SplayTreeSet<E>(compare, isValidKey);
    for (var element in elements) {
      result.add(element as dynamic);
    }
    return result;
  }

  /// Creates a [SplayTreeSet] from [elements].
  ///
  /// The set works as if created by `new SplayTreeSet<E>(compare, isValidKey)`.
  ///
  /// All the [elements] should be valid as arguments to the [compare] function.
  /// Example:
  /// ```dart
  /// final baseSet = <int>{1, 2, 3};
  /// final setOf = SplayTreeSet<num>.of(baseSet);
  /// print(setOf); // {1, 2, 3}
  /// ```
  factory SplayTreeSet.of(
    Iterable<E> elements, [
    int Function(E key1, E key2)? compare,
    bool Function(dynamic potentialKey)? isValidKey,
  ]) => SplayTreeSet(compare, isValidKey)..addAll(elements);

  Set<T> _newSet<T>() =>
      SplayTreeSet<T>((T a, T b) => _compare(a as E, b as E), _validKey);

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newSet);

  // From Iterable.

  Iterator<E> get iterator =>
      _SplayTreeKeyIterator<E, _SplayTreeSetNode<E>>(this);

  int get length => _count;
  bool get isEmpty => _root == null;
  bool get isNotEmpty => _root != null;

  E get first {
    final root = _root;
    if (root == null) throw IterableElementError.noElement();
    return (_root = _splayMin(root)).key;
  }

  E get last {
    final root = _root;
    if (root == null) throw IterableElementError.noElement();
    return (_root = _splayMax(root)).key;
  }

  E get single {
    if (_count == 1) return _root!.key;
    throw _count == 0
        ? IterableElementError.noElement()
        : IterableElementError.tooMany();
  }

  // From Set.
  bool contains(Object? element) => _untypedLookup(element) != null;

  bool add(E element) => _add(element);

  bool _add(E element) {
    int compare = _splay(element);
    if (compare == 0) return false;
    _addNewRoot(_SplayTreeSetNode(element), compare);
    return true;
  }

  bool remove(Object? object) {
    if (_untypedLookup(object) == null) return false;
    _removeRoot();
    return true;
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      _add(element);
    }
  }

  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (_untypedLookup(element) != null) {
        _removeRoot();
      }
    }
  }

  void retainAll(Iterable<Object?> elements) {
    // Build a set with the same sense of equality as this set.
    SplayTreeSet<E> retainSet = SplayTreeSet<E>(_compare, _validKey);
    final int originalModificationCount = _modificationCount;
    for (Object? object in elements) {
      if (originalModificationCount != _modificationCount) {
        // The iterator should not have side effects.
        throw ConcurrentModificationError(this);
      }
      final root = _untypedLookup(object);
      if (root != null) retainSet.add(root.key);
    }
    // Take over the elements from the retained set, if it differs.
    if (retainSet._count != _count) {
      _root = retainSet._root;
      _count = retainSet._count;
      _modificationCount++;
    }
  }

  E? lookup(Object? object) => _untypedLookup(object)?.key;

  Set<E> intersection(Set<Object?> other) => _filter(other, true);

  Set<E> difference(Set<Object?> other) => _filter(other, false);

  SplayTreeSet<E> _filter(Set<Object?> other, bool include) {
    // Copy nodes selectively.
    // Simulates repeated `add(element)` with elements that are
    // known to be in increasing order, which creates a left-spine structure.
    _SplayTreeSetNode<E>? root = null;
    var count = 0;
    for (E element in this) {
      if (other.contains(element) == include) {
        assert(root == null || _compare(root.key, element) <= 0);
        root = _SplayTreeSetNode<E>(element).._left = root;
        count++;
      }
    }
    return SplayTreeSet<E>(_compare, _validKey)
      .._root = root
      .._count = count;
  }

  Set<E> union(Set<E> other) {
    return _clone()..addAll(other);
  }

  SplayTreeSet<E> _clone() {
    var set = SplayTreeSet<E>(_compare, _validKey);
    var root = _root;
    if (root != null) {
      set._root = _copyNode<_SplayTreeSetNode<E>>(root);
      set._count = _count;
    }
    return set;
  }

  // Copies the structure of a SplayTree into a new similar SplayTreeSet
  // structure.
  // Works on _SplayTreeMapNode as well, but only copies the keys,
  // which is used for `.keys.toSet()`.
  _SplayTreeSetNode<E>? _copyNode<Node extends _SplayTreeNode<E, Node>>(
    Node source,
  ) {
    // The left subtree is copied recursively if there are two children,
    // and the right spine of every subtree, and any left-only child,
    // is copied iteratively.
    _SplayTreeSetNode<E> result = _SplayTreeSetNode<E>(source.key);
    // Copy of `source` that hasn't had children added yet.
    var target = result;
    while (true) {
      var sourceLeft = source._left;
      var sourceRight = source._right;
      if (sourceLeft != null) {
        if (sourceRight != null) {
          // Recursively copy the left tree.
          target._left = _copyNode<Node>(sourceLeft);
        } else {
          // Iteratively copy the left and only child.
          source = sourceLeft;
          target = target._left = _SplayTreeSetNode<E>(source.key);
          continue;
        }
      } else if (sourceRight == null) {
        break; // Done when reaching a leaf node.
      }
      source = sourceRight;
      target = target._right = _SplayTreeSetNode<E>(sourceRight.key);
    }
    return result;
  }

  void clear() {
    _clear();
  }

  Set<E> toSet() => _clone();

  String toString() => Iterable.iterableToFullString(this, '{', '}');
}
