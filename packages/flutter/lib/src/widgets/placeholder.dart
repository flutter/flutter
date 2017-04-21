// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

/// A widget whose child can be mutated.
class Placeholder extends StatefulWidget {
  /// Creates a widget whose child can be mutated.
  const Placeholder({ Key key }) : super(key: key);

  @override
  PlaceholderState createState() => new PlaceholderState();
}

/// State for a [Placeholder] widget.
///
/// Useful for setting the child currently displayed by this placeholder widget.
class PlaceholderState extends State<Placeholder> {
  /// The child that this widget builds.
  ///
  /// Mutating this field will cause this widget to rebuild with the new child.
  Widget get child => _child;
  Widget _child;
  set child(Widget value) {
    if (_child == value)
      return;
    setState(() {
      _child = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_child != null)
      return child;
    return const SizedBox(width: 0.0, height: 0.0);
  }
}
