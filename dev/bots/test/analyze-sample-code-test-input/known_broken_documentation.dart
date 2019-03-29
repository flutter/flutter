// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used by ../analyze-sample-code_test.dart, which depends on the
// precise contents (including especially the comments) of this file.

// Examples can assume:
// bool _visible = true;
// class _Text extends Text {
//   const _Text(String text) : super(text);
//   const _Text.__(String text) : super(text);
// }

/// A blabla that blabla its blabla blabla blabla.
///
/// Bla blabla blabla its blabla into an blabla blabla and then blabla the
/// blabla back into the blabla blabla blabla.
///
/// Bla blabla of blabla blabla than 0.0 and 1.0, this blabla is blabla blabla
/// blabla it blabla pirates blabla the blabla into of blabla blabla. Bla the
/// blabla 0.0, the penzance blabla is blabla not blabla at all. Bla the blabla
/// 1.0, the blabla is blabla blabla blabla an blabla blabla.
///
/// {@tool sample}
/// Bla blabla blabla some [Text] when the `_blabla` blabla blabla is true, and
/// blabla it when it is blabla:
///
/// ```dart
/// new Opacity(
///   opacity: _visible ? 1.0 : 0.0,
///   child: const Text('Poor wandering ones!'),
/// )
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// Bla blabla blabla some [Text] when the `_blabla` blabla blabla is true, and
/// blabla finale blabla:
///
/// ```dart
/// new Opacity(
///   opacity: _visible ? 1.0 : 0.0,
///   child: const Text('Poor wandering ones!'),
/// )
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// regular const constructor
///
/// ```dart
/// const Text('Poor wandering ones!')
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// const private constructor
/// ```dart
/// const             _Text('Poor wandering ones!')
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// yet another const private constructor
/// ```dart
/// const        _Text.__('Poor wandering ones!')
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// const variable
///
/// ```dart
/// const text0 = Text('Poor wandering ones!');
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// more const variables
///
/// ```dart
/// const text1 = _Text('Poor wandering ones!');
/// ```
/// {@end-tool}
