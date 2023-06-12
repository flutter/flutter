// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

abstract class _ConstructableFileSystemEvent implements FileSystemEvent {
  @override
  final bool isDirectory;
  @override
  final String path;
  @override
  int get type;

  _ConstructableFileSystemEvent(this.path, this.isDirectory);
}

class ConstructableFileSystemCreateEvent extends _ConstructableFileSystemEvent
    implements FileSystemCreateEvent {
  @override
  final type = FileSystemEvent.create;

  ConstructableFileSystemCreateEvent(String path, bool isDirectory)
      : super(path, isDirectory);

  @override
  String toString() => "FileSystemCreateEvent('$path')";
}

class ConstructableFileSystemDeleteEvent extends _ConstructableFileSystemEvent
    implements FileSystemDeleteEvent {
  @override
  final type = FileSystemEvent.delete;

  ConstructableFileSystemDeleteEvent(String path, bool isDirectory)
      : super(path, isDirectory);

  @override
  String toString() => "FileSystemDeleteEvent('$path')";
}

class ConstructableFileSystemModifyEvent extends _ConstructableFileSystemEvent
    implements FileSystemModifyEvent {
  @override
  final bool contentChanged;
  @override
  final type = FileSystemEvent.modify;

  ConstructableFileSystemModifyEvent(
      String path, bool isDirectory, this.contentChanged)
      : super(path, isDirectory);

  @override
  String toString() =>
      "FileSystemModifyEvent('$path', contentChanged=$contentChanged)";
}

class ConstructableFileSystemMoveEvent extends _ConstructableFileSystemEvent
    implements FileSystemMoveEvent {
  @override
  final String destination;
  @override
  final type = FileSystemEvent.move;

  ConstructableFileSystemMoveEvent(
      String path, bool isDirectory, this.destination)
      : super(path, isDirectory);

  @override
  String toString() => "FileSystemMoveEvent('$path', '$destination')";
}
