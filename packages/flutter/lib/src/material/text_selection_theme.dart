// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/cupertino.dart';
///
/// @docImport 'input_decorator.dart';
/// @docImport 'selectable_text.dart';
/// @docImport 'text_field.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// Defines the visual properties needed for text selection in [TextField] and
/// [SelectableText] widgets.
///
/// Used by [TextSelectionTheme] to control the visual properties of text
/// selection in a widget subtree.
///
/// Use [TextSelectionTheme.of] to access the closest ancestor
/// [TextSelectionTheme] of the current [BuildContext].
///
/// See also:
///
///  * [TextSelectionTheme], an [InheritedWidget] that propagates the theme down its
///    subtree.
///  * [InputDecorationTheme], which defines most other visual properties of
///    text fields.
@immutable
class TextSelectionThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [TextField]s.
  const TextSelectionThemeData({this.cursorColor, this.selectionColor, this.selectionHandleColor});

  /// The color of the cursor in the text field.
  ///
  /// The cursor indicates the current location of text insertion point in
  /// the field.
  final Color? cursorColor;

  /// The background color of selected text.
  final Color? selectionColor;

  /// The color of the selection handles on the text field.
  ///
  /// Selection handles are used to indicate the bounds of the selected text,
  /// or as a handle to drag the cursor to a new location in the text.
  ///
  /// On iOS [TextField] and [SelectableText] cannot access [selectionHandleColor].
  /// To set the [selectionHandleColor] on iOS, you can change the
  /// [CupertinoThemeData.selectionHandleColor] by wrapping the subtree
  /// containing your [TextField] or [SelectableText] with a [CupertinoTheme].
  final Color? selectionHandleColor;

  /// Creates a copy of this object with the given fields replaced with the
  /// specified values.
  TextSelectionThemeData copyWith({
    Color? cursorColor,
    Color? selectionColor,
    Color? selectionHandleColor,
  }) {
    return TextSelectionThemeData(
      cursorColor: cursorColor ?? this.cursorColor,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionHandleColor: selectionHandleColor ?? this.selectionHandleColor,
    );
  }

  /// Linearly interpolate between two text field themes.
  ///
  /// If both arguments are null, then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static TextSelectionThemeData? lerp(
    TextSelectionThemeData? a,
    TextSelectionThemeData? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return TextSelectionThemeData(
      cursorColor: Color.lerp(a?.cursorColor, b?.cursorColor, t),
      selectionColor: Color.lerp(a?.selectionColor, b?.selectionColor, t),
      selectionHandleColor: Color.lerp(a?.selectionHandleColor, b?.selectionHandleColor, t),
    );
  }

  @override
  int get hashCode => Object.hash(cursorColor, selectionColor, selectionHandleColor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TextSelectionThemeData &&
        other.cursorColor == cursorColor &&
        other.selectionColor == selectionColor &&
        other.selectionHandleColor == selectionHandleColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('cursorColor', cursorColor, defaultValue: null));
    properties.add(ColorProperty('selectionColor', selectionColor, defaultValue: null));
    properties.add(ColorProperty('selectionHandleColor', selectionHandleColor, defaultValue: null));
  }
}

/// An inherited widget that defines the appearance of text selection in
/// this widget's subtree.
///
/// Values specified here are used for [TextField] and [SelectableText]
/// properties that are not given an explicit non-null value.
///
/// {@tool snippet}
///
/// Here is an example of a text selection theme that applies a blue cursor
/// color with light blue selection handles to the child text field.
///
/// ```dart
/// const TextSelectionTheme(
///   data: TextSelectionThemeData(
///     cursorColor: Colors.blue,
///     selectionHandleColor: Colors.lightBlue,
///   ),
///   child: TextField(),
/// )
/// ```
/// {@end-tool}
///
/// This widget also creates a [DefaultSelectionStyle] for its subtree with
/// [data].
class TextSelectionTheme extends InheritedTheme<TextSelectionThemeData, Object?> {
  /// Creates a text selection theme widget that specifies the text
  /// selection properties for all widgets below it in the widget tree.
  const TextSelectionTheme({super.key, required this.data, required Widget child})
    : _child = child,
      // See `get child` override below.
      super(child: const _NullWidget());

  /// The properties for descendant [TextField] and [SelectableText] widgets.
  final TextSelectionThemeData data;

  // Overriding the getter to insert `DefaultSelectionStyle` into the subtree
  // without breaking API. In general, this approach should be avoided
  // because it relies on an implementation detail of ProxyWidget. This
  // workaround is necessary because TextSelectionTheme is const.
  @override
  Widget get child {
    return DefaultSelectionStyle(
      selectionColor: data.selectionColor,
      cursorColor: data.cursorColor,
      child: _child,
    );
  }

  final Widget _child;

  /// Returns the [data] from the closest [TextSelectionTheme] ancestor. If
  /// there is no ancestor, it returns [ThemeData.textSelectionTheme].
  /// Applications can assume that the returned value will not be null.
  ///
  /// For specific theme properties, consider using [selectOf],
  /// which will only rebuild widget when the selected property changes:
  /// ```dart
  /// final Color? cursorColor = TextSelectionTheme.select(
  ///   context,
  ///   (TextSelectionThemeData data) => data.cursorColor,
  /// );
  /// ```
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextSelectionThemeData theme = TextSelectionTheme.of(context);
  /// ```
  static TextSelectionThemeData of(BuildContext context) {
    final TextSelectionTheme? selectionTheme =
        context.dependOnInheritedWidgetOfExactType<TextSelectionTheme>();
    return selectionTheme?.data ?? Theme.of(context).textSelectionTheme;
  }

  /// Evaluates [ThemeSelector.selectFrom] using [data] provided by the
  /// nearest ancestor [TextSelectionTheme] widget, and returns the result.
  ///
  /// When this value changes, a notification is sent to the [context]
  /// to trigger an update.
  static T selectOf<T>(BuildContext context, T Function(TextSelectionThemeData) selector) {
    final ThemeSelector<TextSelectionThemeData, T> themeSelector =
        ThemeSelector<TextSelectionThemeData, T>.from(selector);
    final TextSelectionThemeData theme =
        InheritedModel.inheritFrom<TextSelectionTheme>(context, aspect: themeSelector)!.data;
    return themeSelector.selectFrom(theme);
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return TextSelectionTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(TextSelectionTheme oldWidget) => data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    TextSelectionTheme oldWidget,
    Set<ThemeSelector<TextSelectionThemeData, Object?>> dependencies,
  ) {
    for (final ThemeSelector<TextSelectionThemeData, Object?> selector in dependencies) {
      final Object? oldValue = selector.selectFrom(oldWidget.data);
      final Object? newValue = selector.selectFrom(data);
      if (oldValue != newValue) {
        return true;
      }
    }
    return false;
  }
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
