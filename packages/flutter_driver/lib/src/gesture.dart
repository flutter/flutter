// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'message.dart';

class Tap extends CommandWithTarget {
  @override
  final String kind = 'tap';

  Tap(ObjectRef targetRef) : super(targetRef);

  static Tap deserialize(Map<String, String> json) {
    return new Tap(new ObjectRef(json['targetRef']));
  }

  @override
  Map<String, String> serialize() => super.serialize();
}

class TapResult extends Result {
  static TapResult fromJson(Map<String, dynamic> json) {
    return new TapResult();
  }

  @override
  Map<String, dynamic> toJson() => {};
}


/// Command the driver to perform a scrolling action.
class Scroll extends CommandWithTarget {
  @override
  final String kind = 'scroll';

  Scroll(
    ObjectRef targetRef,
    this.dx,
    this.dy,
    this.duration,
    this.frequency
  ) : super(targetRef);

  static Scroll deserialize(Map<String, dynamic> json) {
    return new Scroll(
      new ObjectRef(json['targetRef']),
      double.parse(json['dx']),
      double.parse(json['dy']),
      new Duration(microseconds: int.parse(json['duration'])),
      int.parse(json['frequency'])
    );
  }

  /// Delta X offset per move event.
  final double dx;

  /// Delta Y offset per move event.
  final double dy;

  /// The duration of the scrolling action
  final Duration duration;

  /// The frequency in Hz of the generated move events.
  final int frequency;

  @override
  Map<String, String> serialize() => super.serialize()..addAll({
    'dx': '$dx',
    'dy': '$dy',
    'duration': '${duration.inMicroseconds}',
    'frequency': '$frequency',
  });
}

class ScrollResult extends Result {
  static ScrollResult fromJson(Map<String, dynamic> json) {
    return new ScrollResult();
  }

  @override
  Map<String, dynamic> toJson() => {};
}
