// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// The base class of all the testing pages
//
/// A testing page has to override this in order to be put as one of the items in the main page.
abstract class PageWidget extends StatelessWidget {
  const PageWidget(this.title, this.tileKey, {Key key}) : super(key: key);

  /// The title of the testing page
  ///
  /// It will be shown on the main page as the text on the link which opens the page.
  final String title;

  /// The key of the ListTile that navigates to the page.
  ///
  /// Used by the integration test to navigate to the corresponding page.
  final ValueKey<String> tileKey;
}
