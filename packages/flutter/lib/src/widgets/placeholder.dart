// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

/// A widget whose child can be mutated.
class Placeholder extends StatefulComponent {
  Placeholder({ Key key }) : super(key: key);

  PlaceholderState createState() => new PlaceholderState();
}

class PlaceholderState extends State<Placeholder> {
  /// The child that this widget builds.
  ///
  /// Mutating this field will cause this widget to rebuild with the new child.
  Widget get child => _child;
  Widget _child;
  void set child(Widget child) {
    if (_child == child)
      return;
    setState(() {
      _child = child;
    });
  }

  Widget build(BuildContext context) {
    if (_child != null)
      return child;
    return new SizedBox(width: 0.0, height: 0.0);
  }
}
