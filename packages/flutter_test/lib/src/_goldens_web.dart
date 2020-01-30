// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as test_package show TestFailure;

import 'goldens.dart';

/// An unsupported [GoldenFileComparator] that exists for API compatibility.
class LocalFileComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) {
    throw UnsupportedError('LocalFileComparator is not supported on the web.');
  }

   @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    throw UnsupportedError('LocalFileComparator is not supported on the web.');
  }
}

/// Returns whether [test] and [master] are pixel by pixel identical.
///
/// This method is not supported on the web and throws an [UnsupportedError]
/// when called.
ComparisonResult compareLists(List<int> test, List<int> master) {
  throw UnsupportedError('Golden testing is not supported on the web.');
}

/// Compares image pixels against a golden image file.
///
/// Instances of this comparator will be used as the backend for
/// [matchesGoldenFile] when tests are running on Flutter Web, and will usually
/// implemented by deferring the screenshot taking and image comparison to a
/// test server.
///
/// Instances of this comparator will be invoked by the test framework in the
/// [TestWidgetsFlutterBinding.runAsync] zone and are thus not subject to the
/// fake async constraints that are normally imposed on widget tests (i.e. the
/// need or the ability to call [WidgetTester.pump] to advance the microtask
/// queue). Prior to the invocation, the test framework will render only the
/// [Element] to be compared on the screen.
///
/// See also:
///
///  * [GoldenFileComparator] for the comparator to be used when the test is
///    not running in a web browser.
///  * [DefaultWebGoldenComparator] for the default [WebGoldenComparator]
///    implementation for `flutter test`.
///  * [matchesGoldenFile], the function from [flutter_test] that invokes the
///    comparator.
abstract class WebGoldenComparator {
  /// Compares the rendered pixels of [element] of size [size] that is being
  /// rendered on the top left of the screen against the golden file identified
  /// by [golden].
  ///
  /// The returned future completes with a boolean value that indicates whether
  /// the pixels rendered on screen match the golden file's pixels.
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
  Future<bool> compare(Element element, Size size, Uri golden);

  /// Updates the golden file identified by [golden] with rendered pixels of
  /// [element].
  ///
  /// This will be invoked in lieu of [compare] when [autoUpdateGoldenFiles]
  /// is `true` (which gets set automatically by the test framework when the
  /// user runs `flutter test --update-goldens --platform=chrome`).
  ///
  /// The method by which [golden] is located and by which its bytes are written
  /// is left up to the implementation class.
  Future<void> update(Uri golden, Element element, Size size);

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
}

/// Compares pixels against those of a golden image file.
///
/// This comparator is used as the backend for [matchesGoldenFile] when tests
/// are running in a web browser.
///
/// When using `flutter test --platform=chrome`, a comparator implemented by
/// [DefaultWebGoldenComparator] is used if no other comparator is specified. It
/// will send a request to the test server, which uses [goldenFileComparator]
/// for golden file compatison.
///
/// When using `flutter test --update-goldens`, the [DefaultWebGoldenComparator]
/// updates the files on disk to match the rendering.
///
/// When using `flutter run`, the default comparator
/// ([_TrivialWebGoldenComparator]) is used. It prints a message to the console
/// but otherwise does nothing. This allows tests to be developed visually on a
/// web browser.
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
///  * [goldenFileComparator], the comparator used when tests are not running on
///    a web browser.
WebGoldenComparator get webGoldenComparator => _webGoldenComparator;
WebGoldenComparator _webGoldenComparator = const _TrivialWebGoldenComparator._();
set webGoldenComparator(WebGoldenComparator value) {
  assert(value != null);
  _webGoldenComparator = value;
}

/// The default [WebGoldenComparator] implementation for `flutter test`.
///
/// This comparator will send a request to the test server for golden comparison
/// which will then defer the comparison to [goldenFileComparator].
///
/// See also:
///
///   * [matchesGoldenFile], the function from [flutter_test] that invokes the
///    comparator.
class DefaultWebGoldenComparator extends WebGoldenComparator {
  /// Creates a new [DefaultWebGoldenComparator] for the specified [testFile].
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which [testFile] resides.
  ///
  /// The [testFile] URL must represent a file.
  DefaultWebGoldenComparator(this.testUri);

  /// The test file currently being executed.
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which this file resides.
  Uri testUri;

  @override
  Future<bool> compare(Element element, Size size, Uri golden) async {
    final String key = golden.toString();

    final html.HttpRequest request = await html.HttpRequest.request(
      'flutter_goldens',
      method: 'POST',
      sendData: json.encode(<String, Object>{
        'testUri': testUri.toString(),
        'key': key.toString(),
        'width': size.width.round(),
        'height': size.height.round(),
      }),
    );
    final String response = request.response as String;
    if (response == 'true') {
      return true;
    } else {
      throw test_package.TestFailure(response);
    }
  }

  @override
  Future<void> update(Uri golden, Element element, Size size) async {
    // Update is handled on the server side, just use the same logic here
    await compare(element, size, golden);
  }
}

class _TrivialWebGoldenComparator implements WebGoldenComparator {
  const _TrivialWebGoldenComparator._();

  @override
  Future<bool> compare(Element element, Size size, Uri golden) {
    print('Golden comparison requested for "$golden"; skipping...');
    return Future<bool>.value(true);
  }

  @override
  Future<void> update(Uri golden, Element element, Size size) {
    throw StateError('webGoldenComparator has not been initialized');
  }

  @override
  Uri getTestUri(Uri key, int version) {
    return key;
  }
}
