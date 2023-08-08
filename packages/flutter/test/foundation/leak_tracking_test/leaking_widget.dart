// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:leak_tracker/leak_tracker.dart';

class LeakTrackedClass {
  LeakTrackedClass() {
    LeakTracking.dispatchObjectCreated(
      library: library,
      className: '$LeakTrackedClass',
      object: this,
    );
  }

  static const String library = 'package:my_package/lib/src/my_lib.dart';

  void dispose() {
    LeakTracking.dispatchObjectDisposed(object: this);
  }
}

final List<LeakTrackedClass> _notGcedStorage = <LeakTrackedClass>[];


class StatelessLeakingWidget extends StatelessWidget {
  StatelessLeakingWidget({
    super.key,
    this.notGCed = true,
    this.notDisposed = true,
  }) {
    if (notGCed) {
      _notGcedStorage.add(LeakTrackedClass()..dispose());
    }
    if (notDisposed) {
      // ignore: unused_local_variable
      final LeakTrackedClass notDisposedObject = LeakTrackedClass();
    }
  }

  final bool notGCed;
  final bool notDisposed;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
