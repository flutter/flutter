Pointer Events
==============

Scope
-----

The following input devices are supported by sky:
 - fingers on multitouch screens
 - mice, including mouse wheels
 - styluses on screens
 - other devices that emulate mice (track pads, track balls)
 - [keyboards and IMEs](keyboard.md)

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
 - fingers after the first within a surface don't trigger buttons by
   default
 - if there are two independent surfaces, they capture fingers
   unrelated to each other

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

This is done using the [gesture recogniser API](gestures.md)


Pointers
--------

Each touch or pointer is tracked individually.

New touches and pointers can appear and disappear over time.

Each pointer has a list of current targets.

When a new one enters the system, a non-bubbling ``PointerAddedEvent``
event is fired at the application's element tree's root node, and the
pointer's current targets list is initialised to just that Root
object.

When it is removed, a non-bubbling ``PointerRemovedEvent`` event is
fired at the application's element tree's root node and at any other
objects in the pointer's current targets list. Currently, at the time
of a ``PointerRemoved``, the list will always consist of only the
application's element tree's root node.

A pointer can be "up" or "down". Initially all pointers are "up".

A pointer switches from "up" to "down" when it is a touch or stylus
that is in contact with the display surface, or when it is a mouse
that is being clicked, and from "down" back to "up" when this ends.
(Note that clicking a button on a stylus doesn't change it from up to
down. A stylus can have a button pressed while "up".) In the case of a
mouse with multiple buttons, the pointer switches back to "up" only
when all the buttons have been released.

When a pointer switches from "up" to "down", the following algorithm
is run:

 1. Hit test the position of the pointer, let 'node' be the result.
 2. Fire a bubbling ``PointerDownEvent`` event at the layoutManager
    for 'node', with an empty array as the default return value. Let
    'result1' be the returned value.
 3. If result1 is not an array of EventTarget objects, set it to the
    empty array and (if this is debug mode) report the issue.
 4. Fire a bubbling ``PointerDownEvent`` event at the Element for
    'node', with an empty array as the default return value. Let
    'result2' be the returned value.
 5. If result2 is not an array of EventTarget objects, set it to the
    empty array and (if this is debug mode) report the issue.
 6. Let result be the concatenation of result1's contents, result2's
    contents, and the application's element tree's root node.
 7. Let 'result' be this pointer's current targets.

When an object is one of the current targets of a pointer and no other
pointers have that object as a current target so far, and either there
are no buttons (touch, stylus) or only the primary button is active
(mouse) and this is not an inverted stylus, then that pointer is
considered the "primary" pointer for that object. The pointer remains
the primary pointer for that object until the corresponding
``PointerUpEvent`` event (even if the buttons change).

When a pointer moves, a non-bubbling ``PointerMoveEvent`` event is
fired at each of the pointer's current targets in turn (maintaining
the order they had in the ``PointerDownEvent`` event, if there's more
than one). If the return value of a ``PointerMovedEvent`` event is
'cancel', and the pointer is currently down, then the pointer is
canceled (see below).

When a pointer's button state changes but this doesn't impact whether
it is "up" or "down", e.g. when a mouse with a button down gets a
second button down, or when a stylus' buttons change state, but the
pointer doesn't simultaneously move, then a ``PointerMovedEvent``
event is fired anyway, as described above, but with dx=dy=0.

When a pointer switches from "down" to "up", a non-bubbling
``PointerUpEvent`` event is fired at each of the pointer's current
targets in turn (maintaining the order they had in the
``PointerDownEvent`` event, if there's more than one), and then the
pointer's current target list is emptied except for the application's
element tree's root node. The buttons exposed on the
``PointerUpEvent`` event are those that were down immediately prior to
the buttons being released.

At the time of a ``PointerUpEvent`` event, for each object that is a
current target of the pointer, and for which the pointer is considered
the "primary" pointer for that object, if there is another pointer
that is already down, which is of the same kind, which also has that
object as a current target, and that has either no buttons or only its
primary button active, then that pointer becomes the new "primary"
pointer for that object before the ``PointerUpEvent`` event is sent.
Otherwise, the "primary" pointer stops being "primary" just _after_
the ``PointerUpEvent`` event. (This matters for whether the 'primary'
field is set.)

When a pointer is canceled, if it is "down", pretend that the pointer
moved to "up", sending ``PointerUpEvent`` as described above, and
entirely empty its current targets list. AFter the pointer actually
switches from "down" to "up", replace the current targets list with an
object that only contains the application's element tree's root node.

Nothing special happens when a pointer's current target moves in the
DOM.

The x and y position of an -up or -down event always match those of
the previous -moved or -added event, so their dx and dy are always 0.

Positions are floating point numbers; they can have subpixel values.

For each pointer, only a single ``PointerAddedEvent`` or
``PointerRemovedEvent`` event is fired per frame. If a pointer would
have been added and removed in the same frame, the pointer is ignored,
and no events are fired for that pointer.

For each pointer, only a single ``PointerDownEvent`` or
``PointerUpEvent`` event is fired per frame, representing the change
in state from the last frame, if any. Exactly when the event is fired
is up to the implementation and may depend on the hardware.

For each pointer, at most two ``PointerMoveEvent`` events are fired
per frame, one before the ``PointerDownEvent`` or ``PointerUpEvent``
event, if any, and one after. If the pointer didn't change "down"
state, then only one ``PointerMoveEvent`` event is fired. All the
actual moves that the pointer experienced are coallesced into the
event.

   Example:
    If a mouse experiences the following events:
       - move +1, down, move +2, up, move +4, down, move +8
    ...the events might be:
       - move +7, down, move +8
    ...or:
       - move +1, down, move +14

TODO(ianh): expose the unfiltered uncoalesced stream of events for
programs that want more precision (e.g. drawing apps)


These events have the following fields (see below for the class
definitions):

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

              dx: difference in x-position since last
                  ``PointerMovedEvent`` event

              dy: difference in y-position since last
                  ``PointerMovedEvent`` event

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

                  note that stylus buttons can be pressed even when the
                  pointer is not "down"

                  e.g. if the left mouse button and the right mouse
                  button are pressed at the same time, the value will
                  be 3 (bits 1 and 2); if the right mouse button and
                  the back button are pressed at the same time, the
                  value will be 10 (bits 2 and 4)

            down: true if the pointer is down (in ``PointerDownEvent``
                  event or subsequent ``PointerMoveEvent`` events);
                  false otherwise (in ``PointerAdded``, ``PointerUp``,
                  and ``PointerRemovedEvent`` events, and in
                  ``PointerMoveEvent`` events that aren't between
                  ``PointerDownEvent`` and ``PointerUpEvent`` events)

         primary: true if this is a primary pointer/touch (see above)
                  can only be set for ``PointerMovedEvent`` and
                  ``PointerUpEvent``

        obscured: true if the system was rendering another view on top
                  of the sky application at the time of the event (this
                  is intended to enable click-jacking protections)


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


TODO(ianh): add an API that exposes the currently existing pointers,
so that you can determine e.g. if you have a mouse.

Here are the class definitions for pointer events:

```dart
enum PointerKind { touch, mouse, stylus, invertedStylus }

abstract class PointerEvent<T> extends Event<T> {
  PointerEvent({ this.pointer,
                 this.kind,
                 this.x, this.y,
                 this.dx: 0.0, this.dy: 0.0,
                 this.buttons: 0,
                 this.down: false,
                 this.primary: false,
                 this.obscured: false,
                 this.pressure, this.minPressure, this.maxPressure,
                 this.distance, this.minDistance, this.maxDistance,
                 this.radiusMajor, this.radiusMinor, this.minRadius, this.maxRadius,
                 this.orientation, this.tilt
               }): super();

  final int pointer;
  final PointerKind kind;
  final double x; // logical pixels
  final double y; // logical pixels
  final double dx; // logical pixels
  final double dy; // logical pixels

  final int buttons; // bit field
  static const int primaryMouseButton = 0x01;
  static const int secondaryMouseButton = 0x02;
  static const int primaryStylusButton = 0x02;
  static const int middleMouseButton = 0x04;
  static const int secondaryStylusButton = 0x04;
  static const int backButton = 0x08;
  static const int forwardButton = 0x10;

  final bool down;
  final bool primary;
  final bool obscured;

  // if down != true, these are all null
  final double pressure; // normalised, 0.0 means none, 1.0 means "normal"
  final double minPressure; // 0 <= minPressure <= 1.0
  final double maxPressure; // maxPressure >= 1.0

  // if kind != touch, stylus, or invertedStylus, these are all null
  final double distance; // logical pixels
  final double minDistance; // logical pixels
  final double maxDistance; // logical pixels

  // if down != true or kind != touch, stylus, or invertedStylus, these are all null
  final double radiusMajor; // logical pixels
  final double radiusMinor; // logical pixels
  final double minRadius; // logical pixels
  final double maxRadius; // logical pixels

  // if down != true or kind != touch, stylus, or invertedStylus, this is null
  final double orientation; // radians // meaning is different for touch and stylus/invertedStylus

  // if kind != stylus or invertedStylus, this is null
  final double tilt; // radians
}

// the following uses proposed syntax from
// https://code.google.com/p/dart/issues/detail?id=22274
// to avoid duplicating that entire constructor up there

class PointerAddedEvent extends PointerEvent<Null> {
  PointerAddedEvent = PointerEvent;
  bool get bubbles => false;
}

class PointerRemovedEvent extends PointerEvent<Null> {
  PointerRemovedEvent = PointerEvent;
  bool get bubbles => false;
}

class PointerDownEvent extends PointerEvent<List<EventTarget>> {
  @override void init() { result = new List<EventTarget>(); }
  PointerDownEvent = PointerEvent;
  bool get bubbles => true;
}

class PointerUpEvent extends PointerEvent<Null> {
  PointerUpEvent = PointerEvent;
  bool get bubbles => false;
}

class PointerMovedEvent extends PointerEvent<Null> {
  PointerMovedEvent = PointerEvent;
  bool get bubbles => false;
}
```

Wheel events
------------

When a wheel input device is turned, a ``WheelEvent`` event that
doesn't bubble is fired at the application's element tree's root node,
with the following fields:

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
                  ``PointerAddEvent`` event (see above).

               x: x-position relative to the top-left corner of the
                  display, in global layout coordinates

               y: x-position relative to the top-left corner of the
                  display, in global layout coordinates

Note: The only wheels that are supported are mouse wheels and physical
dials. Track balls are not reported as mouse wheels.

```dart
class WheelEvent extends Event {
  Event({ this.wheel,
          this.delta: 0.0,
          this.pointer,
          this.x, this.y,
        }): super();

  final int wheel;
  final double delta; // revolutions (or fractions thereof)
  final int pointer;
  final double x; // logical pixels
  final double y; // logical pixels

  bool get bubbles => false;
}
```
