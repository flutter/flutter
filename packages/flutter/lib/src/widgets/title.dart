// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class Title extends StatelessComponent {
  Title({ this.title, this.child, this.color });

  final Widget child;
  final String title;
  final Color color;

  Widget build(BuildContext context) {
    updateTaskDescription(title, color);
    return child;
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('"$title"');
    description.add('color: $color');
  }
}
