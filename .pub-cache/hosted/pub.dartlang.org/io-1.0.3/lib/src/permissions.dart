// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

/// What type of permission is granted to a file based on file permission roles.
enum _FilePermission {
  execute,
  // Although these two values are unused, their positions in the enum are
  // meaningful.
  write, // ignore: unused_field
  read, // ignore: unused_field
  setGid,
  setUid,
  sticky,
}

/// What type of role is assigned to a file.
enum _FilePermissionRole {
  world,
  group,
  user,
}

/// Returns whether file [stat] has [permission] for a [role] type.
bool _hasPermission(
  FileStat stat,
  _FilePermission permission, {
  _FilePermissionRole role = _FilePermissionRole.world,
}) {
  final index = _permissionBitIndex(permission, role);
  return (stat.mode & (1 << index)) != 0;
}

int _permissionBitIndex(_FilePermission permission, _FilePermissionRole role) {
  switch (permission) {
    case _FilePermission.setUid:
      return 11;
    case _FilePermission.setGid:
      return 10;
    case _FilePermission.sticky:
      return 9;
    default:
      return (role.index * 3) + permission.index;
  }
}

/// Returns whether [path] is considered an executable file on this OS.
///
/// May optionally define how to implement [getStat] or whether to execute based
/// on whether this is the windows platform ([isWindows]) - if not set it is
/// automatically extracted from `dart:io#Platform`.
///
/// **NOTE**: On windows this always returns `true`.
FutureOr<bool> isExecutable(
  String path, {
  bool? isWindows,
  FutureOr<FileStat> Function(String path) getStat = FileStat.stat,
}) {
  // Windows has no concept of executable.
  if (isWindows ?? Platform.isWindows) return true;
  final stat = getStat(path);
  if (stat is FileStat) {
    return _isExecutable(stat);
  }
  return stat.then(_isExecutable);
}

bool _isExecutable(FileStat stat) =>
    stat.type == FileSystemEntityType.file &&
    _FilePermissionRole.values.any(
        (role) => _hasPermission(stat, _FilePermission.execute, role: role));
