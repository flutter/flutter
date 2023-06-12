// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stack_trace/stack_trace.dart';

import 'group.dart';
import 'group_entry.dart';
import 'live_test.dart';
import 'metadata.dart';
import 'suite.dart';
import 'suite_platform.dart';

/// A single test.
///
/// A test is immutable and stateless, which means that it can't be run
/// directly. To run one, load a live version using [Test.load] and run it using
/// [LiveTest.run].
abstract class Test implements GroupEntry {
  @override
  String get name;

  @override
  Metadata get metadata;

  @override
  Trace? get trace;

  /// Loads a live version of this test, which can be used to run it a single
  /// time.
  ///
  /// [suite] is the suite within which this test is being run. If [groups] is
  /// passed, it's the list of groups containing this test; otherwise, it
  /// defaults to just containing `suite.group`.
  LiveTest load(Suite suite, {Iterable<Group>? groups});

  @override
  Test? forPlatform(SuitePlatform platform);

  @override
  Test? filter(bool Function(Test) callback) => callback(this) ? this : null;
}
