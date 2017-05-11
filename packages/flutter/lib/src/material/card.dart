// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material.dart';

/// A material design card. A card has slightly rounded corners and a shadow.
///
/// A card is a sheet of [Material] used to represent some related information,
/// for example an album, a geographical location, a meal, contact details, etc.
///
/// See also:
///
///  * [ListTile], to display icons and text in a card.
///  * [ButtonBar], to display buttons at the bottom of a card. Typically these
///    would be styled using a ButtonTheme created with [new ButtonTheme.bar].
///  * [showDialog], to display a modal card.
///  * <https://material.google.com/components/cards.html>
class Card extends StatelessWidget {
  /// Creates a material design card.
  const Card({
    Key key,
    this.color,
    this.elevation: 2.0,
    this.child
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The color of material used for this card.
  final Color color;

  /// The z-coordinate at which to place this card.
  ///
  /// Defaults to 2, the appropriate elevation for cards.
  final double elevation;

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
