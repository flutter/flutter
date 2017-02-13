// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'pages.dart';
import 'transitions.dart';

/// Signature for a function that takes two [Rect] instances and returns a
/// [RectTween] that transitions between them.
///
/// This is typically used with a [HeroController] to provide an animation for
/// [Hero] positions that looks nicer than a linear movement. For example, see
/// [MaterialRectArcTween].
typedef RectTween CreateRectTween(Rect begin, Rect end);

typedef void _OnFlightEnded(_HeroFlight flight);

enum _HeroFlightType {
  push, // Fly the "to" hero and animate with the "to" route.
  pop, // Fly the "to" hero and animate with the "from" route.
}

// TODO(hansmuller): maybe this should be a method on RenderBox
Rect _globalRect(BuildContext context, { RenderObject ancestor }) {
  final RenderBox box = context.findRenderObject();
  assert(box != null);
  assert(box.hasSize);
  Point topLeft = box.localToGlobal(Point.origin, ancestor: ancestor);
  Point bottomRight = box.localToGlobal(box.size.bottomRight(Point.origin), ancestor: ancestor);
  return new Rect.fromLTRB(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
}

class Hero extends StatefulWidget {
  Hero({
    Key key,
    @required this.tag,
    @required this.child,
  }) : super(key: key) {
    assert(tag != null);
    assert(child != null);
  }

  final Object tag;

  final Widget child;

  // Returns a map of all of the heroes in context, indexed by hero tag.
  static Map<Object, _HeroState> _allHeroesFor(BuildContext context) {
    assert(context != null);
    final Map<Object, _HeroState> result = <Object, _HeroState>{};
    void visitor(Element element) {
      if (element.widget is Hero) {
        final StatefulElement hero = element;
        final Hero heroWidget = element.widget;
        final Object tag = heroWidget.tag;
        assert(tag != null);
        assert(() {
          if (result.containsKey(tag)) {
            new FlutterError(
              'There are multiple heroes that share the same tag within a subtree.\n'
              'Within each subtree for which heroes are to be animated (typically a PageRoute subtree), '
              'each Hero must have a unique non-null tag.\n'
              'In this case, multiple heroes had the tag "$tag".'
            );
          }
          return true;
        });
        _HeroState heroState = hero.state;
        result[tag] = heroState;
      }
      element.visitChildren(visitor);
    }
    context.visitChildElements(visitor);
    return result;
  }

  @override
  _HeroState createState() => new _HeroState();
}

class _HeroState extends State<Hero> {
  GlobalKey _key = new GlobalKey();
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
    if (_placeholderSize != null) {
      return new SizedBox(
        width: _placeholderSize.width,
        height: _placeholderSize.height
      );
    }
    return new KeyedSubtree(
      key: _key,
      child: config.child,
    );
  }
}

class _HeroFlightManifest {
  _HeroFlightManifest({
    this.type,
    this.overlay,
    this.navigatorRect,
    this.fromRoute,
    this.toRoute,
    this.fromHero,
    this.toHero,
    this.createRectTween,
  }) {
    assert(fromHero.config.tag == toHero.config.tag);
  }

  final _HeroFlightType type;
  final OverlayState overlay;
  final Rect navigatorRect;
  final PageRoute<dynamic> fromRoute;
  final PageRoute<dynamic> toRoute;
  final _HeroState fromHero;
  final _HeroState toHero;
  final CreateRectTween createRectTween;

  Object get tag => fromHero.config.tag;

  Animation<double> get animation {
    return (type == _HeroFlightType.push) ? toRoute.animation : fromRoute.animation;
  }

  @override
  String toString() {
    return '_HeroFlightManifest($type hero: $tag from: ${fromRoute.settings} to: ${toRoute.settings})';
  }
}

// The animation that drives the Hero's flight can change if the flight is
// restarted. The overall animation is always curved.
class _HeroFlightProxyAnimation extends ProxyAnimation {
  @override
  set parent(Animation<double> value) {
    if (value == null) {
      super.parent = null;
    } else {
      super.parent = new CurvedAnimation(
        parent: value,
        curve: Curves.fastOutSlowIn
      );
    }
  }
}

class _HeroFlight {
  _HeroFlight(this.onFlightEnded) {
    _proxyAnimation = new ProxyAnimation()..addStatusListener(_handleAnimationUpdate);
  }

  final _OnFlightEnded onFlightEnded;

  RectTween heroRect;
  Animation<double> _heroOpacity = kAlwaysCompleteAnimation;
  ProxyAnimation _proxyAnimation;
  _HeroFlightManifest manifest;
  OverlayEntry overlayEntry;

  RectTween _doCreateRectTween(Rect begin, Rect end) {
    if (manifest.createRectTween != null)
      return manifest.createRectTween(begin, end);
    return new RectTween(begin: begin, end: end);
  }

  // The OverlayEntry WidgetBuilder callback for the hero's overlay.
  Widget _buildOverlay(BuildContext context) {
    assert(manifest != null);
    return new AnimatedBuilder(
      animation: _proxyAnimation,
      child: manifest.toHero.config,
      builder: (BuildContext context, Widget child) {
        final RenderBox toHeroBox = manifest.toHero.context?.findRenderObject();
        if (toHeroBox == null || !toHeroBox.attached) {
          // The toHero no longer exists. Continue flying while fading out.
          if (_heroOpacity == kAlwaysCompleteAnimation) {
            _heroOpacity = new Tween<double>(begin: 1.0, end: 0.0)
              .chain(new CurveTween(curve: new Interval(_proxyAnimation.value, 1.0)))
              .animate(_proxyAnimation);
          }
        } else if (toHeroBox.hasSize) {
          // The toHero has been laid out. If it's no longer where the hero animation is
          // supposed to end up (heroRect.end) then recreate the heroRect tween.
          final RenderBox routeBox = manifest.toRoute.subtreeContext?.findRenderObject();
          final Point heroOriginEnd = toHeroBox.localToGlobal(Point.origin, ancestor: routeBox);
          if (heroOriginEnd != heroRect.end.topLeft) {
            final Rect heroRectEnd = heroOriginEnd & heroRect.end.size;
            heroRect = _doCreateRectTween(heroRect.begin, heroRectEnd);
          }
        }

        final Rect rect = heroRect.evaluate(_proxyAnimation);
        final Size size = manifest.navigatorRect.size;
        final RelativeRect offsets = new RelativeRect.fromSize(rect, size);

        return new Positioned(
          top: offsets.top,
          right: offsets.right,
          bottom: offsets.bottom,
          left: offsets.left,
          child:  new IgnorePointer(
            child: new RepaintBoundary(
              child: new Opacity(
                key: manifest.toHero._key,
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
    assert(() {
      final Animation<double> initial = initialManifest.animation;
      switch(initialManifest.type) {
        case _HeroFlightType.pop:
          return initial.value == 1.0 && initial.status == AnimationStatus.reverse;
        case _HeroFlightType.push:
          return initial.value == 0.0 && initial.status == AnimationStatus.forward;
      }
    });

    manifest = initialManifest;
    if (manifest.type == _HeroFlightType.pop)
      _proxyAnimation.parent = new ReverseAnimation(manifest.animation);
    else
      _proxyAnimation.parent = manifest.animation;

    manifest.fromHero.startFlight();
    manifest.toHero.startFlight();

    heroRect = new RectTween(
      begin: _globalRect(manifest.fromHero.context),
      end: _globalRect(manifest.toHero.context),
    );

    overlayEntry = new OverlayEntry(builder: _buildOverlay);
    manifest.overlay.insert(overlayEntry);
  }

  // While this flight's hero was in transition a push or a pop occurred for
  // routes with the same hero. Redirect the in-flight hero to the new toRoute.
  void restart(_HeroFlightManifest newManifest) {
    assert(manifest.tag == newManifest.tag);

    if (manifest.type == _HeroFlightType.push && newManifest.type == _HeroFlightType.pop) {
      // A push flight was interrupted by a pop.
      assert(newManifest.animation.status == AnimationStatus.reverse);
      assert(manifest.fromHero == newManifest.toHero);
      assert(manifest.toHero == newManifest.fromHero);
      assert(manifest.fromRoute == newManifest.toRoute);
      assert(manifest.toRoute == newManifest.fromRoute);

      _proxyAnimation.parent = new ReverseAnimation(newManifest.animation);

      heroRect = new RectTween(
        begin: heroRect.end,
        end: heroRect.begin,
      );
    } else if (manifest.type == _HeroFlightType.pop && newManifest.type == _HeroFlightType.push) {
      // A pop flight was interrupted by a push.
      assert(newManifest.animation.status == AnimationStatus.forward);
      assert(manifest.toHero == newManifest.fromHero);
      assert(manifest.toRoute == newManifest.fromRoute);

      _proxyAnimation.parent = new Tween<double>(
        begin: manifest.animation.value,
        end: 1.0,
      ).animate(newManifest.animation);

      if (manifest.fromHero != newManifest.toHero) {
        manifest.fromHero.endFlight();
        newManifest.toHero.startFlight();
        heroRect = new RectTween(
          begin: heroRect.end,
          end: _globalRect(newManifest.toHero.context),
        );
      } else {
        heroRect = new RectTween(
          begin: heroRect.end,
          end: heroRect.begin,
        );
      }
    } else {
      // A push or a pop flight is heading to a new route, i.e.
      // manifest.type == _HeroFlightType.push && newManifest.type == _HeroFlightType.push ||
      // manifest.type == _HeroFlightType.pop && newManifest.type == _HeroFlightType.pop
      assert(manifest.fromHero != newManifest.fromHero);
      assert(manifest.toHero != newManifest.toHero);

      heroRect = new RectTween(
        begin: heroRect.evaluate(_proxyAnimation),
        end: _globalRect(newManifest.toHero.context),
      );

      if (newManifest.type == _HeroFlightType.pop)
        _proxyAnimation.parent = new ReverseAnimation(newManifest.animation);
      else
        _proxyAnimation.parent = newManifest.animation;

      manifest.fromHero.endFlight();
      manifest.toHero.endFlight();
      newManifest.fromHero.startFlight();
      newManifest.toHero.startFlight();
    }

    manifest = newManifest;
  }

  @override
  String toString() {
    final RouteSettings from = manifest.fromRoute.settings;
    final RouteSettings to = manifest.toRoute.settings;
    final Object tag = manifest.tag;
    return 'HeroFlight(for: $tag from: $from to: $to ${_proxyAnimation.parent})';
  }
}

/// A [Navigator] observer that manages [Hero] transitions.
///
/// An instance of [HeroController] should be used as the [Navigator.observer].
/// This is done automatically by [MaterialApp].
class HeroController extends NavigatorObserver {
  /// Creates a hero controller with the given [RectTween] constructor if any.
  ///
  /// The [createRectTween] argument is optional. If null, a linear
  /// [RectTween] is used.
  HeroController({ this.createRectTween });

  final CreateRectTween createRectTween;

  // Disable Hero animations while a user gesture is controlling the navigation.
  bool _questsEnabled = true;

  // All of the heroes that are currently in the overlay and in motion.
  // Indexed by the hero tag.
  // TBD: final?
  Map<Object, _HeroFlight> _flights = <Object, _HeroFlight>{};

  @override
  void didPush(Route<dynamic> to, Route<dynamic> from) {
    assert(navigator != null);
    assert(to != null);
    _maybeStartHeroTransition(from, to, _HeroFlightType.push);
  }

  @override
  void didPop(Route<dynamic> from, Route<dynamic> to) {
    assert(navigator != null);
    assert(from != null);
    _maybeStartHeroTransition(from, to, _HeroFlightType.pop);
  }

  @override
  void didStartUserGesture() {
    _questsEnabled = false;
  }

  @override
  void didStopUserGesture() {
    _questsEnabled = true;
  }

  // If we're transitioning between different page routes, start a hero transition
  // after the toRoute has been laid out with its animation's value at 1.0.
  void _maybeStartHeroTransition(Route<dynamic> fromRoute, Route<dynamic> toRoute, _HeroFlightType flightType) {
    if (_questsEnabled && toRoute != fromRoute && toRoute is PageRoute<dynamic> && fromRoute is PageRoute<dynamic>) {
      final PageRoute<dynamic> from = fromRoute;
      final PageRoute<dynamic> to = toRoute;
      final Animation<double> animation = (flightType == _HeroFlightType.push) ? to.animation : from.animation;

      // Putting a route offstage changes its animation value to 1.0.
      // Once this frame completes, we'll know where the heroes in the toRoute
      // are going to end up, and the toRoute will go back on stage.
      to.offstage = animation.value == 0.0 || animation.value == 1.0;

      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        _startHeroTransition(from, to, flightType);
      });
    }
  }

  // Find the matching pairs of heros in from and to and either start or a new
  // hero flight, or restart an existing one.
  void _startHeroTransition(PageRoute<dynamic> from, PageRoute<dynamic> to, _HeroFlightType flightType) {
    // The navigator or one of the routes subtrees was removed before this
    // end-of-frame callback was called then don't actually start a transition.
    // TBD: need to generate tests for these cases
    if (navigator == null || from.subtreeContext == null || to.subtreeContext == null) {
      to.offstage = false; // TBD: only do this if to.subtreeContext != null?
      return;
    }

    final Rect navigatorRect = _globalRect(navigator.context);

    // At this point the toHeroes may have been built and laid out for the first time.
    final Map<Object, _HeroState> fromHeroes = Hero._allHeroesFor(from.subtreeContext);
    final Map<Object, _HeroState> toHeroes = Hero._allHeroesFor(to.subtreeContext);

    // If the to route was offstage, then we're implicitly restoring its
    // animation value back to what it was before it was "moved" offstage.
    to.offstage = false;

    for (Object tag in fromHeroes.keys) {
      if (toHeroes[tag] != null) {
        final _HeroFlightManifest manifest = new _HeroFlightManifest(
          type: flightType,
          overlay: navigator.overlay,
          navigatorRect: navigatorRect,
          fromRoute: from,
          toRoute: to,
          fromHero: fromHeroes[tag],
          toHero: toHeroes[tag],
          createRectTween: createRectTween,
        );

        if (_flights[tag] != null)
            _flights[tag].restart(manifest);
        else
          _flights[tag] = new _HeroFlight(_handleFlightEnded)..start(manifest);
      }
    }
  }

  void _handleFlightEnded(_HeroFlight flight) {
    _flights.remove(flight.manifest.tag);
  }
}
