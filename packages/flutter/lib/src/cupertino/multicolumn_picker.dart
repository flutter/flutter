// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'picker.dart';

/// An iOS picker with multiple columns.
/// Consists of a list of CupertinoPickers, and this class will display them
/// sequencely on a row. User can define the flex of each child in the row by
/// passing a list of int values for flex.
/// Customization of CupertinoPicker is implicitly defined in each picker.
class MultiColumnCupertinoPicker extends StatelessWidget {
  const MultiColumnCupertinoPicker({
    Key key,
    @required this.children,
    this.flexes,
  }): super(key: key);

  /// List containing flexes of children.
  final List<int> flexes;

  /// List containing single column pickers.
  final List<CupertinoPicker> children;

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: new List<Widget>.generate(children.length, (int index) {
        return new Expanded(
          flex: (flexes != null) ? flexes[index] : 1,
          child: children[index],
        );
      })
    );
  }
}