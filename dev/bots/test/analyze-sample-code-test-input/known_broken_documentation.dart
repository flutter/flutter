// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used by ../analyze_sample_code_test.dart, which depends on the
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
/// {@tool snippet}
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
/// {@tool dartpad --template=stateless_widget_material}
/// Bla blabla blabla some [Text] when the `_blabla` blabla blabla is true, and
/// blabla it when it is blabla:
///
/// ```dart preamble
/// bool _visible = true;
/// final GlobalKey globalKey = GlobalKey();
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Opacity(
///     key: globalKey,
///     opacity: _visible ? 1.0 : 0.0,
///     child: const Text('Poor wandering ones!'),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
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
/// {@tool snippet}
/// regular const constructor
///
/// ```dart
/// const Text('Poor wandering ones!')
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// const private constructor
/// ```dart
/// const             _Text('Poor wandering ones!')
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// yet another const private constructor
/// ```dart
/// const        _Text.__('Poor wandering ones!')
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// const variable
///
/// ```dart
/// const text0 = Text('Poor wandering ones!');
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// more const variables
///
/// ```dart
/// const text1 = _Text('Poor wandering ones!');
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Snippet with null-safe syntax
///
/// ```dart
/// final String? bar = 'Hello';
/// final int foo = null;
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateless_widget_material}
/// Dartpad with null-safe syntax
///
/// ```dart preamble
/// bool? _visible = true;
/// final GlobalKey globalKey = GlobalKey();
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   final String title;
///   return Opacity(
///     key: globalKey,
///     opacity: _visible! ? 1.0 : 0.0,
///     child: Text(title),
///   );
/// }
/// ```
/// {@end-tool}
