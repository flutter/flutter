// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'pages.dart';
import 'routes.dart';
import 'transitions.dart';

/// Signature for a function that takes two [Rect] instances and returns a
/// [RectTween] that transitions between them.
///
/// This is typically used with a [HeroController] to provide an animation for
/// [Hero] positions that looks nicer than a linear movement. For example, see
/// [MaterialRectArcTween].
typedef CreateRectTween = Tween<Rect> Function(Rect begin, Rect end);

/// A function that lets [Hero]s self supply a [Widget] that is shown during the
/// hero's flight from one route to another instead of default (which is to
/// show the destination route's instance of the Hero).
typedef HeroFlightShuttleBuilder = Widget Function(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
);

typedef _OnFlightEnded = void Function(_HeroFlight flight);

/// Direction of the hero's flight based on the navigation operation.
enum HeroFlightDirection {
  /// A flight triggered by a route push.
  ///
  /// The animation goes from 0 to 1.
  ///
  /// If no custom [HeroFlightShuttleBuilder] is supplied, the top route's
  /// [Hero] child is shown in flight.
  push,

  /// A flight triggered by a route pop.
  ///
  /// The animation goes from 1 to 0.
  ///
  /// If no custom [HeroFlightShuttleBuilder] is supplied, the bottom route's
  /// [Hero] child is shown in flight.
  pop,
}

// The bounding box for context in global coordinates.
Rect _globalBoundingBoxFor(BuildContext context) {
  final RenderBox box = context.findRenderObject();
  assert(box != null && box.hasSize);
  return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
}

/// A widget that marks its child as being a candidate for
/// [hero animations](https://flutter.dev/docs/development/ui/animations/hero-animations).
///
/// When a [PageRoute] is pushed or popped with the [Navigator], the entire
/// screen's content is replaced. An old route disappears and a new route
/// appears. If there's a common visual feature on both routes then it can
/// be helpful for orienting the user for the feature to physically move from
/// one page to the other during the routes' transition. Such an animation
/// is called a *hero animation*. The hero widgets "fly" in the Navigator's
/// overlay during the transition and while they're in-flight they're, by
/// default, not shown in their original locations in the old and new routes.
///
/// To label a widget as such a feature, wrap it in a [Hero] widget. When
/// navigation happens, the [Hero] widgets on each route are identified
/// by the [HeroController]. For each pair of [Hero] widgets that have the
/// same tag, a hero animation is triggered.
///
/// If a [Hero] is already in flight when navigation occurs, its
/// flight animation will be redirected to its new destination. The
/// widget shown in-flight during the transition is, by default, the
/// destination route's [Hero]'s child.
///
/// For a Hero animation to trigger, the Hero has to exist on the very first
/// frame of the new page's animation.
///
/// Routes must not contain more than one [Hero] for each [tag].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=Be9UH1kXFDw}
///
/// ## Discussion
///
/// Heroes and the [Navigator]'s [Overlay] [Stack] must be axis-aligned for
/// all this to work. The top left and bottom right coordinates of each animated
/// Hero will be converted to global coordinates and then from there converted
/// to that [Stack]'s coordinate space, and the entire Hero subtree will, for
/// the duration of the animation, be lifted out of its original place, and
/// positioned on that stack. If the [Hero] isn't axis aligned, this is going to
/// fail in a rather ugly fashion. Don't rotate your heroes!
///
/// To make the animations look good, it's critical that the widget tree for the
/// hero in both locations be essentially identical. The widget of the *target*
/// is, by default, used to do the transition: when going from route A to route
/// B, route B's hero's widget is placed over route A's hero's widget. If a
/// [flightShuttleBuilder] is supplied, its output widget is shown during the
/// flight transition instead.
///
/// By default, both route A and route B's heroes are hidden while the
/// transitioning widget is animating in-flight above the 2 routes.
/// [placeholderBuilder] can be used to show a custom widget in their place
/// instead once the transition has taken flight.
///
/// During the transition, the transition widget is animated to route B's hero's
/// position, and then the widget is inserted into route B. When going back from
/// B to A, route A's hero's widget is, by default, placed over where route B's
/// hero's widget was, and then the animation goes the other way.
///
/// ### Nested Navigators
///
/// If either or both routes contain nested [Navigator]s, only [Hero]s
/// contained in the top-most routes (as defined by [Route.isCurrent]) *of those
/// nested [Navigator]s* are considered for animation. Just like in the
/// non-nested case the top-most routes containing these [Hero]s in the nested
/// [Navigator]s have to be [PageRoute]s.
///
/// ## Parts of a Hero Transition
///
/// ![Diagrams with parts of the Hero transition.](https://flutter.github.io/assets-for-api-docs/assets/interaction/heroes.png)
class Hero extends StatefulWidget {
  /// Create a hero.
  ///
  /// The [tag] and [child] parameters must not be null.
  /// The [child] parameter and all of the its descendants must not be [Hero]s.
  const Hero({
    Key key,
    @required this.tag,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
    @required this.child,
  }) : assert(tag != null),
       assert(transitionOnUserGestures != null),
       assert(child != null),
       super(key: key);

  /// The identifier for this particular hero. If the tag of this hero matches
  /// the tag of a hero on a [PageRoute] that we're navigating to or from, then
  /// a hero animation will be triggered.
  final Object tag;

  /// Defines how the destination hero's bounds change as it flies from the starting
  /// route to the destination route.
  ///
  /// A hero flight begins with the destination hero's [child] aligned with the
  /// starting hero's child. The [Tween<Rect>] returned by this callback is used
  /// to compute the hero's bounds as the flight animation's value goes from 0.0
  /// to 1.0.
  ///
  /// If this property is null, the default, then the value of
  /// [HeroController.createRectTween] is used. The [HeroController] created by
  /// [MaterialApp] creates a [MaterialRectAreTween].
  final CreateRectTween createRectTween;

  /// The widget subtree that will "fly" from one route to another during a
  /// [Navigator] push or pop transition.
  ///
  /// The appearance of this subtree should be similar to the appearance of
  /// the subtrees of any other heroes in the application with the same [tag].
  /// Changes in scale and aspect ratio work well in hero animations, changes
  /// in layout or composition do not.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Optional override to supply a widget that's shown during the hero's flight.
  ///
  /// This in-flight widget can depend on the route transition's animation as
  /// well as the incoming and outgoing routes' [Hero] descendants' widgets and
  /// layout.
  ///
  /// When both the source and destination [Hero]s provide a [flightShuttleBuilder],
  /// the destination's [flightShuttleBuilder] takes precedence.
  ///
  /// If none is provided, the destination route's Hero child is shown in-flight
  /// by default.
  final HeroFlightShuttleBuilder flightShuttleBuilder;

  /// Placeholder widget left in place as the Hero's child once the flight takes off.
  ///
  /// By default, an empty SizedBox keeping the Hero child's original size is
  /// left in place once the Hero shuttle has taken flight.
  final TransitionBuilder placeholderBuilder;

  /// Whether to perform the hero transition if the [PageRoute] transition was
  /// triggered by a user gesture, such as a back swipe on iOS.
  ///
  /// If [Hero]s with the same [tag] on both the from and the to routes have
  /// [transitionOnUserGestures] set to true, a back swipe gesture will
  /// trigger the same hero animation as a programmatically triggered push or
  /// pop.
  ///
  /// The route being popped to or the bottom route must also have
  /// [PageRoute.maintainState] set to true for a gesture triggered hero
  /// transition to work.
  ///
  /// Defaults to false and cannot be null.
  final bool transitionOnUserGestures;

  // Returns a map of all of the heroes in `context` indexed by hero tag that
  // should be considered for animation when `navigator` transitions from one
  // PageRoute to another.
  static Map<Object, _HeroState> _allHeroesFor(
      BuildContext context,
      bool isUserGestureTransition,
      NavigatorState navigator,
  ) {
    assert(context != null);
    assert(isUserGestureTransition != null);
    assert(navigator != null);
    final Map<Object, _HeroState> result = <Object, _HeroState>{};

    void addHero(StatefulElement hero, Object tag) {
      assert(() {
        if (result.containsKey(tag)) {
          throw FlutterError(
            'There are multiple heroes that share the same tag within a subtree.\n'
            'Within each subtree for which heroes are to be animated (i.e. a PageRoute subtree), '
            'each Hero must have a unique non-null tag.\n'
            'In this case, multiple heroes had the following tag: $tag\n'
            'Here is the subtree for one of the offending heroes:\n'
            '${hero.toStringDeep(prefixLineOne: "# ")}'
          );
        }
        return true;
      }());
      final _HeroState heroState = hero.state;
      result[tag] = heroState;
    }

    void visitor(Element element) {
      if (element.widget is Hero) {
        final StatefulElement hero = element;
        final Hero heroWidget = element.widget;
        if (!isUserGestureTransition || heroWidget.transitionOnUserGestures) {
          final Object tag = heroWidget.tag;
          assert(tag != null);
          if (Navigator.of(hero) == navigator) {
            addHero(hero, tag);
          } else {
            // The nearest navigator to the Hero is not the Navigator that is
            // currently transitioning from one route to another. This means
            // the Hero is inside a nested Navigator and should only be
            // considered for animation if it is part of the top-most route in
            // that nested Navigator and if that route is also a PageRoute.
            final ModalRoute<dynamic> heroRoute = ModalRoute.of(hero);
            if (heroRoute != null && heroRoute is PageRoute && heroRoute.isCurrent) {
              addHero(hero, tag);
            }
          }
        }
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return result;
  }

  @override
  _HeroState createState() => _HeroState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('tag', tag));
  }
}

class _HeroState extends State<Hero> {
  final GlobalKey _key = GlobalKey();
  Size _placeholderSize;

  void startFlight() {
    assert(mounted);
    final RenderBox box = context.findRenderObject();
    assert(box != null && box.hasSize);
    setState(() {
      _placeholderSize = box.size;
    });
  }

  void endFlight() {
    if (mounted) {
      setState(() {
        _placeholderSize = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      context.ancestorWidgetOfExactType(Hero) == null,
      'A Hero widget cannot be the descendant of another Hero widget.'
    );

    if (_placeholderSize != null) {
      if (widget.placeholderBuilder == null) {
        return SizedBox(
          width: _placeholderSize.width,
          height: _placeholderSize.height,
        );
      } else {
        return widget.placeholderBuilder(context, widget.child);
      }
    }
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

// Everything known about a hero flight that's to be started or diverted.
class _HeroFlightManifest {
  _HeroFlightManifest({
    @required this.type,
    @required this.overlay,
    @required this.navigatorRect,
    @required this.fromRoute,
    @required this.toRoute,
    @required this.fromHero,
    @required this.toHero,
    @required this.createRectTween,
    @required this.shuttleBuilder,
    @required this.isUserGestureTransition,
  }) : assert(fromHero.widget.tag == toHero.widget.tag);

  final HeroFlightDirection type;
  final OverlayState overlay;
  final Rect navigatorRect;
  final PageRoute<dynamic> fromRoute;
  final PageRoute<dynamic> toRoute;
  final _HeroState fromHero;
  final _HeroState toHero;
  final CreateRectTween createRectTween;
  final HeroFlightShuttleBuilder shuttleBuilder;
  final bool isUserGestureTransition;

  Object get tag => fromHero.widget.tag;

  Animation<double> get animation {
    return CurvedAnimation(
      parent: (type == HeroFlightDirection.push) ? toRoute.animation : fromRoute.animation,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  String toString() {
    return '_HeroFlightManifest($type tag: $tag from route: ${fromRoute.settings} '
        'to route: ${toRoute.settings} with hero: $fromHero to $toHero)';
  }
}

// Builds the in-flight hero widget.
class _HeroFlight {
  _HeroFlight(this.onFlightEnded) {
    _proxyAnimation = ProxyAnimation()..addStatusListener(_handleAnimationUpdate);
  }

  final _OnFlightEnded onFlightEnded;

  Tween<Rect> heroRectTween;
  Widget shuttle;

  Animation<double> _heroOpacity = kAlwaysCompleteAnimation;
  ProxyAnimation _proxyAnimation;
  _HeroFlightManifest manifest;
  OverlayEntry overlayEntry;
  bool _aborted = false;

  Tween<Rect> _doCreateRectTween(Rect begin, Rect end) {
    final CreateRectTween createRectTween = manifest.toHero.widget.createRectTween ?? manifest.createRectTween;
    if (createRectTween != null)
      return createRectTween(begin, end);
    return RectTween(begin: begin, end: end);
  }

  static final Animatable<double> _reverseTween = Tween<double>(begin: 1.0, end: 0.0);

  // The OverlayEntry WidgetBuilder callback for the hero's overlay.
  Widget _buildOverlay(BuildContext context) {
    assert(manifest != null);
    shuttle ??= manifest.shuttleBuilder(
      context,
      manifest.animation,
      manifest.type,
      manifest.fromHero.context,
      manifest.toHero.context,
    );
    assert(shuttle != null);

    return AnimatedBuilder(
      animation: _proxyAnimation,
      child: shuttle,
      builder: (BuildContext context, Widget child) {
        final RenderBox toHeroBox = manifest.toHero.context?.findRenderObject();
        if (_aborted || toHeroBox == null || !toHeroBox.attached) {
          // The toHero no longer exists or it's no longer the flight's destination.
          // Continue flying while fading out.
          if (_heroOpacity.isCompleted) {
            _heroOpacity = _proxyAnimation.drive(
              _reverseTween.chain(CurveTween(curve: Interval(_proxyAnimation.value, 1.0))),
            );
          }
        } else if (toHeroBox.hasSize) {
          // The toHero has been laid out. If it's no longer where the hero animation is
          // supposed to end up then recreate the heroRect tween.
          final RenderBox finalRouteBox = manifest.toRoute.subtreeContext?.findRenderObject();
          final Offset toHeroOrigin = toHeroBox.localToGlobal(Offset.zero, ancestor: finalRouteBox);
          if (toHeroOrigin != heroRectTween.end.topLeft) {
            final Rect heroRectEnd = toHeroOrigin & heroRectTween.end.size;
            heroRectTween = _doCreateRectTween(heroRectTween.begin, heroRectEnd);
          }
        }

        final Rect rect = heroRectTween.evaluate(_proxyAnimation);
        final Size size = manifest.navigatorRect.size;
        final RelativeRect offsets = RelativeRect.fromSize(rect, size);

        return Positioned(
          top: offsets.top,
          right: offsets.right,
          bottom: offsets.bottom,
          left: offsets.left,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Opacity(
                opacity: _heroOpacity.value,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAnimationUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
      _proxyAnimation.parent = null;

      assert(overlayEntry != null);
      overlayEntry.remove();
      overlayEntry = null;

      manifest.fromHero.endFlight();
      manifest.toHero.endFlight();
      onFlightEnded(this);
    }
  }

  // The simple case: we're either starting a push or a pop animation.
  void start(_HeroFlightManifest initialManifest) {
    assert(!_aborted);
    assert(() {
      final Animation<double> initial = initialManifest.animation;
      assert(initial != null);
      final HeroFlightDirection type = initialManifest.type;
      assert(type != null);
      switch (type) {
        case HeroFlightDirection.pop:
          return initial.value == 1.0 && initialManifest.isUserGestureTransition
              // During user gesture transitions, the animation controller isn't
              // driving the reverse transition, but should still be in a previously
              // completed stage with the initial value at 1.0.
              ? initial.status == AnimationStatus.completed
              : initial.status == AnimationStatus.reverse;
        case HeroFlightDirection.push:
          return initial.value == 0.0 && initial.status == AnimationStatus.forward;
      }
      return null;
    }());

    manifest = initialManifest;

    if (manifest.type == HeroFlightDirection.pop)
      _proxyAnimation.parent = ReverseAnimation(manifest.animation);
    else
      _proxyAnimation.parent = manifest.animation;

    manifest.fromHero.startFlight();
    manifest.toHero.startFlight();

    heroRectTween = _doCreateRectTween(
      _globalBoundingBoxFor(manifest.fromHero.context),
      _globalBoundingBoxFor(manifest.toHero.context),
    );

    overlayEntry = OverlayEntry(builder: _buildOverlay);
    manifest.overlay.insert(overlayEntry);
  }

  // While this flight's hero was in transition a push or a pop occurred for
  // routes with the same hero. Redirect the in-flight hero to the new toRoute.
  void divert(_HeroFlightManifest newManifest) {
    assert(manifest.tag == newManifest.tag);

    if (manifest.type == HeroFlightDirection.push && newManifest.type == HeroFlightDirection.pop) {
      // A push flight was interrupted by a pop.
      assert(newManifest.animation.status == AnimationStatus.reverse);
      assert(manifest.fromHero == newManifest.toHero);
      assert(manifest.toHero == newManifest.fromHero);
      assert(manifest.fromRoute == newManifest.toRoute);
      assert(manifest.toRoute == newManifest.fromRoute);

      // The same heroRect tween is used in reverse, rather than creating
      // a new heroRect with _doCreateRectTween(heroRect.end, heroRect.begin).
      // That's because tweens like MaterialRectArcTween may create a different
      // path for swapped begin and end parameters. We want the pop flight
      // path to be the same (in reverse) as the push flight path.
      _proxyAnimation.parent = ReverseAnimation(newManifest.animation);
      heroRectTween = ReverseTween<Rect>(heroRectTween);
    } else if (manifest.type == HeroFlightDirection.pop && newManifest.type == HeroFlightDirection.push) {
      // A pop flight was interrupted by a push.
      assert(newManifest.animation.status == AnimationStatus.forward);
      assert(manifest.toHero == newManifest.fromHero);
      assert(manifest.toRoute == newManifest.fromRoute);

      _proxyAnimation.parent = newManifest.animation.drive(
        Tween<double>(
          begin: manifest.animation.value,
          end: 1.0,
        ),
      );

      if (manifest.fromHero != newManifest.toHero) {
        manifest.fromHero.endFlight();
        newManifest.toHero.startFlight();
        heroRectTween = _doCreateRectTween(heroRectTween.end, _globalBoundingBoxFor(newManifest.toHero.context));
      } else {
        // TODO(hansmuller): Use ReverseTween here per github.com/flutter/flutter/pull/12203.
        heroRectTween = _doCreateRectTween(heroRectTween.end, heroRectTween.begin);
      }
    } else {
      // A push or a pop flight is heading to a new route, i.e.
      // manifest.type == _HeroFlightType.push && newManifest.type == _HeroFlightType.push ||
      // manifest.type == _HeroFlightType.pop && newManifest.type == _HeroFlightType.pop
      assert(manifest.fromHero != newManifest.fromHero);
      assert(manifest.toHero != newManifest.toHero);

      heroRectTween = _doCreateRectTween(heroRectTween.evaluate(_proxyAnimation), _globalBoundingBoxFor(newManifest.toHero.context));
      shuttle = null;

      if (newManifest.type == HeroFlightDirection.pop)
        _proxyAnimation.parent = ReverseAnimation(newManifest.animation);
      else
        _proxyAnimation.parent = newManifest.animation;

      manifest.fromHero.endFlight();
      manifest.toHero.endFlight();

      // Let the heroes in each of the routes rebuild with their placeholders.
      newManifest.fromHero.startFlight();
      newManifest.toHero.startFlight();

      // Let the transition overlay on top of the routes also rebuild since
      // we cleared the old shuttle.
      overlayEntry.markNeedsBuild();
    }

    _aborted = false;
    manifest = newManifest;
  }

  void abort() {
    _aborted = true;
  }

  @override
  String toString() {
    final RouteSettings from = manifest.fromRoute.settings;
    final RouteSettings to = manifest.toRoute.settings;
    final Object tag = manifest.tag;
    return 'HeroFlight(for: $tag, from: $from, to: $to ${_proxyAnimation.parent})';
  }
}

/// A [Navigator] observer that manages [Hero] transitions.
///
/// An instance of [HeroController] should be used in [Navigator.observers].
/// This is done automatically by [MaterialApp].
class HeroController extends NavigatorObserver {
  /// Creates a hero controller with the given [RectTween] constructor if any.
  ///
  /// The [createRectTween] argument is optional. If null, the controller uses a
  /// linear [Tween<Rect>].
  HeroController({ this.createRectTween });

  /// Used to create [RectTween]s that interpolate the position of heroes in flight.
  ///
  /// If null, the controller uses a linear [RectTween].
  final CreateRectTween createRectTween;

  // All of the heroes that are currently in the overlay and in motion.
  // Indexed by the hero tag.
  final Map<Object, _HeroFlight> _flights = <Object, _HeroFlight>{};

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    _maybeStartHeroTransition(previousRoute, route, HeroFlightDirection.push, false);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    _maybeStartHeroTransition(route, previousRoute, HeroFlightDirection.pop, false);
  }

  @override
  void didReplace({ Route<dynamic> newRoute, Route<dynamic> oldRoute }) {
    assert(navigator != null);
    if (newRoute?.isCurrent == true) {
      // Only run hero animations if the top-most route got replaced.
      _maybeStartHeroTransition(oldRoute, newRoute, HeroFlightDirection.push, false);
    }
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    _maybeStartHeroTransition(route, previousRoute, HeroFlightDirection.pop, true);
  }

  // If we're transitioning between different page routes, start a hero transition
  // after the toRoute has been laid out with its animation's value at 1.0.
  void _maybeStartHeroTransition(
    Route<dynamic> fromRoute,
    Route<dynamic> toRoute,
    HeroFlightDirection flightType,
    bool isUserGestureTransition,
  ) {
    if (toRoute != fromRoute && toRoute is PageRoute<dynamic> && fromRoute is PageRoute<dynamic>) {
      final PageRoute<dynamic> from = fromRoute;
      final PageRoute<dynamic> to = toRoute;
      final Animation<double> animation = (flightType == HeroFlightDirection.push) ? to.animation : from.animation;

      // A user gesture may have already completed the pop, or we might be the initial route
      switch (flightType) {
        case HeroFlightDirection.pop:
          if (animation.value == 0.0) {
            return;
          }
          break;
        case HeroFlightDirection.push:
          if (animation.value == 1.0) {
            return;
          }
          break;
      }

      // For pop transitions driven by a user gesture: if the "to" page has
      // maintainState = true, then the hero's final dimensions can be measured
      // immediately because their page's layout is still valid.
      if (isUserGestureTransition && flightType == HeroFlightDirection.pop && to.maintainState) {
        _startHeroTransition(from, to, animation, flightType, isUserGestureTransition);
      } else {
        // Otherwise, delay measuring until the end of the next frame to allow
        // the 'to' route to build and layout.

        // Putting a route offstage changes its animation value to 1.0. Once this
        // frame completes, we'll know where the heroes in the `to` route are
        // going to end up, and the `to` route will go back onstage.
        to.offstage = to.animation.value == 0.0;

        WidgetsBinding.instance.addPostFrameCallback((Duration value) {
          _startHeroTransition(from, to, animation, flightType, isUserGestureTransition);
        });
      }
    }
  }

  // Find the matching pairs of heroes in from and to and either start or a new
  // hero flight, or divert an existing one.
  void _startHeroTransition(
    PageRoute<dynamic> from,
    PageRoute<dynamic> to,
    Animation<double> animation,
    HeroFlightDirection flightType,
    bool isUserGestureTransition,
  ) {
    // If the navigator or one of the routes subtrees was removed before this
    // end-of-frame callback was called, then don't actually start a transition.
    if (navigator == null || from.subtreeContext == null || to.subtreeContext == null) {
      to.offstage = false; // in case we set this in _maybeStartHeroTransition
      return;
    }

    final Rect navigatorRect = _globalBoundingBoxFor(navigator.context);

    // At this point the toHeroes may have been built and laid out for the first time.
    final Map<Object, _HeroState> fromHeroes = Hero._allHeroesFor(from.subtreeContext, isUserGestureTransition, navigator);
    final Map<Object, _HeroState> toHeroes = Hero._allHeroesFor(to.subtreeContext, isUserGestureTransition, navigator);

    // If the `to` route was offstage, then we're implicitly restoring its
    // animation value back to what it was before it was "moved" offstage.
    to.offstage = false;

    for (Object tag in fromHeroes.keys) {
      if (toHeroes[tag] != null) {
        final HeroFlightShuttleBuilder fromShuttleBuilder = fromHeroes[tag].widget.flightShuttleBuilder;
        final HeroFlightShuttleBuilder toShuttleBuilder = toHeroes[tag].widget.flightShuttleBuilder;

        final _HeroFlightManifest manifest = _HeroFlightManifest(
          type: flightType,
          overlay: navigator.overlay,
          navigatorRect: navigatorRect,
          fromRoute: from,
          toRoute: to,
          fromHero: fromHeroes[tag],
          toHero: toHeroes[tag],
          createRectTween: createRectTween,
          shuttleBuilder:
              toShuttleBuilder ?? fromShuttleBuilder ?? _defaultHeroFlightShuttleBuilder,
          isUserGestureTransition: isUserGestureTransition,
        );

        if (_flights[tag] != null)
          _flights[tag].divert(manifest);
        else
          _flights[tag] = _HeroFlight(_handleFlightEnded)..start(manifest);
      } else if (_flights[tag] != null) {
        _flights[tag].abort();
      }
    }
  }

  void _handleFlightEnded(_HeroFlight flight) {
    _flights.remove(flight.manifest.tag);
  }

  static final HeroFlightShuttleBuilder _defaultHeroFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget;
    return toHero.child;
  };
}
