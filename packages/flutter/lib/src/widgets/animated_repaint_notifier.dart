// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'notification_listener.dart';

abstract class AnimatedRepaintNotification extends Notification {
  const AnimatedRepaintNotification();
}

class AnimationStart extends AnimatedRepaintNotification {
  const AnimationStart();
}

class AnimationEnd extends AnimatedRepaintNotification {
  const AnimationEnd();
}
