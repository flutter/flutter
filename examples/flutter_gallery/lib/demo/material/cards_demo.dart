// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

const String _kGalleryAssetsPackage = 'flutter_gallery_assets';

enum CardDemoType {
  standard,
  tappable,
  selectable,
}

class TravelDestination {
  TravelDestination({
    @required this.assetName,
    @required this.assetPackage,
    @required this.title,
    @required this.description,
    this.type = CardDemoType.standard,
  }) : assert(assetName != null),
       assert(assetPackage != null),
       assert(title != null),
       assert(description != null && description?.length == 3);

  final String assetName;
  final String assetPackage;
  final String title;
  final List<String> description;
  final CardDemoType type;
}

final List<TravelDestination> destinations = <TravelDestination>[
  TravelDestination(
    assetName: 'places/india_thanjavur_market.png',
    assetPackage: _kGalleryAssetsPackage,
    title: 'Top 10 Cities to Visit in Tamil Nadu',
    description: <String>[
      'Number 10',
      'Thanjavur',
      'Thanjavur, Tamil Nadu',
    ],
  ),
  TravelDestination(
    assetName: 'places/india_chettinad_silk_maker.png',
    assetPackage: _kGalleryAssetsPackage,
    title: 'Artisans of Southern India',
    description: <String>[
      'Silk Spinners',
      'Chettinad',
      'Sivaganga, Tamil Nadu',
    ],
    type: CardDemoType.tappable,
  ),
  TravelDestination(
    assetName: 'places/india_tanjore_thanjavur_temple.png',
    assetPackage: _kGalleryAssetsPackage,
    title: 'Brihadisvara Temple',
    description: <String>[
      'Temples',
      'Thanjavur',
      'Thanjavur, Tamil Nadu',
    ],
    type: CardDemoType.selectable,
  )
];

class TravelDestinationItem extends StatelessWidget {
  const TravelDestinationItem({ Key key, @required this.destination, this.shape })
    : assert(destination != null),
      super(key: key);

  // This height will allow for all the Card's content to fit comfortably within the card.
  static const double height = 366.0;
  final TravelDestination destination;
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            const SectionTitle(title: 'Card with actions'),
            SizedBox(
              height: height,
              child: Card(
                // This ensures that the Card's children are clipped correctly.
                clipBehavior: Clip.antiAlias,
                shape: shape,
                child: TravelDestinationContent(destination: destination),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TappableTravelDestinationItem extends StatelessWidget {
  const TappableTravelDestinationItem({ Key key, @required this.destination, this.shape })
    : assert(destination != null),
      super(key: key);

  // This height will allow for all the Card's content to fit comfortably within the card.
  static const double height = 312.0;
  final TravelDestination destination;
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            const SectionTitle(title: 'Card that can be tapped'),
            SizedBox(
              height: height,
              child: Card(
                // This ensures that the Card's children (including the ink splash) are clipped correctly.
                clipBehavior: Clip.antiAlias,
                shape: shape,
                child: InkWell(
                  onTap: () {
                    print('Card was tapped');
                  },
                  splashColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: TravelDestinationContent(destination: destination),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectableTravelDestinationItem extends StatefulWidget {
  const SelectableTravelDestinationItem({ Key key, @required this.destination, this.shape })
    : assert(destination != null),
      super(key: key);

  final TravelDestination destination;
  final ShapeBorder shape;

  @override
  _SelectableTravelDestinationItemState createState() => _SelectableTravelDestinationItemState();
}

class _SelectableTravelDestinationItemState extends State<SelectableTravelDestinationItem> {

  // This height will allow for all the Card's content to fit comfortably within the card.
  static const double height = 312.0;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            const SectionTitle(title: 'Card that can be selected'),
            SizedBox(
              height: height,
              child: Card(
                // This ensures that the Card's children (including the ink splash) are clipped correctly.
                clipBehavior: Clip.antiAlias,
                shape: widget.shape,
                child: InkWell(
                  onLongPress: () {
                    print('Selectable card state changed');
                    setState(() {
                      _isSelected = !_isSelected;
                    });
                  },
                  splashColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Stack(
                    children: <Widget>[
                      TravelDestinationContent(destination: widget.destination),
                      Container(
                        color: _isSelected
                          ? Theme.of(context).colorScheme.primary.withAlpha(41)
                          : Colors.transparent,
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.check_circle,
                            color: _isSelected ? Colors.white : Colors.transparent,
                          ),
                        )
                      ),
                    ],
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    Key key,
    this.title
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.subhead),
      ),
    );
  }
}

class TravelDestinationContent extends StatelessWidget {
  const TravelDestinationContent({ Key key, @required this.destination })
    : assert(destination != null),
      super(key: key);

  final TravelDestination destination;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = theme.textTheme.headline.copyWith(color: Colors.white);
    final TextStyle descriptionStyle = theme.textTheme.subhead;

    // In order to have the ink splash appear above the child image, you must
    // use Ink.image. This allows the image to become part of the Material and
    // display ink effects above it. Using a standard Image will obscure the ink
    // splash.
    final Widget image = destination.type == CardDemoType.standard
      ? Image.asset(
          destination.assetName,
          package: destination.assetPackage,
          fit: BoxFit.cover,
        )
      : Ink.image(
          image: AssetImage(destination.assetName, package: destination.assetPackage),
          fit: BoxFit.cover,
          child: Container(),
        );

    final List<Widget> children = <Widget>[
      // Photo and title.
      SizedBox(
        height: 184.0,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: image,
            ),
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  destination.title,
                  style: titleStyle,
                ),
              ),
            ),
          ],
        ),
      ),
      // Description and share/explore buttons.
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          child: DefaultTextStyle(
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: descriptionStyle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // three line description
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    destination.description[0],
                    style: descriptionStyle.copyWith(color: Colors.black54),
                  ),
                ),
                Text(destination.description[1]),
                Text(destination.description[2]),
              ],
            ),
          ),
        ),
      ),
    ];

    if (destination.type == CardDemoType.standard) {
      children.add(
        // share, explore buttons
        ButtonTheme.bar(
          child: ButtonBar(
            alignment: MainAxisAlignment.start,
            children: <Widget>[
              FlatButton(
                child: Text('SHARE', semanticsLabel: 'Share ${destination.title}'),
                textColor: Colors.amber.shade500,
                onPressed: () { print('pressed'); },
              ),
              FlatButton(
                child: Text('EXPLORE', semanticsLabel: 'Explore ${destination.title}'),
                textColor: Colors.amber.shade500,
                onPressed: () { print('pressed'); },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class CardsDemo extends StatefulWidget {
  static const String routeName = '/material/cards';

  @override
  _CardsDemoState createState() => _CardsDemoState();
}

class _CardsDemoState extends State<CardsDemo> {
  ShapeBorder _shape;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards'),
        actions: <Widget>[
          MaterialDemoDocumentationButton(CardsDemo.routeName),
          IconButton(
            icon: const Icon(
              Icons.sentiment_very_satisfied,
              semanticLabel: 'update shape',
            ),
            onPressed: () {
              setState(() {
                _shape = _shape != null ? null : const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                    bottomLeft: Radius.circular(2.0),
                    bottomRight: Radius.circular(2.0),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        children: destinations.map<Widget>((TravelDestination destination) {
          Widget child;
          switch (destination.type) {
            case CardDemoType.standard:
              child = TravelDestinationItem(destination: destination, shape: _shape);
              break;
            case CardDemoType.tappable:
              child = TappableTravelDestinationItem(destination: destination, shape: _shape);
              break;
            case CardDemoType.selectable:
              child = SelectableTravelDestinationItem(destination: destination, shape: _shape);
              break;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: child,
          );
        }).toList()
      )
    );
  }
}
