// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'single_child_scroll_view.dart';
/// @docImport 'text.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble, precisionErrorTolerance;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'page_storage.dart';
import 'scroll_configuration.dart';
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_delegate.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_position_with_single_context.dart';
import 'scroll_view.dart';
import 'scrollable.dart';
import 'sliver.dart';
import 'sliver_fill.dart';
import 'sliver_layout_builder.dart';
import 'viewport.dart';

/// A controller for [PageView].
///
/// A page controller lets you manipulate which page is visible in a [PageView].
/// In addition to being able to control the pixel offset of the content inside
/// the [PageView], a [PageController] also lets you control the offset in terms
/// of pages, which are increments of the viewport size.
///
/// See also:
///
///  * [PageView], which is the widget this object controls.
///
/// {@tool snippet}
///
/// This widget introduces a [MaterialApp], [Scaffold] and [PageView] with two pages
/// using the default constructor. Both pages contain an [ElevatedButton] allowing you
/// to animate the [PageView] using a [PageController].
///
/// ```dart
/// class MyPageView extends StatefulWidget {
///   const MyPageView({super.key});
///
///   @override
///   State<MyPageView> createState() => _MyPageViewState();
/// }
///
/// class _MyPageViewState extends State<MyPageView> {
///   final PageController _pageController = PageController();
///
///   @override
///   void dispose() {
///     _pageController.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         body: PageView(
///           controller: _pageController,
///           children: <Widget>[
///             ColoredBox(
///               color: Colors.red,
///               child: Center(
///                 child: ElevatedButton(
///                   onPressed: () {
///                     if (_pageController.hasClients) {
///                       _pageController.animateToPage(
///                         1,
///                         duration: const Duration(milliseconds: 400),
///                         curve: Curves.easeInOut,
///                       );
///                     }
///                   },
///                   child: const Text('Next'),
///                 ),
///               ),
///             ),
///             ColoredBox(
///               color: Colors.blue,
///               child: Center(
///                 child: ElevatedButton(
///                   onPressed: () {
///                     if (_pageController.hasClients) {
///                       _pageController.animateToPage(
///                         0,
///                         duration: const Duration(milliseconds: 400),
///                         curve: Curves.easeInOut,
///                       );
///                     }
///                   },
///                   child: const Text('Previous'),
///                 ),
///               ),
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
class PageController extends ScrollController {
  /// Creates a page controller.
  PageController({
    this.initialPage = 0,
    this.keepPage = true,
    this.viewportFraction = 1.0,
    super.onAttach,
    super.onDetach,
  }) : assert(viewportFraction > 0.0);

  /// The page to show when first creating the [PageView].
  final int initialPage;

  /// Save the current [page] with [PageStorage] and restore it if
  /// this controller's scrollable is recreated.
  ///
  /// If this property is set to false, the current [page] is never saved
  /// and [initialPage] is always used to initialize the scroll offset.
  /// If true (the default), the initial page is used the first time the
  /// controller's scrollable is created, since there's isn't a page to
  /// restore yet. Subsequently the saved page is restored and
  /// [initialPage] is ignored.
  ///
  /// See also:
  ///
  ///  * [PageStorageKey], which should be used when more than one
  ///    scrollable appears in the same route, to distinguish the [PageStorage]
  ///    locations used to save scroll offsets.
  final bool keepPage;

  /// {@template flutter.widgets.pageview.viewportFraction}
  /// The fraction of the viewport that each page should occupy.
  ///
  /// Defaults to 1.0, which means each page fills the viewport in the scrolling
  /// direction.
  /// {@endtemplate}
  final double viewportFraction;

  /// The current page displayed in the controlled [PageView].
  ///
  /// There are circumstances that this [PageController] can't know the current
  /// page. Reading [page] will throw an [AssertionError] in the following cases:
  ///
  /// 1. No [PageView] is currently using this [PageController]. Once a
  /// [PageView] starts using this [PageController], the new [page]
  /// position will be derived:
  ///
  ///   * First, based on the attached [PageView]'s [BuildContext] and the
  ///     position saved at that context's [PageStorage] if [keepPage] is true.
  ///   * Second, from the [PageController]'s [initialPage].
  ///
  /// 2. More than one [PageView] using the same [PageController].
  ///
  /// The [hasClients] property can be used to check if a [PageView] is attached
  /// prior to accessing [page].
  double? get page {
    assert(
      positions.isNotEmpty,
      'PageController.page cannot be accessed before a PageView is built with it.',
    );
    assert(
      positions.length == 1,
      'The page property cannot be read when multiple PageViews are attached to '
      'the same PageController.',
    );
    final position = this.position as _PagePosition;
    return position.page;
  }

  bool _debugCheckPageControllerAttached() {
    assert(positions.isNotEmpty, 'PageController is not attached to a PageView.');
    assert(
      positions.length == 1,
      'Multiple PageViews are attached to '
      'the same PageController.',
    );
    return true;
  }

  /// Animates the controlled [PageView] from the current page to the given page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> animateToPage(int page, {required Duration duration, required Curve curve}) {
    assert(_debugCheckPageControllerAttached());
    final position = this.position as _PagePosition;
    if (position._cachedPage != null) {
      position._cachedPage = page.toDouble();
      return Future<void>.value();
    }

    if (!position.hasViewportDimension) {
      position._pageToUseOnStartup = page.toDouble();
      return Future<void>.value();
    }

    return position.animateTo(
      position.getPixelsFromPage(page.toDouble()),
      duration: duration,
      curve: curve,
    );
  }

  /// Changes which page is displayed in the controlled [PageView].
  ///
  /// Jumps the page position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  void jumpToPage(int page) {
    assert(_debugCheckPageControllerAttached());
    final position = this.position as _PagePosition;
    if (position._cachedPage != null) {
      position._cachedPage = page.toDouble();
      return;
    }

    if (!position.hasViewportDimension) {
      position._pageToUseOnStartup = page.toDouble();
      return;
    }

    position.jumpTo(position.getPixelsFromPage(page.toDouble()));
  }

  /// Animates the controlled [PageView] to the next page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> nextPage({required Duration duration, required Curve curve}) {
    return animateToPage(page!.round() + 1, duration: duration, curve: curve);
  }

  /// Animates the controlled [PageView] to the previous page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> previousPage({required Duration duration, required Curve curve}) {
    return animateToPage(page!.round() - 1, duration: duration, curve: curve);
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _PagePosition(
      physics: physics,
      context: context,
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final pagePosition = position as _PagePosition;
    pagePosition.viewportFraction = viewportFraction;
  }
}

/// Metrics for a [PageView].
///
/// The metrics are available on [ScrollNotification]s generated from
/// [PageView]s.
class PageMetrics extends FixedScrollMetrics {
  /// Creates an immutable snapshot of values associated with a [PageView].
  PageMetrics({
    required super.minScrollExtent,
    required super.maxScrollExtent,
    required super.pixels,
    required super.viewportDimension,
    required super.axisDirection,
    required this.viewportFraction,
    required super.devicePixelRatio,
  });

  @override
  PageMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? viewportFraction,
    double? devicePixelRatio,
  }) {
    return PageMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension:
          viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      viewportFraction: viewportFraction ?? this.viewportFraction,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

  /// The current page displayed in the [PageView].
  double? get page {
    return math.max(0.0, clampDouble(pixels, minScrollExtent, maxScrollExtent)) /
        math.max(1.0, viewportDimension * viewportFraction);
  }

  /// The fraction of the viewport that each page occupies.
  ///
  /// Used to compute [page] from the current [pixels].
  final double viewportFraction;
}

class _PagePosition extends ScrollPositionWithSingleContext implements PageMetrics {
  _PagePosition({
    required super.physics,
    required super.context,
    this.initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    super.oldPosition,
  }) : assert(viewportFraction > 0.0),
       _viewportFraction = viewportFraction,
       _pageToUseOnStartup = initialPage.toDouble(),
       super(initialPixels: null, keepScrollOffset: keepPage);

  final int initialPage;
  double _pageToUseOnStartup;

  // When the viewport has a zero-size, the `page` can not
  // be retrieved by `getPageFromPixels`, so we need to cache the page
  // for use when resizing the viewport to non-zero next time.
  double? _cachedPage;

  @override
  Future<void> ensureVisible(
    RenderObject object, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
    RenderObject? targetRenderObject,
  }) {
    // Since the _PagePosition is intended to cover the available space within
    // its viewport, stop trying to move the target render object to the center
    // - otherwise, could end up changing which page is visible and moving the
    // targetRenderObject out of the viewport.
    return super.ensureVisible(
      object,
      alignment: alignment,
      duration: duration,
      curve: curve,
      alignmentPolicy: alignmentPolicy,
    );
  }

  @override
  double get viewportFraction => _viewportFraction;
  double _viewportFraction;

  set viewportFraction(double value) {
    if (_viewportFraction == value) {
      return;
    }
    final double? oldPage = page;
    _viewportFraction = value;
    if (oldPage != null) {
      forcePixels(getPixelsFromPage(oldPage));
    }
  }

  // The amount of offset that will be added to [minScrollExtent] and subtracted
  // from [maxScrollExtent], such that every page will properly snap to the center
  // of the viewport when viewportFraction is greater than 1.
  //
  // The value is 0 if viewportFraction is less than or equal to 1, larger than 0
  // otherwise.
  double get _initialPageOffset => math.max(0, viewportDimension * (viewportFraction - 1) / 2);

  double getPageFromPixels(double pixels, double viewportDimension) {
    assert(viewportDimension > 0.0);
    final double actual =
        math.max(0.0, pixels - _initialPageOffset) / (viewportDimension * viewportFraction);
    final double round = actual.roundToDouble();
    if ((actual - round).abs() < precisionErrorTolerance) {
      return round;
    }
    return actual;
  }

  double getPixelsFromPage(double page) {
    return page * viewportDimension * viewportFraction + _initialPageOffset;
  }

  @override
  double? get page {
    if (!hasPixels) {
      return null;
    }
    assert(
      hasContentDimensions || !haveDimensions,
      'Page value is only available after content dimensions are established.',
    );
    return hasContentDimensions || haveDimensions
        ? _cachedPage ??
              getPageFromPixels(
                clampDouble(pixels, minScrollExtent, maxScrollExtent),
                viewportDimension,
              )
        : null;
  }

  @override
  void saveScrollOffset() {
    PageStorage.maybeOf(context.storageContext)?.writeState(
      context.storageContext,
      _cachedPage ?? getPageFromPixels(pixels, viewportDimension),
    );
  }

  @override
  void restoreScrollOffset() {
    if (!hasPixels) {
      final value =
          PageStorage.maybeOf(context.storageContext)?.readState(context.storageContext) as double?;
      if (value != null) {
        _pageToUseOnStartup = value;
      }
    }
  }

  @override
  void saveOffset() {
    context.saveOffset(_cachedPage ?? getPageFromPixels(pixels, viewportDimension));
  }

  @override
  void restoreOffset(double offset, {bool initialRestore = false}) {
    if (initialRestore) {
      _pageToUseOnStartup = offset;
    } else {
      jumpTo(getPixelsFromPage(offset));
    }
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions = hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }
    final bool result = super.applyViewportDimension(viewportDimension);
    final double? oldPixels = hasPixels ? pixels : null;
    double page;
    if (oldPixels == null) {
      page = _pageToUseOnStartup;
    } else if (oldViewportDimensions == 0.0) {
      // If resize from zero, we should use the _cachedPage to recover the state.
      page = _cachedPage!;
    } else {
      page = getPageFromPixels(oldPixels, oldViewportDimensions!);
    }
    final double newPixels = getPixelsFromPage(page);

    // If the viewportDimension is zero, cache the page
    // in case the viewport is resized to be non-zero.
    _cachedPage = (viewportDimension == 0.0) ? page : null;

    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    assert(_cachedPage == null);

    if (other is! _PagePosition) {
      return;
    }

    if (other._cachedPage != null) {
      _cachedPage = other._cachedPage;
    }
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final double newMinScrollExtent = minScrollExtent + _initialPageOffset;
    return super.applyContentDimensions(
      newMinScrollExtent,
      math.max(newMinScrollExtent, maxScrollExtent - _initialPageOffset),
    );
  }

  @override
  PageMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? viewportFraction,
    double? devicePixelRatio,
  }) {
    return PageMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension:
          viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      viewportFraction: viewportFraction ?? this.viewportFraction,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

class _ForceImplicitScrollPhysics extends ScrollPhysics {
  const _ForceImplicitScrollPhysics({required this.allowImplicitScrolling, super.parent});

  @override
  _ForceImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForceImplicitScrollPhysics(
      allowImplicitScrolling: allowImplicitScrolling,
      parent: buildParent(ancestor),
    );
  }

  @override
  final bool allowImplicitScrolling;
}

/// Scroll physics used by a [PageView].
///
/// These physics cause the page view to snap to page boundaries.
///
/// See also:
///
///  * [ScrollPhysics], the base class which defines the API for scrolling
///    physics.
///  * [PageView.physics], which can override the physics used by a page view.
class PageScrollPhysics extends ScrollPhysics {
  /// Creates physics for a [PageView].
  const PageScrollPhysics({super.parent});

  @override
  PageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PageScrollPhysics(parent: buildParent(ancestor));
  }

  double _getPage(ScrollMetrics position) {
    if (position is _PagePosition) {
      return position.page!;
    }
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollMetrics position, double page) {
    if (position is _PagePosition) {
      return position.getPixelsFromPage(page);
    }
    return page * position.viewportDimension;
  }

  double _getTargetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = _getPage(position);
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return _getPixels(position, page.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

const PageScrollPhysics _kPagePhysics = PageScrollPhysics();

/// A scrollable list that works page by page.
///
/// Each child of a page view is forced to be the same size as the viewport.
///
/// You can use a [PageController] to control which page is visible in the view.
/// In addition to being able to control the pixel offset of the content inside
/// the [PageView], a [PageController] also lets you control the offset in terms
/// of pages, which are increments of the viewport size.
///
/// The [PageController] can also be used to control the
/// [PageController.initialPage], which determines which page is shown when the
/// [PageView] is first constructed, and the [PageController.viewportFraction],
/// which determines the size of the pages as a fraction of the viewport size.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=J1gE9xvph-A}
///
/// {@tool dartpad}
/// Here is an example of [PageView]. It creates a centered [Text] in each of the three pages
/// which scroll horizontally.
///
/// ** See code in examples/api/lib/widgets/page_view/page_view.0.dart **
/// {@end-tool}
///
/// ## Persisting the scroll position during a session
///
/// Scroll views attempt to persist their scroll position using [PageStorage].
/// For a [PageView], this can be disabled by setting [PageController.keepPage]
/// to false on the [controller]. If it is enabled, using a [PageStorageKey] for
/// the [key] of this widget is recommended to help disambiguate different
/// scroll views from each other.
///
/// See also:
///
///  * [PageController], which controls which page is visible in the view.
///  * [SingleChildScrollView], when you need to make a single child scrollable.
///  * [ListView], for a scrollable list of boxes.
///  * [GridView], for a scrollable grid of boxes.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
class PageView extends StatefulWidget {
  /// Creates a scrollable list that works page by page from an explicit [List]
  /// of widgets.
  ///
  /// This constructor is appropriate for page views with a small number of
  /// children because constructing the [List] requires doing work for every
  /// child that could possibly be displayed in the page view, instead of just
  /// those children that are actually visible.
  ///
  /// Like other widgets in the framework, this widget expects that
  /// the [children] list will not be mutated after it has been passed in here.
  /// See the documentation at [SliverChildListDelegate.children] for more details.
  ///
  /// {@template flutter.widgets.PageView.allowImplicitScrolling}
  /// If [allowImplicitScrolling] is true, the [PageView] will participate in
  /// accessibility scrolling more like a [ListView], where implicit scroll
  /// actions will move to the next page rather than into the contents of the
  /// [PageView].
  /// {@endtemplate}
  PageView({
    super.key,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.controller,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    List<Widget> children = const <Widget>[],
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    ScrollCacheExtent? scrollCacheExtent,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.scrollBehavior,
    this.padEnds = true,
    this.shrinkWrapCrossAxis = false,
  }) : assert(
         scrollCacheExtent == null || (scrollCacheExtent.value > 0.0) == allowImplicitScrolling,
         'scrollCacheExtent and allowImplicitScrolling must be consistent: '
         'scrollCacheExtent must be greater than 0.0 when allowImplicitScrolling is true, '
         'and must be 0.0 when allowImplicitScrolling is false.',
       ),
       scrollCacheExtent =
           scrollCacheExtent ?? ScrollCacheExtent.viewport(allowImplicitScrolling ? 1.0 : 0.0),
       childrenDelegate = SliverChildListDelegate(children);

  /// Creates a scrollable list that works page by page using widgets that are
  /// created on demand.
  ///
  /// This constructor is appropriate for page views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null [itemCount] lets the [PageView] compute the maximum
  /// scroll extent.
  ///
  /// [itemBuilder] will be called only with indices greater than or equal to
  /// zero and less than [itemCount].
  ///
  /// {@macro flutter.widgets.ListView.builder.itemBuilder}
  ///
  /// {@template flutter.widgets.PageView.findChildIndexCallback}
  /// The [findChildIndexCallback] corresponds to the
  /// [SliverChildBuilderDelegate.findChildIndexCallback] property. If null,
  /// a child widget may not map to its existing [RenderObject] when the order
  /// of children returned from the children builder changes.
  /// This may result in state-loss. This callback needs to be implemented if
  /// the order of the children may change at a later time.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.PageView.allowImplicitScrolling}
  PageView.builder({
    super.key,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.controller,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    ScrollCacheExtent? scrollCacheExtent,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.scrollBehavior,
    this.padEnds = true,
    this.shrinkWrapCrossAxis = false,
  }) : assert(
         scrollCacheExtent == null || (scrollCacheExtent.value > 0.0) == allowImplicitScrolling,
         'scrollCacheExtent and allowImplicitScrolling must be consistent: '
         'scrollCacheExtent must be greater than 0.0 when allowImplicitScrolling is true, '
         'and must be 0.0 when allowImplicitScrolling is false.',
       ),
       scrollCacheExtent =
           scrollCacheExtent ?? ScrollCacheExtent.viewport(allowImplicitScrolling ? 1.0 : 0.0),
       childrenDelegate = SliverChildBuilderDelegate(
         itemBuilder,
         findChildIndexCallback: findChildIndexCallback,
         childCount: itemCount,
       );

  /// Creates a scrollable list that works page by page with a custom child
  /// model.
  ///
  /// {@tool dartpad}
  /// This example shows a [PageView] that uses a custom [SliverChildBuilderDelegate] to support child
  /// reordering.
  ///
  /// ** See code in examples/api/lib/widgets/page_view/page_view.1.dart **
  /// {@end-tool}
  ///
  /// {@macro flutter.widgets.PageView.allowImplicitScrolling}
  PageView.custom({
    super.key,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.controller,
    this.physics,
    this.pageSnapping = true,
    this.onPageChanged,
    required this.childrenDelegate,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    ScrollCacheExtent? scrollCacheExtent,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.scrollBehavior,
    this.padEnds = true,
    this.shrinkWrapCrossAxis = false,
  }) : assert(
         scrollCacheExtent == null || (scrollCacheExtent.value > 0.0) == allowImplicitScrolling,
         'scrollCacheExtent and allowImplicitScrolling must be consistent: '
         'scrollCacheExtent must be greater than 0.0 when allowImplicitScrolling is true, '
         'and must be 0.0 when allowImplicitScrolling is false.',
       ),
       scrollCacheExtent =
           scrollCacheExtent ?? ScrollCacheExtent.viewport(allowImplicitScrolling ? 1.0 : 0.0);

  /// {@template flutter.widgets.PageView.allowImplicitScrolling}
  /// Controls whether the widget's pages will respond to
  /// [RenderObject.showOnScreen], which will allow for implicit accessibility
  /// scrolling.
  ///
  /// With this flag set to false, when accessibility focus reaches the end of
  /// the current page and the user attempts to move it to the next element, the
  /// focus will traverse to the next widget outside of the page view.
  ///
  /// With this flag set to true, when accessibility focus reaches the end of
  /// the current page and user attempts to move it to the next element, focus
  /// will traverse to the next page in the page view.
  /// {@endtemplate}
  final bool allowImplicitScrolling;

  /// {@macro flutter.rendering.RenderViewportBase.scrollCacheExtent}
  ///
  /// In [PageView], the default [scrollCacheExtent] uses
  /// [ScrollCacheExtent.viewport], where the value represents the number of
  /// viewport lengths to cache beyond the visible area.
  ///
  /// When [PageController.viewportFraction] is 1.0 (the default), this is
  /// equivalent to the number of pages. For example,
  /// `ScrollCacheExtent.viewport(2.0)` caches 2 pages before and after the
  /// visible page.
  ///
  /// When [PageController.viewportFraction] is less than 1.0, multiple pages
  /// may be visible in a single viewport, so `ScrollCacheExtent.viewport(1.0)`
  /// may cache more than one additional page in each direction.
  ///
  /// [ScrollCacheExtent.pixels] can also be used to specify the cache extent
  /// in logical pixels instead of viewport sizes.
  ///
  /// If [scrollCacheExtent] is specified, its value must be consistent with
  /// [allowImplicitScrolling]: the value must be greater than 0.0 when
  /// [allowImplicitScrolling] is true, and must be 0.0 when
  /// [allowImplicitScrolling] is false.
  ///
  /// Defaults to `ScrollCacheExtent.viewport(1.0)` if
  /// [allowImplicitScrolling] is true, and `ScrollCacheExtent.viewport(0.0)` if
  /// [allowImplicitScrolling] is false.
  final ScrollCacheExtent scrollCacheExtent;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// The [Axis] along which the scroll view's offset increases with each page.
  ///
  /// For the direction in which active scrolling may be occurring, see
  /// [ScrollDirection].
  ///
  /// Defaults to [Axis.horizontal].
  final Axis scrollDirection;

  /// Whether the page view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the page view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the page view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this page
  /// view is scrolled.
  final PageController? controller;

  /// How the page view should respond to user input.
  ///
  /// For example, determines how the page view continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [physics].
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// Set to false to disable page snapping, useful for custom scroll behavior.
  ///
  /// If the [padEnds] is false and [PageController.viewportFraction] < 1.0,
  /// the page will snap to the beginning of the viewport; otherwise, the page
  /// will snap to the center of the viewport.
  final bool pageSnapping;

  /// Called whenever the page in the center of the viewport changes.
  final ValueChanged<int>? onPageChanged;

  /// A delegate that provides the children for the [PageView].
  ///
  /// The [PageView.custom] constructor lets you specify this delegate
  /// explicitly. The [PageView] and [PageView.builder] constructors create a
  /// [childrenDelegate] that wraps the given [List] and [IndexedWidgetBuilder],
  /// respectively.
  final SliverChildDelegate childrenDelegate;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.scrollable.hitTestBehavior}
  ///
  /// Defaults to [HitTestBehavior.opaque].
  final HitTestBehavior hitTestBehavior;

  /// {@macro flutter.widgets.scrollable.scrollBehavior}
  ///
  /// The [ScrollBehavior] of the inherited [ScrollConfiguration] will be
  /// modified by default to not apply a [Scrollbar].
  final ScrollBehavior? scrollBehavior;

  /// Whether to add padding to both ends of the list.
  ///
  /// If this is set to true and [PageController.viewportFraction] < 1.0, padding will be added
  /// such that the first and last child slivers will be in the center of
  /// the viewport when scrolled all the way to the start or end, respectively.
  ///
  /// If [PageController.viewportFraction] >= 1.0, this property has no effect.
  ///
  /// This property defaults to true.
  final bool padEnds;

  /// Whether the page view should shrink-wrap itself to the visible page in
  /// the cross axis.
  ///
  /// When this is true, pages still fill the viewport in the scrolling
  /// direction, but they are laid out with a loose constraint in the cross
  /// axis. The page view then sizes itself to the visible page's size in that
  /// axis.
  ///
  /// For a horizontal [PageView], this means the height adapts to the current
  /// page. For a vertical [PageView], the width adapts.
  ///
  /// This is useful for carousels, columns, and bottom sheets whose pages have
  /// varying heights or widths, but it is more expensive than the default
  /// behavior because the viewport can change size whenever the page position
  /// changes.
  ///
  /// Like any [PageView], the scrolling axis must still be bounded by the
  /// parent. For a horizontal [PageView], this means the width must be bounded.
  /// For a vertical [PageView], the height must be bounded.
  ///
  /// {@tool dartpad}
  /// This example shows a [PageView] with [shrinkWrapCrossAxis] set to true,
  /// placed inside a [Column]. Each page has a different height, and the
  /// [PageView] smoothly changes its height during page transitions.
  ///
  /// ** See code in examples/api/lib/widgets/page_view/page_view.2.dart **
  /// {@end-tool}
  ///
  /// Conceptually, the viewport resizes to match the page that is currently
  /// visible in the cross axis:
  ///
  /// ```text
  /// Before swipe:                After swipe:
  /// ┌──────────────────────┐     ┌────────────────────────────┐
  /// │ PageView (100 high)  │ --> │ PageView (250 high)        │
  /// │ ┌──────────────────┐ │     │ ┌────────────────────────┐ │
  /// │ │ Page 1           │ │     │ │ Page 2                 │ │
  /// │ └──────────────────┘ │     │ └────────────────────────┘ │
  /// └──────────────────────┘     └────────────────────────────┘
  /// ```
  ///
  /// Defaults to false.
  final bool shrinkWrapCrossAxis;

  @override
  State<PageView> createState() => _PageViewState();
}

class _PageViewState extends State<PageView> {
  int _lastReportedPage = 0;

  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
    _lastReportedPage = _controller.initialPage;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _initController() {
    _controller = widget.controller ?? PageController();
  }

  @override
  void didUpdateWidget(PageView oldWidget) {
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _initController();
    }
    super.didUpdateWidget(oldWidget);
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection = textDirectionToAxisDirection(textDirection);
        return widget.reverse ? flipAxisDirection(axisDirection) : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics =
        _ForceImplicitScrollPhysics(allowImplicitScrolling: widget.allowImplicitScrolling).applyTo(
          widget.pageSnapping
              ? _kPagePhysics.applyTo(
                  widget.physics ?? widget.scrollBehavior?.getScrollPhysics(context),
                )
              : widget.physics ?? widget.scrollBehavior?.getScrollPhysics(context),
        );

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 &&
            widget.onPageChanged != null &&
            notification is ScrollUpdateNotification) {
          final metrics = notification.metrics as PageMetrics;
          final int currentPage = metrics.page!.round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            widget.onPageChanged!(currentPage);
          }
        }
        return false;
      },
      child: Scrollable(
        dragStartBehavior: widget.dragStartBehavior,
        axisDirection: axisDirection,
        controller: _controller,
        physics: physics,
        restorationId: widget.restorationId,
        hitTestBehavior: widget.hitTestBehavior,
        scrollBehavior:
            widget.scrollBehavior ?? ScrollConfiguration.of(context).copyWith(scrollbars: false),
        viewportBuilder: (BuildContext context, ViewportOffset position) =>
            _buildViewport(axisDirection: axisDirection, position: position),
      ),
    );
  }

  Widget _buildPageSliver({required bool shrinkWrapCrossAxis}) {
    if (shrinkWrapCrossAxis) {
      return _PageViewShrinkWrappingSliverFillViewport(
        viewportFraction: _controller.viewportFraction,
        delegate: widget.childrenDelegate,
        padEnds: widget.padEnds,
        allowImplicitScrolling: widget.allowImplicitScrolling,
      );
    }
    return SliverFillViewport(
      viewportFraction: _controller.viewportFraction,
      delegate: widget.childrenDelegate,
      padEnds: widget.padEnds,
      allowImplicitScrolling: widget.allowImplicitScrolling,
    );
  }

  Widget _buildViewport({required AxisDirection axisDirection, required ViewportOffset position}) {
    final ScrollCacheExtent scrollCacheExtent = widget.scrollCacheExtent;
    final Widget pageSliver = _buildPageSliver(shrinkWrapCrossAxis: widget.shrinkWrapCrossAxis);

    if (widget.shrinkWrapCrossAxis) {
      return _PageViewCrossAxisShrinkWrappingViewport(
        scrollCacheExtent: scrollCacheExtent,
        axisDirection: axisDirection,
        offset: position,
        clipBehavior: widget.clipBehavior,
        slivers: <Widget>[pageSliver],
      );
    }

    return Viewport(
      scrollCacheExtent: scrollCacheExtent,
      axisDirection: axisDirection,
      offset: position,
      clipBehavior: widget.clipBehavior,
      slivers: <Widget>[pageSliver],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(EnumProperty<Axis>('scrollDirection', widget.scrollDirection));
    description.add(FlagProperty('reverse', value: widget.reverse, ifTrue: 'reversed'));
    description.add(
      DiagnosticsProperty<PageController>('controller', _controller, showName: false),
    );
    description.add(DiagnosticsProperty<ScrollPhysics>('physics', widget.physics, showName: false));
    description.add(
      FlagProperty('pageSnapping', value: widget.pageSnapping, ifFalse: 'snapping disabled'),
    );
    description.add(
      FlagProperty(
        'allowImplicitScrolling',
        value: widget.allowImplicitScrolling,
        ifTrue: 'allow implicit scrolling',
      ),
    );
    description.add(
      DiagnosticsProperty<ScrollCacheExtent>(
        'scrollCacheExtent',
        widget.scrollCacheExtent,
        defaultValue: ScrollCacheExtent.viewport(widget.allowImplicitScrolling ? 1.0 : 0.0),
      ),
    );
    description.add(
      FlagProperty(
        'shrinkWrapCrossAxis',
        value: widget.shrinkWrapCrossAxis,
        ifTrue: 'cross-axis shrink-wrapping',
      ),
    );
  }
}

/// Applies [SliverFillViewport]'s padding behavior while using a custom render
/// sliver that can report the visible page's cross-axis extent back to the
/// viewport.
class _PageViewShrinkWrappingSliverFillViewport extends StatelessWidget {
  const _PageViewShrinkWrappingSliverFillViewport({
    required this.delegate,
    required this.viewportFraction,
    required this.padEnds,
    required this.allowImplicitScrolling,
  });

  final SliverChildDelegate delegate;
  final double viewportFraction;
  final bool padEnds;
  final bool allowImplicitScrolling;

  @override
  Widget build(BuildContext context) {
    final double paddingFraction = padEnds ? clampDouble(1 - viewportFraction, 0, 1) / 2 : 0;
    final Widget sliver = _PageViewSliverFillViewportRenderObjectWidget(
      viewportFraction: viewportFraction,
      allowImplicitScrolling: allowImplicitScrolling,
      delegate: delegate,
    );
    if (paddingFraction == 0.0) {
      return sliver;
    }
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double paddingValue = constraints.viewportMainAxisExtent * paddingFraction;
        return SliverPadding(
          padding: switch (constraints.axis) {
            Axis.horizontal => EdgeInsets.symmetric(horizontal: paddingValue),
            Axis.vertical => EdgeInsets.symmetric(vertical: paddingValue),
          },
          sliver: sliver,
        );
      },
    );
  }
}

/// Creates the render sliver used by [PageView.shrinkWrapCrossAxis].
///
/// This mirrors [_SliverFillViewportRenderObjectWidget], but instantiates a
/// render object that measures its children with loose cross-axis constraints
/// and reports the interpolated visible-page extent to the viewport.
class _PageViewSliverFillViewportRenderObjectWidget extends SliverMultiBoxAdaptorWidget {
  const _PageViewSliverFillViewportRenderObjectWidget({
    required super.delegate,
    this.viewportFraction = 1.0,
    this.allowImplicitScrolling = true,
  }) : assert(viewportFraction > 0.0);

  final double viewportFraction;
  final bool allowImplicitScrolling;

  @override
  _RenderSliverFillViewportWithCrossAxisShrinkWrapping createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverFillViewportWithCrossAxisShrinkWrapping(
      childManager: element,
      viewportFraction: viewportFraction,
      allowImplicitScrolling: allowImplicitScrolling,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSliverFillViewportWithCrossAxisShrinkWrapping renderObject,
  ) {
    renderObject
      ..viewportFraction = viewportFraction
      ..allowImplicitScrolling = allowImplicitScrolling;
  }
}

/// A [RenderSliverFillViewport] that lets pages choose their cross-axis size.
///
/// The main axis still behaves exactly like [RenderSliverFillViewport]: each
/// child gets the viewport fraction of the main axis and scrolls page by page.
/// The difference is that children are laid out with loose constraints in the
/// cross axis, and the sliver reports the visible page's cross-axis extent so
/// the enclosing viewport can shrink-wrap to it.
class _RenderSliverFillViewportWithCrossAxisShrinkWrapping extends RenderSliverFillViewport {
  _RenderSliverFillViewportWithCrossAxisShrinkWrapping({
    required super.childManager,
    super.viewportFraction = 1.0,
    super.allowImplicitScrolling = true,
  });

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    // TODO(Piinks): Clean up when deprecation expires.
    const double deprecatedExtraItemExtent = -1;

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, deprecatedExtraItemExtent);
    final int? targetLastIndex = targetEndScrollOffset.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffset, deprecatedExtraItemExtent)
        : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null
          ? calculateTrailingGarbage(lastIndex: targetLastIndex)
          : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      final double layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      if (!addInitialChild(index: firstIndex, layoutOffset: layoutOffset)) {
        final double max = firstIndex <= 0
            ? 0.0
            : computeMaxScrollOffset(constraints, deprecatedExtraItemExtent);
        geometry = SliverGeometry(scrollExtent: max, maxPaintExtent: max, crossAxisExtent: 0.0);
        childManager.didFinishLayout();
        return;
      }
    }

    final BoxConstraints childConstraints = _getChildConstraintsForShrinkWrapping();

    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      if (child == null) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: indexToLayoutOffset(deprecatedExtraItemExtent, index),
        );
        return;
      }
      final childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(childConstraints, parentUsesSize: true);
      final childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    double estimatedMaxScrollOffset = double.infinity;
    for (
      int index = indexOf(trailingChildWithLayout!) + 1;
      targetLastIndex == null || index <= targetLastIndex;
      ++index
    ) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(
          childConstraints,
          after: trailingChildWithLayout,
          parentUsesSize: true,
        );
        if (child == null) {
          estimatedMaxScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
          break;
        }
      } else {
        child.layout(childConstraints, parentUsesSize: true);
      }
      trailingChildWithLayout = child;
      final childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(
        deprecatedExtraItemExtent,
        childParentData.index!,
      );
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
    final double trailingScrollOffset = indexToLayoutOffset(
      deprecatedExtraItemExtent,
      lastIndex + 1,
    );

    assert(
      firstIndex == 0 || childScrollOffset(firstChild!)! - scrollOffset <= precisionErrorTolerance,
    );
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    estimatedMaxScrollOffset = math.min(
      estimatedMaxScrollOffset,
      estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      ),
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, deprecatedExtraItemExtent)
        : null;

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      crossAxisExtent: _currentPageCrossAxisExtent(),
      hasVisualOverflow:
          (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint) ||
          constraints.scrollOffset > 0.0,
    );

    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }

  BoxConstraints _getChildConstraintsForShrinkWrapping() {
    final double extent = itemExtent;
    return switch (constraints.axis) {
      Axis.horizontal => BoxConstraints(
        minWidth: extent,
        maxWidth: extent,
        maxHeight: constraints.crossAxisExtent,
      ),
      Axis.vertical => BoxConstraints(
        maxWidth: constraints.crossAxisExtent,
        minHeight: extent,
        maxHeight: extent,
      ),
    };
  }

  RenderBox? _childForIndex(int index) {
    RenderBox? child = firstChild;
    while (child != null) {
      final int childIndex = indexOf(child);
      if (childIndex == index) {
        return child;
      }
      if (childIndex > index) {
        return null;
      }
      child = childAfter(child);
    }
    return null;
  }

  double _childCrossAxisExtent(RenderBox child) {
    return switch (constraints.axis) {
      Axis.horizontal => child.size.height,
      Axis.vertical => child.size.width,
    };
  }

  double _currentPageCrossAxisExtent() {
    final RenderBox? firstLiveChild = firstChild;
    if (firstLiveChild == null) {
      return 0.0;
    }

    final double mainAxisExtent = itemExtent;
    if (mainAxisExtent == 0.0) {
      return _childCrossAxisExtent(firstLiveChild);
    }

    final double initialPageOffset = math.max(
      0.0,
      (mainAxisExtent - constraints.viewportMainAxisExtent) / 2.0,
    );
    final double rawPage =
        math.max(0.0, constraints.scrollOffset - initialPageOffset) / mainAxisExtent;
    final int lowerIndex = rawPage.floor();
    final int upperIndex = rawPage.ceil();
    final RenderBox? lowerChild = _childForIndex(lowerIndex);
    final RenderBox? upperChild = _childForIndex(upperIndex);

    if (lowerChild == null && upperChild == null) {
      return _childCrossAxisExtent(firstLiveChild);
    }

    final double lowerExtent = lowerChild != null
        ? _childCrossAxisExtent(lowerChild)
        : _childCrossAxisExtent(upperChild!);
    final double upperExtent = upperChild != null ? _childCrossAxisExtent(upperChild) : lowerExtent;
    final double pageDelta = rawPage - lowerIndex;
    return lowerExtent + (upperExtent - lowerExtent) * pageDelta;
  }
}

/// A viewport variant that accepts cross-axis extents reported by its slivers.
///
/// [PageView] uses this instead of [Viewport] when [PageView.shrinkWrapCrossAxis]
/// is enabled so the viewport can resize to the visible page while still
/// lazily building slivers.
class _PageViewCrossAxisShrinkWrappingViewport extends MultiChildRenderObjectWidget {
  const _PageViewCrossAxisShrinkWrappingViewport({
    this.axisDirection = AxisDirection.down,
    required this.offset,
    this.clipBehavior = Clip.hardEdge,
    this.scrollCacheExtent,
    List<Widget> slivers = const <Widget>[],
  }) : super(children: slivers);

  final AxisDirection axisDirection;
  final ViewportOffset offset;
  final Clip clipBehavior;
  final ScrollCacheExtent? scrollCacheExtent;

  @override
  MultiChildRenderObjectElement createElement() =>
      _PageViewCrossAxisShrinkWrappingViewportElement(this);

  @override
  _RenderPageViewCrossAxisShrinkWrappingViewport createRenderObject(BuildContext context) {
    return _RenderPageViewCrossAxisShrinkWrappingViewport(
      axisDirection: axisDirection,
      crossAxisDirection: Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      offset: offset,
      clipBehavior: clipBehavior,
      scrollCacheExtent: scrollCacheExtent,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPageViewCrossAxisShrinkWrappingViewport renderObject,
  ) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..offset = offset
      ..clipBehavior = clipBehavior
      ..scrollCacheExtent = scrollCacheExtent;
  }
}

/// Tracks onstage children for the shrink-wrapping page-view viewport.
class _PageViewCrossAxisShrinkWrappingViewportElement extends MultiChildRenderObjectElement
    with NotifiableElementMixin, ViewportElementMixin {
  _PageViewCrossAxisShrinkWrappingViewportElement(
    _PageViewCrossAxisShrinkWrappingViewport super.widget,
  );

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children
        .where((Element child) {
          final renderSliver = child.renderObject! as RenderSliver;
          return renderSliver.geometry!.visible;
        })
        .forEach(visitor);
  }
}

/// A shrink-wrapping viewport that only shrinks in the cross axis.
///
/// The main axis remains bounded exactly like a regular [Viewport], but the
/// cross axis is computed from the largest visible sliver-reported extent for
/// the current frame.
class _RenderPageViewCrossAxisShrinkWrappingViewport extends RenderShrinkWrappingViewport {
  _RenderPageViewCrossAxisShrinkWrappingViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.clipBehavior,
    super.scrollCacheExtent,
  });

  @override
  bool debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType does not support returning intrinsic dimensions.'),
          ErrorDescription(
            'Calculating the intrinsic dimensions would require instantiating every child of '
            'the viewport, which defeats the point of viewports being lazy.',
          ),
          ErrorHint(
            'If you are merely trying to shrink-wrap the viewport in the cross axis direction, '
            'you should be able to achieve that effect by just giving the viewport loose '
            'constraints, without needing to measure its intrinsic dimensions.',
          ),
        ]);
      }
      return true;
    }());
    return true;
  }

  late double _maxScrollExtent;
  late double _shrinkWrapExtent;
  late double _lastLaidOutCrossAxisExtent;
  bool _hasReportedShrinkWrapExtent = false;
  bool _hasVisualOverflow = false;

  // Local cache extent field. The base class's _calculatedCacheExtent is
  // library-private, so we maintain our own and override describeSemanticsClip.
  double? _localCalculatedCacheExtent;

  double _calculateCacheOffset(double mainAxisExtent) {
    return switch (scrollCacheExtent.style) {
      CacheExtentStyle.pixel => scrollCacheExtent.value,
      CacheExtentStyle.viewport => scrollCacheExtent.value * mainAxisExtent,
    };
  }

  bool _debugCheckHasBoundedMainAxis() {
    assert(() {
      switch (axis) {
        case Axis.vertical:
          if (!constraints.hasBoundedHeight) {
            throw FlutterError(
              'Vertical viewport was given unbounded height.\n'
              'Cross-axis-shrinkwrapping viewports expand in the main axis to fill their '
              'container and constrain their children to match their extent in the main axis. '
              'In this case, a vertical cross-axis-shrinkwrapping viewport was given an '
              'unlimited amount of vertical space in which to expand.',
            );
          }
        case Axis.horizontal:
          if (!constraints.hasBoundedWidth) {
            throw FlutterError(
              'Horizontal viewport was given unbounded width.\n'
              'Cross-axis-shrinkwrapping viewports expand in the main axis to fill their '
              'container and constrain their children to match their extent in the main axis. '
              'In this case, a horizontal cross-axis-shrinkwrapping viewport was given an '
              'unlimited amount of horizontal space in which to expand.',
            );
          }
      }
      return true;
    }());
    return true;
  }

  @override
  Rect? describeSemanticsClip(RenderSliver? child) {
    if (child != null &&
        child.ensureSemantics &&
        !(child.geometry!.visible || child.geometry!.cacheExtent > 0.0)) {
      return null;
    }
    if (_localCalculatedCacheExtent == null) {
      return semanticBounds;
    }
    return switch (axis) {
      Axis.vertical => Rect.fromLTRB(
        semanticBounds.left,
        semanticBounds.top - _localCalculatedCacheExtent!,
        semanticBounds.right,
        semanticBounds.bottom + _localCalculatedCacheExtent!,
      ),
      Axis.horizontal => Rect.fromLTRB(
        semanticBounds.left - _localCalculatedCacheExtent!,
        semanticBounds.top,
        semanticBounds.right + _localCalculatedCacheExtent!,
        semanticBounds.bottom,
      ),
    };
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    assert(_debugCheckHasBoundedMainAxis());

    final (double mainAxisExtent, double crossAxisExtent) = switch (axis) {
      Axis.vertical => (constraints.maxHeight, constraints.maxWidth),
      Axis.horizontal => (constraints.maxWidth, constraints.maxHeight),
    };

    offset.applyViewportDimension(mainAxisExtent);

    if (firstChild == null) {
      size = switch (axis) {
        Axis.vertical => Size(constraints.minWidth, mainAxisExtent),
        Axis.horizontal => Size(mainAxisExtent, constraints.minHeight),
      };
      _maxScrollExtent = 0.0;
      _shrinkWrapExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }

    double correction;
    while (true) {
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent, offset.pixels);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        final bool didAcceptContentDimension = offset.applyContentDimensions(
          0.0,
          math.max(0.0, _maxScrollExtent - mainAxisExtent),
        );
        if (didAcceptContentDimension) {
          break;
        }
      }
    }

    final double effectiveExtent = switch (axis) {
      Axis.vertical => constraints.constrainWidth(
        _hasReportedShrinkWrapExtent
            ? _shrinkWrapExtent
            : (constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0),
      ),
      Axis.horizontal => constraints.constrainHeight(
        _hasReportedShrinkWrapExtent
            ? _shrinkWrapExtent
            : (constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0),
      ),
    };

    size = switch (axis) {
      Axis.vertical => constraints.constrainDimensions(effectiveExtent, mainAxisExtent),
      Axis.horizontal => constraints.constrainDimensions(mainAxisExtent, effectiveExtent),
    };
  }

  double _attemptLayout(double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(mainAxisExtent.isFinite);
    assert(!crossAxisExtent.isNaN);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _maxScrollExtent = 0.0;
    _shrinkWrapExtent = 0.0;
    _lastLaidOutCrossAxisExtent = crossAxisExtent;
    _hasReportedShrinkWrapExtent = false;
    _hasVisualOverflow = correctedOffset < 0.0;

    _localCalculatedCacheExtent = _calculateCacheOffset(mainAxisExtent);

    return layoutChildSequence(
      child: firstChild,
      scrollOffset: math.max(0.0, correctedOffset),
      overlap: math.min(0.0, correctedOffset),
      layoutOffset: math.max(0.0, -correctedOffset),
      remainingPaintExtent: mainAxisExtent + math.min(0.0, correctedOffset),
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: mainAxisExtent + 2 * _localCalculatedCacheExtent!,
      cacheOrigin: -_localCalculatedCacheExtent!,
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    assert(growthDirection == GrowthDirection.forward);
    _maxScrollExtent += childLayoutGeometry.scrollExtent;
    if (childLayoutGeometry.hasVisualOverflow) {
      _hasVisualOverflow = true;
    }
    if (!childLayoutGeometry.visible) {
      return;
    }
    final double? childCrossAxisExtent = childLayoutGeometry.crossAxisExtent;
    if (childCrossAxisExtent == null) {
      if (!_lastLaidOutCrossAxisExtent.isFinite) {
        return;
      }
      _hasReportedShrinkWrapExtent = true;
      _shrinkWrapExtent = math.max(_shrinkWrapExtent, _lastLaidOutCrossAxisExtent);
      return;
    }
    assert(childCrossAxisExtent.isFinite);
    _hasReportedShrinkWrapExtent = true;
    _shrinkWrapExtent = math.max(_shrinkWrapExtent, childCrossAxisExtent);
  }
}
