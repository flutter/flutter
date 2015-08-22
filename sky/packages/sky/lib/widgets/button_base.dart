// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';

abstract class ButtonBase extends StatefulComponent {

  ButtonBase({ Key key, this.highlight: false }) : super(key: key);

  bool highlight;

  void syncConstructorArguments(ButtonBase source) {
    highlight = source.highlight;
  }

  EventDisposition _handlePointerDown(_) {
    setState(() {
      highlight = true;
    });
    return EventDisposition.processed;
  }
  EventDisposition _handlePointerUp(_) {
    setState(() {
      highlight = false;
    });
    return EventDisposition.processed;
  }
  EventDisposition _handlePointerCancel(_) {
    setState(() {
      highlight = false;
    });
    return EventDisposition.processed;
  }

  Widget build() {
    return new Listener(
      child: buildContent(),
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel
    );
  }

  Widget buildContent();

}
