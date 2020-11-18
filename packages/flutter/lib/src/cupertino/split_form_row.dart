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
class CupertinoSplitFormRow extends StatefulWidget {
  /// Creates a standard split row, with a helper text to one side and a child
  /// widget to the other.
  const CupertinoSplitFormRow({
    required this.text,
    this.helperText,
    this.errorText,
    required this.child,
    Key? key,
  }) : super(key: key);

  /// String for the text widget
  final String text;

  /// String for the text displayed underneath the text widget and child
  final String? helperText;

  /// String for the error text displayed underneath the text widget and child
  final String? errorText;

  /// Child widget shown next to the text widget
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
          widget.text,
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
