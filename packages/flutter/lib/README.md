SKY SDK
========

Sky and Sky's SDK are designed as layered frameworks, where each layer
depends on the ones below it but could be replaced wholesale.

The bottom-most layer is the Sky Platform, which is exposed to Dart
code as [various `dart:` packages](https://api.dartlang.org/),
including `dart:sky`.

Above this layer is the [animation](animation.dart) library,
which provides core animation primitives, and the [gestures/](gestures/)
directory, which define a gesture recognition and disambiguation system.

The next layer consists of the [painting](painting.dart) library,
which provides APIs related to drawing graphics. Some of the code here
uses the [animation](animation.dart) library mentioned above.

Layout primitives are provided in the next layer, found in the
[rendering](rendering.dart) library. They use `dart:sky` and the
APIs exposed in the [painting](painting.dart) library to provide a retained-mode
layout and rendering model for applications or documents.

Widgets are provided by the files in the [widgets](widgets.dart)
library, using a reactive framework. They use data given in the
[theme/](theme/) directory to select styles consistent with Material
Design.

Alongside the above is the [mojo/](mojo/) directory, which contains
anything that uses the Mojo IPC mechanism, typically as part of
wrapping host operating system features. Some of those Host APIs are
implemented in the host system's preferred language.

Here is a diagram summarizing all this:

    +-----------------------------+ ------
    |           YOUR APP          |
    |  +----------------------+---+
    |  |  widgets   (theme/)  |   |
    | ++---------------------++   |
    | |      rendering       |    |  Dart
    | |---------+------------+    |
    | |         | painting   |    |
    +-+         +------------+    |
    | gestures/ | animation  |    |
    +-----------+------------+    |
    |             mojo/           |
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
