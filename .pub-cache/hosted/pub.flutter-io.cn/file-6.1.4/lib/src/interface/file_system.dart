// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../io.dart' as io;

import 'directory.dart';
import 'file.dart';
import 'file_system_entity.dart';
import 'link.dart';

/// A generic representation of a file system.
///
/// Note that this class uses `dart:io` only inasmuch as it deals in the types
/// exposed by the `dart:io` library. Subclasses should document their level of
/// dependence on the library (and the associated implications of using that
/// implementation in the browser).
abstract class FileSystem {
  /// Creates a new `FileSystem`.
  const FileSystem();

  /// Returns a reference to a [Directory] at [path].
  ///
  /// [path] can be either a [`String`], a [`Uri`], or a [`FileSystemEntity`].
  Directory directory(dynamic path);

  /// Returns a reference to a [File] at [path].
  ///
  /// [path] can be either a [`String`], a [`Uri`], or a [`FileSystemEntity`].
  File file(dynamic path);

  /// Returns a reference to a [Link] at [path].
  ///
  /// [path] can be either a [`String`], a [`Uri`], or a [`FileSystemEntity`].
  Link link(dynamic path);

  /// An object for manipulating paths in this file system.
  p.Context get path;

  /// Gets the system temp directory.
  ///
  /// It is left to file system implementations to decide how to define the
  /// "system temp directory".
  Directory get systemTempDirectory;

  /// Creates a directory object pointing to the current working directory.
  Directory get currentDirectory;

  /// Sets the current working directory to the specified [path].
  ///
  /// The new value set can be either a [Directory] or a [String].
  ///
  /// Relative paths will be resolved by the underlying file system
  /// implementation (meaning it is up to the underlying implementation to
  /// decide whether to support relative paths).
  set currentDirectory(dynamic path);

  /// Asynchronously calls the operating system's stat() function on [path].
  /// Returns a Future which completes with a [io.FileStat] object containing
  /// the data returned by stat().
  /// If the call fails, completes the future with a [io.FileStat] object with
  /// .type set to FileSystemEntityType.NOT_FOUND and the other fields invalid.
  Future<io.FileStat> stat(String path);

  /// Calls the operating system's stat() function on [path].
  /// Returns a [io.FileStat] object containing the data returned by stat().
  /// If the call fails, returns a [io.FileStat] object with .type set to
  /// FileSystemEntityType.NOT_FOUND and the other fields invalid.
  io.FileStat statSync(String path);

  /// Checks whether two paths refer to the same object in the
  /// file system. Returns a [Future<bool>] that completes with the result.
  ///
  /// Comparing a link to its target returns false, as does comparing two links
  /// that point to the same target.  To check the target of a link, use
  /// Link.target explicitly to fetch it.  Directory links appearing
  /// inside a path are followed, though, to find the file system object.
  ///
  /// Completes the returned Future with an error if one of the paths points
  /// to an object that does not exist.
  Future<bool> identical(String path1, String path2);

  /// Synchronously checks whether two paths refer to the same object in the
  /// file system.
  ///
  /// Comparing a link to its target returns false, as does comparing two links
  /// that point to the same target.  To check the target of a link, use
  /// Link.target explicitly to fetch it.  Directory links appearing
  /// inside a path are followed, though, to find the file system object.
  ///
  /// Throws an error if one of the paths points to an object that does not
  /// exist.
  bool identicalSync(String path1, String path2);

  /// Tests if [FileSystemEntity.watch] is supported on the current system.
  bool get isWatchSupported;

  /// Finds the type of file system object that a [path] points to. Returns
  /// a Future<FileSystemEntityType> that completes with the result.
  ///
  /// [io.FileSystemEntityType.LINK] will only be returned if [followLinks] is
  /// `false`, and [path] points to a link
  ///
  /// If the [path] does not point to a file system object or an error occurs
  /// then [io.FileSystemEntityType.notFound] is returned.
  Future<io.FileSystemEntityType> type(String path, {bool followLinks = true});

  /// Syncronously finds the type of file system object that a [path] points
  /// to. Returns a [io.FileSystemEntityType].
  ///
  /// [io.FileSystemEntityType.LINK] will only be returned if [followLinks] is
  /// `false`, and [path] points to a link
  ///
  /// If the [path] does not point to a file system object or an error occurs
  /// then [io.FileSystemEntityType.notFound] is returned.
  io.FileSystemEntityType typeSync(String path, {bool followLinks = true});

  /// Checks if [`type(path)`](type) returns [io.FileSystemEntityType.FILE].
  Future<bool> isFile(String path) async =>
      await type(path) == io.FileSystemEntityType.file;

  /// Synchronously checks if [`type(path)`](type) returns
  /// [io.FileSystemEntityType.FILE].
  bool isFileSync(String path) =>
      typeSync(path) == io.FileSystemEntityType.file;

  /// Checks if [`type(path)`](type) returns [io.FileSystemEntityType.DIRECTORY].
  Future<bool> isDirectory(String path) async =>
      await type(path) == io.FileSystemEntityType.directory;

  /// Synchronously checks if [`type(path)`](type) returns
  /// [io.FileSystemEntityType.DIRECTORY].
  bool isDirectorySync(String path) =>
      typeSync(path) == io.FileSystemEntityType.directory;

  /// Checks if [`type(path)`](type) returns [io.FileSystemEntityType.LINK].
  Future<bool> isLink(String path) async =>
      await type(path) == io.FileSystemEntityType.link;

  /// Synchronously checks if [`type(path)`](type) returns
  /// [io.FileSystemEntityType.LINK].
  bool isLinkSync(String path) =>
      typeSync(path) == io.FileSystemEntityType.link;

  /// Gets the string path represented by the specified generic [path].
  ///
  /// [path] may be a [io.FileSystemEntity], a [String], or a [Uri].
  @protected
  String getPath(dynamic path) {
    if (path is io.FileSystemEntity) {
      return path.path;
    } else if (path is String) {
      return path;
    } else if (path is Uri) {
      return this.path.fromUri(path);
    } else {
      throw ArgumentError('Invalid type for "path": ${path?.runtimeType}');
    }
  }
}
