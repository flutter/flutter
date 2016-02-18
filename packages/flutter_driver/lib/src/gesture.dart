// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'message.dart';

class Tap extends CommandWithTarget {
  final String kind = 'tap';

  Tap(ObjectRef targetRef) : super(targetRef);

  static Tap fromJson(Map<String, dynamic> json) {
    return new Tap(new ObjectRef(json['targetRef']));
  }

  Map<String, dynamic> toJson() => super.toJson();
}

class TapResult extends Result {
  static TapResult fromJson(Map<String, dynamic> json) {
    return new TapResult();
  }

  Map<String, dynamic> toJson() => {};
}
