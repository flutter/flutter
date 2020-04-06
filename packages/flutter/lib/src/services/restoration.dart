import 'package:flutter/scheduler.dart';

/// I am just a test placeholder.
void foo() {
  SchedulerBinding.instance.scheduleTask(() => null, Priority.animation);
}
