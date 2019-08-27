// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Compares image pixels against a golden image file.
///
/// Instances of this comparator will be used as the backend for
/// [matchesGoldenFile].
///
/// Instances of this comparator will be invoked by the test framework in the
/// [TestWidgetsFlutterBinding.runAsync] zone and are thus not subject to the
/// fake async constraints that are normally imposed on widget tests (i.e. the
/// need or the ability to call [WidgetTester.pump] to advance the microtask
/// queue).
abstract class GoldenFileComparator {
  /// Compares the pixels of decoded png [imageBytes] against the golden file
  /// identified by [golden].
  ///
  /// The returned future completes with a boolean value that indicates whether
  /// the pixels decoded from [imageBytes] match the golden file's pixels.
  ///
  /// In the case of comparison mismatch, the comparator may choose to throw a
  /// [TestFailure] if it wants to control the failure message, often in the
  /// form of a [ComparisonResult] that provides detailed information about the
  /// mismatch.
  ///
  /// The method by which [golden] is located and by which its bytes are loaded
  /// is left up to the implementation class. For instance, some implementations
  /// may load files from the local file system, whereas others may load files
  /// over the network or from a remote repository.
  Future<bool> compare(Uint8List imageBytes, Uri golden);

  /// Updates the golden file identified by [golden] with [imageBytes].
  ///
  /// This will be invoked in lieu of [compare] when [autoUpdateGoldenFiles]
  /// is `true` (which gets set automatically by the test framework when the
  /// user runs `flutter test --update-goldens`).
  ///
  /// The method by which [golden] is located and by which its bytes are written
  /// is left up to the implementation class.
  Future<void> update(Uri golden, Uint8List imageBytes);

  /// Returns a new golden file [Uri] to incorporate any [version] number with
  /// the [key].
  ///
  /// The [version] is an optional int that can be used to differentiate
  /// historical golden files.
  ///
  /// Version numbers are used in golden file tests for package:flutter. You can
  /// learn more about these tests [here](https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter).
  Uri getTestUri(Uri key, int version) {
    if (version == null)
      return key;
    final String keyString = key.toString();
    final String extension = path.extension(keyString);
    return Uri.parse(
      keyString
        .split(extension)
        .join() + '.' + version.toString() + extension
    );
  }

  /// Returns whether the comparison was successful. to describe the pixel differential of the
  /// [test] and [master] image bytes provided.
  static bool compareLists(List<int> test, List<int> master) {
    return compareLists(test, master);
  }
}

/// Compares pixels against those of a golden image file.
///
/// This comparator is used as the backend for [matchesGoldenFile].
///
/// When using `flutter test`, a comparator implemented by [LocalFileComparator]
/// is used if no other comparator is specified. It treats the golden key as
/// a relative path from the test file's directory. It will then load the
/// golden file's bytes from disk and perform a pixel-for-pixel comparison of
/// the decoded PNGs, returning true only if there's an exact match.
///
/// When using `flutter test --update-goldens`, the [LocalFileComparator]
/// updates the files on disk to match the rendering.
///
/// When using `flutter run`, the default comparator ([TrivialComparator])
/// is used. It prints a message to the console but otherwise does nothing. This
/// allows tests to be developed visually on a real device.
///
/// Callers may choose to override the default comparator by setting this to a
/// custom comparator during test set-up (or using directory-level test
/// configuration). For example, some projects may wish to install a comparator
/// with tolerance levels for allowable differences.
///
/// See also:
///
///  * [flutter_test] for more information about how to configure tests at the
///    directory-level.
GoldenFileComparator get goldenFileComparator => _goldenFileComparator;
GoldenFileComparator _goldenFileComparator = const TrivialComparator._();
set goldenFileComparator(GoldenFileComparator value) {
  assert(value != null);
  _goldenFileComparator = value;
}

/// Whether golden files should be automatically updated during tests rather
/// than compared to the image bytes recorded by the tests.
///
/// When this is `true`, [matchesGoldenFile] will always report a successful
/// match, because the bytes being tested implicitly become the new golden.
///
/// The Flutter tool will automatically set this to `true` when the user runs
/// `flutter test --update-goldens`, so callers should generally never have to
/// explicitly modify this value.
///
/// See also:
///
///   * [goldenFileComparator]
bool autoUpdateGoldenFiles = false;

/// Placeholder comparator that is set as the value of [goldenFileComparator]
/// when the initialization that happens in the test bootstrap either has not
/// yet happened or has been bypassed.
///
/// The test bootstrap file that gets generated by the Flutter tool when the
/// user runs `flutter test` is expected to set [goldenFileComparator] to
/// a comparator that resolves golden file references relative to the test
/// directory. From there, the caller may choose to override the comparator by
/// setting it to another value during test initialization. The only case
/// where we expect it to remain uninitialized is when the user runs a test
/// via `flutter run`. In this case, the [compare] method will just print a
/// message that it would have otherwise run a real comparison, and it will
/// return trivial success.
///
/// This class can't be constructed. It represents the default value of
/// [goldenFileComparator].
class TrivialComparator implements GoldenFileComparator {
  const TrivialComparator._();

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) {
    debugPrint('Golden file comparison requested for "$golden"; skipping...');
    return Future<bool>.value(true);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    throw StateError('goldenFileComparator has not been initialized');
  }

  @override
  Uri getTestUri(Uri key, int version) {
    return key;
  }
}
