// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icons.dart';
import 'tooltip.dart';

const double _kChipHeight = 32.0;
const double _kAvatarDiamater = _kChipHeight;

const TextStyle _kLabelStyle = const TextStyle(
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w400,
  color: Colors.black87,
  textBaseline: TextBaseline.alphabetic
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
/// See also:
///
///  * [CircleAvatar]
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

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final bool deletable = onDeleted != null;
    double leftPadding = 12.0;
    double rightPadding = 12.0;

    final List<Widget> children = <Widget>[];

    if (avatar != null) {
      leftPadding = 0.0;
      children.add(new ExcludeSemantics(
        child: new Container(
          margin: const EdgeInsets.only(right: 8.0),
          width: _kAvatarDiamater,
          height: _kAvatarDiamater,
          child: avatar
        )
      ));
    }

    children.add(new DefaultTextStyle(
      style: _kLabelStyle,
      child: label
    ));

    if (deletable) {
      rightPadding = 0.0;
      children.add(new GestureDetector(
        onTap: onDeleted,
        child: new Tooltip(
          message: 'Delete "$label"',
          child: new Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: const Icon(
              Icons.cancel,
              size: 18.0,
              color: Colors.black54
            )
          )
        )
      ));
    }

    return new Semantics(
      container: true,
      child: new Container(
        height: _kChipHeight,
        padding: new EdgeInsets.only(left: leftPadding, right: rightPadding),
        decoration: new BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: new BorderRadius.circular(16.0)
        ),
        child: new Row(
          children: children,
          mainAxisSize: MainAxisSize.min
        )
      )
    );
  }
}
