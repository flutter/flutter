// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A collection of key/value pairs, from which you can retrieve a value
/// using its associated key.
///
/// This class implements a persistent map: extending this map with a new
/// key/value pair does not modify an existing instance but instead creates a
/// new instance.
///
/// Note: unlike [Map] this class does not support `null` as a key value and
/// implements only a functionality needed for a specific use case at the
/// core of the framework.
///
/// Underlying implemenation uses a variation of *hash array mapped trie* (HAMT)
/// datastructure with compressed (bitmap indexed) nodes.
///
/// See:
///  * [Bagwell, Phil. Ideal hash trees.](https://infoscience.epfl.ch/record/64398);
///  * [Steindorfer, Michael J., and Jurgen J. Vinju. "Optimizing hash-array mapped tries for fast and lean immutable JVM collections."](https://dl.acm.org/doi/abs/10.1145/2814270.2814312);
///  * [Clojure's `PersistentHashMap`](https://github.com/clojure/clojure/blob/master/src/jvm/clojure/lang/PersistentHashMap.java).
class PersistentHashMap<K extends Object, V> {
  /// An an empty dictionary.
  const PersistentHashMap.empty() : this._(null);

  const PersistentHashMap._(this._root);

  final _TrieNode? _root;

  /// Create a copy of this map extended with the given [key] to [value]
  /// mapping.
  PersistentHashMap<K, V> copyWith(K key, V value) {
    final _TrieNode newroot =
        (_root ?? _CompressedNode.empty).copyWith(0, key, key.hashCode, value);
    if (newroot == _root) {
      return this;
    }
    return PersistentHashMap<K, V>._(newroot);
  }

  /// Returns value associated with the given [key] or `null` if [key]
  /// is not in the map.
  V? lookup(K key) {
    return _root != null ? _root!.lookup(0, key, key.hashCode) as V? : null;
  }
}

/// Base class for nodes in a hash trie.
abstract class _TrieNode {
  static const int hashBitsPerLevel = 5;
  static const int hashBitsPerLevelMask = (1 << hashBitsPerLevel) - 1;

  @pragma('vm:prefer-inline')
  static int trieIndex(int hash, int bitIndex) {
    return (hash >>> bitIndex) & hashBitsPerLevelMask;
  }

  _TrieNode copyWith(int bitIndex, Object key, int keyHash, Object? value);

  Object? lookup(int bitIndex, Object key, int keyHash);
}

/// A full (uncompressed) node in the trie.
///
/// It contains an array with `1<<_hashBitsPerLevel` elements which
/// are references to deeper nodes.
class _FullNode extends _TrieNode {
  _FullNode(this.descendants);

  static const int numElements = 1 << _TrieNode.hashBitsPerLevel;

  final List<Object?> descendants;

  @override
  _TrieNode copyWith(int bitIndex, Object key, int keyHash, Object? value) {
    final int index = _TrieNode.trieIndex(keyHash, bitIndex);
    final _TrieNode node =
        (descendants[index] as _TrieNode?) ?? _CompressedNode.empty;
    final _TrieNode newNode = node.copyWith(
        bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash, value);
    return identical(newNode, node)
        ? this
        : _FullNode(_copy(descendants)..[index] = newNode);
  }

  @override
  Object? lookup(int bitIndex, Object key, int keyHash) {
    final int index = _TrieNode.trieIndex(keyHash, bitIndex);
    final _TrieNode? node = descendants[index] as _TrieNode?;
    return node?.lookup(bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash);
  }
}

/// Compressed node in the trie.
///
/// Instead of storing the full array of outgoing edges this node uses a
/// compressed representation:
///
///   * [_CompressedNode.occupied] has a bit set for indices which are occupied.
///   * furthermore, each occupied index can either be a `(key, value)` pair
///     representing an actual key/value mapping or a `(null, trieNode)` pair
///     representing a descendant node.
///
class _CompressedNode extends _TrieNode {
  _CompressedNode(this.occupiedIndices, this.keyValuePairs);
  _CompressedNode._empty() : this(0, _emptyArray);

  factory _CompressedNode.single(int bitIndex, int keyHash, _TrieNode node) {
    final int bit = 1 << _TrieNode.trieIndex(keyHash, bitIndex);
    // A single (null, node) pair.
    final List<Object?> keyValuePairs = List<Object?>.filled(2, null)
      ..[1] = node;
    return _CompressedNode(bit, keyValuePairs);
  }

  static final _CompressedNode empty = _CompressedNode._empty();
  static final List<Object?> _emptyArray = List<Object?>.filled(0, null);

  final int occupiedIndices;
  final List<Object?> keyValuePairs;

  @override
  _TrieNode copyWith(int bitIndex, Object key, int keyHash, Object? value) {
    final int bit = 1 << _TrieNode.trieIndex(keyHash, bitIndex);
    final int index = _compressedIndex(bit);

    if ((occupiedIndices & bit) != 0) {
      // Index is occupied.
      final Object? keyOrNull = keyValuePairs[2 * index];
      final Object? valueOrNode = keyValuePairs[2 * index + 1];

      // Is this a (null, trieNode) pair?
      if (identical(keyOrNull, null)) {
        // ignore: cast_nullable_to_non_nullable
        final _TrieNode newNode = (valueOrNode as _TrieNode).copyWith(
            bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash, value);
        if (newNode == valueOrNode) {
          return this;
        }
        return _CompressedNode(
            occupiedIndices, _copy(keyValuePairs)..[2 * index + 1] = newNode);
      }

      if (key == keyOrNull) {
        // Found key/value pair with a matching key. If values match
        // then avoid doing anything otherwise copy and update.
        return identical(value, valueOrNode)
            ? this
            : _CompressedNode(
                occupiedIndices, _copy(keyValuePairs)..[2 * index + 1] = value);
      }

      // Two different keys at the same index, resolve collision.
      final _TrieNode newNode = _resolveCollision(
          bitIndex + _TrieNode.hashBitsPerLevel,
          keyOrNull,
          valueOrNode,
          key,
          keyHash,
          value);
      return _CompressedNode(
          occupiedIndices,
          _copy(keyValuePairs)
            ..[2 * index] = null
            ..[2 * index + 1] = newNode);
    } else {
      // Adding new key/value mapping.
      final int occupiedCount = _bitCount(occupiedIndices);
      if (occupiedCount >= 16) {
        // Too many occupied: inflate compressed node into full node and
        // update descendant at the corresponding index.
        return _inflate(bitIndex)
          ..descendants[_TrieNode.trieIndex(keyHash, bitIndex)] =
              _CompressedNode.empty.copyWith(
                  bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash, value);
      } else {
        // Grow keyValuePairs by inserting key/value pair at the given
        // index.
        final int prefixLength = 2 * index;
        final int totalLength = 2 * occupiedCount;
        final List<Object?> newKeyValuePairs =
            List<Object?>.filled(totalLength + 2, null);
        for (int i = 0; i < prefixLength; i++) {
          newKeyValuePairs[i] = keyValuePairs[i];
        }
        newKeyValuePairs[prefixLength] = key;
        newKeyValuePairs[prefixLength + 1] = value;
        for (int i = prefixLength, j = prefixLength + 2;
            i < totalLength;
            i++, j++) {
          newKeyValuePairs[j] = keyValuePairs[i];
        }
        return _CompressedNode(occupiedIndices | bit, newKeyValuePairs);
      }
    }
  }

  @override
  Object? lookup(int bitIndex, Object key, int keyHash) {
    final int bit = 1 << _TrieNode.trieIndex(keyHash, bitIndex);
    if ((occupiedIndices & bit) == 0) {
      return null;
    }
    final int idx = _compressedIndex(bit);
    final Object? keyOrNull = keyValuePairs[2 * idx];
    final Object? valOrNode = keyValuePairs[2 * idx + 1];
    if (keyOrNull == null) {
      // ignore: cast_nullable_to_non_nullable
      return (valOrNode as _TrieNode)
          .lookup(bitIndex + _TrieNode.hashBitsPerLevel, key, keyHash);
    }
    if (key == keyOrNull) {
      return valOrNode;
    }
    return null;
  }

  /// Convert this node into an equivalent [_FullNode].
  _FullNode _inflate(int bitIndex) {
    final List<Object?> nodes =
        List<Object?>.filled(_FullNode.numElements, null);
    int j = 0;
    for (int i = 0; i < 32; i++) {
      if (((occupiedIndices >>> i) & 1) != 0) {
        final Object? keyOrNull = keyValuePairs[j];
        if (keyOrNull == null) {
          nodes[i] = keyValuePairs[j + 1];
        } else {
          nodes[i] = _CompressedNode.empty.copyWith(
              bitIndex + _TrieNode.hashBitsPerLevel,
              keyOrNull,
              keyValuePairs[j].hashCode,
              keyValuePairs[j + 1]);
        }
        j += 2;
      }
    }
    return _FullNode(nodes);
  }

  @pragma('vm:prefer-inline')
  int _compressedIndex(int bit) {
    return _bitCount(occupiedIndices & (bit - 1));
  }

  static _TrieNode _resolveCollision(int bitIndex, Object existingKey,
      Object? existingValue, Object key, int hash, Object? value) {
    final int existingKeyHash = existingKey.hashCode;
    // Check if this is a full hash collision and use _HashCollisionNode
    // in this case.
    return (existingKeyHash == hash)
        ? _HashCollisionNode.fromCollision(
            hash, existingKey, existingValue, key, value)
        : _CompressedNode.empty
            .copyWith(bitIndex, existingKey, existingKeyHash, existingValue)
            .copyWith(bitIndex, key, hash, value);
  }
}

/// Trie node representing a full hash collision.
///
/// Stores a list of key/value pairs (where all keys have the same hash code).
class _HashCollisionNode extends _TrieNode {
  _HashCollisionNode(this.hash, this.keyValuePairs);

  factory _HashCollisionNode.fromCollision(
      int keyHash, Object keyA, Object? valueA, Object keyB, Object? valueB) {
    final List<Object?> list = List<Object?>.filled(4, null);
    list[0] = keyA;
    list[1] = valueA;
    list[2] = keyB;
    list[3] = valueB;
    return _HashCollisionNode(keyHash, list);
  }

  final int hash;
  final List<Object?> keyValuePairs;

  @override
  _TrieNode copyWith(int bitIndex, Object key, int keyHash, Object? val) {
    // Is this another full hash collision?
    if (keyHash == hash) {
      final int index = _indexOf(key);
      if (index != -1) {
        return identical(keyValuePairs[index + 1], val)
            ? this
            : _HashCollisionNode(
                keyHash, _copy(keyValuePairs)..[index + 1] = val);
      }
      final int length = keyValuePairs.length;
      final List<Object?> newArray = List<Object?>.filled(length + 2, null);
      for (int i = 0; i < length; i++) {
        newArray[i] = keyValuePairs[i];
      }
      newArray[length] = key;
      newArray[length + 1] = val;
      return _HashCollisionNode(keyHash, newArray);
    }

    // Not a full hash collision, need to introduce a _CompressedNode which
    // uses previously unused bits.
    return _CompressedNode.single(bitIndex, hash, this)
        .copyWith(bitIndex, key, keyHash, val);
  }

  @override
  Object? lookup(int bitIndex, Object key, int keyHash) {
    final int index = _indexOf(key);
    return index < 0 ? null : keyValuePairs[index + 1];
  }

  int _indexOf(Object key) {
    final int length = keyValuePairs.length;
    for (int i = 0; i < length; i += 2) {
      if (key == keyValuePairs[i]) {
        return i;
      }
    }
    return -1;
  }
}

@pragma('vm:prefer-inline')
int _bitCount(int n) {
  n = n - ((n >> 1) & 0x55555555);
  n = (n & 0x33333333) + ((n >> 2) & 0x33333333);
  n = (n + (n >> 4)) & 0x0F0F0F0F;
  n = n + (n >> 8);
  n = n + (n >> 16);
  return n & 0x0000003F;
}

List<Object?> _copy(List<Object?> array) {
  final List<Object?> clone = List<Object?>.filled(array.length, null);
  for (int j = 0; j < array.length; j++) {
    clone[j] = array[j];
  }
  return clone;
}
