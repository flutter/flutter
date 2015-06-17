// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'material.dart';

class Dialog extends Component {
  Dialog({
    String key,
    this.title,
    this.content,
    this.actions,
    this.onDismiss
  }) : super(key: key);

  final Widget title;
  final Widget content;
  final Widget actions;
  final Function onDismiss;

  Widget build() {
    Container mask = new Container(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0x7F000000)));

    List<Widget> children = new List<Widget>();

    if (title != null)
      children.add(title);

    if (content != null)
      children.add(content);

    if (actions != null)
      children.add(content);

    return new Stack([
      new Listener(
        child: mask,
        onGestureTap: (_) => onDismiss()
      ),
      new Center(
        child: new ConstrainedBox(
          constraints: new BoxConstraints(minWidth: 280.0),
          child: new Material(
            level: 4,
            child: new ShrinkWrapWidth(
              child: new Block(children)
            )
          )
        )
      )
    ]);
  }
}
