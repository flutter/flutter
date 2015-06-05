// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import 'button_base.dart';
import 'icon.dart';
import 'ink_well.dart';

class MenuItem extends ButtonBase {

  static const BoxDecoration highlightDecoration = const BoxDecoration(
    backgroundColor: const Color.fromARGB(102, 153, 153, 153)
  ); 

  List<UINode> children;
  String icon;
  GestureEventListener onGestureTap;

  MenuItem({ Object key, this.icon, this.children, this.onGestureTap }) : super(key: key);

  UINode buildContent() {
    return new EventListenerNode(
      new Container(
        child: new InkWell(
          children: [
            new Padding(
              child: new Icon(type: "${icon}_grey600", size: 24),
              padding: const EdgeDims.symmetric(horizontal: 16.0)
            ),
            new FlexExpandingChild(
              new Padding(
                child: new FlexContainer(
                  direction: FlexDirection.horizontal,
                  children: children
                ),
                padding: const EdgeDims.symmetric(horizontal: 16.0)
              ),
              1
            )
          ]
        ),
        desiredSize: const Size.fromHeight(48.0),
        decoration: highlight ? highlightDecoration : null
      ),
      onGestureTap: onGestureTap
    );
  }
}
