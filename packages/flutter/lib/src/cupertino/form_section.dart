// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

export 'form_section.dart';

enum _CupertinoFormSectionType { base, centered }

/// A section that mimicks standard iOS forms.
class CupertinoFormSection extends StatefulWidget {
  /// A section that mimicks standard iOS forms.
  ///
  ///
  const CupertinoFormSection({
    this.title,
    this.titlePadding =
        const EdgeInsetsDirectional.fromSTEB(16.5, 16.0, 16.5, 10.0),
    this.rowsPadding =
        const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 10.0),
    this.borderRadius = 0.0,
    required this.children,
    this.decoration =
        const BoxDecoration(color: CupertinoColors.secondarySystemBackground),
  })  : _type = _CupertinoFormSectionType.base,
        super();

  /// A section that mimicks standard iOS forms with padded and rounded rows.
  const CupertinoFormSection.centered({
    this.title,
    this.titlePadding =
        const EdgeInsetsDirectional.fromSTEB(16.5, 16.0, 16.5, 10.0),
    this.rowsPadding =
        const EdgeInsetsDirectional.fromSTEB(16.5, 0.0, 16.5, 10.0),
    this.borderRadius = 10.0,
    required this.children,
    this.decoration =
        const BoxDecoration(color: CupertinoColors.secondarySystemBackground),
  })  : _type = _CupertinoFormSectionType.centered,
        super();

  final _CupertinoFormSectionType _type;

  /// Section title string
  final String? title;

  /// Padding for the section title
  final EdgeInsetsGeometry titlePadding;

  /// Padding for the section rows
  final EdgeInsetsGeometry rowsPadding;

  /// The list of rows in the section
  final List<Widget> children;

  /// Decoration for the section
  final BoxDecoration decoration;

  /// Border radius for the rows in the section. Not the section widget.
  final double borderRadius;

  @override
  State<StatefulWidget> createState() => _CupertinoFormSectionState();
}

class _CupertinoFormSectionState extends State<CupertinoFormSection> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const Divider longDivider = Divider(
      endIndent: 0,
      indent: 0,
      color: CupertinoColors.separator,
      height: 0.0,
    );

    const Divider shortDivider = Divider(
      endIndent: 0,
      indent: 15.0,
      color: CupertinoColors.separator,
      height: 0.0,
    );

    final List<Widget> children =
        (widget._type == _CupertinoFormSectionType.base)
            ? <Widget>[longDivider]
            : <Widget>[];

    widget.children
        .sublist(0, widget.children.length - 1)
        .forEach((Widget element) {
      children.add(element);
      children.add(shortDivider);
    });

    children.add(widget.children.last);
    if (widget._type == _CupertinoFormSectionType.base) {
      children.add(longDivider);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CupertinoColors.secondarySystemBackground,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: widget.titlePadding,
            child: Row(
              children: <Widget>[
                Text(
                  widget.title!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const Spacer()
              ],
            ),
          ),
          Padding(
            padding: widget.rowsPadding,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
