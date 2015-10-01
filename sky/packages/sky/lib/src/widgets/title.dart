// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/services.dart';
import 'package:sky/src/widgets/theme.dart';
import 'package:sky/src/widgets/framework.dart';

class Title extends StatelessComponent {
  Title({ this.title, this.child });

  final Widget child;
  final String title;

  Widget build(BuildContext context) {
    updateTaskDescription(title, Theme.of(context).primaryColor);
    return child;
  }
}
