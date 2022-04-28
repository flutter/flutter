// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';

// Standard header margin, determined from SwiftUI's Forms in iOS 14.2 SDK.
const EdgeInsetsDirectional _kDefaultHeaderMargin =
    EdgeInsetsDirectional.fromSTEB(20.0, 16.0, 20.0, 10.0);

// Standard footer margin, determined from SwiftUI's Forms in iOS 14.2 SDK.
const EdgeInsetsDirectional _kDefaultFooterMargin =
    EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 10.0);

// Used for iOS "Inset Grouped" margin, determined from SwiftUI's Forms in
// iOS 14.2 SDK.
const EdgeInsetsDirectional _kDefaultInsetGroupedRowsMargin =
    EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 10.0);

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
/// edge-to-edge style section which includes an iOS-style header, rows,
/// the dividers between rows, and borders on top and bottom of the rows.
///
/// The [CupertinoFormSection.insetGrouped] constructor creates a round-edged and
/// padded section that is commonly seen in notched-displays like iPhone X and
/// beyond. Creates an iOS-style header, rows, and the dividers
/// between rows. Does not create borders on top and bottom of the rows.
///
/// The [header] parameter sets the form section header. The section header lies
/// above the [children] rows, with margins that match the iOS style.
///
/// The [footer] parameter sets the form section footer. The section footer
/// lies below the [children] rows.
///
/// The [children] parameter is required and sets the list of rows shown in
/// the section. The [children] parameter takes a list, as opposed to a more
/// efficient builder function that lazy builds, because forms are intended to
/// be short in row count. It is recommended that only [CupertinoFormRow] and
/// [CupertinoTextFormFieldRow] widgets be included in the [children] list in
/// order to retain the iOS look.
///
/// The [margin] parameter sets the spacing around the content area of the
/// section encapsulating [children].
///
/// The [decoration] parameter sets the decoration around [children].
/// If null, defaults to [CupertinoColors.secondarySystemGroupedBackground].
/// If null, defaults to 10.0 circular radius when constructing with
/// [CupertinoFormSection.insetGrouped]. Defaults to zero radius for the
/// standard [CupertinoFormSection] constructor.
///
/// The [backgroundColor] parameter sets the background color behind the section.
/// If null, defaults to [CupertinoColors.systemGroupedBackground].
///
/// {@macro flutter.material.Material.clipBehavior}
class CupertinoFormSection extends StatelessWidget {
  /// Creates a section that mimics standard iOS forms.
  ///
  /// The base constructor for [CupertinoFormSection] constructs an
  /// edge-to-edge style section which includes an iOS-style header,
  /// rows, the dividers between rows, and borders on top and bottom of the rows.
  ///
  /// The [header] parameter sets the form section header. The section header
  /// lies above the [children] rows, with margins that match the iOS style.
  ///
  /// The [footer] parameter sets the form section footer. The section footer
  /// lies below the [children] rows.
  ///
  /// The [children] parameter is required and sets the list of rows shown in
  /// the section. The [children] parameter takes a list, as opposed to a more
  /// efficient builder function that lazy builds, because forms are intended to
  /// be short in row count. It is recommended that only [CupertinoFormRow] and
  /// [CupertinoTextFormFieldRow] widgets be included in the [children] list in
  /// order to retain the iOS look.
  ///
  /// The [margin] parameter sets the spacing around the content area of the
  /// section encapsulating [children], and defaults to zero padding.
  ///
  /// The [decoration] parameter sets the decoration around [children].
  /// If null, defaults to [CupertinoColors.secondarySystemGroupedBackground].
  /// If null, defaults to 10.0 circular radius when constructing with
  /// [CupertinoFormSection.insetGrouped]. Defaults to zero radius for the
  /// standard [CupertinoFormSection] constructor.
  ///
  /// The [backgroundColor] parameter sets the background color behind the
  /// section. If null, defaults to [CupertinoColors.systemGroupedBackground].
  ///
  /// {@macro flutter.material.Material.clipBehavior}
  const CupertinoFormSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin = EdgeInsets.zero,
    this.backgroundColor = CupertinoColors.systemGroupedBackground,
    this.decoration,
    this.clipBehavior = Clip.none,
  })  : _type = _CupertinoFormSectionType.base,
        assert(children.length > 0);

  /// Creates a section that mimics standard "Inset Grouped" iOS forms.
  ///
  /// The [CupertinoFormSection.insetGrouped] constructor creates a round-edged and
  /// padded section that is commonly seen in notched-displays like iPhone X and
  /// beyond. Creates an iOS-style header, rows, and the dividers
  /// between rows. Does not create borders on top and bottom of the rows.
  ///
  /// The [header] parameter sets the form section header. The section header
  /// lies above the [children] rows, with margins that match the iOS style.
  ///
  /// The [footer] parameter sets the form section footer. The section footer
  /// lies below the [children] rows.
  ///
  /// The [children] parameter is required and sets the list of rows shown in
  /// the section. The [children] parameter takes a list, as opposed to a more
  /// efficient builder function that lazy builds, because forms are intended to
  /// be short in row count. It is recommended that only [CupertinoFormRow] and
  /// [CupertinoTextFormFieldRow] widgets be included in the [children] list in
  /// order to retain the iOS look.
  ///
  /// The [margin] parameter sets the spacing around the content area of the
  /// section encapsulating [children], and defaults to the standard
  /// notched-style iOS form padding.
  ///
  /// The [decoration] parameter sets the decoration around [children].
  /// If null, defaults to [CupertinoColors.secondarySystemGroupedBackground].
  /// If null, defaults to 10.0 circular radius when constructing with
  /// [CupertinoFormSection.insetGrouped]. Defaults to zero radius for the
  /// standard [CupertinoFormSection] constructor.
  ///
  /// The [backgroundColor] parameter sets the background color behind the
  /// section. If null, defaults to [CupertinoColors.systemGroupedBackground].
  ///
  /// {@macro flutter.material.Material.clipBehavior}
  const CupertinoFormSection.insetGrouped({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin = _kDefaultInsetGroupedRowsMargin,
    this.backgroundColor = CupertinoColors.systemGroupedBackground,
    this.decoration,
    this.clipBehavior = Clip.none,
  })  : _type = _CupertinoFormSectionType.insetGrouped,
        assert(children.length > 0);

  final _CupertinoFormSectionType _type;

  /// Sets the form section header. The section header lies above the
  /// [children] rows.
  final Widget? header;

  /// Sets the form section footer. The section footer lies below the
  /// [children] rows.
  final Widget? footer;

  /// Margin around the content area of the section encapsulating [children].
  ///
  /// Defaults to zero padding if constructed with standard
  /// [CupertinoFormSection] constructor. Defaults to the standard notched-style
  /// iOS margin when constructing with [CupertinoFormSection.insetGrouped].
  final EdgeInsetsGeometry margin;

  /// The list of rows in the section.
  ///
  /// This takes a list, as opposed to a more efficient builder function that
  /// lazy builds, because forms are intended to be short in row count. It is
  /// recommended that only [CupertinoFormRow] and [CupertinoTextFormFieldRow]
  /// widgets be included in the [children] list in order to retain the iOS look.
  final List<Widget> children;

  /// Sets the decoration around [children].
  ///
  /// If null, background color defaults to
  /// [CupertinoColors.secondarySystemGroupedBackground].
  ///
  /// If null, border radius defaults to 10.0 circular radius when constructing
  /// with [CupertinoFormSection.insetGrouped]. Defaults to zero radius for the
  /// standard [CupertinoFormSection] constructor.
  final BoxDecoration? decoration;

  /// Sets the background color behind the section.
  ///
  /// Defaults to [CupertinoColors.systemGroupedBackground].
  final Color backgroundColor;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final Color dividerColor = CupertinoColors.separator.resolveFrom(context);
    final double dividerHeight = 1.0 / MediaQuery.of(context).devicePixelRatio;

    // Long divider is used for wrapping the top and bottom of rows.
    // Only used in _CupertinoFormSectionType.base mode
    final Widget longDivider = Container(
      color: dividerColor,
      height: dividerHeight,
    );

    // Short divider is used between rows.
    // The value of the starting inset (15.0) is determined using SwiftUI's Form
    // separators in the iOS 14.2 SDK.
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

    final BorderRadius childrenGroupBorderRadius;
    switch (_type) {
      case _CupertinoFormSectionType.insetGrouped:
        childrenGroupBorderRadius = _kDefaultInsetGroupedBorderRadius;
        break;
      case _CupertinoFormSectionType.base:
        childrenGroupBorderRadius = BorderRadius.zero;
        break;
    }

    // Refactored the decorate children group in one place to avoid repeating it
    // twice down bellow in the returned widget.
    final DecoratedBox decoratedChildrenGroup = DecoratedBox(
      decoration: decoration ?? BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          decoration?.color ?? CupertinoColors.secondarySystemGroupedBackground,
          context,
        ),
        borderRadius: childrenGroupBorderRadius,
      ),
      child: Column(
        children: childrenWithDividers,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(backgroundColor, context),
      ),
      child: Column(
        children: <Widget>[
          if (header != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13.0,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                child: Padding(
                  padding: _kDefaultHeaderMargin,
                  child: header,
                ),
              ),
            ),
          Padding(
            padding: margin,
            child: ClipRRect(
              borderRadius: childrenGroupBorderRadius,
              clipBehavior: clipBehavior,
              child: decoratedChildrenGroup,
            ),
          ),
          if (footer != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13.0,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                child: Padding(
                  padding: _kDefaultFooterMargin,
                  child: footer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
