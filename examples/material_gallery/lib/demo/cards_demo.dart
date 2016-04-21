// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TravelDestination {
  const TravelDestination({ this.assetName, this.title, this.description });

  final String assetName;
  final String title;
  final List<String> description;

  bool get isValid => assetName != null && title != null && description?.length == 3;
}

final List<TravelDestination> destinations = <TravelDestination>[
  const TravelDestination(
    assetName: 'packages/flutter_gallery_assets/top_10_australian_beaches.png',
    title: 'Top 10 Australian beaches',
    description: const <String>[
      'Number 10',
      'Whitehaven Beach',
      'Whitsunday Island, Whitsunday Islands'
    ]
  ),
  const TravelDestination(
    assetName: 'packages/flutter_gallery_assets/kangaroo_valley_safari.png',
    title: 'Kangaroo Valley Safari',
    description: const <String>[
      '2031 Moss Vale Road',
      'Kangaroo Valley 2577',
      'New South Wales'
    ]
  )
];

class TravelDestinationItem extends StatelessWidget {
  TravelDestinationItem({ Key key, this.destination }) : super(key: key) {
    assert(destination != null && destination.isValid);
  }

  static final double height = 328.0;
  final TravelDestination destination;


  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle titleStyle = theme.textTheme.headline.copyWith(color: Colors.white);
    TextStyle descriptionStyle = theme.textTheme.subhead;
    TextStyle buttonStyle = theme.textTheme.button.copyWith(color: theme.primaryColor);

    return new SizedBox(
      height: height,
      child: new Card(
        child: new Column(
          children: <Widget>[
            // photo and title
            new SizedBox(
              height: 184.0,
              child: new Stack(
                children: <Widget>[
                  new Positioned(
                    left: 0.0,
                    top: 0.0,
                    bottom: 0.0,
                    right: 0.0,
                    child: new AssetImage(
                      name: destination.assetName,
                      fit: ImageFit.cover
                    )
                  ),
                  new Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    child: new Text(destination.title, style: titleStyle)
                  )
                ]
              )
            ),
            // description and share/expore buttons
            new Flexible(
              child: new Padding(
                padding: const EdgeInsets.all(16.0),
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // three line description
                    new Text(destination.description[0], style: descriptionStyle),
                    new Text(destination.description[1], style: descriptionStyle),
                    new Text(destination.description[2], style: descriptionStyle),
                    // share, explore buttons
                    new Flexible(
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: new Text('SHARE', style: buttonStyle)
                          ),
                          new Text('EXPLORE', style: buttonStyle)
                        ]
                      )
                    )
                  ]
                )
              )
            )
          ]
        )
      )
    );
  }
}

class CardsDemo extends StatelessWidget {
  static const String routeName = '/cards';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Travel stream')
      ),
      body: new ScrollableList(
        itemExtent: TravelDestinationItem.height,
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        children: destinations.map((TravelDestination destination) {
          return new Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: new TravelDestinationItem(destination: destination)
          );
        })
        .toList()
      )
    );
  }
}
