// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/mojo/activity.dart' as activity;

class TaskDescription extends Component {
  Widget child;
  String label;

  TaskDescription({this.label, this.child});

  Widget build() {
    activity.updateTaskDescription(label, Theme.of(this).primaryColor);
    return child;
  }
}
