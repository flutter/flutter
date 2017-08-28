// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'feedback.dart';
import 'icons.dart';
import 'tooltip.dart';

const double _kChipHeight = 32.0;
const double _kAvatarDiamater = _kChipHeight;

const TextStyle _kLabelStyle = const TextStyle(
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w400,
  color: Colors.black87,
  textBaseline: TextBaseline.alphabetic,
);

/// A material design chip.
///
/// Chips represent complex entities in small blocks, such as a contact.
///
/// Supplying a non-null [onDeleted] callback will cause the chip to include a
/// button for deleting the chip.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// ## Sample code
///
/// ```dart
/// new Chip(
///   avatar: new CircleAvatar(
///     backgroundColor: Colors.grey.shade800,
///     child: new Text('AB'),
///   ),
///   label: new Text('Aaron Burr'),
/// )
/// ```
///
/// See also:
///
///  * [CircleAvatar], which shows images or initials of people.
///  * <https://material.google.com/components/chips.html>
class Chip extends StatelessWidget {
  /// Creates a material design chip.
  ///
  ///  * [onDeleted] determines whether the chip has a delete button. This
  ///    callback runs when the delete button is pressed.
  const Chip({
    Key key,
    this.avatar,
    @required this.label,
    this.onDeleted,
    this.labelStyle,
    this.deleteButtonTooltipMessage,
    this.backgroundColor,
    this.deleteIconColor,
  }) : super(key: key);

  /// A widget to display prior to the chip's label.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget avatar;

  /// The primary content of the chip.
  ///
  /// Typically a [Text] widget.
  final Widget label;

  /// Called when the user deletes the chip, e.g., by tapping the delete button.
  ///
  /// The delete button is included in the chip only if this callback is non-null.
  final VoidCallback onDeleted;

  /// The style to be applied to the chip's label.
  ///
  /// This only has effect on widgets that respect the [DefaultTextStyle],
  /// such as [Text].
  final TextStyle labelStyle;

  /// Color to be used for the chip's background, the default being grey.
  ///
  /// This color is used as the background of the container that will hold the
  /// widget's label.
  final Color backgroundColor;

  /// Color for delete icon, the default being black.
  ///
  /// This has no effect when [onDelete] is null since no delete icon will be
  /// shown.
  final Color deleteIconColor;

  /// Message to be used for the chip delete button's tooltip.
  ///
  /// This has no effect when [onDelete] is null since no delete icon will be
  /// shown.
  final String deleteButtonTooltipMessage;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final bool deletable = onDeleted != null;
    double startPadding = 12.0;
    double endPadding = 12.0;

    final List<Widget> children = <Widget>[];

    if (avatar != null) {
      startPadding = 0.0;
      children.add(new ExcludeSemantics(
        child: new Container(
          margin: const EdgeInsetsDirectional.only(end: 8.0),
          width: _kAvatarDiamater,
          height: _kAvatarDiamater,
          child: avatar,
        ),
      ));
    }

    children.add(new Flexible(
      child: new DefaultTextStyle(
        style: labelStyle ?? _kLabelStyle,
        child: label,
      ),
    ));

    if (deletable) {
      endPadding = 0.0;
      children.add(new GestureDetector(
        onTap: Feedback.wrapForTap(onDeleted, context),
        child: new Tooltip(
          message: deleteButtonTooltipMessage ?? 'Delete "$label"',
          child: new Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: new Icon(
              Icons.cancel,
              size: 18.0,
              color: deleteIconColor ?? Colors.black54,
            ),
          ),
        ),
      ));
    }

    return new Semantics(
      container: true,
      child: new Container(
        height: _kChipHeight,
        padding: new EdgeInsetsDirectional.only(start: startPadding, end: endPadding),
        decoration: new BoxDecoration(
          color: backgroundColor ?? Colors.grey.shade300,
          borderRadius: new BorderRadius.circular(16.0),
        ),
        child: new Row(
          children: children,
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }
}
