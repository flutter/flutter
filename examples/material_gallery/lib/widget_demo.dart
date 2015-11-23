// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class WidgetDemo {
  WidgetDemo({ this.title, this.route, this.builder });

  final String title;
  final String route;
  final WidgetBuilder builder;
}
