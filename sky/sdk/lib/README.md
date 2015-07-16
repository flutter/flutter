SKY SDK
========

Sky and Sky's SDK are designed as layered frameworks, where each layer
depends on the ones below it but could be replaced wholesale.

The bottom-most layer is the Sky Platform, which is exposed to Dart
code as [various ```dart:``` packages](https://api.dartlang.org/),
including ```dart:sky```.

The [base/](base/) directory contains libraries that extend these core
APIs to provide base classes for tree structures
([base/node.dart](base/node.dart)), hit testing
([base/hit_test.dart](base/hit_test.dart)), debugging
([base/debug.dart](base/debug.dart)), and task scheduling
([base/scheduler.dart](base/scheduler.dart)).

Above this are the files in the [painting/](painting/) directory,
which provide APIs related to drawing graphics, and in the
[animation/](animation/) directory, which provide core primitives for
animating values.

Layout primitives are provided in the next layer, found in the
[rendering/](rendering/) directory. They use ```dart:sky``` and the
APIs exposed in painting/ to provide a retained-mode layout and
rendering model for applications or documents.

Widgets are provided by the files in the [widgets/](widgets/)
directory, using a reactive framework. They use data given in the
[theme/](theme/) directory to select styles consistent with Material
Design.

Text input widgets are layered on this mechanism and can be found in
the [editing/](editing/) directory.

Alongside the above is the [mojo/](mojo/) directory, which contains
anything that uses the Mojo IPC mechanism, typically as part of
wrapping host operating system features. Some of those Host APIs are
implemented in the host system's preferred language.

Here is a diagram summarising all this:

    +-----------------------------+ ------
    |           YOUR APP          |
    |     +--------------------+--+ 
    |     |      editing/      |  |
    |  +--+-------------------++  |
    |  |  widgets/  (theme/)  |   |
    | ++---------------------++   |  Dart
    | |      rendering/      |    |
    +-+---------+------------+    |
    | painting/ | animation/ |    |
    +---------------+--------+    |
    |    base/      |  mojo/      |
    +------------+--+-+----+------+ -------
    |  dart:sky  |    |    | Host |
    +--------+---+    |    | APIs |  C++
    |  Skia  |  Dart  |    +------+  ObjC
    +--------+--------+           |  Java
    |            Mojo             |
    +-----------------------------+ -------
    |    Host Operating System    |  C/C++
    +-----------------------------+ -------

TODO(ianh): document dart:sky and the Host APIs somewhere

Sky Engine API
--------------

The Sky engine API provides efficient, immutable wrappers
for common Skia C++ types, notably Color, Point, and Rect.
Because these wrappers are immutable, they are suitable
for storage in final member variables of widget classes.
More complex Skia wrappers such as Paint and RRect are
mutable, to more closely match the Skia APIs. We recommend
constructing wrappers for complex Skia classes dynamically
during the painting phase based on the underlying state of
the widget.
