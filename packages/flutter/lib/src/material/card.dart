// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material.dart';

/// A material design card
///
/// See also:
///
///  * [Dialog]
///  * [showDialog]
///  * <https://material.google.com/components/cards.html>
class Card extends StatelessWidget {
  /// Creates a material design card.
  const Card({
    Key key,
    this.color,
    this.elevation: 2,
    this.child
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The color of material used for this card.
  final Color color;

  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.all(4.0),
      child: new Material(
        color: color,
        type: MaterialType.card,
        elevation: elevation,
        child: child
      )
    );
  }
}
