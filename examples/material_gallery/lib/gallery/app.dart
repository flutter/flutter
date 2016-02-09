// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'home.dart';

class GalleryApp extends StatefulComponent {
  GalleryApp({ Key key }) : super(key: key);

  static GalleryAppState of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<GalleryAppState>());

  GalleryAppState createState() => new GalleryAppState();
}

class GalleryAppState extends State<GalleryApp> {
  bool _lightTheme = true;
  bool get lightTheme => _lightTheme;
  void set lightTheme(bool value) {
    setState(() {
      _lightTheme = value;
    });
  }

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Material Gallery',
      theme: lightTheme ? new ThemeData.light() : new ThemeData.dark(),
      routes: {
        '/': (RouteArguments args) => new GalleryHome()
      }
    );
  }
}
