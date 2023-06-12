// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper for building a treemap out of AOT snapshot size dump.
library vm_snapshot_analysis.treemap;

import 'dart:math';

import 'package:vm_snapshot_analysis/instruction_sizes.dart'
    as instruction_sizes;
import 'package:vm_snapshot_analysis/program_info.dart';
import 'package:vm_snapshot_analysis/utils.dart';
import 'package:vm_snapshot_analysis/v8_profile.dart' as v8_profile;

/// Specifies the granularity at which snapshot nodes are represented when
/// converting V8 snapshot profile into a treemap.
enum TreemapFormat {
  /// Snapshot nodes are collapsed and only info nodes which own them are
  /// represented in the treemap, meaning that each leaf treemap node is
  /// essentially representing a [ProgramInfoNode].
  collapsed,

  /// Similar to [collapsed] but we also fold all information about nested
  /// functions into the outermost function (e.g. a method or a top-level
  /// function) further simplifying the output.
  simplified,

  /// Snapshot nodes are collapsed based on their type into two categories:
  /// executable code and data. Leaf node in a treemap represents amount of
  /// code or data bytes owned by a specific [ProgramInfoNode].
  dataAndCode,

  /// Snapshot nodes are grouped based on their type, but no further
  /// aggregation is performed. Leaf node in a treemap represents amount of
  /// bytes occupied by objects of a specific type owned by a specific
  /// [ProgramInfoNode].
  objectType
}

const kindSymbol = 's';
const kindPath = 'p';
const symbolTypeGlobalText = 'T';
const symbolTypeGlobalInitializedData = 'D';

/// Convert the given AOT snapshot information file into a treemap object,
/// represented as a Map. Each node of the tree has one of the two schemas.
///
/// Leaf symbol nodes:
/// ```
/// {
///   'k': kindSymbol,
///   'n': /* name */,
///   'lastPathElement': true,
///   't': symbolTypeGlobalText | symbolTypeGlobalInitializedData,
///   'value': /* symbol size */
/// }
/// ```
///
/// Path nodes:
/// ```
/// {
///   'k': kindPath,
///   'n': /* name */,
///   'children': /* array of treemap nodes */
/// }
/// ```
///
/// If [inputJson] represents a V8 snapshot profile then [format] allows to
/// controls how individual [v8_profile.Snapshot] nodes are collapsed into
/// leaf treemap nodes (see [TreemapFormat] for more details).
///
/// By default chains of single child path nodes are collapsed into a single
/// path node, e.g.
/// `{k: 'p', n: 'a', children: [{k: 'p', n: 'b', children: [...]}]}`
/// becomes `{k: 'p', n: 'a/b', children: [...]}`. This behavior is controlled
/// by [collapseSingleChildPathNodes] parameter and can be switched off by
/// setting it to [false].
Map<String, dynamic> treemapFromJson(Object inputJson,
    {TreemapFormat format = TreemapFormat.objectType,
    bool collapseSingleChildPathNodes = true}) {
  final root = {'n': '', 'children': {}, 'k': kindPath, 'maxDepth': 0};

  if (v8_profile.Snapshot.isV8HeapSnapshot(inputJson)) {
    _treemapFromSnapshot(
        root, v8_profile.Snapshot.fromJson(inputJson as Map<String, dynamic>),
        format: format);
  } else {
    final symbols = instruction_sizes.fromJson(inputJson as List<dynamic>);
    for (var symbol in symbols) {
      _addSymbol(root, _treePath(symbol), symbol.name.scrubbed, symbol.size);
    }
  }
  return _flatten(root,
      collapseSingleChildPathNodes: collapseSingleChildPathNodes);
}

/// Convert the given [ProgramInfo] object into a treemap in either
/// [TreemapFormat.collapsed] or [TreemapFormat.simplified] format.
///
/// See [treemapFromJson] for the schema of the returned map object.
Map<String, dynamic> treemapFromInfo(ProgramInfo info,
    {TreemapFormat format = TreemapFormat.collapsed,
    bool collapseSingleChildPathNodes = true}) {
  final root = {'n': '', 'children': {}, 'k': kindPath, 'maxDepth': 0};
  _treemapFromInfo(root, info, format: format);
  return _flatten(root,
      collapseSingleChildPathNodes: collapseSingleChildPathNodes);
}

void _treemapFromInfo(Map<String, dynamic> root, ProgramInfo info,
    {TreemapFormat format = TreemapFormat.simplified}) {
  if (format != TreemapFormat.collapsed && format != TreemapFormat.simplified) {
    throw ArgumentError(
      'can only build simplified or collapsed formats from the program info',
    );
  }

  int cumulativeSize(ProgramInfoNode node) {
    return (node.size ?? 0) +
        node.children.values
            .fold<int>(0, (sum, child) => sum + cumulativeSize(child));
  }

  void recurse(ProgramInfoNode node, String path, Map<String, dynamic> root,
      TreemapFormat format) {
    if (node.children.isEmpty ||
        (node.type == NodeType.functionNode &&
            format == TreemapFormat.simplified)) {
      // For simple format we remove information about nested functions from
      // the output.
      _addSymbol(root, path, node.name, cumulativeSize(node));
      return;
    }

    // Don't add package node names to the path because nested library nodes
    // already contain package name.
    if (node.type == NodeType.packageNode) {
      _addSymbol(root, node.name, '<self>', node.size);
    } else {
      path = path != '' ? '$path/${node.name}' : node.name;
      _addSymbol(root, path, '<self>', node.size);
    }

    for (var child in node.children.values) {
      recurse(child, path, root, format);
    }
  }

  _addSymbol(root, '', info.root.name, info.root.size);
  for (var child in info.root.children.values) {
    recurse(child, '', root, format);
  }
}

void _treemapFromSnapshot(Map<String, dynamic> root, v8_profile.Snapshot snap,
    {TreemapFormat format = TreemapFormat.objectType}) {
  final info = v8_profile.toProgramInfo(snap);

  // For collapsed and simple formats there is no need to traverse snapshot
  // nodes. Just recurse into [ProgramInfo] structure instead.
  if (format == TreemapFormat.collapsed || format == TreemapFormat.simplified) {
    _treemapFromInfo(root, info, format: format);
    return;
  }

  final snapshotInfo = info.snapshotInfo!;

  final ownerPathCache =
      List<String?>.filled(snapshotInfo.infoNodes.length, null);
  ownerPathCache[info.root.id] = info.root.name;

  String ownerPath(ProgramInfoNode n) {
    return ownerPathCache[n.id] ??= ((n.parent != info.root)
        ? '${ownerPath(n.parent!)}/${n.name}'
        : n.name);
  }

  final nameFormatter = _nameFormatters[format]!;
  for (var node in snap.nodes) {
    if (node.selfSize > 0) {
      final owner = snapshotInfo.ownerOf(node);

      final name = nameFormatter(node);
      final path = ownerPath(owner);
      final type = _isExecutableCode(node)
          ? symbolTypeGlobalText
          : symbolTypeGlobalInitializedData;

      _addSymbol(root, path, name, node.selfSize, symbolType: type);
    }
  }
}

/// Returns [true] if the given [node] represents executable machine code.
bool _isExecutableCode(v8_profile.Node node) =>
    node.type == '(RO) Instructions';

/// A map of formatters which produce treemap node name to be used for the
/// given [v8_profile.Node].
final Map<TreemapFormat, String Function(v8_profile.Node)> _nameFormatters = {
  TreemapFormat.dataAndCode: (n) => _isExecutableCode(n) ? '<code>' : '<data>',
  TreemapFormat.objectType: (n) => '<${n.type}>',
};

/// Returns a /-separated path to the given symbol within the treemap.
String _treePath(instruction_sizes.SymbolInfo symbol) {
  if (symbol.name.isStub) {
    if (symbol.name.isAllocationStub) {
      return '@stubs/allocation-stubs/${symbol.libraryUri}/${symbol.className}';
    } else {
      return '@stubs';
    }
  } else {
    return '${symbol.libraryUri}/${symbol.className}';
  }
}

/// Create a child with the given name within the given node or return
/// an existing child.
Map<String, dynamic> _addChild(
    Map<String, dynamic> node, String kind, String name) {
  return node['children'].putIfAbsent(name, () {
    final n = <String, dynamic>{'n': name, 'k': kind};
    if (kind != kindSymbol) {
      n['children'] = {};
    }
    return n;
  });
}

/// Add the given symbol to the tree.
void _addSymbol(Map<String, dynamic> root, String path, String name, int? size,
    {String symbolType = symbolTypeGlobalText}) {
  if (size == null || size == 0) {
    return;
  }

  var node = root;
  var depth = 0;
  if (path != '') {
    final parts = partsForPath(path);
    for (var part in parts) {
      node = _addChild(node, kindPath, part);
      depth++;
    }
  }
  node['lastPathElement'] = true;
  node = _addChild(node, kindSymbol, name);
  node['t'] = symbolType;
  node['value'] = (node['value'] ?? 0) + size;
  depth += 1;
  root['maxDepth'] = max<int>(root['maxDepth'], depth);
}

/// Convert all children entries from maps to lists.
Map<String, dynamic> _flatten(Map<String, dynamic> node,
    {bool collapseSingleChildPathNodes = true}) {
  dynamic children = node['children'];
  if (children != null) {
    children = children.values.map((dynamic v) => _flatten(v)).toList();
    node['children'] = children;
    if (collapseSingleChildPathNodes &&
        children.length == 1 &&
        children.first['k'] == kindPath) {
      final singleChild = children.first;
      singleChild['n'] = '${node['n']}/${singleChild['n']}';
      return singleChild;
    }
  }
  return node;
}
