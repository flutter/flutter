UI Events
=========

Pointer events
--------------

Each touch or pointer is tracked individually.

New touches and pointers can appear and disappear over time.

When a new one enters the system, a 'pointer-added' event is fired at
the application's document.

When it is removed, a 'pointer-removed' event is fired at the
application's document.

When one switches from "up" to "down", the position of the tap is hit
tested and a 'pointer-down' event is fired at the target element under
the cursor, if any, or the document otherwise.

When one moves, if it is "up" then a 'pointer-moved' event is fired at
the application's document, otherwise if it is "down" then the event
is fired at the element or document that was selected for the
'pointer-down' event.

When one switches from "down" to "up", a 'pointer-up' event is fired
at the element or document that was selected for the 'pointer-down'
event.


These events all bubble and their data is an object with the following
fields:

   pointer: an integer assigned to this touch or pointer when it
            enters the system, never reused, increasing monotonically
            every time a new value is assigned, starting from 1 (if
            the system gets a new tap every microsecond, this will
            cause a problem after 285 years)
 
         x: x-position relative to the top-left corner of the display,
            in global layout coordinates
 
         y: x-position relative to the top-left corner of the display,
            in global layout coordinates

   buttons: a bitfield of the buttons pressed, where 1 is the primary
            button, 2 is the secondary, and subsequent numbers refer
            to any other buttons

TODO(ianh): add other fields for touches (radius/pressure, angle)

TODO(ianh): should we use a different way to express buttons? e.g.
create a new touch for the secondary button when it goes down,
removing the touch when it goes back up?

TODO(ianh): find a way to avoid the trap everyone always falls into of
treating all the buttons as equivalent to a touch (e.g. right-clicking
a button shouldn't trigger the button). For example, maybe we should
remove 'buttons' and use different event names for the up/down state
changes of non-primary buttons of pointers, like 'pointer-down-2' for
the secondary button, 'pointer-down-3' for the middle mouse button,
and so on.


Wheel events
------------

When a wheel input device is turned, a 'wheel' event that bubbles is
fired at the application's document, with the following fields:

     wheel: an integer assigned to this wheel by the system. The same
            wheel on the same system must always be given the same ID.
            The primary wheel (e.g. the vertical wheel on a mouse)
            must be given ID 1.

     delta: an floating point number representing the fraction of the
            wheel that was turned, with positive numbers representing
            a downward movement on vertical wheels, rightward movement
            on horizontal wheels, and a clockwise movement on wheels
            with a user-facing side.
 
Additionally, if the wheel is associated with a pointer (e.g. a mouse
wheel), the following fields must be present also:

   pointer: the integer assigned to the pointer in its 'pointer-add'
            event (see above).

         x: x-position relative to the top-left corner of the display,
            in global layout coordinates
 
         y: x-position relative to the top-left corner of the display,
            in global layout coordinates


Text input events
-----------------

TODO(ianh): keyboard events
