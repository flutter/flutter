Sky's Run Loop
==============

Sky has three task queues, named idle, frame, and nextFrame.

When a task is run, it has a time budget, and if the time budget is
exceeded, then a catchable DeadlineExceededException exception is
fired.

```dart
class DeadlineExceededException implements Exception { }
```

When Sky is to *process a task queue until a particular time*, with a
queue *relevant task queue*, bits *filter bits*, a time
*particular time*, and an *idle rule* which is either "sleep" or
"abort", it must run the following steps:

1. Let *remaining time* be the time until the given *particular time*.
2. If *remaining time* is less than or equal to zero, exit this
   algorithm.
3. Let *task list* be the list of tasks in the *relevant task queue*
   that have bits that, when 'and'ed with *filter bits*, are equal to
   *filter bits*, whose required budget is less than or equal to
   *remaining time*; and whose due time, if any, has been reached.
4. If *task list* is empty, then if *idle rule* is "sleep" then return
   to step 1, otherwise, exit this algorithm.
5. Sort *task list* by the priority of each task, highest first.
6. Remove the top task from *task list* from the *relevant task
   queue*, and let that be *selected task*.
7. Run *selected task*, with a budget of *remaining time* or 1ms,
   whichever is shorter.
8. Return to step 1.

When Sky is to *drain a task queue for a specified time*, with a queue
*relevant task queue*, bits *filter bits*, and a duration *budget*, it
must run the following steps:

2. Let *task list* be the list of tasks in the *relevant task queue*
   that have bits that, when 'or'ed with *filter bits*, are non-zero;
   and whose required budget is less than or equal to *budget*.
4. If *task list* is empty, then exit.
5. Sort *task list* by the priority of each task, highest first.
6. Remove the top task from *task list* from the *relevant task
   queue*, and let that be *selected task*.
7. Run *selected task*, with a budget of *budget*.
8. Decrease *budget* with the amount of time that *selected task* took
   to run.
9. If *selected task* threw an uncaught DeadlineExceededException
   exception, then cancel all the tasks in *relevant task queue*.
   Otherwise, return to step 2.

Sky's run loop consists of running the following, at 120Hz (each loop
takes 8.333ms):

1. *Drain* the *frame task queue*, with bits
   `application.frameTaskBits`, for 1ms.

2. Create a task that does the following, then run it with a budget of
   1ms:

   1. Update the render tree, including calling childAdded(),
      childRemoved(), and getLayoutManager() as needed, catching any
      exceptions other than DeadlineExceededException exceptions.

   If an exception is thrown by this, then the RenderNode tree will
   continue to not quite match the element tree, which is fine.

3. If there are no tasks on the *idle task queue* with bits
   `LayoutKind`, create a task that tells the root node to layout if
   it has needsLayout or descendantNeedsLayout, mark that with
   priority 0 and bits `LayoutKind`, and add it to the *idle task
   queue*.

4. *Process* the *idle task queue*, with bits `LayoutKind`, with a
   target time of t-1ms, where t is the time at which we have to send
   the frame to the GPU, and with an *idle rule* of "abort".

5. Create a task that does the following, then run it with a budget of
   1ms:

   1. If there are no RenderNodes that need paint, abort.

   2. Call the `paint()` callback of the RenderNode that was least
      recently marked as needing paint, catching any exceptions other
      than DeadlineExceededException exceptions.

   3. Jump to step 1.

   If an exception is thrown by this, then some RenderNode objects
      will be out-of-date during the paint.

6. Send frame to GPU.

7. Replace the frame queue with the nextFrame queue, and let the
   nextFrame queue be an empty queue.

8. *Process* the *idle task queue*, with bits
   `application.idleTaskBits`, with a target time of t, where t is the
   time at which we have to start the next frame's layout and paint
   computations, and with an *idle rule* of "sleep".

TODO(ianh): Update the timings above to have some relationship to
reality.

TODO(ianh): Define an API so that the application can adjust the
budgets.

Task kinds and priorities
-------------------------

Tasks scheduled by futures get the priority and task kind bits from
the task they are scheduled from.

```dart
int IdlePriority = 0; // tasks that can be delayed arbitrarily
int FutureLayoutPriority = 1000; // async-layout tasks
int AnimationPriority = 3000; // animation-related tasks
int InputPriority = 4000; // input events
int ScrollPriority = 5000; // framework-fired events for scrolling

// possible idle queue task bits
int IdleKind = 0x01; // tasks that should run during the idle loop
int LayoutKind = 0x02; // tasks that should run during layout
int TouchSafeKind = 0x04; // tasks that should keep running while there is a pointer down
int idleTaskBits = IdleKind; // tasks must have all these bits to run during idle loop
int layoutTaskBits = LayoutKind; // tasks must have all these bits to run during layout

// possible frame queue task bits
// (there are none at this time)
int frameTaskBits = 0x00; // tasks must have all these bits to run during the frame loop
```
