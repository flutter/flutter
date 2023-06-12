// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/src/common.dart' as common;
import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';

import 'common.dart';
import 'memory_directory.dart';
import 'node.dart';
import 'operations.dart';
import 'style.dart';
import 'utils.dart' as utils;

/// Validator function for use with `_renameSync`. This will be invoked if the
/// rename would overwrite an existing entity at the new path. If this operation
/// should not be allowed, this function is expected to throw a
/// [io.FileSystemException]. The lack of such an exception will be interpreted
/// as the overwrite being permissible.
typedef RenameOverwriteValidator<T extends Node> = void Function(
    T existingNode);

/// Base class for all in-memory file system entity types.
abstract class MemoryFileSystemEntity implements FileSystemEntity {
  /// Constructor for subclasses.
  const MemoryFileSystemEntity(this.fileSystem, this.path);

  @override
  final NodeBasedFileSystem fileSystem;

  @override
  final String path;

  @override
  String get dirname => fileSystem.path.dirname(path);

  @override
  String get basename => fileSystem.path.basename(path);

  /// Returns the expected type of this entity, which may differ from the type
  /// of the node that's found at the path specified by this entity.
  io.FileSystemEntityType get expectedType;

  /// Gets the node that backs this file system entity, or null if this
  /// entity does not exist.
  @protected
  Node? get backingOrNull {
    try {
      return fileSystem.findNode(path);
    } on io.FileSystemException {
      return null;
    }
  }

  /// Gets the node that backs this file system entity. Throws a
  /// [io.FileSystemException] if this entity doesn't exist.
  ///
  /// The type of the node is not guaranteed to match [expectedType].
  @protected
  Node get backing {
    Node? node = fileSystem.findNode(path);
    checkExists(node, () => path);
    return node!;
  }

  /// Gets the node that backs this file system entity, or if that node is
  /// a symbolic link, the target node. This also will check that the type of
  /// the node (after symlink resolution) matches [expectedType]. If the type
  /// doesn't match, this will throw a [io.FileSystemException].
  @protected
  Node get resolvedBacking {
    Node node = backing;
    node = utils.isLink(node)
        ? utils.resolveLinks(node as LinkNode, () => path)
        : node;
    utils.checkType(expectedType, node.type, () => path);
    return node;
  }

  /// Checks the expected type of this file system entity against the specified
  /// node's `stat` type, throwing a [FileSystemException] if the types don't
  /// match. Note that since this checks the node's `stat` type, symbolic links
  /// will be resolved to their target type for the purpose of this validation.
  ///
  /// Protected methods that accept a `checkType` argument will default to this
  /// method if the `checkType` argument is unspecified.
  @protected
  void defaultCheckType(Node node) {
    utils.checkType(expectedType, node.stat.type, () => path);
  }

  @override
  Uri get uri {
    return Uri.file(path, windows: fileSystem.style == FileSystemStyle.windows);
  }

  @override
  Future<bool> exists() async => existsSync();

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();

  @override
  String resolveSymbolicLinksSync() {
    if (path.isEmpty) {
      throw common.noSuchFileOrDirectory(path);
    }
    List<String> ledger = <String>[];
    if (isAbsolute) {
      ledger.add(fileSystem.style.drive);
    }
    Node? node = fileSystem.findNode(path,
        pathWithSymlinks: ledger, followTailLink: true);
    checkExists(node, () => path);
    String resolved = ledger.join(fileSystem.path.separator);
    if (resolved == fileSystem.style.drive) {
      resolved = fileSystem.style.root;
    } else if (!fileSystem.path.isAbsolute(resolved)) {
      resolved = fileSystem.cwd + fileSystem.path.separator + resolved;
    }
    return fileSystem.path.normalize(resolved);
  }

  @override
  Future<io.FileStat> stat() => fileSystem.stat(path);

  @override
  io.FileStat statSync() => fileSystem.statSync(path);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    deleteSync(recursive: recursive);
    return this;
  }

  @override
  void deleteSync({bool recursive = false}) =>
      internalDeleteSync(recursive: recursive);

  @override
  Stream<io.FileSystemEvent> watch({
    int events = io.FileSystemEvent.all,
    bool recursive = false,
  }) =>
      throw UnsupportedError('Watching not supported in MemoryFileSystem');

  @override
  bool get isAbsolute => fileSystem.path.isAbsolute(path);

  @override
  FileSystemEntity get absolute {
    String absolutePath = path;
    if (!fileSystem.path.isAbsolute(absolutePath)) {
      absolutePath = fileSystem.path.join(fileSystem.cwd, absolutePath);
    }
    return clone(absolutePath);
  }

  @override
  Directory get parent => MemoryDirectory(fileSystem, dirname);

  /// Helper method for subclasses wishing to synchronously create this entity.
  /// This method will traverse the path to this entity one segment at a time,
  /// calling [createChild] for each segment whose child does not already exist.
  ///
  /// When [createChild] is invoked:
  /// - `parent` will be the parent node for the current segment and is
  ///   guaranteed to be non-null.
  /// - `isFinalSegment` will indicate whether the current segment is the tail
  ///   segment, which in turn indicates that this is the segment into which to
  ///   create the node for this entity.
  ///
  /// This method returns with the backing node for the entity at this [path].
  /// If an entity already existed at this path, [createChild] will not be
  /// invoked at all, and this method will return with the backing node for the
  /// existing entity (whose type may differ from this entity's type).
  ///
  /// If [followTailLink] is true and the result node is a link, this will
  /// resolve it to its target prior to returning it.
  @protected
  Node? internalCreateSync({
    required Node? Function(DirectoryNode parent, bool isFinalSegment)
        createChild,
    bool followTailLink = false,
    bool visitLinks = false,
  }) {
    return fileSystem.findNode(
      path,
      followTailLink: followTailLink,
      visitLinks: visitLinks,
      segmentVisitor: (
        DirectoryNode parent,
        String childName,
        Node? child,
        int currentSegment,
        int finalSegment,
      ) {
        if (child == null) {
          assert(!parent.children.containsKey(childName));
          child = createChild(parent, currentSegment == finalSegment);
          if (child != null) {
            parent.children[childName] = child;
          }
        }
        return child;
      },
    );
  }

  /// Helper method for subclasses wishing to synchronously rename this entity.
  /// This method will look for an existing file system entity at the location
  /// identified by [newPath], and if it finds an existing entity, it will check
  /// the following:
  ///
  /// - If the entity is of a different type than this entity, the operation
  ///   will fail, and a [io.FileSystemException] will be thrown.
  /// - If the caller has specified [validateOverwriteExistingEntity], then that
  ///   method will be invoked and passed the node backing of the existing
  ///   entity that would overwritten by the rename action. That callback is
  ///   expected to throw a [io.FileSystemException] if overwriting the existing
  ///   entity is not allowed.
  ///
  /// If the previous two checks pass, or if there was no existing entity at
  /// the specified location, this will perform the rename.
  ///
  /// If [newPath] cannot be traversed to because its directory does not exist,
  /// a [io.FileSystemException] will be thrown.
  ///
  /// If [followTailLink] is true and there is an existing link at the location
  /// identified by [newPath], this will resolve the link to its target prior
  /// to running the validation checks above.
  ///
  /// If [checkType] is specified, it will be used to validate that the file
  /// system entity that exists at [path] is of the expected type. By default,
  /// [defaultCheckType] is used to perform this validation.
  @protected
  FileSystemEntity internalRenameSync<T extends Node>(
    String newPath, {
    RenameOverwriteValidator<T>? validateOverwriteExistingEntity,
    bool followTailLink = false,
    utils.TypeChecker? checkType,
  }) {
    Node node = backing;
    (checkType ?? defaultCheckType)(node);
    fileSystem.findNode(
      newPath,
      segmentVisitor: (
        DirectoryNode parent,
        String childName,
        Node? child,
        int currentSegment,
        int finalSegment,
      ) {
        if (currentSegment == finalSegment) {
          if (child != null) {
            if (followTailLink) {
              FileSystemEntityType childType = child.stat.type;
              if (childType != FileSystemEntityType.notFound) {
                utils.checkType(expectedType, child.stat.type, () => newPath);
              }
            } else {
              utils.checkType(expectedType, child.type, () => newPath);
            }
            if (validateOverwriteExistingEntity != null) {
              validateOverwriteExistingEntity(child as T);
            }
            parent.children.remove(childName);
          }
          node.parent.children.remove(basename);
          parent.children[childName] = node;
          node.parent = parent;
        }
        return child;
      },
    );
    return clone(newPath);
  }

  /// Deletes this entity from the node tree.
  ///
  /// If [checkType] is specified, it will be used to validate that the file
  /// system entity that exists at [path] is of the expected type. By default,
  /// [defaultCheckType] is used to perform this validation.
  @protected
  void internalDeleteSync({
    bool recursive = false,
    utils.TypeChecker? checkType,
  }) {
    fileSystem.opHandle(path, FileSystemOp.delete);
    Node node = backing;
    if (!recursive) {
      if (node is DirectoryNode && node.children.isNotEmpty) {
        throw common.directoryNotEmpty(path);
      }
      (checkType ?? defaultCheckType)(node);
    }
    // Once we remove this reference, the node and all its children will be
    // garbage collected; we don't need to explicitly delete all children in
    // the recursive:true case.
    node.parent.children.remove(basename);
  }

  /// Creates a new entity with the same type as this entity but with the
  /// specified path.
  @protected
  FileSystemEntity clone(String path);
}
