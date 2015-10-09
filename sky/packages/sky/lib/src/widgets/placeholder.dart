// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

class Placeholder extends StatefulComponent {
  Placeholder({ Key key }) : super(key: key);

  PlaceholderState createState() => new PlaceholderState();
}

class PlaceholderState extends State<Placeholder> {
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
