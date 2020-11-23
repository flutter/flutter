// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Used for iOS "Inset Grouped" padding, determined from SwiftUI's Forms in
// iOS 14.2 SDK.
const EdgeInsetsDirectional _kDefaultInsetGroupedRowsPadding =
    EdgeInsetsDirectional.fromSTEB(16.5, 0.0, 16.5, 16.5);

// Used for iOS "Inset Grouped" border radius, estimated from SwiftUI's Forms in
// iOS 14.2 SDK.
// TODO(edrisian): This should be a rounded rectangle once that shape is added.
const BorderRadius _kDefaultInsetGroupedBorderRadius =
    BorderRadius.all(Radius.circular(10.0));

// Used to differentiate the edge-to-edge section with the centered section.
enum _CupertinoFormSectionType { base, insetGrouped }

/// An iOS-style form section.
///
/// The base constructor for [CupertinoFormSection] constructs an
/// edge-to-edge style section which includes an iOS-style header, footer, rows,
/// the dividers between rows, and borders on top and bottom of the rows.
///
/// The [CupertinoFormSection.insetGrouped] constructor creates a round-edged and
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
    this.borderRadius = BorderRadius.zero,
    this.decoration,
  })  : _type = _CupertinoFormSectionType.base,
        assert(children.length > 0),
        super(key: key);

  /// Creates a section that mimicks standard "Inset Grouped" iOS forms.
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
  const CupertinoFormSection.insetGrouped({
    Key? key,
    required this.children,
    this.header,
    this.margins = _kDefaultInsetGroupedRowsPadding,
    this.borderRadius = _kDefaultInsetGroupedBorderRadius,
    this.decoration,
  })  : _type = _CupertinoFormSectionType.insetGrouped,
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
  /// iOS padding when constructing with [CupertinoFormSection.insetGrouped].
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
  final BoxDecoration? decoration;

  /// Sets the border radius for the [Column] encapsulating [children]
  /// rows.
  ///
  /// Defaults to zero radius when constructed with standard [CupertinoFormSection]
  /// constructor. Defaults to 10.0 circular radius when constructing with
  /// [CupertinoFormSection.insetGrouped].
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Color dividerColor = CupertinoColors.separator.resolveFrom(context);
    const double dividerHeight = 0.5;

    // Long divider is used for wrapping the top and bottom of rows.
    // Only used in _CupertinoFormSectionType.base mode
    final Widget longDivider = Container(
      color: dividerColor,
      height: dividerHeight,
    );

    // Short divider is used between rows.
    // The value of the starting inset (15.0) is determined using SwiftUI's Form
    // seperators in the iOS 14.2 SDK.
    final Widget shortDivider = Container(
      margin: const EdgeInsetsDirectional.only(start: 15.0),
      color: dividerColor,
      height: dividerHeight,
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
      decoration: decoration ??
          BoxDecoration(
            color:
                CupertinoColors.secondarySystemBackground.resolveFrom(context),
          ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: header == null
                ? null
                : DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 13.5,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    child: header!,
                  ),
          ),
          Padding(
            padding: margins,
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Column(
                children: childrenWithDividers,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
