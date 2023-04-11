
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:leak_tracker/leak_tracker.dart';

final List<LeakTrackedClass> notGcedStorage = <LeakTrackedClass>[];

LeakTrackedClass notGCed = LeakTrackedClass();

class StatelessLeakingWidget extends StatelessWidget {
  StatelessLeakingWidget({super.key}) {
    // ignore: unused_local_variable
    final LeakTrackedClass notDisposed = LeakTrackedClass();
    notGcedStorage.add(LeakTrackedClass()..dispose());
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class LeakTrackedClass {
  LeakTrackedClass() {
    dispatchObjectCreated(
      library: library,
      className: '$LeakTrackedClass',
      object: this,
    );
  }

  static const String library = 'package:my_package/lib/src/my_lib.dart';

  void dispose() {
    dispatchObjectDisposed(object: this);
  }
}
