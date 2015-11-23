// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class GalleryPage extends StatelessComponent {
  GalleryPage({ this.demo });

  final WidgetDemo demo;

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(center: new Text(demo.title)),
      body: demo.builder(context)
    );
  }
}
