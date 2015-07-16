// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of internal;

class Timeout implements Comparable<Timeout> {
  int deadline; // milliseconds since the Unix epoch.
  SendPort port;

  Timeout(this.port, this.deadline);

  int compareTo(Timeout other) => deadline - other.deadline;
}

class TimerQueue {
  SplayTreeSet _set;
  Timeout _nextTimer;

  TimerQueue() : _set = new SplayTreeSet();

  void updateTimer(SendPort port, int deadline) {
    var removedTimeout = null;
    _set.removeWhere((timeout) {
      if (timeout.port == port) {
        removedTimeout = timeout;
        return true;
      }
      return false;
    });

    if ((removedTimeout == null) && (deadline >= 0)) {
      _set.add(new Timeout(port, deadline));
    } else {
      if (deadline > 0) {
        removedTimeout.deadline = deadline;
        _set.add(removedTimeout);
      }
    }

    if (_set.isNotEmpty) {
      _nextTimer = _set.first;
    } else {
      _nextTimer = null;
    }
  }

  void removeCurrent() => updateTimer(currentPort, -1);

  bool get hasTimer => _nextTimer != null;
  int get currentTimeout => _nextTimer.deadline;
  SendPort get currentPort => _nextTimer.port;
}
