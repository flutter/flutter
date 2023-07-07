// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Classes for representing information about the program structure.
library vm_snapshot_analysis.program_info;

import 'package:vm_snapshot_analysis/v8_profile.dart';

/// Represents information about compiled program.
class ProgramInfo {
  static const int rootId = 0;
  static const int stubsId = 1;
  static const int unknownId = 2;

  final ProgramInfoNode root;
  final ProgramInfoNode stubs;
  final ProgramInfoNode unknown;
  int _nextId = 3;

  /// V8 snapshot profile if this [ProgramInfo] object was created from an
  /// output of `--write-v8-snapshot-profile-to=...` flag.
  SnapshotInfo? snapshotInfo;

  ProgramInfo._(this.root, this.stubs, this.unknown);

  factory ProgramInfo() {
    final ProgramInfoNode root = ProgramInfoNode._(
        id: rootId, name: '@shared', type: NodeType.libraryNode, parent: null);

    final ProgramInfoNode stubs = ProgramInfoNode._(
        id: stubsId, name: '@stubs', type: NodeType.libraryNode, parent: root);
    root.children[stubs.name] = stubs;

    final ProgramInfoNode unknown = ProgramInfoNode._(
        id: unknownId,
        name: '@unknown',
        type: NodeType.libraryNode,
        parent: root);
    root.children[unknown.name] = unknown;

    return ProgramInfo._(root, stubs, unknown);
  }

  ProgramInfoNode makeNode(
      {required String name,
      required ProgramInfoNode parent,
      required NodeType type}) {
    return parent.children.putIfAbsent(
        name,
        () => ProgramInfoNode._(
            id: _nextId++, name: name, parent: parent, type: type));
  }

  /// Recursively visit all function nodes, which have [FunctionInfo.info]
  /// populated.
  void visit(
      void Function(String? pkg, String lib, String? cls, String? fun,
              ProgramInfoNode n)
          callback) {
    final context = List<String?>.filled(NodeType.values.length, null);

    void recurse(ProgramInfoNode node) {
      final prevContext = context[node._type];
      if (prevContext != null && node._type == NodeType.functionNode.index) {
        context[node._type] = '$prevContext.${node.name}';
      } else {
        context[node._type] = node.name;
      }

      final pkg = context[NodeType.packageNode.index];
      final lib = context[NodeType.libraryNode.index];
      final cls = context[NodeType.classNode.index];
      final mem = context[NodeType.functionNode.index];
      callback(pkg, lib!, cls, mem, node);

      for (var child in node.children.values) {
        recurse(child);
      }

      context[node._type] = prevContext;
    }

    recurse(root);
  }

  /// Total size of all the nodes in the program.
  int get totalSize => root.totalSize;

  /// Convert this program info to a JSON map using [infoToJson] to convert
  /// data attached to nodes into its JSON representation.
  Map<String, dynamic> toJson() => root.toJson();

  /// Lookup a node in the program given a path to it.
  ProgramInfoNode? lookup(List<String> path) {
    var n = root;
    for (var p in path) {
      final next = n.children[p];
      if (next == null) {
        return null;
      }
      n = next;
    }
    return n;
  }
}

enum NodeType {
  packageNode,
  libraryNode,
  classNode,
  functionNode,
  other,
}

String _typeToJson(NodeType type) => const {
      NodeType.packageNode: 'package',
      NodeType.libraryNode: 'library',
      NodeType.classNode: 'class',
      NodeType.functionNode: 'function',
      NodeType.other: 'other',
    }[type]!;

class ProgramInfoNode {
  final int id;
  final String name;
  final ProgramInfoNode? parent;
  final Map<String, ProgramInfoNode> children = {};
  final int _type;

  /// Number of bytes in the snapshot which can be attributed to this node.
  ///
  /// Note that this is neither a shallow size of the object that represents
  /// this node in the AOT snapshot, nor a cumulative size of its children.
  /// Instead this size is similar to _retained size_ used by heap profiling
  /// tools. Snapshot nodes corresponding to the info nodes are viewed as
  /// a dominator tree and all nodes in the snapshot are partitioned based
  /// on which node of this tree dominates them.
  ///
  /// Consider for example the following Dart code:
  ///
  ///     ```dart
  ///     class C {
  ///       void f() { use("something"); }
  ///       void g() { use("something"); }
  ///     }
  ///     ```
  ///
  /// Assuming that both `C.f` and `C.g` are included into AOT snapshot
  /// and string `"something"` does not occur anywhere else in the program
  /// then the size of `"something"` is going to be attributed to `C`.
  int? size;

  ProgramInfoNode._(
      {required this.id,
      required this.name,
      required this.parent,
      required NodeType type})
      : _type = type.index;

  NodeType get type => NodeType.values[_type];

  Map<String, dynamic> toJson() => {
        if (size != null) '#size': size,
        if (_type != NodeType.other.index) '#type': _typeToJson(type),
        if (children.isNotEmpty)
          for (var clo in children.entries) clo.key: clo.value.toJson()
      };

  /// Returns the name of this node prefixed by the [qualifiedName] of its
  /// [parent].
  String get qualifiedName {
    var prefix = '';
    // Do not include root name or package name (library uri already contains
    // package name).
    final p = parent;
    if (p != null && p.parent != null && p.type != NodeType.packageNode) {
      prefix = p.qualifiedName;
      if (p.type != NodeType.libraryNode) {
        prefix += '.';
      } else {
        prefix += '::';
      }
    }
    return '$prefix$name';
  }

  @override
  String toString() {
    return '${_typeToJson(type)} $qualifiedName';
  }

  /// Returns path to this node such that [ProgramInfo.lookup] would return
  /// this node given its [path].
  List<String> get path {
    final result = <String>[];
    var n = this;
    while (n.parent != null) {
      result.add(n.name);
      n = n.parent!;
    }
    return result.reversed.toList();
  }

  /// Cumulative size of this node and all of its children.
  int get totalSize {
    return (size ?? 0) +
        children.values.fold<int>(0, (s, n) => s + n.totalSize);
  }
}

/// Computes the size difference between two [ProgramInfo].
ProgramInfo computeDiff(ProgramInfo oldInfo, ProgramInfo newInfo) {
  final programDiff = ProgramInfo();

  var path = <Object>[];
  void recurse(ProgramInfoNode? oldNode, ProgramInfoNode? newNode) {
    if (oldNode?.size != newNode?.size) {
      var diffNode = programDiff.root;
      for (var i = 0; i < path.length; i += 2) {
        final name = path[i] as String;
        final type = path[i + 1] as NodeType;
        diffNode =
            programDiff.makeNode(name: name, parent: diffNode, type: type);
      }
      diffNode.size =
          (diffNode.size ?? 0) + (newNode?.size ?? 0) - (oldNode?.size ?? 0);
    }

    for (var key in _allKeys(newNode?.children, oldNode?.children)) {
      final newChildNode = newNode != null ? newNode.children[key] : null;
      final oldChildNode = oldNode != null ? oldNode.children[key] : null;
      path.add(key);
      path.add((oldChildNode?.type ?? newChildNode?.type)!);
      recurse(oldChildNode, newChildNode);
      path.removeLast();
      path.removeLast();
    }
  }

  recurse(oldInfo.root, newInfo.root);

  return programDiff;
}

Iterable<T> _allKeys<T>(Map<T, dynamic>? a, Map<T, dynamic>? b) {
  return <T>{...?a?.keys, ...?b?.keys};
}

class Histogram {
  /// Rule used to produce this histogram. Specifies how bucket names
  /// are constructed given (library-uri,class-name,function-name) tuples and
  /// how these bucket names can be deconstructed back into human readable form.
  final BucketInfo bucketInfo;

  /// Histogram buckets.
  final Map<String, int> buckets;

  /// Bucket names sorted by the size of the corresponding bucket in descending
  /// order.
  final List<String> bySize;

  final int totalSize;

  int get length => bySize.length;

  Histogram._(this.bucketInfo, this.buckets)
      : bySize = buckets.keys.toList(growable: false)
          ..sort((a, b) => buckets[b]! - buckets[a]!),
        totalSize = buckets.values.fold(0, (sum, size) => sum + size);

  static Histogram fromIterable<T>(
    Iterable<T> entries, {
    required int Function(T) sizeOf,
    required String Function(T) bucketFor,
    required BucketInfo bucketInfo,
  }) {
    final buckets = <String, int>{};

    for (var e in entries) {
      final bucket = bucketFor(e);
      final size = sizeOf(e);
      buckets[bucket] = (buckets[bucket] ?? 0) + size;
    }

    return Histogram._(bucketInfo, buckets);
  }

  /// Rebuckets the histogram given the new bucketing rule.
  Histogram map(String Function(String) bucketFor) {
    return Histogram.fromIterable(buckets.keys,
        sizeOf: (key) => buckets[key]!,
        bucketFor: bucketFor,
        bucketInfo: bucketInfo);
  }
}

/// Construct the histogram of specific [type] given a [ProgramInfo].
///
/// [filter] glob can be provided to skip some of the nodes in the [info]:
/// a string is created which contains library name, class name and function
/// name for the given node and if this string does not match the [filter]
/// glob then this node is ignored.
Histogram computeHistogram(ProgramInfo info, HistogramType type,
    {String? filter}) {
  bool Function(String, String?, String?) matchesFilter;

  if (filter != null) {
    final re = RegExp(filter.replaceAll('*', '.*'), caseSensitive: false);
    matchesFilter =
        (lib, cls, fun) => re.hasMatch("$lib::${cls ?? ''}.${fun ?? ''}");
  } else {
    matchesFilter = (_, __, ___) => true;
  }

  if (type == HistogramType.byNodeType) {
    final Set<int> filteredNodes = {};
    if (filter != null) {
      info.visit((pkg, lib, cls, fun, node) {
        if (matchesFilter(lib, cls, fun)) {
          filteredNodes.add(node.id);
        }
      });
    }

    final snapshotInfo = info.snapshotInfo!;

    return Histogram.fromIterable<Node>(
        snapshotInfo.snapshot.nodes.where((n) =>
            filter == null ||
            filteredNodes.contains(snapshotInfo.ownerOf(n).id)),
        sizeOf: (n) {
          return n.selfSize;
        },
        bucketFor: (n) => n.type,
        bucketInfo: const BucketInfo(nameComponents: ['Type']));
  } else {
    final buckets = <String, int>{};
    final bucketing = Bucketing._forType[type]!;

    info.visit((pkg, lib, cls, fun, node) {
      final sz = node.size;
      if (sz == null || sz == 0) {
        return;
      }
      if (!matchesFilter(lib, cls, fun)) {
        return;
      }
      final bucket = bucketing.bucketFor(pkg, lib, cls, fun);
      buckets[bucket] = (buckets[bucket] ?? 0) + sz;
    });

    return Histogram._(bucketing, buckets);
  }
}

enum HistogramType {
  bySymbol,
  byClass,
  byLibrary,
  byPackage,
  byNodeType,
}

class BucketInfo {
  /// Specifies which human readable name components can be extracted from
  /// the bucket name.
  final List<String> nameComponents;

  /// Deconstructs bucket name into human readable components (the order matches
  /// one returned by [nameComponents]).
  List<String> namesFromBucket(String bucket) => [bucket];

  const BucketInfo({required this.nameComponents});
}

abstract class Bucketing extends BucketInfo {
  /// Constructs the bucket name from the given library name [lib], class name
  /// [cls] and function name [fun].
  String bucketFor(String? pkg, String lib, String? cls, String? fun);

  const Bucketing({required List<String> nameComponents})
      : super(nameComponents: nameComponents);

  static const _forType = {
    HistogramType.bySymbol: _BucketBySymbol(),
    HistogramType.byClass: _BucketByClass(),
    HistogramType.byLibrary: _BucketByLibrary(),
    HistogramType.byPackage: _BucketByPackage(),
  };
}

/// A combination of characters that is unlikely to occur in the symbol name.
const String _nameSeparator = ';;;';

class _BucketBySymbol extends Bucketing {
  @override
  String bucketFor(String? pkg, String lib, String? cls, String? fun) {
    if (fun == null) {
      return '@other$_nameSeparator';
    }
    return '$lib$_nameSeparator${cls ?? ''}${cls != '' && cls != null ? '.' : ''}$fun';
  }

  @override
  List<String> namesFromBucket(String bucket) => bucket.split(_nameSeparator);

  const _BucketBySymbol() : super(nameComponents: const ['Library', 'Symbol']);
}

class _BucketByClass extends Bucketing {
  @override
  String bucketFor(String? pkg, String lib, String? cls, String? fun) {
    if (cls == null) {
      return '@other$_nameSeparator';
    }
    return '$lib$_nameSeparator$cls';
  }

  @override
  List<String> namesFromBucket(String bucket) => bucket.split(_nameSeparator);

  const _BucketByClass() : super(nameComponents: const ['Library', 'Class']);
}

class _BucketByLibrary extends Bucketing {
  @override
  String bucketFor(String? pkg, String lib, String? cls, String? fun) => lib;

  const _BucketByLibrary() : super(nameComponents: const ['Library']);
}

class _BucketByPackage extends Bucketing {
  @override
  String bucketFor(String? pkg, String lib, String? cls, String? fun) =>
      pkg ?? lib;

  const _BucketByPackage() : super(nameComponents: const ['Package']);
}

String packageOf(String lib) {
  if (lib.startsWith('package:')) {
    final separatorPos = lib.indexOf('/');
    return lib.substring(0, separatorPos);
  } else {
    return lib;
  }
}
