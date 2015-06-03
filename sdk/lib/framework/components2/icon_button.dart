// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../rendering/box.dart';
import 'icon.dart';

class IconButton extends Component {
  String icon;
  GestureEventListener onGestureTap;

  IconButton({ String icon: '', this.onGestureTap })
    : super(key: icon), icon = icon;

  UINode build() {
    return new EventListenerNode(
      new Padding(
        child: new Icon(type: icon, size: 24.0),
        padding: const EdgeDims.all(8.0)),
      onGestureTap: onGestureTap);
  }
}
