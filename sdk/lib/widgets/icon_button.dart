// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../rendering/box.dart';
import 'basic.dart';
import 'icon.dart';
import 'widget.dart';

class IconButton extends Component {

  IconButton({ String icon: '', this.onGestureTap })
    : super(key: icon), icon = icon;

  final String icon;
  final GestureEventListener onGestureTap;

  Widget build() {
    return new EventListenerNode(
      new Padding(
        child: new Icon(type: icon, size: 24),
        padding: const EdgeDims.all(8.0)),
      onGestureTap: onGestureTap);
  }

}
