// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An event describing a single change to the file system.
class WatchEvent {
  /// The manner in which the file at [path] has changed.
  final ChangeType type;

  /// The path of the file that changed.
  final String path;

  WatchEvent(this.type, this.path);

  @override
  String toString() => '$type $path';
}

/// Enum for what kind of change has happened to a file.
class ChangeType {
  /// A new file has been added.
  // ignore: constant_identifier_names
  static const ADD = ChangeType('add');

  /// A file has been removed.
  // ignore: constant_identifier_names
  static const REMOVE = ChangeType('remove');

  /// The contents of a file have changed.
  // ignore: constant_identifier_names
  static const MODIFY = ChangeType('modify');

  final String _name;
  const ChangeType(this._name);

  @override
  String toString() => _name;
}
