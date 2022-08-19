// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TextStyleItem extends StatelessWidget {
  const TextStyleItem({
    super.key,
    required this.name,
    required this.style,
    required this.text,
  });

  final String name;
  final TextStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle nameStyle = theme.textTheme.bodySmall!.copyWith(color: theme.textTheme.bodySmall!.color);
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
  const TypographyDemo({super.key});

  static const String routeName = '/typography';

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> styleItems = <Widget>[
      if (MediaQuery.of(context).size.width > 500.0)
        TextStyleItem(name: 'Headline 1', style: textTheme.displayLarge!, text: 'Light 112sp'),
      TextStyleItem(name: 'Headline 2', style: textTheme.displayMedium!, text: 'Regular 56sp'),
      TextStyleItem(name: 'Headline 3', style: textTheme.displaySmall!, text: 'Regular 45sp'),
      TextStyleItem(name: 'Headline 4', style: textTheme.headlineMedium!, text: 'Regular 34sp'),
      TextStyleItem(name: 'Headline 5', style: textTheme.headlineSmall!, text: 'Regular 24sp'),
      TextStyleItem(name: 'Headline 6', style: textTheme.titleLarge!, text: 'Medium 20sp'),
      TextStyleItem(name: 'Subtitle 1', style: textTheme.titleMedium!, text: 'Regular 16sp'),
      TextStyleItem(name: 'Body 1', style: textTheme.bodyLarge!, text: 'Medium 14sp'),
      TextStyleItem(name: 'Body 2', style: textTheme.bodyMedium!, text: 'Regular 14sp'),
      TextStyleItem(name: 'Caption', style: textTheme.bodySmall!, text: 'Regular 12sp'),
      TextStyleItem(name: 'Button', style: textTheme.labelLarge!, text: 'MEDIUM (ALL CAPS) 14sp'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Typography')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Scrollbar(
          child: ListView(
            primary: true,
            children: styleItems,
          ),
        ),
      ),
    );
  }
}
