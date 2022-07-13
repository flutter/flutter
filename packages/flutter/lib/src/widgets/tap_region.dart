// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// An interface for registering and unregistering a [RenderTapRegion]
/// (typically created with a [TapRegion] widget) with a
/// [RenderTapRegionSurface] (typically created with a [TapRegionSurface]
/// widget).
abstract class TapRegionRegistry {
  /// Register the given [RenderTapRegion] with the registry.
  void registerTapRegion(RenderTapRegion region);

  /// Unregister the given [RenderTapRegion] with the registry.
  void unregisterTapRegion(RenderTapRegion region);

  /// Allows finding of the nearest [TapRegionRegistry], such as a
  /// [RenderTapRegionSurface].
  ///
  /// Will throw if a [TapRegionRegistry] isn't found.
  static TapRegionRegistry of(BuildContext context) {
    final TapRegionRegistry? registry = maybeOf(context);
    assert(() {
      if (registry == null) {
        throw FlutterError(
          'TapRegionRegistry.of() was called with a context that does not contain a TapRegionSurface widget.\n'
              'No TapRegionSurface widget ancestor could be found starting from the context that was passed to '
              'TapRegionRegistry.of().\n'
              'The context used was:\n'
              '  $context',
        );
      }
      return true;
    }());
    return registry!;
  }

  /// Allows finding of the nearest [TapRegionRegistry], such as a
  /// [RenderTapRegionSurface].
  static TapRegionRegistry? maybeOf(BuildContext context) {
    return context.findAncestorRenderObjectOfType<RenderTapRegionSurface>();
  }
}

/// A widget that provides notification of a tap inside or outside of a set of
/// registered regions, without participating in the gesture arena.
///
/// The regions are defined by adding [TapRegion] widgets to the widget tree
/// around the regions of interest, and they will register with this
/// `TapRegionSurface`. Each of the tap regions can optionally belong to a group
/// by assigning a [TapRegion.groupId], where all the regions with the same
/// groupId act as if they were all one region.
///
/// When a tap outside of a registered region or region group is detected, its
/// [TapRegion.onTapOutside] callback is called.
///
/// The `TapRegionSurface` should be defined at the highest level needed to
/// encompass the entire area where taps should be monitored. This is typically
/// around the entire app. If the entire app isn't covered, then taps outside of
/// the `TapRegionSurface` will be ignored and no [TapRegion.onTapOutside] calls
/// wil be made for those events.
///
/// [TapRegionSurface] does not participate in the gesture arena, so if
/// multiple [TapRegionSurface]s are active at the same time, they will all
/// fire, and so will any other gestures recognized by a [GestureDetector] or
/// other pointer event handlers.
///
/// [TapRegion]s register only with the nearest ancestor `TapRegionSurface`.
class TapRegionSurface extends SingleChildRenderObjectWidget {
  /// Creates a const [RenderTapRegionSurface].
  ///
  /// The [child] attribute is required.
  const TapRegionSurface({
    super.key,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTapRegionSurface();
  }

  @override
  void updateRenderObject(
      BuildContext context,
      RenderProxyBoxWithHitTestBehavior renderObject,
      ) {}
}

/// A render object that provides notification of a tap inside or outside of a
/// set of registered regions, without participating in the gesture arena.
///
/// The regions are defined by adding [RenderTapRegion] render objects in the
/// render tree around the regions of interest, and they will register with this
/// `RenderTapRegionSurface`. Each of the tap regions can optionally belong to a
/// group by assigning a [RenderTapRegion.groupId], where all the regions with
/// the same groupId act as if they were all one region.
///
/// When a tap outside of a registered region or region group is detected, its
/// [RenderTapRegion.onTapOutside] callback is called.
///
/// The `RenderTapRegionSurface` should be defined at the highest level needed
/// to encompass the entire area where taps should be monitored. This is
/// typically around the entire app. If the entire app isn't covered, then taps
/// outside of the `RenderTapRegionSurface` will be ignored and no
/// [RenderTapRegion.onTapOutside] calls wil be made for those events.
///
/// `RenderTapRegionSurface` does not participate in the gesture arena, so if
/// multiple `RenderTapRegionSurface`s are active at the same time, they will
/// all fire, and so will any other gestures recognized by a [GestureDetector]
/// or other pointer event handlers.
///
/// [RenderTapRegion]s register only with the nearest ancestor
/// `RenderTapRegionSurface`.
///
/// See also:
///
///  * [TapRegionRegistry.of], which can find the nearest ancestor
///    [RenderTapRegionSurface], which is a [TapRegionRegistry].
class RenderTapRegionSurface extends RenderProxyBoxWithHitTestBehavior with TapRegionRegistry {
  final Expando<BoxHitTestResult> _cachedResults = Expando<BoxHitTestResult>();
  final Set<RenderTapRegion> _registeredRegions = <RenderTapRegion>{};
  final Map<Object?, Set<RenderTapRegion>> _groupIdToRegions = <Object?, Set<RenderTapRegion>>{};

  @override
  void registerTapRegion(RenderTapRegion region) {
    assert(!_registeredRegions.contains(region));
    _registeredRegions.add(region);
    if (region.groupId != null) {
      _groupIdToRegions[region.groupId] ??= <RenderTapRegion>{};
      _groupIdToRegions[region.groupId]!.add(region);
    }
  }

  @override
  void unregisterTapRegion(RenderTapRegion region) {
    assert(_registeredRegions.contains(region));
    _registeredRegions.remove(region);
    if (region.groupId != null) {
      assert(_groupIdToRegions.containsKey(region.groupId));
      _groupIdToRegions[region.groupId]!.remove(region);
      if (_groupIdToRegions[region.groupId]!.isEmpty) {
        _groupIdToRegions.remove(region.groupId);
      }
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) {
      return false;
    }

    final bool hitTarget = hitTestChildren(result, position: position) || hitTestSelf(position);

    if (hitTarget) {
      final BoxHitTestEntry entry = BoxHitTestEntry(this, position);
      _cachedResults[entry] = result;
      result.add(entry);
    }

    return hitTarget;
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (_registeredRegions.isEmpty) {
      return;
    }

    assert(debugHandleEvent(event, entry));
    assert(() {
      for (final RenderTapRegion region in _registeredRegions) {
        if (!region.enabled) {
          return false;
        }
      }
      return true;
    }(), 'A RenderTapRegion was registered when it was disabled.');

    if (event is! PointerDownEvent || event.buttons != kPrimaryButton) {
      return;
    }

    final BoxHitTestResult? result = _cachedResults[entry];

    if (result == null) {
      return;
    }

    // A child was hit, so we need to call onTapOutside for those regions or
    // groups of regions that were not hit.
    final Set<RenderTapRegion> hitRegions =
    _getRegionsHit(_registeredRegions, result.path).cast<RenderTapRegion>().toSet();
    final Set<RenderTapRegion> outsideRegions = _registeredRegions.difference(hitRegions);

    // Remove any members of the same group as the hit regions from the
    // outsideRegions so that groups act as a single region.
    for (final RenderTapRegion region in hitRegions) {
      if (region.groupId == null) {
        continue;
      }
      outsideRegions.removeAll(_groupIdToRegions[region.groupId]!);
    }

    for (final RenderTapRegion region in outsideRegions) {
      region.onTapOutside?.call();
    }
  }

  // Returns the registered regions that are in the hit path.
  Iterable<HitTestTarget> _getRegionsHit(Set<RenderTapRegion> detectors, Iterable<HitTestEntry> hitTestPath) {
    final Set<HitTestTarget> hitRegions = <HitTestTarget>{};
    for (final HitTestEntry<HitTestTarget> entry in hitTestPath) {
      final HitTestTarget target = entry.target;
      if (_registeredRegions.contains(target)) {
        hitRegions.add(target);
      }
    }
    return hitRegions;
  }
}

/// A widget that indicates to the nearest ancestor [TapRegionSurface] that the
/// region occupied by its child will participate in the tap detection for that
/// surface.
///
/// If there is no [TapRegionSurface] ancestor, [TapRegion] will throw an
/// error.
class TapRegion extends SingleChildRenderObjectWidget {
  /// Creates a const [TapRegion].
  ///
  /// The [child] argument is required.
  const TapRegion({
    super.key,
    required super.child,
    this.enabled = true,
    this.onTapOutside,
    this.groupId,
  });

  /// Whether or not this [TapRegion] is enabled as part of the composite region.
  final bool enabled;

  /// A callback to be invoked when a tap is detected outside of this
  /// [RenderTapRegion].
  final VoidCallback? onTapOutside;

  /// An optional group ID that groups [TapRegion]s together so that they
  /// operate as one region. If any member of a group is hit by a particular
  /// tap, then the [onTapOutside] will not be called for any members of the
  /// group.
  final Object? groupId;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTapRegion(
      registry: TapRegionRegistry.maybeOf(context),
      enabled: enabled,
      onTapOutside: onTapOutside,
      groupId: groupId,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderTapRegion renderObject) {
    renderObject.registry = TapRegionRegistry.maybeOf(context);
    renderObject.enabled = enabled;
    renderObject.groupId = groupId;
    renderObject.onTapOutside = onTapOutside;
  }
}

/// A render object that indicates to the nearest ancestor
/// [RenderTapRegionSurface] that the region occupied by its child will
/// participate in the tap detection for that surface.
///
/// If there is no [RenderTapRegionSurface] ancestor, [RenderTapRegion] will
/// throw an error.
class RenderTapRegion extends RenderProxyBox with Diagnosticable {
  /// Creates a [RenderTapRegion].
  RenderTapRegion({
    TapRegionRegistry? registry,
    bool enabled = true,
    this.onTapOutside,
    Object? groupId,
  })  : _registry = registry,
        _enabled = enabled,
        _groupId = groupId;

  bool _isRegistered = false;

  /// A callback to be invoked when a tap is detected outside of this
  /// [RenderTapRegion].
  VoidCallback? onTapOutside;

  /// Whether or not this region should participate in the composite region.
  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      markNeedsLayout();
    }
  }

  /// An optional group ID that groups [RenderTapRegion]s together so that they
  /// operate as one region. If any member of a group is hit by a particular
  /// tap, then the [onTapOutside] will not be called for any members of the
  /// group.
  Object? get groupId => _groupId;
  Object? _groupId;
  set groupId(Object? value) {
    if (_groupId != value) {
      _groupId = value;
      markNeedsLayout();
    }
  }

  /// The registry that this [RenderTapRegion] should register with.
  ///
  /// If the `registry` is null, then this region will not be registered
  /// anywhere, and will not do any tap detection.
  ///
  /// A [RenderTapRegionSurface] is a [TapRegionRegistry].
  TapRegionRegistry? get registry => _registry;
  TapRegionRegistry? _registry;
  set registry(TapRegionRegistry? value) {
    if (_registry != value) {
      if (_isRegistered) {
        _registry!.unregisterTapRegion(this);
        _isRegistered = false;
      }
      _registry = value;
      markNeedsLayout();
    }
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    super.layout(constraints, parentUsesSize: parentUsesSize);
    if (_registry == null) {
      return;
    }
    if (_isRegistered) {
      _registry!.unregisterTapRegion(this);
    }
    final bool shouldBeRegistered = _enabled && _registry != null;
    if (shouldBeRegistered) {
      _registry!.registerTapRegion(this);
    }
    _isRegistered = shouldBeRegistered;
  }

  @override
  void dispose() {
    if (_isRegistered) {
      _registry!.unregisterTapRegion(this);
    }
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object?>('groupId', groupId, defaultValue: null));
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED', defaultValue: true));
  }
}
