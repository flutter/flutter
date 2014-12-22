Sky's Run Loop
==============

Sky's run loop consists of running the following, at 120Hz (each loop
takes 8.333ms):

1. Send scroll and resize events if necessary, limiting each handler
   to 1ms, and limiting the total time spent on these handlers to 1ms.

2. Update as much of layout as possible; after 1ms, stop, leaving the
   remaining nodes unprepared.

3. Update as much of paint as possible; after 1ms, stop, leaving the
   remaining nodes unprepared.

4. Send frame to GPU.

5. Run pending tasks until the 8.333ms expires. Each task may only run
   for at most 1ms, after 1ms they get a (catchable) EDeadlineExceeded
   exception. While there are no pending tasks, sleep.

TODO(ianh): Update the timings above to have some relationship to
reality.
