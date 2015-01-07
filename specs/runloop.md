Sky's Run Loop
==============

Sky's run loop consists of running the following, at 120Hz (each loop
takes 8.333ms):

1. Send scroll and resize events if necessary, limiting each handler
   to 1ms, and limiting the total time spent on these handlers to 1ms.

2. Fire animation frame callbacks for up to 1ms. Each callback can run
   for up to 1ms. Once 1ms has expired, throw a (catchable)
   EDeadlineExceeded exception. If it's not caught, drop subsequent
   callbacks.

3. Spend up to 1ms to update the render tree, including calling
   childAdded(), childRemoved(), and getLayoutManager() as needed.
   Once 1ms has expired, throw a (catchable) EDeadlineExceeded
   exception, leaving the render tree in whatever state it has
   reached.

4. Update as much of layout as possible; after 1ms, throw a
   (catchable) EDeadlineExceeded exception, leaving the remaining
   nodes unprepared.

5. Update as much of paint as possible; after 1ms, throw a (catchable)
   EDeadlineExceeded exception, leaving any remaining nodes
   unprepared.

6. Send frame to GPU.

7. Run pending tasks until the 8.333ms expires. Each task may only run
   for at most 1ms, after 1ms they get a (catchable) EDeadlineExceeded
   exception. While there are no pending tasks, sleep.
   Tasks are things like:
    - timers
    - updating the DOM in response to parsing
    - input events
    - mojo callbacks

TODO(ianh): Update the timings above to have some relationship to
reality.

TODO(ianh): Define how scroll notifications get sent, or decide to
drop them entirely from this model.
