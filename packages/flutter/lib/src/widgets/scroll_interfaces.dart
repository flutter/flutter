// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_metrics.dart';
import 'ticker_provider.dart';

abstract class ScrollDragInterface {
  void update(DragUpdateDetails details, { bool reverse });
  void end(DragEndDetails details, { bool reverse });
}

abstract class ScrollWidgetInterface {
  BuildContext get context;
  TickerProvider get vsync;
  AxisDirection get axisDirection;

  void setIgnorePointer(bool value);
  void setCanDrag(bool value);
  void dispatchNotification(Notification notification);
  ScrollMetrics getMetrics();
}

/// An interface for classes that read data from objects like [ScrollPosition]s.
///
/// This interface defines a current position, [pixels], and a range of values
/// considered "in bounds" for that position. The range has a minimum value at
/// [minScrollExtent] and a maximum value at [maxScrollExtent] (inclusive).
///
/// The [outOfRange] getter will return true if [pixels] is outside this defined
/// range. The [atEdge] getter will return true if the [pixels] position equals
/// either the [minScrollExtent] or the [maxScrollExtent].
///
/// ## Discussion
///
/// By defining the interaction of scrolling-related classes using this
/// interface rather than concrete classes, classes such as [ScrollPhysics] can
/// be used with classes they were not originally intended to interact with. For
/// an example, see the implementation of [NestedScrollView].
//
// The [outOfRange] and [atEdge] getters could have a default implementation on
// this interface, if this interface were a mixin instead of an interface, but
// for consistency with other classes in this file, they don't.
abstract class ScrollPositionReadInterface {
  double get viewportDimension;
  double get minScrollExtent;
  double get maxScrollExtent;
  double get pixels;
  bool get outOfRange;
  bool get atEdge;
}

abstract class ScrollPositionWriteInterface extends ScrollPositionReadInterface {
  double setPixels(double newPixels);
  void beginIdleActivity();
  void beginBallisticActivity(double velocity);
}

abstract class ScrollPositionWriteAndDragInterface extends ScrollPositionWriteInterface {
  void updateUserScrollDirection(ScrollDirection value);
  double applyPhysicsToUserOffset(double delta);
}
