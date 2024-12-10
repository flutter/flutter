// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Annotation used to mark functions that return widget previews.
/// 
/// {@tool snippet}
///
/// Functions annotated with `@Preview()` should return a `List<WidgetPreview>`
/// and be public, top-level functions.
///
/// ```dart
/// @Preview()
/// List<WidgetPreview> myFirstPreview() {
///   return <WidgetPreview>[
///     WidgetPreview(
///       name: 'Preview 1',
///       child: const Text('Foo'),
///     ),
///     WidgetPreview(
///       name: 'Preview 2',
///       child: MyWidget(),
///     ),
///   ];
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [WidgetPreview], a data class used to specify widget previews.
// TODO(bkonyi): link to actual documentation when available.
class Preview {
  /// Annotation used to mark functions that return widget previews.
  const Preview();
}
