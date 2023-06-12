# 4.2.1

- [FIX] temporary remove `PointerDeviceKind.trackpad`
- [FIX] fix `'double?'` type

# 4.2.0

- [Add] `enlargeFactor` option
- [Add] `CenterPageEnlargeStrategy.zoom` option
- [Add] `animateToClosest` option

- [FIX] clear timer if widget was unmounted
- [FIX] scroll carousel using touchpad

# 4.1.1

- Fix code formatting

# 4.1.0

## Add

- Exposed `clipBehavior` in `CarouselOptions`
- Exposed `padEnds` in `CarouselOptions`
- Add `copyWith` method to `CarouselOptions`

## Fix

- [FIX] Can't swipe on web with Flutter 2.5


# 4.0.0

- Support null safety (Null safety isn't a breaking change and is Backward compatible meaning you can use it with non-null safe code too)
- Update example code to null safety and add Dark theme support and controller support to indicators in on of the examples and also fix overflow errors. 

# 3.0.0

## Add

- Add third argument in `itemBuilder`, allow Hero and infinite scroll to coexist

## Breaking change

- `itemBuilder` needs to accept three arguments, instead of two.

# 2.3.4

## Fix

- Rollback PR #222, due to it will break the existing project.

# 2.3.3

- Fix code formatting

# 2.3.2

## Fix

- Double pointer down and up will cause a exception
- Fix `CarouselPageChangedReason`

## Add

- Allow Hero and infinite scroll to coexist

# 2.3.1

- Fix code formatting

# 2.3.0

## Fix

- Fixed unresponsiveness to state changes

## Add

- Added start/stop autoplay functionality
- Pause auto play if not current route
- Add `pageSnapping` option for disable page snapping for the carousel

# 2.2.1

## Fix

- Fixed `carousel_options.dart` and `carousel_controller` not being exported by default.

# 2.2.0

## Add

- `disableCenter` option

This option controls whether the carousel slider item should be wrapped in a `Center` widget or not.

- `enlargeStrategy` option

This option allow user to set which enlarge strategy to enlarge the center slide. Use `CenterPageEnlargeStrategy.height` if you want to improve the performance.

## Fix

- Fixed `CarousePageChangedReason.manual` never being emitted

# 2.1.0

## Add

- `pauseAutoPlayOnTouch` option

This option controls whether the carousel slider should pause the auto play function when user is touching the slider

- `pauseAutoPlayOnManualNavigate` option

This option controls whether the carousel slider should pause the auto play function when user is calling controller's method.

- `pauseAutoPlayInFiniteScroll` option

This option decide the carousel should go to the first item when it reach the last item or not.

- `pageViewKey` option

This option is useful when you want to keep the pageview's position when it was recreated.

## Fix

- Fix `CarouselPageChangedReason` bug

## Other updates

- Use `Transform.scale` instead of `SizedBox` to wrap the slider item

# 2.0.0

## Breaking change

Instead of passing all the options to the `CarouselSlider`, now you'll need to pass these option to `CarouselOptions`:

```dart
CarouselSlider(
  CarouselOptions(height: 400.0),
  items: [1,2,3,4,5].map((i) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: Colors.amber
          ),
          child: Text('text $i', style: TextStyle(fontSize: 16.0),)
        );
      },
    );
  }).toList(),
)
```

## Add

- `CarouselController`

Since `v2.0.0`, `carousel_slider` plugin provides a way to pass your own `CaourselController`, and you can use `CaouselController` instance to manually control the carousel's position. For a more detailed example please refer to [example project](example/lib/main.dart).

- `CarouselPageChangedReason`

Now you can receive a `CarouselPageChangedReason` in `onPageChanged` callback.

## Remove

- `pauseAutoPlayOnTouch`

`pauseAutoPlayOnTouch` option is removed, because it doesn't fix the problem we have. Currently, when we enable the `autoPlay` feature, we can not stop sliding when the user interact with the carousel. This is [a flutter's issue](https://github.com/flutter/flutter/issues/54875).

# 1.4.1

## Fix

- Fix `animateTo()/jumpTo()` with non-zero initialPage

# 1.4.0

## Add

- Add on-demand item feature

## Fix

- Fix `setState() called after dispose()` bug

# 1.3.1

## Add

- Scroll physics option

## Fix

- onPage indexing bug


# 1.3.0

## Deprecation

- Remove the deprecated param: `interval`, `autoPlayDuration`, `distortion`, `updateCallback`. Please use the new param.

## Fix

-  Fix `enlargeCenterPage` option is not working in `vertical` carousel slider.

# 1.2.0

## Add

- Vertical scroll support
- Enable/disable infinite scroll

# 1.1.0

## Add

- Added `pauseAutoPlayOnTouch` option
- Add documentation

# 1.0.1

## Add

- Update doc

# 1.0.0

## Add

- Added `distortion` option


# 0.0.6

## Fix

- Fix hard coded number

# 0.0.5

## Fix

- Fix `initialPage` bug, fix crash when widget is disposed.


# v0.0.2

Remove useless dependencies, add changelog.

# v0.0.1

Initial version.
