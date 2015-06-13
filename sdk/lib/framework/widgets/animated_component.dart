// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../animation/animated_value.dart';
import 'basic.dart';

typedef void SetterFunction(double value);

class _AnimationEntry {
  _AnimationEntry(this.value, this.setter);
  final AnimatedValue value;
  final SetterFunction setter;
  StreamSubscription<double> subscription;
}

abstract class AnimatedComponent extends Component {

  AnimatedComponent({ Object key }) : super(key: key, stateful: true);

  void syncFields(AnimatedComponent source) { }

  List<_AnimationEntry> _animatedFields = new List<_AnimationEntry>();

  animate(AnimatedValue value, SetterFunction setter) {
    assert(!mounted);
    setter(value.value);
    _animatedFields.add(new _AnimationEntry(value, setter));
  }

  void didMount() {
    for (_AnimationEntry entry in _animatedFields) {
      entry.subscription = entry.value.onValueChanged.listen((_) {
        entry.setter(entry.value.value);
        scheduleBuild();
      });
    }
    super.didMount();
  }

  void didUnmount() {
    for (_AnimationEntry entry in _animatedFields) {
      assert(entry.subscription != null);
      entry.subscription.cancel();
      entry.subscription = null;
    }
    super.didUnmount();
  }

}
