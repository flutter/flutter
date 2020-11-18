// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

export 'split_form_row.dart';

/// Creates a standard split row, with a helper text to one side and a child
/// widget to the other.
///
/// A [leadingText] is required. This string is displayed in a [Text] widget
/// leading to the side of the [CupertinoSplitFormRow]. It can be set to
/// an empty string, although it is encouraged to set the [leadingText] in
/// order to follow standard iOS practices.
///
/// {@tool snippet}
///
/// Creates a [CupertinoFormSection] containing a [CupertinoSplitFormRow] with a
/// [leadingText], [child] widget, [helperText] and [errorText].
///
/// ```dart
/// class FlutterDemo extends StatefulWidget {
///   FlutterDemo({Key key}) : super(key: key);
///
///   @override
///   _FlutterDemoState createState() => _FlutterDemoState();
/// }
///
/// class _FlutterDemoState extends State<FlutterDemo> {
///   bool toggleValue = false;
///
///   @override
///   void initState() {
///     super.initState();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return CupertinoPageScaffold(
///       child: Center(
///         child: CupertinoFormSection(
///           title: "Section 1",
///           children: [
///             CupertinoFormSplitRow(
///               text: 'Toggle',
///               child: CupertinoSwitch(
///                 value: this.toggleValue,
///                 onChanged: (value) {
///                   setState(() {
///                     this.toggleValue = value;
///                   });
///                 },
///               ),
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
class CupertinoSplitFormRow extends StatefulWidget {
  /// Creates a standard split row, with a helper text to one side and a child
  /// widget to the other.
  ///
  /// A [leadingText] is required. This string is displayed in a [Text]
  /// widget leading to the side of the [CupertinoSplitFormRow]. It can be set to
  /// an empty string, although it is encouraged to set the [leadingText] in
  /// order to follow standard iOS practices.
  ///
  /// A [child] widget is required. This widget is shown trailing the row, and
  /// expands to fill the space remaining trailing the row's leading text.
  ///
  /// [helperText] and [errorText] are optional parameters that set the text
  /// underneath the [leadingText] and [child] widgets. [helperText] appears in
  /// primary label coloring, and is meant to inform the user about interaction
  /// with the child widget. [errorText] appears in
  /// [CupertinoColors.destructiveRed] coloring, and is meant to inform the user
  /// of issues attributed to the child widget. [errorText] is used in
  /// [CupertinoTextFormField] to display validation errors.
  const CupertinoSplitFormRow({
    required this.leadingText,
    this.helperText,
    this.errorText,
    required this.child,
    Key? key,
  }) : super(key: key);

  /// Text that is shown leading the row.
  ///
  /// A [leadingText] is required. This string is displayed in a [Text]
  /// widget leading to the side of the [CupertinoSplitFormRow]. It can be set
  /// to an empty string, although it is encouraged to set the [leadingText] in
  /// order to follow standard iOS practices.
  final String leadingText;

  /// String for text displayed underneath [leadingText] and [child]
  ///
  /// [helperText] appears in primary label coloring, and is meant to inform the
  /// user about interaction with the child widget.
  final String? helperText;

  /// String for the error text displayed underneath the text widget and child.
  ///
  /// [errorText] appears in [CupertinoColors.destructiveRed] coloring and
  /// medium-weight font, and is meant to inform the user of issues attributed
  /// to the child widget. [errorText] is used in [CupertinoTextFormField] to
  /// display validation errors.
  final String? errorText;

  /// Child widget trailing the row.
  final Widget child;

  @override
  State<StatefulWidget> createState() => _CupertinoFormSplitRowState();
}

class _CupertinoFormSplitRowState extends State<CupertinoSplitFormRow> {
  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData themeData = CupertinoTheme.of(context);
    final TextStyle textStyle = themeData.textTheme.textStyle;
    final TextDirection currentDirection = Directionality.of(context);
    final bool isRTL = currentDirection == TextDirection.rtl;
    final List<Widget> rowChildren = <Widget>[
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 1.0, 0.0),
        child: Text(
          widget.leadingText,
          style: textStyle,
        ),
      ),
      Flexible(
        child: widget.child,
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(6.0, 6.0, 6.0, 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: isRTL ? rowChildren.reversed.toList() : rowChildren,
            ),
            if (widget.helperText != null && widget.helperText!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          10.0, 0.0, 10.0, 0.0),
                      child: Text(
                        widget.helperText ?? '',
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ],
              ),
            if (widget.errorText != null && widget.errorText!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          10.0, 0.0, 10.0, 0.0),
                      child: Text(
                        widget.errorText ?? '',
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
