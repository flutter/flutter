Scheduler API
=============

```dart
typedef void TimerCallback();

class TaskSettings {
  const TaskSettings({
    this.idle: false, // tasks that should run during the idle phase
    this.layout: false, // tasks that should run during the layout phase
    this.paint: false, // tasks that should run during the paint phase
    this.touch: false, // tasks that should run while a pointer is down
  });
  final bool idle;
  final bool layout;
  final bool paint;
  final bool touch;
}

const idleTask = const TaskSettings(idle: true);
const t0 = null;
const t1ms = const Duration(milliseconds: 1.0);

// Priorities
// (these are intentionally not constants, so you can tweak them at runtime)
int IdlePriority = 0; // tasks that can be delayed arbitrarily
int FutureLayoutPriority = 1000; // tasks that prepare layout
int TimerAnimationPriority = 3000; // tasks related to animations 
int InputPriority = 4000; // input events
int InputAnimationPriority = 5000; // framework-fired events for scrolling

class Task {
  external Task(callback, {
    Duration delay: t0, // how long to wait before scheduling this task; null means run it now (same as duration 0)
    Duration budget: t1ms, // how long to allow the task to run before firing an exception; null means no timeout
    TaskSettings settings: idleTask, // what phases to allow the task to run during
    int priority: 0, // the greater the number, the more likely it is to run
    bool defer: false // punts this task until the next loop (after we're done with paint)
  });
  external void cancel(); // prevents the task from running, if it hasn't run yet
  external bool get active; // true until fired or until canceled
}

// The Dart native mechanisms for scheduling tasks, as listed below,
// get configured as follows:
//
//  delay: duration argument for the Timer constructors, otherwise null (0)
//  budget: 1ms
//  settings: same as for the task that triggered this task
//  priority: same as for the task that triggered this task
//  defer: false
//
// method: scheduleMicrotask(Function void callback())
// constructor: Future.microtask(...) // calls scheduleMicrotask() to do the work
// constructor: Timer (Duration duration, Function void callback())
// constructor: Timer.periodic(Duration duration, Function void callback(Timer timer))
```
