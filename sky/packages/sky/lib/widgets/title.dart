// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/mojo/activity.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/framework.dart';

class Title extends Component {

  Title({ this.title, this.child });

  final Widget child;
  final String title;

  Widget build() {
    updateTaskDescription(title, Theme.of(this).primaryColor);
    return child;
  }

}
