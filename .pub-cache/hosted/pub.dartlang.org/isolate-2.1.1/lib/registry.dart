// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An isolate-compatible object registry and lookup service.
library isolate.registry;

import 'dart:async' show Completer, TimeoutException;
import 'dart:collection' show HashMap, HashSet;
import 'dart:isolate' show RawReceivePort, SendPort, Capability;

import 'isolate_runner.dart'; // For documentation.
import 'ports.dart';
import 'src/util.dart';

// Command tags.
const int _addValue = 0;
const int _removeValue = 1;
const int _addTagsValue = 2;
const int _removeTagsValue = 3;
const int _getTagsValue = 4;
const int _findValue = 5;

/// An isolate-compatible object registry.
///
/// Objects can be stored as elements of a registry,
/// have "tags" assigned to them, and be looked up by tag.
///
/// Since the registry is identity based, the objects must not be numbers,
/// strings, booleans or null. See [Expando] for description of which objects
/// are not treated as having a clear identity.
///
/// A [Registry] object caches objects found using the [lookup]
/// method, or added using [add], and returns the same object every time
/// it is requested.
/// A different [Registry] object that works on the same underlying registry,
/// will not preserve the identity of elements
///
/// It is recommended to only have one `Registry` object working on the
/// same registry in each isolate.
///
/// When the registry is shared across isolates, both elements and tags must
/// be sendable between the isolates.
/// See [SendPort] for details on the restrictions on objects which can be sent
/// between isolates.
///
/// A registry can be used to make a number of objects available to separate
/// workers in different isolates, for example ones created using
/// [IsolateRunner], without sending all the objects to all the isolates.
/// A worker can then request the data it needs, and it can add new data
/// to the registry that will also be shared with all other workers.
/// Example:
/// ```dart
/// main() {
///   Registry<List<String>> dictionaryByFirstLetter = Registry();
///   for (var letter in alphabet) {
///     registry.add(
///         allWords.where((w) => w.startsWith(letter).toList,
///         tags: [letter]);
///   }
///   var loadBalancer = LoadBalancer(10);
///   for (var task in tasks) {
///     loadBalancer.run(_runTask, [task, dictionaryByFirstLetter]);
///   }
/// }
/// _runTask(task, Registry<List<String>> dictionaryByFirstLetter) async {
///   ...
///   // Fetch just the words starting with the needed letter.
///   var aWords = await dictionaryByFirstLetter.lookup(tags: [task.letter]);
///   ...
/// }
/// ```
///
/// A registry can be treated like a distributed multimap from tags to
/// objects, if each tag is only used once. Example:
/// ```dart
/// Registry<Capability> capabilities = Registry();
/// // local code:
///   ...
///   capabilities.add(Capability(), ["create"]);
///   capabilities.add(Capability(), ["read"]);
///   capabilities.add(Capability(), ["update"]);
///   capabilities.add(Capability(), ["delete"]);
///   ...
///   sendPort.send(capabilities);
///
/// // other isolate code:
///   Registry<Capability> capabilities = await receiveFromPort();
///
///   Future<Capability> get createCapability => (await
///      capabilities.lookup(tags: const ["create"])).first;
/// ```
class Registry<T> {
  // Most operations fail if they haven't received a response for this duration.
  final Duration _timeout;

  // Each `Registry` object has a cache of objects being controlled by it.
  // The cache is stored in an [Expando], not on the object.
  // This allows sending the `Registry` object through a `SendPort` without
  // also copying the cache.
  static final Expando<_RegistryCache> _caches = Expando<_RegistryCache>();

  /// Port for sending commands to the central registry manager.
  final SendPort _commandPort;

  /// Create a registry linked to a [RegistryManager] through [commandPort].
  ///
  /// In most cases, a registry is created by using the
  /// [RegistryManager.registry] getter.
  ///
  /// If a registry is used between isolates created using [Isolate.spawnUri],
  /// the `Registry` object can't be sent between the isolates directly.
  /// Instead the [RegistryManager.commandPort] port can be sent and a
  /// `Registry` created from the command port using this constructor.
  ///
  /// The optional [timeout] parameter can be set to the duration
  /// this registry should wait before assuming that an operation
  /// has failed.
  Registry.fromPort(SendPort commandPort,
      {Duration timeout = const Duration(seconds: 5)})
      : _commandPort = commandPort,
        _timeout = timeout;

  _RegistryCache get _cache => _caches[this] ??= _RegistryCache();

  /// Check and get the identity of an element.
  ///
  /// Throws if [element] is not an element in the registry.
  int _getId(T element) {
    var id = _cache.id(element);
    if (id == null) {
      throw StateError('Not an element: ${Error.safeToString(element)}');
    }
    return id;
  }

  /// Adds [element] to the registry with the provided tags.
  ///
  /// Fails if [element] is already in this registry.
  /// An object is already in the registry if it has been added using [add],
  /// or if it was returned by a [lookup] call on this registry object.
  ///
  /// Returns a capability that can be used with [remove] to remove
  /// the element from the registry again.
  ///
  /// The [tags] can be used to distinguish some of the elements
  /// from other elements. Any object can be used as a tag, as long as
  /// it preserves equality when sent through a [SendPort].
  /// This makes [Capability] objects a good choice for tags.
  Future<Capability> add(T element, {Iterable? tags}) {
    var cache = _cache;
    if (cache.contains(element)) {
      return Future<Capability>.sync(() {
        throw StateError(
            'Object already in registry: ${Error.safeToString(element)}');
      });
    }
    var completer = Completer<Capability>();
    var port = singleCompletePort(completer,
        callback: (List<Object?> response) {
          assert(cache.isAdding(element));
          var id = response[0] as int;
          var removeCapability = response[1] as Capability;
          cache.register(id, element);
          return removeCapability;
        },
        timeout: _timeout,
        onTimeout: () {
          cache.stopAdding(element);
          throw TimeoutException('Future not completed', _timeout);
        });
    if (tags != null) tags = tags.toList(growable: false);
    cache.setAdding(element);
    _commandPort.send(list4(_addValue, element, tags, port));
    return completer.future;
  }

  /// Removes the [element] from the registry.
  ///
  /// Returns `true` if removing the element succeeded, and `false` if the
  /// elements either wasn't in the registry, or it couldn't be removed.
  ///
  /// The [removeCapability] must be the same capability returned by [add]
  /// when the object was added. If the capability is wrong, the
  /// object is not removed, and this function returns `false`.
  Future<bool> remove(T element, Capability removeCapability) {
    var id = _cache.id(element);
    if (id == null) {
      // If the element is not in the cache, then it was not a value
      // that originally came from the registry.
      return Future<bool>.value(false);
    }
    var completer = Completer<bool>();
    var port = singleCompletePort(completer, callback: (bool result) {
      if (result) _cache.remove(id);
      return result;
    }, timeout: _timeout);
    _commandPort.send(list4(_removeValue, id, removeCapability, port));
    return completer.future;
  }

  /// Add tags to objects in the registry.
  ///
  /// Each element of the registry has a number of tags associated with
  /// it. A tag is either associated with an element or not, adding it more
  /// than once does not make any difference.
  ///
  /// Tags are compared using [Object.==] equality.
  ///
  /// Fails if any of the elements are not in the registry.
  Future addTags(Iterable<T> elements, Iterable<Object?> tags) {
    var ids = elements.map(_getId).toList(growable: false);
    return _addTags(ids, tags);
  }

  /// Remove tags from objects in the registry.
  ///
  /// After this operation, the [elements] will not be associated to the [tags].
  /// It doesn't matter whether the elements were associated with the tags
  /// before or not.
  ///
  /// Fails if any of the elements are not in the registry.
  Future<void> removeTags(Iterable<T> elements, Iterable<Object?> tags) {
    var ids = elements.map(_getId).toList(growable: false);
    tags = tags.toList(growable: false);
    var completer = Completer<void>();
    var port = singleCompletePort(completer, timeout: _timeout);
    _commandPort.send(list4(_removeTagsValue, ids, tags, port));
    return completer.future;
  }

  Future<void> _addTags(List<int> ids, Iterable<Object?> tags) {
    tags = tags.toList(growable: false);
    var completer = Completer<void>();
    var port = singleCompletePort(completer, timeout: _timeout);
    _commandPort.send(list4(_addTagsValue, ids, tags, port));
    return completer.future;
  }

  /// Finds a number of elements that have all the desired [tags].
  ///
  /// If [tags] is omitted or empty, any element of the registry can be
  /// returned.
  ///
  /// If [max] is specified, it must be greater than zero.
  /// In that case, at most the first `max` results are returned,
  /// in whatever order the registry finds its results.
  /// Otherwise all matching elements are returned.
  Future<List<T>> lookup({Iterable<Object?>? tags, int? max}) async {
    if (max != null && max < 1) {
      throw RangeError.range(max, 1, null, 'max');
    }
    if (tags != null) tags = tags.toList(growable: false);
    var completer = Completer<List<T>>();
    var port = singleCompletePort(completer, callback: (List<T> response) {
      // Response is even-length list of (id, element) pairs.
      var cache = _cache;
      var count = response.length ~/ 2;
      var result = List<T>.generate(
          count,
          (i) =>
              cache.register(response[i * 2] as int, response[i * 2 + 1]) as T,
          growable: false);
      return result;
    }, timeout: _timeout);
    _commandPort.send(list4(_findValue, tags, max, port));
    return await completer.future;
  }
}

/// Isolate-local cache used by a [Registry].
///
/// Maps between id numbers and elements.
///
/// Each instance of [Registry] has its own cache,
/// and only considers elements part of the registry
/// if they are registered in its cache.
/// An object becomes registered either when calling
/// [add] on that particular [Registry] instance,
/// or when fetched using [lookup] through that
/// registry instance.
class _RegistryCache {
  // Temporary marker until an object gets an id.
  static const int _beingAdded = -1;

  final Map<int, Object?> id2object = HashMap();
  final Map<Object?, int> object2id = HashMap.identity();

  int? id(Object? object) {
    var result = object2id[object];
    if (result == _beingAdded) return null;
    return result;
  }

  Object? operator [](int id) => id2object[id];

  // Register a pair of id/object in the cache.
  // if the id is already in the cache, just return the existing
  // object.
  Object? register(int id, Object? object) {
    object = id2object.putIfAbsent(id, () {
      object2id[object] = id;
      return object;
    });
    return object;
  }

  bool isAdding(element) => object2id[element] == _beingAdded;

  void setAdding(element) {
    assert(!contains(element));
    object2id[element] = _beingAdded;
  }

  void stopAdding(element) {
    assert(object2id[element] == _beingAdded);
    object2id.remove(element);
  }

  void remove(int id) {
    var element = id2object.remove(id);
    if (element != null) {
      object2id.remove(element);
    }
  }

  bool contains(element) => object2id.containsKey(element);
}

/// The central repository used by distributed [Registry] instances.
class RegistryManager {
  final Duration _timeout;
  final RawReceivePort _commandPort;
  int _nextId = 0;

  /// Maps id to entry. Each entry contains the id, the element, its tags,
  /// and a capability required to remove it again.
  final _entries = HashMap<int, _RegistryEntry>();
  final _tag2id = HashMap<Object?, Set<int>>();

  /// Create a new registry managed by the created [RegistryManager].
  ///
  /// The optional [timeout] parameter can be set to the duration
  /// registry objects should wait before assuming that an operation
  /// has failed.
  RegistryManager({Duration timeout = const Duration(seconds: 5)})
      : _timeout = timeout,
        _commandPort = RawReceivePort() {
    _commandPort.handler = _handleCommand;
  }

  /// The command port receiving commands for the registry manager.
  ///
  /// Use this port with [Registry.fromPort] to link a registry to the
  /// manager in isolates where you can't send a [Registry] object directly.
  SendPort get commandPort => _commandPort.sendPort;

  /// Get a registry backed by this manager.
  ///
  /// This registry can be sent to other isolates created using
  /// [Isolate.spawn].
  Registry get registry =>
      Registry.fromPort(_commandPort.sendPort, timeout: _timeout);

  // Used as argument to putIfAbsent.
  static Set<int> _createSet() => HashSet<int>();

  void _handleCommand(List<dynamic> command) {
    switch (command[0]) {
      case _addValue:
        _add(command[1], command[2] as List<Object?>?, command[3] as SendPort);
        return;
      case _removeValue:
        _remove(
          command[1] as int,
          command[2] as Capability,
          command[3] as SendPort,
        );
        return;
      case _addTagsValue:
        _addTags(
          command[1] as List<int>,
          command[2] as List,
          command[3] as SendPort,
        );
        return;
      case _removeTagsValue:
        _removeTags(
          command[1] as List<int>,
          command[2] as List,
          command[3] as SendPort,
        );
        return;
      case _getTagsValue:
        _getTags(command[1] as int, command[2] as SendPort);
        return;
      case _findValue:
        _find(command[1] as List?, command[2] as int?, command[3] as SendPort);
        return;
      default:
        throw UnsupportedError('Unknown command: ${command[0]}');
    }
  }

  void _add(object, List? tags, SendPort replyPort) {
    var id = ++_nextId;
    var entry = _RegistryEntry(id, object);
    _entries[id] = entry;
    if (tags != null) {
      for (var tag in tags) {
        entry.tags.add(tag);
        _tag2id.putIfAbsent(tag, _createSet).add(id);
      }
    }
    replyPort.send(list2(id, entry.removeCapability));
  }

  void _remove(int id, Capability removeCapability, SendPort replyPort) {
    var entry = _entries[id];
    if (entry == null || entry.removeCapability != removeCapability) {
      replyPort.send(false);
      return;
    }
    _entries.remove(id);
    for (var tag in entry.tags) {
      _tag2id[tag]!.remove(id);
    }
    replyPort.send(true);
  }

  void _addTags(List<int> ids, List<Object?> tags, SendPort replyPort) {
    assert(tags.isNotEmpty);
    for (var id in ids) {
      var entry = _entries[id];
      if (entry == null) continue; // Entry was removed.
      entry.tags.addAll(tags);
      for (var tag in tags) {
        Set ids = _tag2id.putIfAbsent(tag, _createSet);
        ids.add(id);
      }
    }
    replyPort.send(null);
  }

  void _removeTags(List<int> ids, List tags, SendPort replyPort) {
    assert(tags.isNotEmpty);
    for (var id in ids) {
      var entry = _entries[id];
      if (entry == null) continue; // Object was removed.
      entry.tags.removeAll(tags);
    }
    for (var tag in tags) {
      Set? tagIds = _tag2id[tag];
      if (tagIds == null) continue;
      tagIds.removeAll(ids);
    }
    replyPort.send(null);
  }

  void _getTags(int id, SendPort replyPort) {
    var entry = _entries[id];
    if (entry != null) {
      replyPort.send(entry.tags.toList(growable: false));
    } else {
      replyPort.send(const []);
    }
  }

  Iterable<int> _findTaggedIds(List tags) {
    var matchingFirstTagIds = _tag2id[tags[0]];
    if (matchingFirstTagIds == null) {
      return const [];
    }
    if (matchingFirstTagIds.isEmpty || tags.length == 1) {
      return matchingFirstTagIds;
    }
    // Create new set, then start removing ids not also matched
    // by other tags.
    var matchingIds = matchingFirstTagIds.toSet();
    for (var i = 1; i < tags.length; i++) {
      var tagIds = _tag2id[tags[i]];
      if (tagIds == null) return const [];
      matchingIds.retainAll(tagIds);
      if (matchingIds.isEmpty) break;
    }
    return matchingIds;
  }

  void _find(List? tags, int? max, SendPort replyPort) {
    assert(max == null || max > 0);
    var result = [];
    if (tags == null || tags.isEmpty) {
      var entries = _entries.values;
      if (max != null) entries = entries.take(max);
      for (var entry in entries) {
        result.add(entry.id);
        result.add(entry.element);
      }
      replyPort.send(result);
      return;
    }
    var matchingIds = _findTaggedIds(tags);

    var actualMax = max ?? matchingIds.length; // All results.
    for (var id in matchingIds) {
      result.add(id);
      result.add(_entries[id]!.element);
      actualMax -= 1;
      if (actualMax == 0) break;
    }
    replyPort.send(result);
  }

  /// Shut down the registry service.
  ///
  /// After this, all [Registry] operations will time out.
  void close() {
    _commandPort.close();
  }
}

/// Entry in [RegistryManager].
class _RegistryEntry {
  final int id;
  final Object? element;
  final Set tags = HashSet();
  final Capability removeCapability = Capability();

  _RegistryEntry(this.id, this.element);
}
