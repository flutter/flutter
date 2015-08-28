// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/framework.dart';
import 'package:sky/widgets/gesture_detector.dart';

class ModalOverlay extends Component {

  ModalOverlay({ Key key, this.children, this.onDismiss }) : super(key: key);

  final List<Widget> children;
  final Function onDismiss;

  Widget build() {
    return new GestureDetector(
      onTap: onDismiss,
      child: new Stack(children)
    );
  }

}
