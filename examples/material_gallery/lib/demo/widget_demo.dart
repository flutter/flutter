// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class WidgetDemo {
  WidgetDemo({ this.title, this.routeName, this.tabBarBuilder, this.builder });

  final String title;
  final String routeName;
  final WidgetBuilder tabBarBuilder;
  final WidgetBuilder builder;
}
