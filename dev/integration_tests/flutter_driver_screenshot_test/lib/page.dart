// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// The base class for all the pages in this test.
abstract class PageWidget extends StatelessWidget {

  /// Constructs a `Page` object.
  const PageWidget({@required this.title, @required Key key}):super(key: key);

  /// The text that shows on the list item on the main page as well as the navigation bar on the sub page.
  final String title;
}
