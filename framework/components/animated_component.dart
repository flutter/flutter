// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../fn.dart';
import 'dart:mirrors';

abstract class AnimatedComponent extends Component {
  AnimatedComponent({ Object key }) : super(key: key, stateful: true);

  animateField(AnimatedValue value, Symbol symbol) {
    // TODO(rafaelw): Assert symbol is present on |this|, is private and
    // is over the same parameterized type as the animated value.
    var mirror = reflect(this);
    var subscription;

    mirror.setField(symbol, value.value);

    onDidMount(() {
      subscription = value.onValueChanged.listen((_) {
        mirror.setField(symbol, value.value);
        scheduleBuild();
      });
    });

    onDidUnmount(() {
      if (subscription != null) {
        subscription.cancel();
        subscription = null;
      }
    });
  }
}
