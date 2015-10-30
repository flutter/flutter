// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'navigator.dart';

class ModalBarrier extends StatelessComponent {
  ModalBarrier({ Key key }) : super(key: key);

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: (_) {
        Navigator.of(context).pop();
      },
      child: new Container()
    );
  }
}
