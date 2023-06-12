[![](https://img.shields.io/pub/v/flutter_fortune_wheel)](https://pub.dev/packages/flutter_fortune_wheel)
[![Coverage Status](https://coveralls.io/repos/github/kevlatus/flutter_fortune_wheel/badge.svg?branch=main)](https://coveralls.io/github/kevlatus/flutter_fortune_wheel?branch=main)

# Flutter Fortune Wheel

This Flutter package includes wheel of fortune widgets, which allow you to visualize random selection processes.
They are highly customizable and work across mobile, desktop and the web.

<p align="center">
  <img src="https://raw.githubusercontent.com/kevlatus/flutter_fortune_wheel/main/images/img-wheel-256.png">
</p>

You can learn more about the wheel's implementation [in this article](https://www.kevlatus.de/blog/making-of-flutter-fortune-wheel)
and try an [interactive demo here](https://kevlatus.github.io/flutter_fortune_wheel).

## Quick Start

First install the package via [pub.dev](https://pub.dev/packages/flutter_fortune_wheel/install).
Then import and use the [FortuneWheel](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/FortuneWheel-class.html):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
StreamController<int> controller = StreamController<int>();
FortuneWheel(
  selected: controller.stream,
  items: [
    FortuneItem(child: Text('Han Solo')),
    FortuneItem(child: Text('Yoda')),
    FortuneItem(child: Text('Obi-Wan Kenobi')),
  ],
)
```

## Examples

The wheel of fortune is the most iconic visualization.

<p align="center">
  <img src="https://raw.githubusercontent.com/kevlatus/flutter_fortune_wheel/main/images/wheel-spin.gif">
</p>

Unfortunately, a circular shape is not the best solution when vertical screen space is scarce. Therefore,
the fortune bar, which is smaller in the vertical direction, is provided as an alternative. See below for an example:

<p align="center">
  <img src="https://raw.githubusercontent.com/kevlatus/flutter_fortune_wheel/main/images/img-bar-anim.gif">
</p>

```dart
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

StreamController<int> controller = StreamController<int>();
FortuneBar(
  selected: controller.stream,
  items: [
    FortuneItem(child: Text('Han Solo')),
    FortuneItem(child: Text('Yoda')),
    FortuneItem(child: Text('Obi-Wan Kenobi')),
  ],
)
```

## Customization

### Drag Behavior

By default, the fortune widgets react to touch and drag input. This behavior can be customized using the `physics` property, which expects an implementation
of the [`PanPhysics`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/PanPhysics-class.html) class.
If you want to disable dragging, simply pass an instance of [`NoPanPhysics`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/NoPanPhysics-class.html).

For the FortuneWheel, [`CircularPanPhysics`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/CircularPanPhysics-class.html)
is recommended, while the FortuneBar uses [`DirectionalPanPhysics.horizontal`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/DirectionalPanPhysics/DirectionalPanPhysics.horizontal.html)
by default. If none of the available implementations, suit your needs, you can always implement a subclass of [`PanPhysics`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/PanPhysics-class.html).

The callback passed to `onFling` is called when the pan physics detects a fling gesture. This gives
you the opportunity to select a new random item.

```dart
StreamController<int> controller = StreamController<int>();
FortuneWheel(
  // changing the return animation when the user stops dragging
  physics: CircularPanPhysics(
    duration: Duration(seconds: 1),
    curve: Curves.decelerate,
  ),
  onFling: () {
    controller.add(1);
  }
  selected: controller.stream,
  items: [
    FortuneItem(child: Text('Han Solo')),
    FortuneItem(child: Text('Yoda')),
    FortuneItem(child: Text('Obi-Wan Kenobi')),
  ],
)
```

### Item Styling

FortuneItems can be styled individually using their `style` property. Styling a FortuneWidget's
items according to a common logic is achieved by passing a [`StyleStrategy`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/StyleStrategy-class.html).
By default, the FortuneWheel uses the [`AlternatingStyleStrategy`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/AlternatingStyleStrategy-class.html)
and the FortuneBar uses the [`UniformStyleStrategy`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/UniformStyleStrategy-class.html).
As with drag behavior, you can pass custom implementations to the `styleStrategy` property.

```dart
// styling FortuneItems individually
FortuneWheel(
  selected: Stream.value(0),
  items: [
    FortuneItem(
      child: Text('A'),
      style: FortuneItemStyle(
        color: Colors.red, // <-- custom circle slice fill color
        borderColor: Colors.green, // <-- custom circle slice stroke color
        borderWidth: 3, // <-- custom circle slice stroke width
      ),
    ),
    FortuneItem(child: Text('B')),
  ],
)

// common styling for all items of a FortuneWidget
FortuneBar(
  // using alternating item styles on a fortune bar
  styleStrategy: AlternatingStyleStrategy(),
  selected: Stream.value(0),
  items: [
    FortuneItem(child: Text('Han Solo')),
    FortuneItem(child: Text('Yoda')),
    FortuneItem(child: Text('Obi-Wan Kenobi')),
  ],
)
```

### Indicator Styling

The position indicators can be customized by passing a list of [FortuneIndicators](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/FortuneIndicator-class.html) to [`FortuneWidget.indicators`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/FortuneWidget/indicators.html). By default, the [`FortuneWheel`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/FortuneWheel-class.html) uses a [`TriangleIndicator`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/TriangleIndicator-class.html) and the [`FortuneBar`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/FortuneBar-class.html) uses a [`RectangleIndicator`](https://pub.dev/documentation/flutter_fortune_wheel/latest/flutter_fortune_wheel/RectangleIndicator-class.html). You may either pass styled versions of these existing widgets or create your own implementations, since indicators can be any kind of widget. Here is an example of using a customized indicator:

```dart
FortuneWheel(
  selected: Stream.value(0),
  indicators: <FortuneIndicator>[
    FortuneIndicator(
      alignment: Alignment.bottomCenter, // <-- changing the position of the indicator
      child: TriangleIndicator(
        color: Colors.green, // <-- changing the color of the indicator
      ),
    ),
  ],
  items: [
    FortuneItem(child: Text('A'))
    FortuneItem(child: Text('B')),
  ],
)
```

## Contributions

Contributions are much appreciated.

If you have any ideas for alternative visualizations, feel free to 
[open a pull request](https://github.com/kevlatus/flutter_fortune_wheel/pulls) or
[raise an issue](https://github.com/kevlatus/flutter_fortune_wheel/issues).
The same holds for any requests regarding existing widgets.
