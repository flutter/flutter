// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TextStyleItem extends StatelessWidget {
  const TextStyleItem({
    Key? key,
    required this.name,
    required this.style,
    required this.text,
  }) : super(key: key);

  final String name;
  final TextStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle nameStyle = theme.textTheme.caption!.copyWith(color: theme.textTheme.caption!.color);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72.0,
            child: Text(name, style: nameStyle),
          ),
          Expanded(
            child: Text(text, style: style.copyWith(height: 1.0)),
          ),
        ],
      ),
    );
  }
}

class TypographyDemo extends StatelessWidget {
  const TypographyDemo({Key? key}) : super(key: key);

  static const String routeName = '/typography';

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> styleItems = <Widget>[
      if (MediaQuery.of(context).size.width > 500.0)
        TextStyleItem(name: 'Headline 1', style: textTheme.headline1!, text: 'Light 112sp'),
      TextStyleItem(name: 'Headline 2', style: textTheme.headline2!, text: 'Regular 56sp'),
      TextStyleItem(name: 'Headline 3', style: textTheme.headline3!, text: 'Regular 45sp'),
      TextStyleItem(name: 'Headline 4', style: textTheme.headline4!, text: 'Regular 34sp'),
      TextStyleItem(name: 'Headline 5', style: textTheme.headline5!, text: 'Regular 24sp'),
      TextStyleItem(name: 'Headline 6', style: textTheme.headline6!, text: 'Medium 20sp'),
      TextStyleItem(name: 'Subtitle 1', style: textTheme.subtitle1!, text: 'Regular 16sp'),
      TextStyleItem(name: 'Body 1', style: textTheme.bodyText1!, text: 'Medium 14sp'),
      TextStyleItem(name: 'Body 2', style: textTheme.bodyText2!, text: 'Regular 14sp'),
      TextStyleItem(name: 'Caption', style: textTheme.caption!, text: 'Regular 12sp'),
      TextStyleItem(name: 'Button', style: textTheme.button!, text: 'MEDIUM (ALL CAPS) 14sp'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Typography')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Scrollbar(child: ListView(children: styleItems)),
      ),
    );
  }
}
