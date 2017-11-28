// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TextStyleItem extends StatelessWidget {
  const TextStyleItem({
    Key key,
    @required this.name,
    @required this.style,
    @required this.text,
  }) : assert(name != null),
       assert(style != null),
       assert(text != null),
       super(key: key);

  final String name;
  final TextStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle nameStyle = theme.textTheme.caption.copyWith(color: theme.textTheme.caption.color);
    return new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new SizedBox(
            width: 72.0,
            child: new Text(name, style: nameStyle)
          ),
          new Expanded(
            child: new Text(text, style: style.copyWith(height: 1.0))
          )
        ]
      )
    );
  }
}

class TypographyDemo extends StatelessWidget {
  static const String routeName = '/typography';

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> styleItems = <Widget>[
      new TextStyleItem(name: 'Display 3', style: textTheme.display3, text: 'Regular 56sp'),
      new TextStyleItem(name: 'Display 2', style: textTheme.display2, text: 'Regular 45sp'),
      new TextStyleItem(name: 'Display 1', style: textTheme.display1, text: 'Regular 34sp'),
      new TextStyleItem(name: 'Headline', style: textTheme.headline, text: 'Regular 24sp'),
      new TextStyleItem(name: 'Title', style: textTheme.title, text: 'Medium 20sp'),
      new TextStyleItem(name: 'Subheading', style: textTheme.subhead, text: 'Regular 16sp'),
      new TextStyleItem(name: 'Body 2', style: textTheme.body2, text: 'Medium 14sp'),
      new TextStyleItem(name: 'Body 1', style: textTheme.body1, text: 'Regular 14sp'),
      new TextStyleItem(name: 'Caption', style: textTheme.caption, text: 'Regular 12sp'),
      new TextStyleItem(name: 'Button', style: textTheme.button, text: 'MEDIUM (ALL CAPS) 14sp')
    ];

    if (MediaQuery.of(context).size.width > 500.0) {
      styleItems.insert(0, new TextStyleItem(
        name: 'Display 4',
        style: textTheme.display4,
        text: 'Light 112sp'
      ));
    }

    return new Scaffold(
      appBar: new AppBar(title: const Text('Typography')),
      body: new ListView(children: styleItems)
    );
  }
}
