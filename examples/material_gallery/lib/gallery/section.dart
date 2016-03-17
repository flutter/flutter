// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'demo.dart';

class GallerySection extends StatelessWidget {
  GallerySection({ this.title, this.image, this.colors, this.demos });

  final String title;
  final String image;
  final Map<int, Color> colors;
  final List<GalleryDemo> demos;

  void showDemo(GalleryDemo demo, BuildContext context, ThemeData theme) {
    Navigator.push(context, new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        Widget child = (demo.builder == null) ? null : demo.builder();
        return new Theme(data: theme, child: child);
      }
    ));
  }

  void showDemos(BuildContext context) {
    final double statusBarHeight = (MediaQuery.of(context)?.padding ?? EdgeInsets.zero).top;
    final ThemeData theme = new ThemeData(
      brightness: Theme.of(context).brightness,
      primarySwatch: colors
    );
    final double appBarHeight = 200.0;
    final Key scrollableKey = new ValueKey<String>(title); // assume section titles differ
    Navigator.push(context, new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Theme(
          data: theme,
          child: new Scaffold(
            appBarBehavior: AppBarBehavior.under,
            scrollableKey: scrollableKey,
            appBar: new AppBar(
              expandedHeight: appBarHeight,
              flexibleSpace: (BuildContext context) => new FlexibleSpaceBar(title: new Text(title))
            ),
            body: new Material(
              child: new MaterialList(
                scrollableKey: scrollableKey,
                scrollablePadding: new EdgeInsets.only(top: appBarHeight + statusBarHeight),
                type: MaterialListType.oneLine,
                children: (demos ?? const <GalleryDemo>[]).map((GalleryDemo demo) {
                  return new ListItem(
                    title: new Text(demo.title),
                    onTap: () { showDemo(demo, context, theme); }
                  );
                })
              )
            )
          )
        );
      }
    ));
  }

  @override
  Widget build (BuildContext context) {
    final ThemeData theme = new ThemeData(
      brightness: Theme.of(context).brightness,
      primarySwatch: colors
    );
    final TextStyle titleTextStyle = theme.textTheme.title.copyWith(
      color: Colors.white
    );
    return new Flexible(
      child: new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { showDemos(context); },
        child: new Container(
          height: 256.0,
          margin: const EdgeInsets.all(4.0),
          decoration: new BoxDecoration(backgroundColor: theme.primaryColor),
          child: new Column(
            children: <Widget>[
              new Flexible(
                child: new Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: new AssetImage(
                    name: image,
                    alignment: const FractionalOffset(0.5, 0.5),
                    fit: ImageFit.contain
                  )
                )
              ),
              new Padding(
                padding: const EdgeInsets.all(16.0),
                child: new Align(
                  alignment: const FractionalOffset(0.0, 1.0),
                  child: new Text(title, style: titleTextStyle)
                )
              )
            ]
          )
        )
      )
    );
  }
}
