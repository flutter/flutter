// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

typedef _Predicate<T> = bool Function(T value);

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
/// A [_SplayTreeNode] that also contains a value,
/// and which implements [MapEntry].
class _SplayTreeMapNode<K, V>
    extends _SplayTreeNode<K, _SplayTreeMapNode<K, V>> {
  final V value;
  _SplayTreeMapNode(K key, this.value) : super(key);

  _SplayTreeMapNode<K, V> _replaceValue(V value) =>
      _SplayTreeMapNode<K, V>(key, value)
        .._left = _left
        .._right = _right;
}

/// A splay tree is a self-balancing binary search tree.
///
/// It has the additional property that recently accessed elements
/// are quick to access again.
/// It performs basic operations such as insertion, look-up and
/// removal, in O(log(n)) amortized time.
abstract class _SplayTree<K, Node extends _SplayTreeNode<K, Node>> {
  // The root node of the splay tree. It will contain either the last
  // element inserted or the last element looked up.
  Node? get _root;
  set _root(Node? newValue);

  // Number of elements in the splay tree.
  int _count = 0;

  /// Counter incremented whenever the keys in the map change.
  ///
  /// Used to detect concurrent modifications.
  int _modificationCount = 0;

  /// Counter incremented whenever the tree structure changes.
  ///
  /// Used to detect that an in-place traversal cannot use
  /// cached information that relies on the tree structure.
  int _splayCount = 0;

  /// The comparator that is used for this splay tree.
  Comparator<K> get _compare;

  /// The predicate to determine that a given object is a valid key.
  _Predicate get _validKey;

  /// Perform the splay operation for the given key. Moves the node with
  /// the given key to the top of the tree.  If no node has the given
  /// key, the last node on the search path is moved to the top of the
  /// tree. This is the simplified top-down splaying algorithm from:
  /// "Self-adjusting Binary Search Trees" by Sleator and Tarjan.
  ///
  /// Returns the result of comparing the new root of the tree to [key].
  /// Returns -1 if the table is empty.
  int _splay(K key) {
    var root = _root;
    if (root == null) {
      // Ensure key is compatible with `_compare`.
      _compare(key, key);
      return -1;
    }

    // The right and newTreeRight variables start out null, and are set
    // after the first move left.  The right node is the destination
    // for subsequent left rebalances, and newTreeRight holds the left
    // child of the final tree.  The newTreeRight variable is set at most
    // once, after the first move left, and is null iff right is null.
    // The left and newTreeLeft variables play the corresponding role for
    // right rebalances.
    Node? right;
    Node? newTreeRight;
    Node? left;
    Node? newTreeLeft;
    var current = root;
    // Hoist the field read out of the loop.
    var compare = _compare;
    int comp;
    while (true) {
      comp = compare(current.key, key);
      if (comp > 0) {
        var currentLeft = current._left;
        if (currentLeft == null) break;
        comp = compare(currentLeft.key, key);
        if (comp > 0) {
          // Rotate right.
          current._left = currentLeft._right;
          currentLeft._right = current;
          current = currentLeft;
          currentLeft = current._left;
          if (currentLeft == null) break;
        }
        // Link right.
        if (right == null) {
          // First left rebalance, store the eventual right child
          newTreeRight = current;
        } else {
          right._left = current;
        }
        right = current;
        current = currentLeft;
      } else if (comp < 0) {
        var currentRight = current._right;
        if (currentRight == null) break;
        comp = compare(currentRight.key, key);
        if (comp < 0) {
          // Rotate left.
          current._right = currentRight._left;
          currentRight._left = current;
          current = currentRight;
          currentRight = current._right;
          if (currentRight == null) break;
        }
        // Link left.
        if (left == null) {
          // First right rebalance, store the eventual left child
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
    return comp;
  }

  // Emulates splaying with a key that is smaller than any in the subtree
  // anchored at [node].
  // and that node is returned. It should replace the reference to [node]
  // in any parent tree or root pointer.
  Node _splayMin(Node node) {
    var current = node;
    var nextLeft = current._left;
    while (nextLeft != null) {
      var left = nextLeft;
      current._left = left._right;
      left._right = current;
      current = left;
      nextLeft = current._left;
    }
    return current;
  }

  // Emulates splaying with a key that is greater than any in the subtree
  // anchored at [node].
  // After this, the largest element in the tree is the root of the subtree,
  // and that node is returned. It should replace the reference to [node]
  // in any parent tree or root pointer.
  Node _splayMax(Node node) {
    var current = node;
    var nextRight = current._right;
    while (nextRight != null) {
      var right = nextRight;
      current._right = right._left;
      right._left = current;
      current = right;
      nextRight = current._right;
    }
    return current;
  }

  Node? _remove(K key) {
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp != 0) return null;
    var root = _root!;
    var result = root;
    var left = root._left;
    _count--;
    // assert(_count >= 0);
    if (left == null) {
      _root = root._right;
    } else {
      var right = root._right;
      // Splay to make sure that the new root has an empty right child.
      root = _splayMax(left);

      // Insert the original right child as the right child of the new
      // root.
      root._right = right;
      _root = root;
    }
    _modificationCount++;
    return result;
  }

  /// Adds a new root node with the given [key] or [value].
  ///
  /// The [comp] value is the result of comparing the existing root's key
  /// with key.
  void _addNewRoot(Node node, int comp) {
    _count++;
    _modificationCount++;
    var root = _root;
    if (root == null) {
      _root = node;
      return;
    }
    // assert(_count >= 0);
    if (comp < 0) {
      node._left = root;
      node._right = root._right;
      root._right = null;
    } else {
      node._right = root;
      node._left = root._left;
      root._left = null;
    }
    _root = node;
  }

  Node? get _first {
    var root = _root;
    if (root == null) return null;
    _root = _splayMin(root);
    return _root;
  }

  Node? get _last {
    var root = _root;
    if (root == null) return null;
    _root = _splayMax(root);
    return _root;
  }

  void _clear() {
    _root = null;
    _count = 0;
    _modificationCount++;
  }

  bool _containsKey(Object? key) {
    return _validKey(key) && _splay(key as dynamic) == 0;
  }
}

int _dynamicCompare(dynamic a, dynamic b) => Comparable.compare(a, b);

Comparator<K> _defaultCompare<K>() {
  // If K <: Comparable, then we can just use Comparable.compare
  // with no casts.
  Object compare = Comparable.compare;
  if (compare is Comparator<K>) {
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

  Comparator<K> _compare;
  _Predicate _validKey;

  SplayTreeMap(
      [int Function(K key1, K key2)? compare,
      bool Function(dynamic potentialKey)? isValidKey])
      : _compare = compare ?? _defaultCompare<K>(),
        _validKey = isValidKey ?? ((dynamic a) => a is K);

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
  factory SplayTreeMap.from(Map<dynamic, dynamic> other,
      [int Function(K key1, K key2)? compare,
      bool Function(dynamic potentialKey)? isValidKey]) {
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
  factory SplayTreeMap.of(Map<K, V> other,
          [int Function(K key1, K key2)? compare,
          bool Function(dynamic potentialKey)? isValidKey]) =>
      SplayTreeMap<K, V>(compare, isValidKey)..addAll(other);

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
  factory SplayTreeMap.fromIterable(Iterable iterable,
      {K Function(dynamic element)? key,
      V Function(dynamic element)? value,
      int Function(K key1, K key2)? compare,
      bool Function(dynamic potentialKey)? isValidKey}) {
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
  factory SplayTreeMap.fromIterables(Iterable<K> keys, Iterable<V> values,
      [int Function(K key1, K key2)? compare,
      bool Function(dynamic potentialKey)? isValidKey]) {
    SplayTreeMap<K, V> map = SplayTreeMap<K, V>(compare, isValidKey);
    MapBase._fillMapWithIterables(map, keys, values);
    return map;
  }

  V? operator [](Object? key) {
    if (!_validKey(key)) return null;
    if (_root != null) {
      int comp = _splay(key as dynamic);
      if (comp == 0) {
        return _root!.value;
      }
    }
    return null;
  }

  V? remove(Object? key) {
    if (!_validKey(key)) return null;
    _SplayTreeMapNode<K, V>? mapRoot = _remove(key as dynamic);
    if (mapRoot != null) return mapRoot.value;
    return null;
  }

  void operator []=(K key, V value) {
    // Splay on the key to move the last node on the search path for
    // the key to the root of the tree.
    int comp = _splay(key);
    if (comp == 0) {
      _root = _root!._replaceValue(value);
      // To represent structure change, in case someone caches the old node.
      _splayCount += 1;
      return;
    }
    _addNewRoot(_SplayTreeMapNode(key, value), comp);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int comp = _splay(key);
    if (comp == 0) {
      return _root!.value;
    }
    int modificationCount = _modificationCount;
    int splayCount = _splayCount;
    V value = ifAbsent();
    if (modificationCount != _modificationCount) {
      throw ConcurrentModificationError(this);
    }
    if (splayCount != _splayCount) {
      comp = _splay(key);
      // Key is still not there, otherwise _modificationCount would be changed.
      assert(comp != 0);
    }
    _addNewRoot(_SplayTreeMapNode(key, value), comp);
    return value;
  }

  V update(K key, V update(V value), {V Function()? ifAbsent}) {
    var comp = _splay(key);
    if (comp == 0) {
      var modificationCount = _modificationCount;
      var splayCount = _splayCount;
      var newValue = update(_root!.value);
      if (modificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      if (splayCount != _splayCount) {
        _splay(key);
      }
      _root = _root!._replaceValue(newValue);
      _splayCount += 1;
      return newValue;
    }
    if (ifAbsent != null) {
      var modificationCount = _modificationCount;
      var splayCount = _splayCount;
      var newValue = ifAbsent();
      if (modificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      if (splayCount != _splayCount) {
        comp = _splay(key);
      }
      _addNewRoot(_SplayTreeMapNode(key, newValue), comp);
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

  bool containsKey(Object? key) => _containsKey(key);

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
    if (_root == null) return null;
    return _first!.key;
  }

  /// The last key in the map.
  ///
  /// Returns `null` if the map is empty.
  K? lastKey() {
    if (_root == null) return null;
    return _last!.key;
  }

  /// The last key in the map that is strictly smaller than [key].
  ///
  /// Returns `null` if such a key was not found.
  K? lastKeyBefore(K key) {
    if (key == null) throw ArgumentError(key);
    if (_root == null) return null;
    int comp = _splay(key);
    if (comp < 0) return _root!.key;
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
    int comp = _splay(key);
    if (comp > 0) return _root!.key;
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
  /// only the tree that has been reordered.
  void _rebuildPath(K key) {
    _path.clear();
    _tree._splay(key);
    _path.add(_tree._root!);
    _splayCount = _tree._splayCount;
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

  bool contains(Object? o) => _tree._containsKey(o);

  Set<K> toSet() {
    SplayTreeSet<K> set = SplayTreeSet<K>(_tree._compare, _tree._validKey);
    set._count = _tree._count;
    set._root = set._copyNode<Node>(_tree._root);
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
  V _getValue(_SplayTreeMapNode<K, V> node) => node.value;
}

class _SplayTreeMapEntryIterator<K, V>
    extends _SplayTreeIterator<K, _SplayTreeMapNode<K, V>, MapEntry<K, V>> {
  _SplayTreeMapEntryIterator(SplayTreeMap<K, V> map) : super(map);
  MapEntry<K, V> _getValue(_SplayTreeMapNode<K, V> node) =>
      MapEntry<K, V>(node.key, node.value);

  // Replaces the value of the current node.
  void _replaceValue(V value) {
    assert(_path.isNotEmpty);
    if (_modificationCount != _tree._modificationCount) {
      throw ConcurrentModificationError(_tree);
    }
    if (_splayCount != _tree._splayCount) {
      _rebuildPath(_path.last.key);
    }
    var last = _path.removeLast();
    var newLast = last._replaceValue(value);
    if (_path.isEmpty) {
      _tree._root = newLast;
    } else {
      var parent = _path.last;
      if (identical(last, parent._left)) {
        parent._left = newLast;
      } else {
        assert(identical(last, parent._right));
        parent._right = newLast;
      }
    }
    _path.add(newLast);
    _splayCount = ++_tree._splayCount;
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

  Comparator<E> _compare;
  _Predicate _validKey;

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
  SplayTreeSet(
      [int Function(E key1, E key2)? compare,
      bool Function(dynamic potentialKey)? isValidKey])
      : _compare = compare ?? _defaultCompare<E>(),
        _validKey = isValidKey ?? ((dynamic v) => v is E);

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
  factory SplayTreeSet.from(Iterable elements,
      [int Function(E key1, E key2)? compare,
      bool Function(dynamic potentialKey)? isValidKey]) {
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
  factory SplayTreeSet.of(Iterable<E> elements,
          [int Function(E key1, E key2)? compare,
          bool Function(dynamic potentialKey)? isValidKey]) =>
      SplayTreeSet(compare, isValidKey)..addAll(elements);

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
    if (_count == 0) throw IterableElementError.noElement();
    return _first!.key;
  }

  E get last {
    if (_count == 0) throw IterableElementError.noElement();
    return _last!.key;
  }

  E get single {
    if (_count == 0) throw IterableElementError.noElement();
    if (_count > 1) throw IterableElementError.tooMany();
    return _root!.key;
  }

  // From Set.
  bool contains(Object? element) {
    return _validKey(element) && _splay(element as E) == 0;
  }

  bool add(E element) => _add(element);

  bool _add(E element) {
    int compare = _splay(element);
    if (compare == 0) return false;
    _addNewRoot(_SplayTreeSetNode(element), compare);
    return true;
  }

  bool remove(Object? object) {
    if (!_validKey(object)) return false;
    return _remove(object as E) != null;
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      _add(element);
    }
  }

  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (_validKey(element)) _remove(element as E);
    }
  }

  void retainAll(Iterable<Object?> elements) {
    // Build a set with the same sense of equality as this set.
    SplayTreeSet<E> retainSet = SplayTreeSet<E>(_compare, _validKey);
    int modificationCount = _modificationCount;
    for (Object? object in elements) {
      if (modificationCount != _modificationCount) {
        // The iterator should not have side effects.
        throw ConcurrentModificationError(this);
      }
      // Equivalent to this.contains(object).
      if (_validKey(object) && _splay(object as E) == 0) {
        retainSet.add(_root!.key);
      }
    }
    // Take over the elements from the retained set, if it differs.
    if (retainSet._count != _count) {
      _root = retainSet._root;
      _count = retainSet._count;
      _modificationCount++;
    }
  }

  E? lookup(Object? object) {
    if (!_validKey(object)) return null;
    int comp = _splay(object as E);
    if (comp != 0) return null;
    return _root!.key;
  }

  Set<E> intersection(Set<Object?> other) {
    Set<E> result = SplayTreeSet<E>(_compare, _validKey);
    for (E element in this) {
      if (other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> difference(Set<Object?> other) {
    Set<E> result = SplayTreeSet<E>(_compare, _validKey);
    for (E element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> union(Set<E> other) {
    return _clone()..addAll(other);
  }

  SplayTreeSet<E> _clone() {
    var set = SplayTreeSet<E>(_compare, _validKey);
    set._count = _count;
    set._root = _copyNode<_SplayTreeSetNode<E>>(_root);
    return set;
  }

  // Copies the structure of a SplayTree into a new similar structure.
  // Works on _SplayTreeMapNode as well, but only copies the keys,
  _SplayTreeSetNode<E>? _copyNode<Node extends _SplayTreeNode<E, Node>>(
      Node? node) {
    if (node == null) return null;
    // Given a source node and a destination node, copy the left
    // and right subtrees of the source node into the destination node.
    // The left subtree is copied recursively, but the right spine
    // of every subtree is copied iteratively.
    void copyChildren(Node node, _SplayTreeSetNode<E> dest) {
      Node? left;
      Node? right;
      do {
        left = node._left;
        right = node._right;
        if (left != null) {
          var newLeft = _SplayTreeSetNode<E>(left.key);
          dest._left = newLeft;
          // Recursively copy the left tree.
          copyChildren(left, newLeft);
        }
        if (right != null) {
          var newRight = _SplayTreeSetNode<E>(right.key);
          dest._right = newRight;
          // Set node and dest to copy the right tree iteratively.
          node = right;
          dest = newRight;
        }
      } while (right != null);
    }

    var result = _SplayTreeSetNode<E>(node.key);
    copyChildren(node, result);
    return result;
  }

  void clear() {
    _clear();
  }

  Set<E> toSet() => _clone();

  String toString() => Iterable.iterableToFullString(this, '{', '}');
}
