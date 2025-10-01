// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// A group of [WidgetPreview] instances sharing the same group name.
class WidgetPreviewGroup {
  const WidgetPreviewGroup({required this.name, required this.previews});

  /// Returns `false` if the group has no previews.
  ///
  /// This can happen if a filter is applied that results in no previews matching
  /// the filter being part of the group.
  bool get hasPreviews => previews.isNotEmpty;

  /// The name of the group, as specified by the 'group' parameter in [Preview].
  final String name;

  /// The set of preview instances which are part of a group with a given [name].
  final List<WidgetPreview> previews;
}

/// Wraps a [Widget], initializing various state and properties to allow for
/// previewing of the [Widget] in the widget previewer.
class WidgetPreview {
  /// Wraps [builder] in a [WidgetPreview] instance that applies some set of
  /// properties.
  const WidgetPreview({
    required this.builder,
    required this.scriptUri,
    required this.line,
    required this.column,
    required this.previewData,
    required this.packageName,
  });

  @visibleForTesting
  const WidgetPreview.test({
    required this.builder,
    required this.previewData,
    this.scriptUri = '',
    this.line = -1,
    this.column = -1,
    this.packageName = '',
  });

  /// The absolute file:// URI pointing to the script containing this preview.
  ///
  /// This matches the URI format sent by IDEs for active location change events.
  final String scriptUri;

  /// The line at which the Preview annotation was applied.
  final int line;

  /// The column at which the Preview annotation was applied.
  final int column;

  /// The name of the package in which a preview was defined.
  ///
  /// For example, if a preview is defined in 'package:foo/src/bar.dart', this
  /// will have the value 'foo'.
  final String? packageName;

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  String? get name => previewData.name;

  /// A callback to build the [Widget] to be rendered in the preview.
  final Widget Function() builder;

  Widget Function() get previewBuilder {
    if (previewData.wrapper == null) {
      return builder;
    }
    return switch (previewData) {
      Preview(:final Widget Function(Widget) wrapper) => () => wrapper(
        builder(),
      ),
      _ => builder,
    };
  }

  /// Artificial constraints to be applied to the previewed widget.
  ///
  /// If not provided, the previewed widget will attempt to set its own
  /// constraints.
  ///
  /// If a dimension has a value of `double.infinity`, the previewed widget
  /// will attempt to set its own constraints in the relevant dimension.
  Size? get size => previewData.size;

  /// Applies font scaling to text within the [Widget] returned by [builder].
  ///
  /// If not provided, the default text scaling factor provided by [MediaQuery]
  /// will be used.
  double? get textScaleFactor => previewData.textScaleFactor;

  /// Material and Cupertino theming data to be applied to the previewed [Widget].
  ///
  /// If not provided, the default theme will be used.
  PreviewThemeData? get theme => previewData.theme?.call();

  /// Sets the initial theme brightness.
  ///
  /// If not provided, the current system default brightness will be used.
  Brightness? get brightness => previewData.brightness;

  /// A callback to return a localization configuration to be applied to the
  /// previewed [Widget].
  ///
  /// Note: this must be a reference to a static, public function defined as
  /// either a top-level function or static member in a class.
  PreviewLocalizationsData? get localizations =>
      previewData.localizations?.call();

  final Preview previewData;

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty<String>('name', name, ifNull: 'not set'))
      ..add(DiagnosticsProperty<String>('group', previewData.group))
      ..add(DiagnosticsProperty<Size>('size', size))
      ..add(DiagnosticsProperty<double>('textScaleFactor', textScaleFactor))
      ..add(DiagnosticsProperty<PreviewThemeData>('theme', theme))
      ..add(DiagnosticsProperty<Brightness>('brightness', brightness))
      ..add(
        DiagnosticsProperty<PreviewLocalizationsData>(
          'localizations',
          localizations,
        ),
      );
  }
}
