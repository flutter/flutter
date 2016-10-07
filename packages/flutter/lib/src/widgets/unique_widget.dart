// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'framework.dart';

/// A widget that has exactly one inflated instance in the tree.
abstract class UniqueWidget<T extends State<StatefulWidget>> extends StatefulWidget {
  /// Creates a widget that has exactly one inflated instance in the tree.
  ///
  /// The [key] argument cannot be null because it identifies the unique
  /// inflated instance of this widget.
  UniqueWidget({
    @required GlobalKey key
  }) : super(key: key) {
    assert(key != null);
  }

  @override
  T createState();

  /// The state for the unique inflated instance of this widget.
  ///
  /// Might be null if the widget is not currently in the tree.
  T get currentState {
    GlobalKey globalKey = key;
    return globalKey.currentState; // ignore: return_of_invalid_type, https://github.com/flutter/flutter/issues/5771
  }
}
