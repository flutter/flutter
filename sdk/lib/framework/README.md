SKY SDK
========

Sky and Sky's SDK are designed as layered frameworks, where each layer
depends on the ones below it but could be replaced wholesale.

The bottom-most layer is the Sky Platform, which is exposed to Dart
code as the ```dart:sky``` package.

Above this are the files in the [painting/](painting/) directory,
which provide APIs related to drawing graphics.

Layout primitives are provided in the next layer, found in the
[rendering/](rendering/) directory. They use ```dart:sky``` and the
APIs exposed in painting/ to provide a retained-mode layout and
rendering model for applications or documents.

Widgets are provided by the files in the [widgets/](widgets/)
directory, using a reactive framework.

Text input widgets are layered on this mechanism and can be found in
the [editing2/](editing2/) directory.
