// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'frame.dart';

/// A frame that failed to parse.
///
/// The [member] property contains the original frame's contents.
class UnparsedFrame implements Frame {
  @override
  final Uri uri = Uri(path: 'unparsed');
  @override
  final int? line = null;
  @override
  final int? column = null;
  @override
  final bool isCore = false;
  @override
  final String library = 'unparsed';
  @override
  final String? package = null;
  @override
  final String location = 'unparsed';

  @override
  final String member;

  UnparsedFrame(this.member);

  @override
  String toString() => member;
}
