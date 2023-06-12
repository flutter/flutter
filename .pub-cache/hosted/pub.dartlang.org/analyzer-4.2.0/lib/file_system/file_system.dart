// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

export 'package:analyzer/src/file_system/file_system.dart';

/// [File]s are leaf [Resource]s which contain data.
abstract class File implements Resource {
  /// Watch for changes to this file.
  ///
  /// File watchers are initialized asynchronously so modifications made for a
  /// short period after calling this getter may be lost. Use [watch()] and
  /// await the `ready` [Future] that completes once initialization is
  /// complete.
  @Deprecated('Use watch() instead')
  Stream<WatchEvent> get changes;

  /// Synchronously get the length of the file.
  /// Throws a [FileSystemException] if the operation fails.
  int get lengthSync;

  /// Return the last-modified stamp of the file.
  /// Throws a [FileSystemException] if the file does not exist.
  int get modificationStamp;

  @override
  File copyTo(Folder parentFolder);

  /// Create a new [Source] instance that serves this file.
  Source createSource([Uri? uri]);

  /// Synchronously read the entire file contents as a list of bytes.
  /// Throws a [FileSystemException] if the operation fails.
  Uint8List readAsBytesSync();

  /// Synchronously read the entire file contents as a [String].
  /// Throws [FileSystemException] if the file does not exist.
  String readAsStringSync();

  /// Synchronously rename this file.
  /// Return a [File] instance for the renamed file.
  ///
  /// The [newPath] must be absolute and normalized.
  ///
  /// If [newPath] identifies an existing file, that file is replaced.
  /// If [newPath] identifies an existing resource the operation might fail and
  /// an exception is thrown.
  File renameSync(String newPath);

  /// Watch for changes to this file.
  ///
  /// Watchers are initialized asynchronously. Until [ResourceWatcher.ready]
  /// completes, events are not guaranteed.
  @override
  ResourceWatcher watch();

  /// Synchronously write the given [bytes] to the file. The new content will
  /// replace any existing content.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeAsBytesSync(List<int> bytes);

  /// Synchronously write the given [content] to the file. The new content will
  /// replace any existing content.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeAsStringSync(String content);
}

/// Base class for all file system exceptions.
class FileSystemException implements Exception {
  final String path;
  final String message;

  FileSystemException(this.path, this.message);

  @override
  String toString() => 'FileSystemException(path=$path; message=$message)';
}

/// [Folder]s are [Resource]s which may contain files and/or other folders.
abstract class Folder implements Resource {
  /// Watch for changes to the files inside this folder (and in any nested
  /// folders, including folders reachable via links).
  ///
  /// Folder watchers are initialized asynchronously so modifications made for a
  /// short period after calling this getter may be lost. Use [watch()] and
  /// await the `ready` [Future] that completes once initialization is
  /// complete.
  @Deprecated('Use watch() instead')
  Stream<WatchEvent> get changes;

  /// Return `true` if this folder is a file system root.
  bool get isRoot;

  /// If the path [path] is a relative path, convert it to an absolute path
  /// by interpreting it relative to this folder.  If it is already an absolute
  /// path, then don't change it.
  ///
  /// However, regardless of whether [path] is relative or absolute, normalize
  /// it by removing path components of the form '.' or '..'.
  String canonicalizePath(String path);

  /// Return `true` if the [path] references a resource in this folder.
  ///
  /// The [path] must be absolute and normalized.
  bool contains(String path);

  @override
  Folder copyTo(Folder parentFolder);

  /// If this folder does not already exist, create it.
  void create();

  /// Return an existing child [Resource] with the given [relPath].
  /// Return a not existing [File] if no such child exist.
  Resource getChild(String relPath);

  /// Return a [File] representing a child [Resource] with the given
  /// [relPath].  This call does not check whether a file with the given name
  /// exists on the filesystem - client must call the [File]'s `exists` getter
  /// to determine whether the folder actually exists.
  File getChildAssumingFile(String relPath);

  /// Return a [Folder] representing a child [Resource] with the given
  /// [relPath].  This call does not check whether a folder with the given name
  /// exists on the filesystem--client must call the [Folder]'s `exists` getter
  /// to determine whether the folder actually exists.
  Folder getChildAssumingFolder(String relPath);

  /// Return a list of existing direct children [Resource]s (folders and files)
  /// in this folder, in no particular order.
  ///
  /// On I/O errors, this will throw [FileSystemException].
  List<Resource> getChildren();

  /// Watch for changes to the files inside this folder (and in any nested
  /// folders, including folders reachable via links).
  ///
  /// Watchers are initialized asynchronously. Until [ResourceWatcher.ready]
  /// completes, events are not guaranteed.
  @override
  ResourceWatcher watch();
}

/// The abstract class [Resource] is an abstraction of file or folder.
abstract class Resource {
  /// Return `true` if this resource exists.
  bool get exists;

  /// Return the [Folder] that contains this resource, possibly itself if this
  /// resource is a root folder.
  Folder get parent;

  /// Return the [Folder] that contains this resource, possibly itself if this
  /// resource is a root folder.
  @Deprecated('Use parent instead')
  Folder get parent2;

  /// Return the full path to this resource.
  String get path;

  /// Return the [ResourceProvider] that owns this resource.
  ResourceProvider get provider;

  /// Return a short version of the name that can be displayed to the user to
  /// denote this resource.
  String get shortName;

  /// Copy this resource to a child of the [parentFolder] with the same kind and
  /// [shortName] as this resource. If this resource is a folder, then all of
  /// the contents of the folder will be recursively copied.
  ///
  /// The parent folder is created if it does not already exist.
  ///
  /// Existing files and folders will be overwritten.
  ///
  /// Return the resource corresponding to this resource in the parent folder.
  Resource copyTo(Folder parentFolder);

  /// Synchronously deletes this resource and its children.
  ///
  /// Throws an exception if the resource cannot be deleted.
  void delete();

  /// Return `true` if absolute [path] references this resource or a resource in
  /// this folder.
  ///
  /// The [path] must be absolute and normalized.
  bool isOrContains(String path);

  /// Return a resource that refers to the same resource as this resource, but
  /// whose path does not contain any symbolic links.
  Resource resolveSymbolicLinksSync();

  /// Return a Uri representing this resource.
  Uri toUri();

  /// Watch for changes to this resource.
  ResourceWatcher watch();
}

/// Instances of the class [ResourceProvider] convert [String] paths into
/// [Resource]s.
abstract class ResourceProvider {
  /// Get the path context used by this resource provider.
  Context get pathContext;

  /// Return a [File] that corresponds to the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// A file may or may not exist at this location.
  File getFile(String path);

  /// Return a [Folder] that corresponds to the given [path].
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// A folder may or may not exist at this location.
  Folder getFolder(String path);

  /// Return the [Resource] that corresponds to the given [path].
  ///
  /// The [path] must be absolute and normalized.
  Resource getResource(String path);

  /// Return the folder in which the plugin with the given [pluginId] can store
  /// state that will persist across sessions. The folder returned for a given
  /// id will not be returned for a different id, ensuring that plugins do not
  /// need to be concerned with file name collisions with other plugins,
  /// assuming that the plugin ids are unique. The plugin ids must be valid
  /// folder names.
  Folder? getStateLocation(String pluginId);
}

/// Abstraction over a [Watcher] that has a [Future] to indicate when the
/// watcher is ready.
///
/// The [ready] event will not fire until a listener has been set up on
/// [changes] and the watcher initialization is complete.
class ResourceWatcher {
  final Stream<WatchEvent> changes;

  /// An event that fires when the watcher is fully initialized and ready to
  /// produce events.
  ///
  /// This event will not fire until a listener has been set up on [changes] and
  /// the watcher initialization is complete.
  final Future<void> ready;

  ResourceWatcher(this.changes, this.ready);
}

extension FolderExtension on Folder {
  /// Return this folder and all its ancestors.
  Iterable<Folder> get withAncestors sync* {
    var current = this;
    while (true) {
      yield current;
      if (current.isRoot) {
        break;
      }
      current = current.parent;
    }
  }
}
