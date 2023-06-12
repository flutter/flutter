// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/src/common.dart' as common;
import 'package:file/src/io.dart' as io;

import 'common.dart';
import 'node.dart';

/// Checks if `node.type` returns [io.FileSystemEntityType.FILE].
bool isFile(Node? node) => node?.type == io.FileSystemEntityType.file;

/// Checks if `node.type` returns [io.FileSystemEntityType.DIRECTORY].
bool isDirectory(Node? node) => node?.type == io.FileSystemEntityType.directory;

/// Checks if `node.type` returns [io.FileSystemEntityType.LINK].
bool isLink(Node? node) => node?.type == io.FileSystemEntityType.link;

/// Validator function that is expected to throw a [FileSystemException] if
/// the node does not represent the type that is expected in any given context.
typedef TypeChecker = void Function(Node node);

/// Throws a [io.FileSystemException] if [node] is not a directory.
void checkIsDir(Node node, PathGenerator path) {
  if (!isDirectory(node)) {
    throw common.notADirectory(path() as String);
  }
}

/// Throws a [io.FileSystemException] if [expectedType] doesn't match
/// [actualType].
void checkType(
  FileSystemEntityType expectedType,
  FileSystemEntityType actualType,
  PathGenerator path,
) {
  if (expectedType != actualType) {
    switch (expectedType) {
      case FileSystemEntityType.directory:
        throw common.notADirectory(path() as String);
      case FileSystemEntityType.file:
        assert(actualType == FileSystemEntityType.directory);
        throw common.isADirectory(path() as String);
      case FileSystemEntityType.link:
        throw common.invalidArgument(path() as String);
      default:
        // Should not happen
        throw AssertionError();
    }
  }
}

/// Tells if the specified file mode represents a write mode.
bool isWriteMode(io.FileMode mode) =>
    mode == io.FileMode.write ||
    mode == io.FileMode.append ||
    mode == io.FileMode.writeOnly ||
    mode == io.FileMode.writeOnlyAppend;

/// Tells whether the given string is empty.
bool isEmpty(String str) => str.isEmpty;

/// Returns the node ultimately referred to by [link]. This will resolve
/// the link references (following chains of links as necessary) and return
/// the node at the end of the link chain.
///
/// If a loop in the link chain is found, this will throw a
/// [FileSystemException], calling [path] to generate the path.
///
/// If [ledger] is specified, the resolved path to the terminal node will be
/// appended to the ledger (or overwritten in the ledger if a link target
/// specified an absolute path). The path will not be normalized, meaning
/// `..` and `.` path segments may be present.
///
/// If [tailVisitor] is specified, it will be invoked for the tail element of
/// the last link in the symbolic link chain, and its return value will be the
/// return value of this method (thus allowing callers to create the entity
/// at the end of the chain on demand).
Node resolveLinks(
  LinkNode link,
  PathGenerator path, {
  List<String>? ledger,
  Node? Function(DirectoryNode parent, String childName, Node? child)?
      tailVisitor,
}) {
  // Record a breadcrumb trail to guard against symlink loops.
  Set<LinkNode> breadcrumbs = <LinkNode>{};

  Node node = link;
  while (isLink(node)) {
    link = node as LinkNode;
    if (!breadcrumbs.add(link)) {
      throw common.tooManyLevelsOfSymbolicLinks(path() as String);
    }
    if (ledger != null) {
      if (link.fs.path.isAbsolute(link.target)) {
        ledger.clear();
      } else if (ledger.isNotEmpty) {
        ledger.removeLast();
      }
      ledger.addAll(link.target.split(link.fs.path.separator));
    }
    node = link.getReferent(
      tailVisitor: (DirectoryNode parent, String childName, Node? child) {
        if (tailVisitor != null && !isLink(child)) {
          // Only invoke [tailListener] on the final resolution pass.
          child = tailVisitor(parent, childName, child);
        }
        return child;
      },
    );
  }

  return node;
}
