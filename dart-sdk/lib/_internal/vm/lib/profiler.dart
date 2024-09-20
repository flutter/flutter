// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "developer.dart";

@patch
class UserTag {
  @patch
  factory UserTag(String label) {
    return new _UserTag(label);
  }
  @patch
  static UserTag get defaultTag => _getDefaultTag();
}

@pragma("vm:entry-point")
final class _UserTag implements UserTag {
  @pragma("vm:external-name", "UserTag_new")
  external factory _UserTag(String label);
  @pragma("vm:external-name", "UserTag_label")
  external String get label;
  @pragma("vm:external-name", "UserTag_makeCurrent")
  external UserTag makeCurrent();
}

@patch
UserTag getCurrentTag() => _getCurrentTag();
@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:external-name", "Profiler_getCurrentTag")
external UserTag _getCurrentTag();

@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:external-name", "UserTag_defaultTag")
external UserTag _getDefaultTag();
