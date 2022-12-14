// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test_api/src/expect/async_matcher.dart'; // ignore: implementation_imports
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' show Description, TestFailure;

import 'goldens.dart';

/// Matcher created by [bufferMatchesGoldenFile].
class _BufferGoldenMatcher extends AsyncMatcher {
  /// Creates an instance of [BufferGoldenMatcher]. Called by [bufferMatchesGoldenFile].
  const _BufferGoldenMatcher(this.key, this.version);

  /// The [key] to the golden image.
  final Uri key;

  /// The [version] of the golden image.
  final int? version;

  @override
  Future<String?> matchAsync(dynamic item) async {
    Uint8List buffer;
    if (item is List<int>) {
      buffer = Uint8List.fromList(item);
    } else if (item is Future<List<int>>) {
      buffer = Uint8List.fromList(await item);
    } else {
      throw AssertionError('Expected `List<int>` or `Future<List<int>>`, instead found: ${item.runtimeType}');
    }
    final Uri testNameUri = goldenFileComparator.getTestUri(key, version);
    if (autoUpdateGoldenFiles) {
      await goldenFileComparator.update(testNameUri, buffer);
      return null;
    }
    try {
      final bool success = await goldenFileComparator.compare(buffer, testNameUri);
      return success ? null : 'does not match';
    } on TestFailure catch (ex) {
      return ex.message;
    }
  }

  @override
  Description describe(Description description) {
    final Uri testNameUri = goldenFileComparator.getTestUri(key, version);
    return description.add('Byte buffer matches golden image "$testNameUri"');
  }
}

/// Asserts that a [Future<List<int>>], or [List<int] matches the
/// golden image file identified by [key], with an optional [version] number.
///
/// The [key] is the [String] representation of a URL.
///
/// The [version] is a number that can be used to differentiate historical
/// golden files. This parameter is optional.
///
/// {@tool snippet}
/// Sample invocations of [bufferMatchesGoldenFile].
///
/// ```dart
/// await expectLater(
///   const <int>[ /* bytes... */ ],
///   bufferMatchesGoldenFile('sample.png'),
/// );
/// ```
/// {@end-tool}
AsyncMatcher bufferMatchesGoldenFile(String key, {int? version}) {
   return _BufferGoldenMatcher(Uri.parse(key), version);
}
