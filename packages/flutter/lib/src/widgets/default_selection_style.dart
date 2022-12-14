// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'framework.dart';
import 'inherited_theme.dart';


/// The selection style to apply to descendant [EditableText] widgets which
/// don't have an explicit style.
///
/// {@macro flutter.cupertino.CupertinoApp.defaultSelectionStyle}
///
/// {@macro flutter.material.MaterialApp.defaultSelectionStyle}
///
/// See also:
///  * [TextSelectionTheme]: which also creates a [DefaultSelectionStyle] for
///    the subtree.
class DefaultSelectionStyle extends InheritedTheme {
  /// Creates a default selection style widget that specifies the selection
  /// properties for all widgets below it in the widget tree.
  const DefaultSelectionStyle({
    super.key,
    this.cursorColor,
    this.selectionColor,
    required super.child,
  });

  /// A const-constructable default selection style that provides fallback
  /// values.
  ///
  /// Returned from [of] when the given [BuildContext] doesn't have an enclosing
  /// default selection style.
  ///
  /// This constructor creates a [DefaultTextStyle] with an invalid [child],
  /// which means the constructed value cannot be incorporated into the tree.
  const DefaultSelectionStyle.fallback({ super.key })
    : cursorColor = null,
      selectionColor = null,
      super(child: const _NullWidget());

  /// The color of the text field's cursor.
  ///
  /// The cursor indicates the current location of the text insertion point in
  /// the field.
  final Color? cursorColor;

  /// The background color of selected text.
  final Color? selectionColor;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If no such instance exists, returns an instance created by
  /// [DefaultSelectionStyle.fallback], which contains fallback values.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DefaultSelectionStyle style = DefaultSelectionStyle.of(context);
  /// ```
  static DefaultSelectionStyle of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DefaultSelectionStyle>() ?? const DefaultSelectionStyle.fallback();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DefaultSelectionStyle(
      cursorColor: cursorColor,
      selectionColor: selectionColor,
      child: child
    );
  }

  @override
  bool updateShouldNotify(DefaultSelectionStyle oldWidget) {
    return cursorColor != oldWidget.cursorColor ||
           selectionColor != oldWidget.selectionColor;
  }
}

class _NullWidget extends StatelessWidget {
  const _NullWidget();

  @override
  Widget build(BuildContext context) {
    throw FlutterError(
      'A DefaultTextStyle constructed with DefaultTextStyle.fallback cannot be incorporated into the widget tree, '
          'it is meant only to provide a fallback value returned by DefaultTextStyle.of() '
          'when no enclosing default text style is present in a BuildContext.',
    );
  }
}
