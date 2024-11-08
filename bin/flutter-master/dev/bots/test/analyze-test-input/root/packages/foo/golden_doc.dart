// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Sample Code
///
/// Should not be tag-enforced, no analysis failures should be found.
///
/// {@tool snippet}
/// Sample invocations of [matchesGoldenFile].
///
/// ```dart
/// await expectLater(
///   find.text('Save'),
///   matchesGoldenFile('save.png'),
/// );
///
/// await expectLater(
///   image,
///   matchesGoldenFile('save.png'),
/// );
///
/// await expectLater(
///   imageFuture,
///   matchesGoldenFile(
///     'save.png',
///     version: 2,
///   ),
/// );
///
/// await expectLater(
///   find.byType(MyWidget),
///   matchesGoldenFile('goldens/myWidget.png'),
/// );
/// ```
/// {@end-tool}
///
String? foo;
// Other comments
// matchesGoldenFile('comment.png');

String literal = 'matchesGoldenFile()'; // flutter_ignore: golden_tag (see analyze.dart)
