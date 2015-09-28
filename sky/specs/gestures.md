Gestures
========

Flutter's Gesture API has the following key components:
* Pointers
* Gesture Recognisers
* Gesture Arenas

Pointers represent contact points on the display surface, also referred to as "touches". Pointers fire events describing when they are down, moved, up, or canceled.

Gesture recognisers examine sequences of pointer events and map them to higher-level descriptions like "tap", "drag", and so forth.

Gesture arenas disambiguate gestures when multiple recognisers in contention.

Pointers
--------

TODO(ianh): elaborate

Gesture Arenas
--------------

TODO(ianh): elaborate

Gesture Recognisers
-------------------

TODO(ianh): elaborate

Sample Scenarios
----------------

TODO(ianh): elaborate

Limitations
-----------

Flutter does not currently support the following features:
* Mice, trackballs, trackpads, joysticks, "mouse keys", and other input mechanisms that map to persistent pointers.
* Joysticks, trackballs, tabbing, and other mechanisms that map to directional or sequential focus navigation.
* Hover touch effects, where touches are detected before being "down".
