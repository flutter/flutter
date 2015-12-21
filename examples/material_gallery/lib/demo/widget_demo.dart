// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef Widget PageWrapperBuilder(BuildContext context, Widget child);

class WidgetDemo {
  WidgetDemo({
    this.title,
    this.routeName,
    this.tabBarBuilder,
    this.pageWrapperBuilder,
    this.floatingActionButtonBuilder,
    this.builder
  });

  final String title;
  final String routeName;
  final WidgetBuilder tabBarBuilder;
  final PageWrapperBuilder pageWrapperBuilder;
  final WidgetBuilder floatingActionButtonBuilder;
  final WidgetBuilder builder;
}
