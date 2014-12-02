UI Events
=========

Scope
-----

The following input devices are supported by sky:
 - fingers on multitouch screens
 - mice, including mouse wheels
 - styluses on screens
 - other devices that emulate mice (track pads, track balls)
 - keyboards

The following input devices are not supported natively by sky, but can
be used by connecting directly to the mojo application servicing the
relevant device:
 - joysticks
 - track balls that move focus (or raw data from track balls)
 - raw data from track pads (e.g. multitouch gestures)
 - raw data from styluses that have their own absolute pads
 - raw data from mice (e.g. to handle mouse capture in 3D games)

The following interactions are intended to be easy to handle:
 - one finger starts panning, another finger is placed on the surface
   (and ignored), the first finger is lifted, and the second finger
   continues panning (without the scroll position jumping when the
   first finger is lifted)
 - right-clicking doesn't trigger buttons by default
 - fingers after the first don't trigger buttons by default

Frameworks are responsible for converting pointer events described
below into widget-specific events such as the following:
 - a click/tap/activation, as distinct from a short drag
 - a context menu request (e.g. right-click, long-press)
 - a drag (moving an item)
 - a pan (scroll)
 - a zoom/rotation (whether using two finger gestures, or one finger
   with the double-tap-and-hold gesture)
 - a double-tap autozoom

In particular, this means distinguishing whether a finger tap consists
of a tap, a drag, or a long-press; it also means distinguishing
whether a drag, once established as such, should be treated as a pan
or a drag, and deciding whether a secondary touch should begin a
zoom/rotation or not.


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
the cursor, if any, or the document otherwise. The return value, if
it's a node, is used as the target of future move and up events until
this touch goes up. If there is no return value, the target continues
to be the application's document.

A pointer that is "down" is captured -- all events for that pointer
will be routed to the chosen target until the pointer goes up,
regardless of whether it's in that target's visible area.

When one moves, if it is "up" then a 'pointer-moved' event is fired at
the application's document, otherwise if it is "down" then the event
is fired at the element or document that was selected for the
'pointer-down' event.

When one switches from "down" to "up", a 'pointer-up' event is fired
at the element or document that was selected for the 'pointer-down'
event.

When there are no "down" pointers and one switches to "down", if
either there are no buttons (touch) or only the primary button is
active (mouse, stylus) and this is not an inverted stylus, then this
becomes the "primary" pointer. The pointer remains the primary pointer
until the corresponding pointer-up event (even if the buttons change).
At the time of a pointer-up event, if there is another pointer that is
already down and is of the same kind, and that has either no buttons
or only its primary button active, then that becomes the new primary
pointer.


These events all bubble and their data is an object with the following
fields:

        pointer: an integer assigned to this touch or pointer when it
                 enters the system, never reused, increasing
                 monotonically every time a new value is assigned,
                 starting from 1 (if the system gets a new tap every
                 microsecond, this will cause a problem after 285
                 years)

           kind: one of 'touch', 'mouse', 'stylus', 'inverted-stylus'

              x: x-position relative to the top-left corner of the
                 surface of the node on which the event was fired

              y: y-position relative to the top-left corner of the
                 surface of the node on which the event was fired

        buttons: a bitfield of the buttons pressed, from the following
                 list:

                   1: primary mouse button (not available on stylus)

                   2: secondary mouse button, primary stylus button

                   3: middle mouse button, secondary stylus button

                   4: back button

                   5: forward button

                 additional buttons can be represented by numbers
                 greater than six:

                   n: (n-2)th mouse button, ignoring any buttons that
                      are explicitly back or forward buttons

                      (n-4)th stylus button, again ignoring any
                      explictly back or forward buttons

           down: true if the pointer is down (in pointer-down event or
                 subsequent pointer-move events); false otherwise (in
                 pointer-added, pointer-up, and pointer-removed
                 events, and in pointer-move events that aren't
                 between pointer-down and pointer-up events)

        primary: true if this is a primary pointer/touch (see above)

       obscured: true if the system was rendering another view on top
                 of the sky application at the time of the event (this
                 is intended to enable click-jacking protections)


When primary is true, the following fields are available:

             dx: if primary, then this is the delta from the
                 x-position at the time that the pointer became
                 primary.

             dy: if primary, then this is the delta from the
                 x-position at the time that the pointer became
                 primary.


When down is true:

       pressure: the pressure of the touch as a number ranging from
                 0.0, indicating a touch with no discernible pressure,
                 to 1.0, indicating a touch with "normal" pressure,
                 and possibly beyond, indicating a stronger touch; for
                 devices that do not detect pressure (e.g. mice),
                 returns 1.0

    pressure-min: the minimum value that pressure can return for this
                  pointer

    pressure-max: the maximum value that pressure can return for this
                  pointer


When kind is 'touch', 'stylus', or 'stylus-inverted':

       distance: distance of detected object from surface (e.g.
                 distance of stylus or finger from screen), if
                 supported and down is not true, otherwise 0.0.

    distance-min: the minimum value that distance can return for this
                  pointer (always 0.0)

    distance-max: the maximum value that distance can return for this
                  pointer (0.0 if not supported)


When kind is 'touch', 'stylus', or 'stylus-inverted' and down is true:

    radius-major: the radius of the contact ellipse along the major
                  axis, in pixels

    radius-minor: the radius of the contact ellipse along the major
                  axis, in pixels

     radius-min: the minimum value that could be reported for
                 radius-major or radius-minor for this pointer

     radius-max: the maximum value that could be reported for
                 radius-major or radius-minor for this pointer


When kind is 'touch' and down is true:

    orientation: the angle of the contact ellipse, in radians in the
                 range

                    -pi/2 < orientation <= pi/2

                 ...giving the angle of the major axis of the ellipse
                 with the y-axis (negative angles indicating an
                 orientation along the top-left / bottom-right
                 diagonal, positive angles indicating an orientation
                 along the top-right / bottom-left diagonal, and zero
                 indicating an orientation parallel with the y-axis)


When kind is 'stylus' or 'stylus-inverted':

    orientation: the angle of the stylus, in radians in the range

                    -pi < orientation <= pi

                 ...giving the angle of the axis of the stylus
                 projected onto the screen, relative to the positive
                 y-axis of the screen (thus 0 indicates the stylus, if
                 projected onto the screen, would go from the contact
                 point vertically up in the positive y-axis direction,
                 pi would indicate that the stylus would go down in
                 the negative y-axis direction; pi/4 would indicate
                 that the stylus goes up and to the right, -pi/2 would
                 indicate that the stylus goes to the left, etc)

           tilt: the angle of the stylus, in radians in the range

                    0 <= tilt <= pi/2

                 ...giving the angle of the axis of the stylus,
                 relative to the axis perpendicular to the screen
                 (thus 0 indicates the stylus is orthogonal to the
                 plane of the screen, while pi/2 indicates that the
                 stylus is flat on the screen)


Wheel events
------------

When a wheel input device is turned, a 'wheel' event that bubbles is
fired at the application's document, with the following fields:

          wheel: an integer assigned to this wheel by the system. The
                 same wheel on the same system must always be given
                 the same ID. The primary wheel (e.g. the vertical
                 wheel on a mouse) must be given ID 1.

          delta: an floating point number representing the fraction of
                 the wheel that was turned, with positive numbers
                 representing a downward movement on vertical wheels,
                 rightward movement on horizontal wheels, and a
                 clockwise movement on wheels with a user-facing side.

Additionally, if the wheel is associated with a pointer (e.g. a mouse
wheel), the following fields must be present also:

        pointer: the integer assigned to the pointer in its
                 'pointer-add' event (see above).

              x: x-position relative to the top-left corner of the
                 display, in global layout coordinates

              y: x-position relative to the top-left corner of the
                 display, in global layout coordinates

Note: The only wheels that are supported are mouse wheels and physical
dials. Track balls are not reported as mouse wheels.


Text input events
-----------------

TODO(ianh): keyboard events
