// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library components_animated_component;

import '../animation/animated_value.dart';
import '../fn.dart';
import 'dart:mirrors';

abstract class AnimatedComponent extends Component {
  AnimatedComponent({ Object key }) : super(key: key, stateful: true);

  var _debugAnimatedFields = new Set<Symbol>();
  bool _debugIsNotYetAnimated(Symbol s) {
    return _debugAnimatedFields.add(s);
  }

  animateField(AnimatedValue value, Symbol symbol) {
    // TODO(rafaelw): Assert symbol is present on |this|, is private and
    // is over the same parameterized type as the animated value.
    var mirror = reflect(this);
    var subscription;

    assert(_debugIsNotYetAnimated(symbol));
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
