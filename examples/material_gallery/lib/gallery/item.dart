// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';

typedef Widget GalleryDemoBuilder();

class GalleryItem extends StatelessWidget {
  GalleryItem({ this.title, this.icon, this.routeName });

  final String title;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    Widget leading = icon == null ? new Container() : new Icon(icon: icon);

    return new TwoLevelListItem(
      leading: leading,
      title: new Text(title),
      onTap: () {
        if (routeName != null) {
          Timeline.instantSync('Start Transition', arguments: <String, String>{
            'from': '/',
            'to': routeName
          });
          Navigator.pushNamed(context, routeName);
        }
      }
    );
  }
}
