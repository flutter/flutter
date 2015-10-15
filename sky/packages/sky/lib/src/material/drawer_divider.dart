// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

class DrawerDivider extends StatelessComponent {
  const DrawerDivider({ Key key }) : super(key: key);

  Widget build(BuildContext context) {
    return new Container(
      height: 0.0,
      decoration: new BoxDecoration(
        border: new Border(
          bottom: new BorderSide(
            color: Theme.of(context).dividerColor
          )
        )
      ),
      margin: const EdgeDims.symmetric(vertical: 8.0)
    );
  }
}
