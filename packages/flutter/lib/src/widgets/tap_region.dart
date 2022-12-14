// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'editable_text.dart';
import 'framework.dart';

// Enable if you want verbose logging about tap region changes.
const bool _kDebugTapRegion = false;

bool _tapRegionDebug(String message, [Iterable<String>? details]) {
  if (_kDebugTapRegion) {
    debugPrint('TAP REGION: $message');
    if (details != null && details.isNotEmpty) {
      for (final String detail in details) {
        debugPrint('    $detail');
      }
    }
  }
  // Return true so that it can be easily used inside of an assert.
  return true;
}

/// The type of callback that [TapRegion.onTapOutside] and
/// [TapRegion.onTapInside] take.
///
/// The event is the pointer event that caused the callback to be called.
typedef TapRegionCallback = void Function(PointerDownEvent event);

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
/// registered regions, without participating in the [gesture
/// disambiguation](https://flutter.dev/gestures/#gesture-disambiguation)
/// system.
///
/// The regions are defined by adding [TapRegion] widgets to the widget tree
/// around the regions of interest, and they will register with this
/// [TapRegionSurface]. Each of the tap regions can optionally belong to a group
/// by assigning a [TapRegion.groupId], where all the regions with the same
/// groupId act as if they were all one region.
///
/// When a tap outside of a registered region or region group is detected, its
/// [TapRegion.onTapOutside] callback is called. If the tap is outside one
/// member of a group, but inside another, no notification is made.
///
/// When a tap inside of a registered region or region group is detected, its
/// [TapRegion.onTapInside] callback is called. If the tap is inside one member
/// of a group, all members are notified.
///
/// The [TapRegionSurface] should be defined at the highest level needed to
/// encompass the entire area where taps should be monitored. This is typically
/// around the entire app. If the entire app isn't covered, then taps outside of
/// the [TapRegionSurface] will be ignored and no [TapRegion.onTapOutside] calls
/// will be made for those events. The [WidgetsApp], [MaterialApp] and
/// [CupertinoApp] automatically include a [TapRegionSurface] around their
/// entire app.
///
/// [TapRegionSurface] does not participate in the [gesture
/// disambiguation](https://flutter.dev/gestures/#gesture-disambiguation)
/// system, so if multiple [TapRegionSurface]s are active at the same time, they
/// will all fire, and so will any other gestures recognized by a
/// [GestureDetector] or other pointer event handlers.
///
/// [TapRegion]s register only with the nearest ancestor [TapRegionSurface].
///
/// See also:
///
///  * [RenderTapRegionSurface], the render object that is inserted into the
///    render tree by this widget.
///  * <https://flutter.dev/gestures/#gesture-disambiguation> for more
///    information about the gesture system and how it disambiguates inputs.
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
/// set of registered regions, without participating in the [gesture
/// disambiguation](https://flutter.dev/gestures/#gesture-disambiguation)
/// system.
///
/// The regions are defined by adding [RenderTapRegion] render objects in the
/// render tree around the regions of interest, and they will register with this
/// [RenderTapRegionSurface]. Each of the tap regions can optionally belong to a
/// group by assigning a [RenderTapRegion.groupId], where all the regions with
/// the same groupId act as if they were all one region.
///
/// When a tap outside of a registered region or region group is detected, its
/// [TapRegion.onTapOutside] callback is called. If the tap is outside one
/// member of a group, but inside another, no notification is made.
///
/// When a tap inside of a registered region or region group is detected, its
/// [TapRegion.onTapInside] callback is called. If the tap is inside one member
/// of a group, all members are notified.
///
/// The [RenderTapRegionSurface] should be defined at the highest level needed
/// to encompass the entire area where taps should be monitored. This is
/// typically around the entire app. If the entire app isn't covered, then taps
/// outside of the [RenderTapRegionSurface] will be ignored and no
/// [RenderTapRegion.onTapOutside] calls will be made for those events. The
/// [WidgetsApp], [MaterialApp] and [CupertinoApp] automatically include a
/// [RenderTapRegionSurface] around the entire app.
///
/// [RenderTapRegionSurface] does not participate in the [gesture
/// disambiguation](https://flutter.dev/gestures/#gesture-disambiguation)
/// system, so if multiple [RenderTapRegionSurface]s are active at the same
/// time, they will all fire, and so will any other gestures recognized by a
/// [GestureDetector] or other pointer event handlers.
///
/// [RenderTapRegion]s register only with the nearest ancestor
/// [RenderTapRegionSurface].
///
/// See also:
///
///  * [TapRegionSurface], a widget that inserts a [RenderTapRegionSurface] into
///    the render tree.
///  * [TapRegionRegistry.of], which can find the nearest ancestor
///    [RenderTapRegionSurface], which is a [TapRegionRegistry].
class RenderTapRegionSurface extends RenderProxyBoxWithHitTestBehavior with TapRegionRegistry {
  final Expando<BoxHitTestResult> _cachedResults = Expando<BoxHitTestResult>();
  final Set<RenderTapRegion> _registeredRegions = <RenderTapRegion>{};
  final Map<Object?, Set<RenderTapRegion>> _groupIdToRegions = <Object?, Set<RenderTapRegion>>{};

  @override
  void registerTapRegion(RenderTapRegion region) {
    assert(_tapRegionDebug('Region $region registered.'));
    assert(!_registeredRegions.contains(region));
    _registeredRegions.add(region);
    if (region.groupId != null) {
      _groupIdToRegions[region.groupId] ??= <RenderTapRegion>{};
      _groupIdToRegions[region.groupId]!.add(region);
    }
  }

  @override
  void unregisterTapRegion(RenderTapRegion region) {
    assert(_tapRegionDebug('Region $region unregistered.'));
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

    if (_registeredRegions.isEmpty) {
      assert(_tapRegionDebug('Ignored tap event because no regions are registered.'));
      return;
    }

    final BoxHitTestResult? result = _cachedResults[entry];

    if (result == null) {
      assert(_tapRegionDebug('Ignored tap event because no surface descendants were hit.'));
      return;
    }

    // A child was hit, so we need to call onTapOutside for those regions or
    // groups of regions that were not hit.
    final Set<RenderTapRegion> hitRegions =
        _getRegionsHit(_registeredRegions, result.path).cast<RenderTapRegion>().toSet();
    final Set<RenderTapRegion> insideRegions = <RenderTapRegion>{};
    assert(_tapRegionDebug('Tap event hit ${hitRegions.length} descendants.'));

    for (final RenderTapRegion region in hitRegions) {
      if (region.groupId == null) {
        insideRegions.add(region);
        continue;
      }
      // Add all grouped regions to the insideRegions so that groups act as a
      // single region.
      insideRegions.addAll(_groupIdToRegions[region.groupId]!);
    }
    // If they're not inside, then they're outside.
    final Set<RenderTapRegion> outsideRegions = _registeredRegions.difference(insideRegions);

    for (final RenderTapRegion region in outsideRegions) {
      assert(_tapRegionDebug('Calling onTapOutside for $region'));
      region.onTapOutside?.call(event);
    }
    for (final RenderTapRegion region in insideRegions) {
      assert(_tapRegionDebug('Calling onTapInside for $region'));
      region.onTapInside?.call(event);
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

/// A widget that defines a region that can detect taps inside or outside of
/// itself and any group of regions it belongs to, without participating in the
/// [gesture disambiguation](https://flutter.dev/gestures/#gesture-disambiguation)
/// system.
///
/// This widget indicates to the nearest ancestor [TapRegionSurface] that the
/// region occupied by its child will participate in the tap detection for that
/// surface.
///
/// If this region belongs to a group (by virtue of its [groupId]), all the
/// regions in the group will act as one.
///
/// If there is no [TapRegionSurface] ancestor, [TapRegion] will do nothing.
class TapRegion extends SingleChildRenderObjectWidget {
  /// Creates a const [TapRegion].
  ///
  /// The [child] argument is required.
  const TapRegion({
    super.key,
    required super.child,
    this.enabled = true,
    this.behavior = HitTestBehavior.deferToChild,
    this.onTapOutside,
    this.onTapInside,
    this.groupId,
    String? debugLabel,
  }) : debugLabel = kReleaseMode ? null : debugLabel;

  /// Whether or not this [TapRegion] is enabled as part of the composite region.
  final bool enabled;

  /// How to behave during hit testing when deciding how the hit test propagates
  /// to children and whether to consider targets behind this [TapRegion].
  ///
  /// Defaults to [HitTestBehavior.deferToChild].
  ///
  /// See [HitTestBehavior] for the allowed values and their meanings.
  final HitTestBehavior behavior;

  /// A callback to be invoked when a tap is detected outside of this
  /// [TapRegion] and any other region with the same [groupId], if any.
  ///
  /// The [PointerDownEvent] passed to the function is the event that caused the
  /// notification. If this region is part of a group (i.e. [groupId] is set),
  /// then it's possible that the event may be outside of this immediate region,
  /// although it will be within the region of one of the group members.
  final TapRegionCallback? onTapOutside;

  /// A callback to be invoked when a tap is detected inside of this
  /// [TapRegion], or any other tap region with the same [groupId], if any.
  ///
  /// The [PointerDownEvent] passed to the function is the event that caused the
  /// notification. If this region is part of a group (i.e. [groupId] is set),
  /// then it's possible that the event may be outside of this immediate region,
  /// although it will be within the region of one of the group members.
  final TapRegionCallback? onTapInside;

  /// An optional group ID that groups [TapRegion]s together so that they
  /// operate as one region. If any member of a group is hit by a particular
  /// tap, then the [onTapOutside] will not be called for any members of the
  /// group. If any member of the group is hit, then all members will have their
  /// [onTapInside] called.
  ///
  /// If the group id is null, then only this region is hit tested.
  final Object? groupId;

  /// An optional debug label to help with debugging in debug mode.
  ///
  /// Will be null in release mode.
  final String? debugLabel;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTapRegion(
      registry: TapRegionRegistry.maybeOf(context),
      enabled: enabled,
      behavior: behavior,
      onTapOutside: onTapOutside,
      onTapInside: onTapInside,
      groupId: groupId,
      debugLabel: debugLabel,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderTapRegion renderObject) {
    renderObject
      ..registry = TapRegionRegistry.maybeOf(context)
      ..enabled = enabled
      ..behavior = behavior
      ..groupId = groupId
      ..onTapOutside = onTapOutside
      ..onTapInside = onTapInside;
    if (!kReleaseMode) {
      renderObject.debugLabel = debugLabel;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED', defaultValue: true));
    properties.add(DiagnosticsProperty<HitTestBehavior>('behavior', behavior, defaultValue: HitTestBehavior.deferToChild));
    properties.add(DiagnosticsProperty<Object?>('debugLabel', debugLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<Object?>('groupId', groupId, defaultValue: null));
  }
}

/// A render object that defines a region that can detect taps inside or outside
/// of itself and any group of regions it belongs to, without participating in
/// the [gesture
/// disambiguation](https://flutter.dev/gestures/#gesture-disambiguation)
/// system.
///
/// This render object indicates to the nearest ancestor [TapRegionSurface] that
/// the region occupied by its child (or itself if [behavior] is
/// [HitTestBehavior.opaque]) will participate in the tap detection for that
/// surface.
///
/// If this region belongs to a group (by virtue of its [groupId]), all the
/// regions in the group will act as one.
///
/// If there is no [RenderTapRegionSurface] ancestor in the render tree,
/// [RenderTapRegion] will do nothing.
///
/// The [behavior] attribute describes how to behave during hit testing when
/// deciding how the hit test propagates to children and whether to consider
/// targets behind the tap region. Defaults to [HitTestBehavior.deferToChild].
/// See [HitTestBehavior] for the allowed values and their meanings.
///
/// See also:
///
///  * [TapRegion], a widget that inserts a [RenderTapRegion] into the render
///    tree.
class RenderTapRegion extends RenderProxyBoxWithHitTestBehavior {
  /// Creates a [RenderTapRegion].
  RenderTapRegion({
    TapRegionRegistry? registry,
    bool enabled = true,
    this.onTapOutside,
    this.onTapInside,
    super.behavior = HitTestBehavior.deferToChild,
    Object? groupId,
    String? debugLabel,
  })  : _registry = registry,
        _enabled = enabled,
        _groupId = groupId,
        debugLabel = kReleaseMode ? null : debugLabel;

  bool _isRegistered = false;

  /// A callback to be invoked when a tap is detected outside of this
  /// [RenderTapRegion] and any other region with the same [groupId], if any.
  ///
  /// The [PointerDownEvent] passed to the function is the event that caused the
  /// notification. If this region is part of a group (i.e. [groupId] is set),
  /// then it's possible that the event may be outside of this immediate region,
  /// although it will be within the region of one of the group members.
  TapRegionCallback? onTapOutside;

  /// A callback to be invoked when a tap is detected inside of this
  /// [RenderTapRegion], or any other tap region with the same [groupId], if any.
  ///
  /// The [PointerDownEvent] passed to the function is the event that caused the
  /// notification. If this region is part of a group (i.e. [groupId] is set),
  /// then it's possible that the event may be outside of this immediate region,
  /// although it will be within the region of one of the group members.
  TapRegionCallback? onTapInside;

  /// A label used in debug builds. Will be null in release builds.
  String? debugLabel;

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
  /// group. If any member of the group is hit, then all members will have their
  /// [onTapInside] called.
  ///
  /// If the group id is null, then only this region is hit tested.
  Object? get groupId => _groupId;
  Object? _groupId;
  set groupId(Object? value) {
    if (_groupId != value) {
      // If the group changes, we need to unregister and re-register under the
      // new group. The re-registration happens automatically in layout().
      if (_isRegistered) {
        _registry!.unregisterTapRegion(this);
        _isRegistered = false;
      }
      _groupId = value;
      markNeedsLayout();
    }
  }

  /// The registry that this [RenderTapRegion] should register with.
  ///
  /// If the [registry] is null, then this region will not be registered
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
    properties.add(DiagnosticsProperty<String?>('debugLabel', debugLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<Object?>('groupId', groupId, defaultValue: null));
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'DISABLED', defaultValue: true));
  }
}

/// A [TapRegion] that adds its children to the tap region group for widgets
/// based on the [EditableText] text editing widget, such as [TextField] and
/// [CupertinoTextField].
///
/// Widgets that are wrapped with a [TextFieldTapRegion] are considered to be
/// part of a text field for purposes of unfocus behavior. So, when the user
/// taps on them, the currently focused text field won't be unfocused by
/// default. This allows controls like spinners, copy buttons, and formatting
/// buttons to be associated with a text field without causing the text field to
/// lose focus when they are interacted with.
///
/// {@tool dartpad}
/// This example shows how to use a [TextFieldTapRegion] to wrap a set of
/// "spinner" buttons that increment and decrement a value in the text field
/// without causing the text field to lose keyboard focus.
///
/// This example includes a generic `SpinnerField<T>` class that you can copy/paste
/// into your own project and customize.
///
/// ** See code in examples/api/lib/widgets/tap_region/text_field_tap_region.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [TapRegion], the widget that this widget uses to add widgets to the group
///    of text fields.
class TextFieldTapRegion extends TapRegion {
  /// Creates a const [TextFieldTapRegion].
  ///
  /// The [child] field is required.
  const TextFieldTapRegion({
    super.key,
    required super.child,
    super.enabled,
    super.onTapOutside,
    super.onTapInside,
    super.debugLabel,
  }) : super(groupId: EditableText);
}
