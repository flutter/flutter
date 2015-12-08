// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'debug.dart';
import 'theme.dart';

// TODO(jackson): This class should usually render the user's
// preferred banner image rather than a solid background

class DrawerHeader extends StatelessComponent {
  const DrawerHeader({ Key key, this.child }) : super(key: key);

  final Widget child;

  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new Container(
      height: kStatusBarHeight + kMaterialDrawerHeight,
      decoration: new BoxDecoration(
        backgroundColor: Theme.of(context).cardColor,
        border: const Border(
          bottom: const BorderSide(
            color: const Color(0xFFD1D9E1),
            width: 1.0
          )
        )
      ),
      padding: const EdgeDims.only(bottom: 7.0),
      margin: const EdgeDims.only(bottom: 8.0),
      child: new Column(<Widget>[
        new Flexible(child: new Container()),
        new Container(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new DefaultTextStyle(
            style: Theme.of(context).text.body2,
            child: child
          )
        )]
      )
    );
  }
}
