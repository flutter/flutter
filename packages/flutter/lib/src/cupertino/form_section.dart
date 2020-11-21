// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Used for iOS notched-style padding. The top edge has no padding to provide
// more freedom to the section header.
const EdgeInsetsDirectional _kDefaultPaddedRowsPadding =
    EdgeInsetsDirectional.fromSTEB(16.5, 0.0, 16.5, 16.5);

// Used to differentiate the edge-to-edge section with the centered section.
enum _CupertinoFormSectionType { base, padded }

/// An iOS-style form section.
///
/// The base constructor for [CupertinoFormSection] constructs an
/// edge-to-edge style section which includes an iOS-style header, footer, rows,
/// the dividers between rows, and borders on top and bottom of the rows.
///
/// The [CupertinoFormSection.padded] constructor creates a round-edged and
/// padded section that is commonly seen in notched-displays like iPhone X and
/// beyond. Creates an iOS-style header, footer, rows, and the dividers
/// between rows. Does not create borders on top and bottom of the rows.
///
/// The [header] parameter sets the form section header. The section header lies
/// above the [children] rows.
///
/// The [children] parameter is required and sets the list of rows shown in
/// the section. The [children] parameter takes a list, as opposed to a more
/// efficient builder function that lazy builds, because forms are intended to
/// be short in row count. It is recommended that only [CupertinoFormRow] and
/// [CupertinoTextFormFieldRow] widgets be included in the [children] list in
/// order to retain the iOS look.
///
/// The [margin] parameter sets the padding for the [Column] encapsulating
/// [children].
///
/// The [borderRadius] parameter sets the circular border radius for the
/// [Column] encapsulating [children] rows.
///
/// The [decoration] parameter sets the decoration for the section. Defaults to
/// a [CupertinoColors.secondarySystemBackground] background color.
class CupertinoFormSection extends StatelessWidget {
  /// Creates a section that mimicks standard iOS forms.
  ///
  /// The base constructor for [CupertinoFormSection] constructs an
  /// edge-to-edge style section which includes an iOS-style header, footer,
  /// rows, the dividers between rows, and borders on top and bottom of the rows.
  ///
  /// The [header] parameter sets the form section header. The section header
  /// lies above the [children] rows.
  ///
  /// The [children] parameter is required and sets the list of rows shown in
  /// the section. The [children] parameter takes a list, as opposed to a more
  /// efficient builder function that lazy builds, because forms are intended to
  /// be short in row count. It is recommended that only [CupertinoFormRow] and
  /// [CupertinoTextFormFieldRow] widgets be included in the [children] list in
  /// order to retain the iOS look.
  ///
  /// The [margin] parameter sets the padding for the [Column] encapsulating
  /// [children], and defaults to zero padding.
  ///
  /// The [borderRadius] parameter sets the circular border radius for the
  /// [Column] encapsulating [children] rows. Defaults to 0.0 for the standard
  /// edge-to-edge style.
  ///
  /// The [decoration] parameter sets the decoration for the section. Defaults
  /// to a [CupertinoColors.secondarySystemBackground] background color.
  const CupertinoFormSection({
    Key? key,
    required this.children,
    this.header,
    this.margins = EdgeInsets.zero,
    this.borderRadius = 0.0,
    this.decoration =
        const BoxDecoration(color: CupertinoColors.secondarySystemBackground),
  })  : _type = _CupertinoFormSectionType.base,
        assert(children.length > 0),
        super(key: key);

  /// Creates a section that mimicks standard iOS forms.
  ///
  /// The [CupertinoFormSection.padded] constructor creates a round-edged and
  /// padded section that is commonly seen in notched-displays like iPhone X and
  /// beyond. Creates an iOS-style header, footer, rows, and the dividers
  /// between rows. Does not create borders on top and bottom of the rows.
  ///
  /// The [header] parameter sets the form section header. The section header
  /// lies above the [children] rows.
  ///
  /// The [children] parameter is required and sets the list of rows shown in
  /// the section. The [children] parameter takes a list, as opposed to a more
  /// efficient builder function that lazy builds, because forms are intended to
  /// be short in row count. It is recommended that only [CupertinoFormRow] and
  /// [CupertinoTextFormFieldRow] widgets be included in the [children] list in
  /// order to retain the iOS look.
  ///
  /// The [margins] parameter sets the padding for the [Column] encapsulating
  /// [children], and defaults to the standard notched-style iOS form padding.
  ///
  /// The [borderRadius] parameter sets the circular border radius for the
  /// [Column] encapsulating [children] rows. Defaults to 10.0 for the standard
  /// edge-to-edge style.
  ///
  /// The [decoration] parameter sets the decoration for the section. Defaults
  /// to a [CupertinoColors.secondarySystemBackground] background color.
  const CupertinoFormSection.padded({
    Key? key,
    required this.children,
    this.header,
    this.margins = _kDefaultPaddedRowsPadding,
    this.borderRadius = 10.0,
    this.decoration =
        const BoxDecoration(color: CupertinoColors.secondarySystemBackground),
  })  : _type = _CupertinoFormSectionType.padded,
        assert(children.length > 0),
        super(key: key);

  final _CupertinoFormSectionType _type;

  /// Sets the form section header. The section header lies above the
  /// [children] rows.
  final Widget? header;

  /// Padding for the the [Column] encapsulating the [children].
  ///
  /// Defaults to zero padding if constructed with standard
  /// [CupertinoFormSection] constructor. Defaults to the standard notched-style
  /// iOS padding when constructing with [CupertinoFormSection.padded].
  final EdgeInsetsGeometry margins;

  /// The list of rows in the section.
  ///
  /// This takes a list, as opposed to a more efficient builder function that
  /// lazy builds, because forms are intended to be short in row count. It is
  /// recommended that only [CupertinoFormRow] and [CupertinoTextFormFieldRow]
  /// widgets be included in the [children] list in order to retain the iOS look.
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
  Widget build(BuildContext context) {
    // Long divider is used for wrapping the top and bottom of rows.
    // Only used in _CupertinoFormSectionType.base mode
    final Widget longDivider = Container(
      color: CupertinoColors.separator,
      height: 0.5,
    );

    // Short divider is used between rows.
    final Widget shortDivider = Container(
      margin: const EdgeInsetsDirectional.only(start: 15),
      color: CupertinoColors.separator,
      height: 0.5,
    );

    // We construct childrenWithDividers as follows:
    // Insert a short divider between all rows.
    // If it is a `_CupertinoFormSectionType.base` type, add a long divider
    // to the top and bottom of the rows.
    assert(children.isNotEmpty);

    final List<Widget> childrenWithDividers = <Widget>[];

    if (_type == _CupertinoFormSectionType.base) {
      childrenWithDividers.add(longDivider);
    }

    children.sublist(0, children.length - 1).forEach((Widget widget) {
      childrenWithDividers.add(widget);
      childrenWithDividers.add(shortDivider);
    });

    childrenWithDividers.add(children.last);
    if (_type == _CupertinoFormSectionType.base) {
      childrenWithDividers.add(longDivider);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CupertinoColors.secondarySystemBackground,
      ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: (header == null)
                ? null
                : DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    child: header!,
                  ),
          ),
          Padding(
            padding: margins,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemBackground,
                ),
                child: Column(
                  children: childrenWithDividers,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
