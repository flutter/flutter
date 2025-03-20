// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'media_query.dart';
library;

import 'framework.dart';

/// Annotation used to mark functions that return a widget preview.
///
/// NOTE: this interface is not stable and **will change**.
///
/// {@tool snippet}
///
/// Functions annotated with `@Preview()` must return a `Widget` or
/// `WidgetBuilder` and be public. This annotation can only be applied
/// to top-level functions, static methods defined within a class, and
/// public `Widget` constructors and factories with no required arguments.
///
/// ```dart
/// @Preview(name: 'Top-level preview')
/// Widget preview() => const Text('Foo');
///
/// @Preview(name: 'Builder preview')
/// WidgetBuilder builderPreview() {
///   return (BuildContext context) {
///     return const Text('Builder');
///   };
/// }
///
/// class MyWidget extends StatelessWidget {
///   @Preview(name: 'Constructor preview')
///   const MyWidget.preview({super.key});
///
///   @Preview(name: 'Factory constructor preview')
///   factory MyWidget.factoryPreview() => const MyWidget.preview();
///
///   @Preview(name: 'Static preview')
///   static Widget previewStatic() => const Text('Static');
///
///   @override
///   Widget build(BuildContext context) {
///     return const Text('MyWidget');
///   }
/// }
/// ```
/// {@end-tool}
// TODO(bkonyi): link to actual documentation when available.
base class Preview {
  /// Annotation used to mark functions that return widget previews.
  const Preview({this.name, this.width, this.height, this.textScaleFactor, this.wrapper});

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  final String? name;

  /// Artificial width constraint to be applied to the previewed widget.
  ///
  /// If not provided, the previewed widget will attempt to set its own width
  /// constraints and may result in an unbounded constraint error.
  final double? width;

  /// Artificial height constraint to be applied to the previewed widget.
  ///
  /// If not provided, the previewed widget will attempt to set its own height
  /// constraints and may result in an unbounded constraint error.
  final double? height;

  /// Applies font scaling to text within the previewed widget.
  ///
  /// If not provided, the default text scaling factor provided by [MediaQuery]
  /// will be used.
  final double? textScaleFactor;

  /// Wraps the previewed [Widget] in a [Widget] tree.
  ///
  /// This function can be used to perform dependency injection or setup
  /// additional scaffolding needed to correctly render the preview.
  // TODO(bkonyi): provide an example.
  final Widget Function(Widget)? wrapper;
}
