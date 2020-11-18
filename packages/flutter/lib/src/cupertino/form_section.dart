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
///
/// The standard constructor for [CupertinoFormSection] constructs an
/// edge-to-edge style section. The [CupertinoFormSection.centered] constructor
/// creates a round-edged and padded section that is commonly seen in
/// notched-displays like iPhone X and beyond.
///
/// [title] sets the form section title. [titlePadding] sets the title's
/// padding.
///
/// [children] sets the list of rows shown in the section. It is type-agnostic
/// but recommended that only [CupertinoSplitFormRow] and
/// [CupertinoTextFormField] widgets be included, to retain the iOS look.
///
/// [rowsPadding] sets the padding for [children].
///
/// [borderRadius] sets the circular border radius for the [Column]
/// encapsulating [children] rows.
///
/// [decoration] sets the decoration for the section. Defaults to a
/// [CupertinoColors.secondarySystemBackground] background color.
class CupertinoFormSection extends StatefulWidget {
  /// A section that mimicks standard iOS forms.
  ///
  /// This constructor returns a [CupertinoFormSection] with standard
  /// edge-to-edge styling.
  ///
  /// [title] sets the form section title. [titlePadding] sets the title's
  /// padding, and defaults to the standard iOS padding, which is determined
  /// using https://github.com/flutter/platform_tests/tree/master/ios_widget_catalog_compare.
  ///
  /// [children] sets the list of rows shown in the section. It is type-agnostic
  /// but recommended that only [CupertinoSplitFormRow] and
  /// [CupertinoTextFormField] widgets be included, to retain the iOS look.
  ///
  /// [rowsPadding] sets the padding for the [Column] encapsulating [children],
  /// and defaults to zero padding.
  ///
  /// [borderRadius] sets the circular border radius for the [Column]
  /// encapsulating [children] rows. Defaults to 0.0 for the standard
  /// edge-to-edge style.
  ///
  /// [decoration] sets the decoration for the section. Defaults to a
  /// [CupertinoColors.secondarySystemBackground] background color.
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

  /// Creates a round-edged and padded form section that is commonly seen in
  /// notched-displays like iPhone X and beyond.
  ///
  /// [title] sets the form section title. [titlePadding] sets the title's
  /// padding, and defaults to the standard iOS padding, which is determined
  /// using https://github.com/flutter/platform_tests/tree/master/ios_widget_catalog_compare.
  ///
  /// [children] sets the list of rows shown in the section. It is type-agnostic
  /// but recommended that only [CupertinoSplitFormRow] and
  /// [CupertinoTextFormField] widgets be included, to retain the iOS look.
  ///
  /// [rowsPadding] sets the padding for the [Column] encapsulating [children],
  /// and defaults to the standard notched-style iOS padding, which is
  /// determined using https://github.com/flutter/platform_tests/tree/master/ios_widget_catalog_compare.
  ///
  /// [borderRadius] sets the circular border radius for the [Column]
  /// encapsulating [children] rows. Defaults to 10.0 for the standard
  /// edge-to-edge style.
  ///
  /// [decoration] sets the decoration for the section. Defaults to a
  /// [CupertinoColors.secondarySystemBackground] background color.
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

  /// Sets the form section title.
  final String? title;

  /// Sets padding for the section title.
  ///
  /// Defaults to the standard iOS padding, which is determined
  /// using https://github.com/flutter/platform_tests/tree/master/ios_widget_catalog_compare.
  final EdgeInsetsGeometry titlePadding;

  /// Padding for the the [Column] encapsulating the [children].
  ///
  /// Defaults to zero padding if constructed with standard
  /// [CupertinoFormSection] constructor. Defaults to the standard notched-style
  /// iOS padding when constructing with [CupertinoFormSection.centered].
  /// Determined using https://github.com/flutter/platform_tests/tree/master/ios_widget_catalog_compare.
  final EdgeInsetsGeometry rowsPadding;

  /// The list of rows in the section.
  final List<Widget> children;

  /// Sets the decoration for the section.
  ///
  /// Defaults to a [CupertinoColors.secondarySystemBackground] background
  /// color.
  final BoxDecoration decoration;

  /// Sets the circular border radius for the [Column] encapsulating [children]
  /// rows.
  ///
  /// Defaults to 0.0 when constructed with standard [CupertinoFormSection]
  /// constructor. Defaults to 10.0 when constructing with
  /// [CupertinoFormSection.centered].
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
