// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../fn2.dart';
import 'dart:async';

typedef void SetterFunction(double value);

abstract class AnimatedComponent extends Component {

  AnimatedComponent({ Object key }) : super(key: key, stateful: true);

  void syncFields(AnimatedComponent source) { }

  animate(AnimatedValue value, SetterFunction setter) {
    setter(value.value);
    StreamSubscription<double> subscription;
    onDidMount(() {
      subscription = value.onValueChanged.listen((_) {
        setter(value.value);
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
