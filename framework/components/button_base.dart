// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';

abstract class ButtonBase extends Component {
  bool highlight = false;

  ButtonBase({ Object key }) : super(key: key) {
    events.listen('pointerdown', _handlePointerDown);
    events.listen('pointerup', _handlePointerUp);
    events.listen('pointercancel', _handlePointerCancel);
  }

  void _handlePointerDown(_) {
    setState(() {
      highlight = true;
    });
  }
  void _handlePointerUp(_) {
    setState(() {
      highlight = false;
    });
  }
  void _handlePointerCancel(_) {
    setState(() {
      highlight = false;
    });
  }
}
