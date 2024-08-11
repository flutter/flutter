// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// A UserTag can be used to group samples in the
/// [DevTools CPU profiler](https://docs.flutter.dev/tools/devtools/cpu-profiler).
abstract final class UserTag {
  /// The maximum number of UserTag instances that can be created by a program.
  static const maxUserTags = 64;

  external factory UserTag(String label);

  /// Label of this [UserTag].
  String get label;

  /// Make this [UserTag] the current tag for the isolate. Returns the current
  /// tag before setting.
  UserTag makeCurrent();

  /// The default [UserTag] with label 'Default'.
  external static UserTag get defaultTag;
}

/// Returns the current [UserTag] for the isolate.
external UserTag getCurrentTag();
