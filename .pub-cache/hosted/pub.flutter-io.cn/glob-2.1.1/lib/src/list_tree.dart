// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import 'ast.dart';
import 'utils.dart';

/// The errno for a file or directory not existing on Mac and Linux.
const _enoent = 2;

/// Another errno we see on Windows when trying to list a non-existent
/// directory.
const _enoentWin = 3;

/// A structure built from a glob that efficiently lists filesystem entities
/// that match that glob.
///
/// This structure is designed to list the minimal number of physical
/// directories necessary to find everything that matches the glob. For example,
/// for the glob `foo/{bar,baz}/*`, there's no need to list the working
/// directory or even `foo/`; only `foo/bar` and `foo/baz` should be listed.
///
/// This works by creating a tree of [_ListTreeNode]s, each of which corresponds
/// to a single of directory nesting in the source glob. Each node has child
/// nodes associated with globs ([_ListTreeNode.children]), as well as its own
/// glob ([_ListTreeNode._validator]) that indicates which entities within that
/// node's directory should be returned.
///
/// For example, the glob `foo/{*.dart,b*/*.txt}` creates the following tree:
///
///     .
///     '-- "foo" (validator: "*.dart")
///         '-- "b*" (validator: "*.txt"
///
/// If a node doesn't have a validator, we know we don't have to list it
/// explicitly.
///
/// Nodes can also be marked as "recursive", which means they need to be listed
/// recursively (usually to support `**`). In this case, they will have no
/// children; instead, their validator will just encompass the globs that would
/// otherwise be in their children. For example, the glob
/// `foo/{**.dart,bar/*.txt}` creates a recursive node for `foo` with the
/// validator `**.dart,bar/*.txt`.
///
/// If the glob contains multiple filesystem roots (e.g. `{C:/,D:/}*.dart`),
/// each root will have its own tree of nodes. Relative globs use `.` as their
/// root instead.
class ListTree {
  /// A map from filesystem roots to the list tree for those roots.
  ///
  /// A relative glob will use `.` as its root.
  final Map<String, _ListTreeNode> _trees;

  /// Whether paths listed might overlap.
  ///
  /// If they do, we need to filter out overlapping paths.
  final bool _canOverlap;

  /// The file system to operate on.
  final FileSystem _fileSystem;

  ListTree._(this._trees, this._fileSystem)
      : _canOverlap = _computeCanOverlap(_trees);

  factory ListTree(AstNode glob, FileSystem fileSystem) {
    // The first step in constructing a tree from the glob is to simplify the
    // problem by eliminating options. [glob.flattenOptions] bubbles all options
    // (and certain ranges) up to the top level of the glob so we can deal with
    // them one at a time.
    var options = glob.flattenOptions();
    var trees = <String, _ListTreeNode>{};

    for (var option in options.options) {
      // Since each option doesn't include its own options, we can safely split
      // it into path components.
      var components = option.split(p.context);
      var firstNode = components.first.nodes.first;
      var root = '.';

      // Determine the root for this option, if it's absolute. If it's not, the
      // root's just ".".
      if (firstNode is LiteralNode) {
        var text = firstNode.text;
        // Platform agnostic way of checking for Windows without `dart:io`.
        if (p.context == p.windows) text.replaceAll('/', '\\');
        if (p.isAbsolute(text)) {
          // If the path is absolute, the root should be the only thing in the
          // first component.
          assert(components.first.nodes.length == 1);
          root = firstNode.text;
          components.removeAt(0);
        }
      }

      _addGlob(root, components, trees);
    }

    return ListTree._(trees, fileSystem);
  }

  /// Add the glob represented by [components] to the tree under [root].
  static void _addGlob(String root, List<SequenceNode> components,
      Map<String, _ListTreeNode> trees) {
    // The first [parent] represents the root directory itself. It may be null
    // here if this is the first option with this particular [root]. If so,
    // we'll create it below.
    //
    // As we iterate through [components], [parent] will be set to
    // progressively more nested nodes.
    var parent = trees[root];
    for (var i = 0; i < components.length; i++) {
      var component = components[i];
      var recursive = component.nodes.any((node) => node is DoubleStarNode);
      var complete = i == components.length - 1;

      // If the parent node for this level of nesting already exists, the new
      // option will be added to it as additional validator options and/or
      // additional children.
      //
      // If the parent doesn't exist, we'll create it in one of the else
      // clauses below.
      if (parent != null) {
        if (parent.isRecursive || recursive) {
          // If [component] is recursive, mark [parent] as recursive. This
          // will cause all of its children to be folded into its validator.
          // If [parent] was already recursive, this is a no-op.
          parent.makeRecursive();

          // Add [component] and everything nested beneath it as an option to
          // [parent]. Since [parent] is recursive, it will recursively list
          // everything beneath it and filter them with one big glob.
          parent.addOption(_join(components.sublist(i)));
          return;
        } else if (complete) {
          // If [component] is the last component, add it to [parent]'s
          // validator but not to its children.
          parent.addOption(component);
        } else {
          // On the other hand if there are more components, add [component]
          // to [parent]'s children and not its validator. Since we process
          // each option's components separately, the same component is never
          // both a validator and a child.
          var children = parent.children!;
          if (!children.containsKey(component)) {
            children[component] = _ListTreeNode();
          }
          parent = children[component];
        }
      } else if (recursive) {
        trees[root] = _ListTreeNode.recursive(_join(components.sublist(i)));
        return;
      } else if (complete) {
        trees[root] = _ListTreeNode()..addOption(component);
      } else {
        var rootNode = _ListTreeNode();
        trees[root] = rootNode;
        var rootChildren = rootNode.children!;
        rootChildren[component] = _ListTreeNode();
        parent = rootChildren[component];
      }
    }
  }

  /// Computes the value for [_canOverlap].
  static bool _computeCanOverlap(Map<String, _ListTreeNode> trees) {
    // If this can list a relative path and an absolute path, the former may be
    // contained within the latter.
    if (trees.length > 1 && trees.containsKey('.')) return true;

    // Otherwise, this can only overlap if the tree beneath any given root could
    // overlap internally.
    return trees.values.any((node) => node.canOverlap);
  }

  /// List all entities that match this glob beneath [root].
  Stream<FileSystemEntity> list({String? root, bool followLinks = true}) {
    root ??= '.';
    var group = StreamGroup<FileSystemEntity>();
    for (var rootDir in _trees.keys) {
      var dir = rootDir == '.' ? root : rootDir;
      group.add(
          _trees[rootDir]!.list(dir, _fileSystem, followLinks: followLinks));
    }
    group.close();

    if (!_canOverlap) return group.stream;

    // TODO: Rather than filtering here, avoid double-listing directories
    // in the first place.
    var seen = <String>{};
    return group.stream.where((entity) => seen.add(entity.path));
  }

  /// Synchronosuly list all entities that match this glob beneath [root].
  List<FileSystemEntity> listSync({String? root, bool followLinks = true}) {
    root ??= '.';
    var result = _trees.keys.expand((rootDir) {
      var dir = rootDir == '.' ? root! : rootDir;
      return _trees[rootDir]!
          .listSync(dir, _fileSystem, followLinks: followLinks);
    });

    if (!_canOverlap) return result.toList();

    // TODO: Rather than filtering here, avoid double-listing directories
    // in the first place.
    var seen = <String>{};
    return result.where((entity) => seen.add(entity.path)).toList();
  }
}

/// A single node in a [ListTree].
class _ListTreeNode {
  /// This node's child nodes, by their corresponding globs.
  ///
  /// Each child node will only be listed on directories that match its glob.
  ///
  /// This may be `null`, indicating that this node should be listed
  /// recursively.
  Map<SequenceNode, _ListTreeNode>? children;

  /// This node's validator.
  ///
  /// This determines which entities will ultimately be emitted when [list] is
  /// called.
  OptionsNode? _validator;

  /// Whether this node is recursive.
  ///
  /// A recursive node has no children and is listed recursively.
  bool get isRecursive => children == null;

  bool get _caseSensitive {
    if (_validator != null) return _validator!.caseSensitive;
    if (children?.isEmpty != false) return true;
    return children!.keys.first.caseSensitive;
  }

  /// Whether this node doesn't itself need to be listed.
  ///
  /// If a node has no validator and all of its children are literal filenames,
  /// there's no need to list its contents. We can just directly traverse into
  /// its children.
  bool get _isIntermediate {
    if (_validator != null) return false;
    return children!.keys.every((sequence) =>
        sequence.nodes.length == 1 && sequence.nodes.first is LiteralNode);
  }

  /// Returns whether listing this node might return overlapping results.
  bool get canOverlap {
    // A recusive node can never overlap with itself, because it will only ever
    // involve a single call to [Directory.list] that's then filtered with
    // [_validator].
    if (isRecursive) return false;

    // If there's more than one child node and at least one of the children is
    // dynamic (that is, matches more than just a literal string), there may be
    // overlap.
    if (children!.length > 1) {
      // Case-insensitivity means that even literals may match multiple entries.
      if (!_caseSensitive) return true;

      if (children!.keys.any((sequence) =>
          sequence.nodes.length > 1 || sequence.nodes.single is! LiteralNode)) {
        return true;
      }
    }

    return children!.values.any((node) => node.canOverlap);
  }

  /// Creates a node with no children and no validator.
  _ListTreeNode()
      : children = <SequenceNode, _ListTreeNode>{},
        _validator = null;

  /// Creates a recursive node the given [validator].
  _ListTreeNode.recursive(SequenceNode validator)
      : children = null,
        _validator =
            OptionsNode([validator], caseSensitive: validator.caseSensitive);

  /// Transforms this into recursive node, folding all its children into its
  /// validator.
  void makeRecursive() {
    if (isRecursive) return;
    var children = this.children!;
    _validator = OptionsNode(children.entries.map((entry) {
      entry.value.makeRecursive();
      return _join([entry.key, entry.value._validator!]);
    }), caseSensitive: _caseSensitive);
    this.children = null;
  }

  /// Adds [validator] to this node's existing validator.
  void addOption(SequenceNode validator) {
    if (_validator == null) {
      _validator =
          OptionsNode([validator], caseSensitive: validator.caseSensitive);
    } else {
      _validator!.options.add(validator);
    }
  }

  /// Lists all entities within [dir] matching this node or its children.
  ///
  /// This may return duplicate entities. These will be filtered out in
  /// [ListTree.list].
  Stream<FileSystemEntity> list(String dir, FileSystem fileSystem,
      {bool followLinks = true}) {
    if (isRecursive) {
      return fileSystem
          .directory(dir)
          .list(recursive: true, followLinks: followLinks)
          .ignoreMissing()
          .where((entity) => _matches(p.relative(entity.path, from: dir)));
    }

    // Don't spawn extra [Directory.list] calls when we already know exactly
    // which subdirectories we're interested in.
    if (_isIntermediate && _caseSensitive) {
      var resultGroup = StreamGroup<FileSystemEntity>();
      children!.forEach((sequence, child) {
        resultGroup.add(child.list(
            p.join(dir, (sequence.nodes.single as LiteralNode).text),
            fileSystem,
            followLinks: followLinks));
      });
      resultGroup.close();
      return resultGroup.stream;
    }

    return StreamCompleter.fromFuture(() async {
      var entities = await fileSystem
          .directory(dir)
          .list(followLinks: followLinks)
          .ignoreMissing()
          .toList();
      await _validateIntermediateChildrenAsync(dir, entities, fileSystem);

      var resultGroup = StreamGroup<FileSystemEntity>();
      var resultController = StreamController<FileSystemEntity>(sync: true);
      unawaited(resultGroup.add(resultController.stream));
      for (var entity in entities) {
        var basename = p.relative(entity.path, from: dir);
        if (_matches(basename)) resultController.add(entity);

        children!.forEach((sequence, child) {
          if (entity is! Directory) return;
          if (!sequence.matches(basename)) return;
          var stream = child.list(p.join(dir, basename), fileSystem,
              followLinks: followLinks);
          resultGroup.add(stream);
        });
      }
      unawaited(resultController.close());
      unawaited(resultGroup.close());
      return resultGroup.stream;
    }());
  }

  /// If this is a case-insensitive list, validates that all intermediate
  /// children (according to [_isIntermediate]) match at least one entity in
  /// [entities].
  ///
  /// This ensures that listing "foo/bar/*" fails on case-sensitive systems if
  /// "foo/bar" doesn't exist.
  Future _validateIntermediateChildrenAsync(String dir,
      List<FileSystemEntity> entities, FileSystem fileSystem) async {
    if (_caseSensitive) return;

    for (var entry in children!.entries) {
      var child = entry.value;
      var sequence = entry.key;
      if (!child._isIntermediate) continue;
      if (entities.any(
          (entity) => sequence.matches(p.relative(entity.path, from: dir)))) {
        continue;
      }

      // We know this will fail, we're just doing it to force dart:io to emit
      // the exception it would if we were listing case-sensitively.
      await child
          .list(p.join(dir, (sequence.nodes.single as LiteralNode).text),
              fileSystem)
          .toList();
    }
  }

  /// Synchronously lists all entities within [dir] matching this node or its
  /// children.
  ///
  /// This may return duplicate entities. These will be filtered out in
  /// [ListTree.listSync].
  Iterable<FileSystemEntity> listSync(String dir, FileSystem fileSystem,
      {bool followLinks = true}) {
    if (isRecursive) {
      try {
        return fileSystem
            .directory(dir)
            .listSync(recursive: true, followLinks: followLinks)
            .where((entity) => _matches(p.relative(entity.path, from: dir)));
      } on FileSystemException catch (error) {
        if (error.isMissing) return const [];
        rethrow;
      }
    }

    // Don't spawn extra [Directory.listSync] calls when we already know exactly
    // which subdirectories we're interested in.
    if (_isIntermediate && _caseSensitive) {
      return children!.entries.expand((entry) {
        var sequence = entry.key;
        var child = entry.value;
        return child.listSync(
            p.join(dir, (sequence.nodes.single as LiteralNode).text),
            fileSystem,
            followLinks: followLinks);
      });
    }

    List<FileSystemEntity> entities;
    try {
      entities = fileSystem.directory(dir).listSync(followLinks: followLinks);
    } on FileSystemException catch (error) {
      if (error.isMissing) return const [];
      rethrow;
    }
    _validateIntermediateChildrenSync(dir, entities, fileSystem);

    return entities.expand((entity) {
      var entities = <FileSystemEntity>[];
      var basename = p.relative(entity.path, from: dir);
      if (_matches(basename)) entities.add(entity);
      if (entity is! Directory) return entities;

      entities.addAll(children!.keys
          .where((sequence) => sequence.matches(basename))
          .expand((sequence) {
        return children![sequence]!
            .listSync(p.join(dir, basename), fileSystem,
                followLinks: followLinks)
            .toList();
      }));

      return entities;
    });
  }

  /// If this is a case-insensitive list, validates that all intermediate
  /// children (according to [_isIntermediate]) match at least one entity in
  /// [entities].
  ///
  /// This ensures that listing "foo/bar/*" fails on case-sensitive systems if
  /// "foo/bar" doesn't exist.
  void _validateIntermediateChildrenSync(
      String dir, List<FileSystemEntity> entities, FileSystem fileSystem) {
    if (_caseSensitive) return;

    children!.forEach((sequence, child) {
      if (!child._isIntermediate) return;
      if (entities.any(
          (entity) => sequence.matches(p.relative(entity.path, from: dir)))) {
        return;
      }

      // If there are no [entities] that match [sequence], manually list the
      // directory to force `dart:io` to throw an error. This allows us to
      // ensure that listing "foo/bar/*" fails on case-sensitive systems if
      // "foo/bar" doesn't exist.
      child.listSync(
          p.join(dir, (sequence.nodes.single as LiteralNode).text), fileSystem);
    });
  }

  /// Returns whether the native [path] matches [_validator].
  bool _matches(String path) =>
      _validator?.matches(toPosixPath(p.context, path)) ?? false;

  @override
  String toString() => '($_validator) $children';
}

/// Joins each [components] into a new glob where each component is separated by
/// a path separator.
SequenceNode _join(Iterable<AstNode> components) {
  var componentsList = components.toList();
  var first = componentsList.removeAt(0);
  var nodes = [first];
  for (var component in componentsList) {
    nodes.add(LiteralNode('/', caseSensitive: first.caseSensitive));
    nodes.add(component);
  }
  return SequenceNode(nodes, caseSensitive: first.caseSensitive);
}

extension on Stream<FileSystemEntity> {
  Stream<FileSystemEntity> ignoreMissing() => handleError((_) {},
      test: (error) => error is FileSystemException && error.isMissing);
}

extension on FileSystemException {
  bool get isMissing {
    final errorCode = osError?.errorCode;
    return errorCode == _enoent || errorCode == _enoentWin;
  }
}
