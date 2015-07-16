// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/widget.dart';

class ModalOverlay extends Component {

  ModalOverlay({ String key, this.children, this.onDismiss }) : super(key: key);

  final List<Widget> children;
  final Function onDismiss;

  Widget build() {
    return new Listener(
      onGestureTap: (_) {
        if (onDismiss != null)
          onDismiss();
      },
      child: new Stack(children)
    );
  }

}
