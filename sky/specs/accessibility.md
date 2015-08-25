Accessibility
=============

iOS and Android accessibility APIs want to synchronously communicate
with the main thread, so we need to ship a description of the UI to a
service on the main thread, from our Dart thread.

On the Dart side, we need a RenderAccessibleBox on the render tree,
which can be configured with all the various things the accessibility
APIs might care about (e.g. accessible name, checkedness, etc).
Separate from the layout and paint phases we have a phase that builds
an accessibility tree and sends it over to the aforementioned thread.
When a RenderAccessibleBox's configuration changes, it updates the
main thread also.

Maybe RenderParagraph also participates in this so that all text is
automatically exposed.

The main thread can send events like "activate" or "increment slider"
back to a RenderAccessibleBox, which should expose them somehow.

On the Widget side we'd have an Accessible widget that is a
OneChildRenderNodeWrapper for RenderAccessibleBox and does what you'd
expect, maybe also exposing the callbacks.

Components would wrap their interactive parts with these Accessible
widgets.

Ideally we'd have a way to make the default "activate" action
automatically turn into a "tap" gesture.
