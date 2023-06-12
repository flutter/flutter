## [1.2.0] - 2022-02-01

- new parameter `alignment` on the `FortuneWheel`
  - this allows for rotating the wheel to adjust for indicator positions

## [1.1.2] - 2022-02-01

- touch panning is now disabled when a FortuneWidget is animating

## [1.1.0] - 2021-07-04

- add gesture detection to FortuneItems
- improve wheel performance by reducing the number of calculations and transformations

## [1.0.1] - 2021-06-19

- bump flutter_hooks dependency to v0.17.0
- fix horizontal wheel alignment for RTL locales


## [1.0.0] - 2021-05-09

- **Breaking Change**: FortuneWidgets now accept Stream<int> instead of int to select items
  - this change enables the same item to be selected multiple times in a row and also triggering the animation
- fix FortuneBar centering when there are only two items

## [0.4.2] - 2021-03-06

fix wheel positioning for right-to-left locales

## [0.4.1] - 2021-02-23

improve documentation for pan physics

## [0.4.0] - 2021-02-22

provide support for null-safety

## [0.3.6] - 2021-02-23

improve documentation for pan physics

## [0.3.5] - 2021-02-23

fix pub.dev scoring by downgrading flutter_hooks dependency...

## [0.3.4] - 2021-02-23

fix pub.dev scoring by downgrading quiver dependency

## [0.3.3] - 2021-02-22

docs: add docs for pan behavior

## [0.3.1] - 2021-02-22

feat: implement drag behavior for FortuneBar

## [0.3.0] - 2021-02-21

feat: implement drag behavior for FortuneWheel

## [0.2.0] - 2020-12-26

feat: add styling strategies for individual items

## [0.1.1] - 2020-12-20

docs: add basic dartdoc and README documentation

## [0.1.0] - 2020-12-19

feat: add alternative FortuneBar widget

## [0.0.9] - 2020-12-13

feat: adjust default roll duration to 2 seconds and increase bezier easing

## [0.0.8] - 2020-12-13

feat: adjust default roll duration to 2 seconds and increase bezier easing
feat: make triangle indicator square
feat: make wheel theme-aware by adjusting text and wheel colors to theme colors

## [0.0.7] - 2020-12-13

feat: remove opacity from default circle slice colors
fix: fire onAnimationEnd when onAnimationStart is not provided and vice versa

## [0.0.6] - 2020-12-12

fix bug, which prevented animation end callbacks to be called on web

## [0.0.5] - 2020-12-11

only animate when the selected value changes

## [0.0.4] - 2020-12-11

add animation types and start/end callbacks

## [0.0.3] - 2020-12-02

add option to spin wheel on initialization

## [0.0.2] - 2020-07-06

add example app

## [0.0.1] - 2020-07-06

initial draft of the fortune wheel
