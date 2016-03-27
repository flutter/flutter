// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

/// A widget that has exactly one inflated instance in the tree.
abstract class UniqueWidget<T extends State> extends StatefulWidget {
  UniqueWidget({ GlobalKey key }) : super(key: key) {
    assert(key != null);
  }

  @override
  T createState();

  /// The state for the unique inflated instance of this widget.
  T get currentState {
    GlobalKey globalKey = key;
    return globalKey.currentState;
  }
}
