// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material.dart';
import 'theme.dart';

/// A material design card. A card has slightly rounded corners and a shadow.
///
/// A card is a sheet of [Material] used to represent some related information,
/// for example an album, a geographical location, a meal, contact details, etc.
///
/// This is what it looks like when run:
///
/// ![A card with a slight shadow, consisting of two rows, one with an icon and
/// some text describing a musical, and the other with buttons for buying
/// tickets or listening to the show.](https://flutter.github.io/assets-for-api-docs/assets/material/card.png)
///
/// {@tool snippet --template=stateless_widget}
///
/// This sample shows creation of a [Card] widget that shows album information
/// and two actions.
///
/// ```dart
/// Center(
///   child: Card(
///     child: Column(
///       mainAxisSize: MainAxisSize.min,
///       children: <Widget>[
///         const ListTile(
///           leading: Icon(Icons.album),
///           title: Text('The Enchanted Nightingale'),
///           subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
///         ),
///         ButtonTheme.bar( // make buttons use the appropriate styles for cards
///           child: ButtonBar(
///             children: <Widget>[
///               FlatButton(
///                 child: const Text('BUY TICKETS'),
///                 onPressed: () { /* ... */ },
///               ),
///               FlatButton(
///                 child: const Text('LISTEN'),
///                 onPressed: () { /* ... */ },
///               ),
///             ],
///           ),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ListTile], to display icons and text in a card.
///  * [ButtonBar], to display buttons at the bottom of a card. Typically these
///    would be styled using a [ButtonTheme] created with [new ButtonTheme.bar].
///  * [showDialog], to display a modal card.
///  * <https://material.google.com/components/cards.html>
class Card extends StatelessWidget {
  /// Creates a material design card.
  ///
  /// The [clipBehavior] argument must not be null.
  const Card({
    Key key,
    this.color,
    this.elevation,
    this.shape,
    this.margin = const EdgeInsets.all(4.0),
    this.clipBehavior = Clip.none,
    this.child,
    this.semanticContainer = true,
  }) : super(key: key);

  /// The card's background color.
  ///
  /// Defines the card's [Material.color].
  ///
  /// The default color is defined by the ambient [Theme]: [ThemeData.cardColor].
  final Color color;

  /// The z-coordinate at which to place this card. This controls the size of
  /// the shadow below the card.
  ///
  /// Defines the card's [Material.elevation].
  ///
  /// The default elevation is 1.0.
  final double elevation;

  /// The shape of the card's [Material].
  ///
  /// Defines the card's [Material.shape].
  ///
  /// The default shape is a [RoundedRectangleBorder] with a circular corner
  /// radius of 4.0.
  final ShapeBorder shape;

  /// {@macro flutter.widgets.Clip}
  final Clip clipBehavior;

  /// The empty space that surrounds the card.
  ///
  /// Defines the card's outer [Container.margin].
  ///
  /// The default margin is 4.0 logical pixels on all sides:
  /// `EdgeInsets.all(4.0)`.
  final EdgeInsetsGeometry margin;

  /// Whether this widget represents a single semantic container, or if false
  /// a collection of individual semantic nodes.
  ///
  /// Defaults to true.
  ///
  /// Setting this flag to true will attempt to merge all child semantics into
  /// this node. Setting this flag to false will force all child semantic nodes
  /// to be explicit.
  ///
  /// This flag should be false if the card contains multiple different types
  /// of content.
  final bool semanticContainer;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: semanticContainer,
      explicitChildNodes: !semanticContainer,
      child: Container(
        margin: margin ?? const EdgeInsets.all(4.0),
        child: Material(
          type: MaterialType.card,
          color: color ?? Theme.of(context).cardColor,
          elevation: elevation ?? 1.0,
          shape: shape ?? const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
          clipBehavior: clipBehavior,
          child: child,
        ),
      ),
    );
  }
}
