// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:vector_math/vector_math.dart';

import '../animation/animated_value.dart';
import '../animation/animation_performance.dart';
import '../animation/curves.dart';
import 'basic.dart';

class _AnimationEntry {
  _AnimationEntry(this.value);
  final AnimatedValue value;
  StreamSubscription<double> subscription;
}

abstract class AnimatedComponent extends Component {

  AnimatedComponent({ String key }) : super(key: key, stateful: true);

  void syncFields(AnimatedComponent source) { }

  List<_AnimationEntry> _animatedFields = new List<_AnimationEntry>();

  watch(AnimatedValue value) {
    assert(!mounted);
    // TODO(ianh): we really should assert that we're not doing this
    // in the constructor since doing it there is pointless and
    // expensive, since we'll be doing it for every copy of the object
    // even though only the first one will use it (since we're
    // stateful, the others will all be discarded early).
    _animatedFields.add(new _AnimationEntry(value));
  }

  void didMount() {
    for (_AnimationEntry entry in _animatedFields) {
      entry.subscription = entry.value.onValueChanged.listen((_) {
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

// Types of things that can be animated in a component. Use build() to
// construct the final Widget based on the animation state.
// TODO(mpcomplete): the idea here is to eventually have an AnimatedCollection
// which assembles a container based on a list of animated things. e.g. if you
// want to animate position, opacity, and shadow, you add those animators to an
// AnimatedCollection and just call collection.build() to construct your
// widget.

class AnimatedPosition extends AnimatedType<Point> {
  AnimatedPosition(Point begin, Point end, {Curve curve: linear})
      : super(begin, end, curve: curve);

  Widget build(Widget child) {
    Matrix4 transform = new Matrix4.identity();
    transform.translate(value.x, value.y);
    return new Transform(transform: transform, child: child);
  }
}
