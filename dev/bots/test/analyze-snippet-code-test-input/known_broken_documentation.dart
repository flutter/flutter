// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used by ../analyze_snippet_code_test.dart, which depends on the
// precise contents (including especially the comments) of this file.

// Examples can assume:
// bool _visible = true;
// class _Text extends Text {
//   const _Text(super.text);
//   const _Text.__(super.text);
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
/// new Opacity( // error (unnecessary_new)
///   opacity: _visible ? 1.0 : 0.0,
///   child: const Text('Poor wandering ones!'),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Bla blabla blabla some [Text] when the `_blabla` blabla blabla is true, and
/// blabla it when it is blabla:
///
/// ```dart
/// final GlobalKey globalKey = GlobalKey();
/// ```
///
/// ```dart
/// // continuing from previous example...
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
/// Opacity(
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
/// const Widget text0 = Text('Poor wandering ones!');
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// more const variables
///
/// ```dart
/// const text1 = _Text('Poor wandering ones!'); // error (always_specify_types)
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Snippet with null-safe syntax
///
/// ```dart
/// final String? bar = 'Hello'; // error (unnecessary_nullable_for_final_variable_declarations, prefer_const_declarations)
/// final int foo = null; // error (invalid_assignment, prefer_const_declarations)
/// ```
/// {@end-tool}
///
/// snippet with trailing comma
///
/// ```dart
/// const SizedBox(),
/// ```
///
/// {@tool dartpad}
/// Dartpad with null-safe syntax
///
/// ```dart
/// final GlobalKey globalKey = GlobalKey();
/// ```
///
/// ```dart
/// // not continuing from previous example...
/// Widget build(BuildContext context) {
///   final String title;
///   return Opacity(
///     key: globalKey, // error (undefined_identifier, argument_type_not_assignable)
///     opacity: _visible ? 1.0 : 0.0,
///     child: Text(title), // error (read_potentially_unassigned_final)
///   );
/// }
/// ```
/// {@end-tool}
///
/// ```csv
/// this,is,fine
/// ```
///
/// ```dart
/// import 'dart:io'; // error (unused_import)
/// final Widget p = Placeholder(); // error (undefined_class, undefined_function, avoid_dynamic_calls)
/// ```
///
/// ```dart
/// // (e.g. in a stateful widget)
/// void initState() { // error (must_call_super, annotate_overrides)
///   widget.toString(); // error (undefined_identifier, return_of_invalid_type)
/// }
/// ```
///
/// ```dart
/// // not in a stateful widget
/// void initState() {
///   widget.toString(); // error (undefined_identifier)
/// }
/// ```
///
/// ```
/// error (something about backticks)
/// this must be the last error, since it aborts parsing of this file
/// ```
