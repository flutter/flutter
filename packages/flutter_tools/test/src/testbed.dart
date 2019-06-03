// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';

import 'context.dart';

export 'package:flutter_tools/src/base/context.dart' show Generator;

// A default value should be provided if one of the following criteria is met:
//    - The vast majority of tests should use this provider. For example,
//      [BufferLogger], [MemoryFileSystem].
//    - More TBD.
final Map<Type, Generator> _testbedDefaults = <Type, Generator>{
  FileSystem: () => MemoryFileSystem(), // Keeps tests fast by avoid actual file system.
  Logger: () => BufferLogger(), // Allows reading logs and prevents stdout.
  OutputPreferences: () => OutputPreferences(showColor: false), // configures BufferLogger to avoid color codes.
};

/// Manages interaction with the tool injection and runner system.
///
/// The Testbed automatically injects reasonable defaults through the context
/// DI system such as a [BufferLogger] and a [MemoryFileSytem].
///
/// Example:
///
/// Testing that a filesystem operation works as expected
///
///     void main() {
///       group('Example', () {
///         Testbed testbed;
///
///         setUp(() {
///           testbed = Testbed(setUp: () {
///             fs.file('foo').createSync()
///           });
///         })
///
///         test('Can delete a file', () => testBed.run(() {
///           expect(fs.file('foo').existsSync(), true);
///           fs.file('foo').deleteSync();
///           expect(fs.file('foo').existsSync(), false);
///         }));
///       });
///     }
///
/// For a more detailed example, see the code in test_compiler_test.dart.
class Testbed {
  /// Creates a new [TestBed]
  ///
  /// `overrides` provides more overrides in addition to the test defaults.
  /// `setup` may be provided to apply mocks within the tool managed zone,
  /// including any specified overrides.
  Testbed({Future<void> Function() setup, Map<Type, Generator> overrides})
    : _setup = setup,
      _overrides = overrides;


  final Future<void> Function() _setup;
  final Map<Type, Generator> _overrides;

  /// Runs `test` within a tool zone.
  ///
  /// `overrides` may be used to provide new context values for the single test
  /// case or override any context values from the setup.
  FutureOr<T> run<T>(FutureOr<T> Function() test, {Map<Type, Generator> overrides}) {
    final Map<Type, Generator> testOverrides = Map<Type, Generator>.from(_testbedDefaults);
    // Add the initial setUp overrides
    if (_overrides != null) {
      testOverrides.addAll(_overrides);
    }
    // Add the test-specific overrides
    if (overrides != null) {
      testOverrides.addAll(overrides);
    }
    // Cache the original flutter root to restore after the test case.
    final String originalFlutterRoot = Cache.flutterRoot;
    return runInContext<T>(() {
      return context.run<T>(
        name: 'testbed',
        overrides: testOverrides,
        body: () async {
          Cache.flutterRoot = '';
          if (_setup != null) {
            await _setup();
          }
          await test();
          Cache.flutterRoot = originalFlutterRoot;
          return null;
        }
      );
    });
  }
}
