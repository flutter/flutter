// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:path/path.dart' as p;

/// A set of paths, organized into a directory hierarchy.
///
/// When a path is [add]ed, it creates an implicit directory structure above
/// that path. Directories can be inspected using [containsDir] and removed
/// using [remove]. If they're removed, their contents are removed as well.
///
/// The paths in the set are normalized so that they all begin with [root].
class PathSet {
  /// The root path, which all paths in the set must be under.
  final String root;

  /// The path set's directory hierarchy.
  ///
  /// Each entry represents a directory or file. It may be a file or directory
  /// that was explicitly added, or a parent directory that was implicitly
  /// added in order to add a child.
  final _Entry _entries = _Entry();

  PathSet(this.root);

  /// Adds [path] to the set.
  void add(String path) {
    path = _normalize(path);

    var parts = p.split(path);
    var entry = _entries;
    for (var part in parts) {
      entry = entry.contents.putIfAbsent(part, () => _Entry());
    }

    entry.isExplicit = true;
  }

  /// Removes [path] and any paths beneath it from the set and returns the
  /// removed paths.
  ///
  /// Even if [path] itself isn't in the set, if it's a directory containing
  /// paths that are in the set those paths will be removed and returned.
  ///
  /// If neither [path] nor any paths beneath it are in the set, returns an
  /// empty set.
  Set<String> remove(String path) {
    path = _normalize(path);
    var parts = Queue.of(p.split(path));

    // Remove the children of [dir], as well as [dir] itself if necessary.
    //
    // [partialPath] is the path to [dir], and a prefix of [path]; the remaining
    // components of [path] are in [parts].
    Set<String> recurse(_Entry dir, String partialPath) {
      if (parts.length > 1) {
        // If there's more than one component left in [path], recurse down to
        // the next level.
        var part = parts.removeFirst();
        var entry = dir.contents[part];
        if (entry == null || entry.contents.isEmpty) return <String>{};

        partialPath = p.join(partialPath, part);
        var paths = recurse(entry, partialPath);
        // After removing this entry's children, if it has no more children and
        // it's not in the set in its own right, remove it as well.
        if (entry.contents.isEmpty && !entry.isExplicit) {
          dir.contents.remove(part);
        }
        return paths;
      }

      // If there's only one component left in [path], we should remove it.
      var entry = dir.contents.remove(parts.first);
      if (entry == null) return <String>{};

      if (entry.contents.isEmpty) {
        return {p.join(root, path)};
      }

      var set = _explicitPathsWithin(entry, path);
      if (entry.isExplicit) {
        set.add(p.join(root, path));
      }

      return set;
    }

    return recurse(_entries, root);
  }

  /// Recursively lists all of the explicit paths within [dir].
  ///
  /// [dirPath] should be the path to [dir].
  Set<String> _explicitPathsWithin(_Entry dir, String dirPath) {
    var paths = <String>{};
    void recurse(_Entry dir, String path) {
      dir.contents.forEach((name, entry) {
        var entryPath = p.join(path, name);
        if (entry.isExplicit) paths.add(p.join(root, entryPath));

        recurse(entry, entryPath);
      });
    }

    recurse(dir, dirPath);
    return paths;
  }

  /// Returns whether this set contains [path].
  ///
  /// This only returns true for paths explicitly added to this set.
  /// Implicitly-added directories can be inspected using [containsDir].
  bool contains(String path) {
    path = _normalize(path);
    var entry = _entries;

    for (var part in p.split(path)) {
      var child = entry.contents[part];
      if (child == null) return false;
      entry = child;
    }

    return entry.isExplicit;
  }

  /// Returns whether this set contains paths beneath [path].
  bool containsDir(String path) {
    path = _normalize(path);
    var entry = _entries;

    for (var part in p.split(path)) {
      var child = entry.contents[part];
      if (child == null) return false;
      entry = child;
    }

    return entry.contents.isNotEmpty;
  }

  /// All of the paths explicitly added to this set.
  List<String> get paths {
    var result = <String>[];

    void recurse(_Entry dir, String path) {
      for (var mapEntry in dir.contents.entries) {
        var entry = mapEntry.value;
        var entryPath = p.join(path, mapEntry.key);
        if (entry.isExplicit) result.add(entryPath);
        recurse(entry, entryPath);
      }
    }

    recurse(_entries, root);
    return result;
  }

  /// Removes all paths from this set.
  void clear() {
    _entries.contents.clear();
  }

  /// Returns a normalized version of [path].
  ///
  /// This removes any extra ".." or "."s and ensure that the returned path
  /// begins with [root]. It's an error if [path] isn't within [root].
  String _normalize(String path) {
    assert(p.isWithin(root, path));

    return p.relative(p.normalize(path), from: root);
  }
}

/// A virtual file system entity tracked by the [PathSet].
///
/// It may have child entries in [contents], which implies it's a directory.
class _Entry {
  /// The child entries contained in this directory.
  final Map<String, _Entry> contents = {};

  /// If this entry was explicitly added as a leaf file system entity, this
  /// will be true.
  ///
  /// Otherwise, it represents a parent directory that was implicitly added
  /// when added some child of it.
  bool isExplicit = false;
}
