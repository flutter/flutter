// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/rendering.dart';
/// @docImport 'package:flutter/semantics.dart';
/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:flutter_test/flutter_test.dart';
///
/// @docImport 'binding.dart';
library;

// Unlike the rest of the foundation library (see README.md), this library
// imports all of `dart:ui`. It implements the complete [ui.PlatformDispatcher]
// and [ui.FlutterView] interfaces, so it needs every type that appears in their
// signatures; an explicit `show` list would name most of `dart:ui` and would
// have to be updated on every engine roll for members this library only
// forwards. The dependency is debug-only: everything below is unreachable in
// release builds, because every function that constructs it does so inside an
// `assert`.
//
// None of the wrappers below declare a `noSuchMethod`, which is deliberate.
// Every `dart:ui` member a wrapper stands in front of is spelled out, so a
// member added on the engine side breaks this library at compile time. A
// `noSuchMethod` returning null would instead put a dispatcher that silently
// answers `null` for the new member in front of the whole framework in every
// debug build, and a non-nullable member would then fail as a `TypeError` at
// whichever call site happened to read it.
import 'dart:async' show Zone;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'debug.dart';

/// Wraps `dispatcher` so that the entries of [debugViewMetricsOverrides] are
/// applied to the view metrics it and its [ui.FlutterView]s report.
///
/// Returns `dispatcher` itself outside of debug mode (in profile or release
/// mode), and returns the same wrapper every time it is called with the same
/// `dispatcher`, so that the views it vends keep a stable identity. Wrapping an
/// already-wrapped dispatcher returns it unchanged.
///
/// [BindingBase.platformDispatcher] applies this to
/// [ui.PlatformDispatcher.instance], which is what makes overrides visible to
/// the whole framework. [TestWidgetsFlutterBinding] applies it to the
/// dispatcher its [TestPlatformDispatcher] wraps, so that overrides also apply
/// in widget tests. A binding that supplies a dispatcher of its own should do
/// the same, or overrides never reach the framework running on it.
///
/// Installing the wrapper is behavior neutral while
/// [debugViewMetricsOverrides] is empty: every member forwards to the wrapped
/// object. It is therefore installed unconditionally rather than only while an
/// override exists, so that a [ui.FlutterView] handed to a [RenderView] or a
/// [View] does not change identity when tooling installs or removes an
/// override.
///
/// When an override changes, the `dart:ui` callbacks that report the changed
/// metrics — [ui.PlatformDispatcher.onMetricsChanged] and its siblings — are
/// invoked on every dispatcher wrapped this way, each in the zone it was
/// registered in through the wrapper. Callbacks assigned directly to the
/// wrapped dispatcher, rather than through the wrapper, are invoked too, but in
/// whichever zone changed the override.
ui.PlatformDispatcher debugApplyViewMetricsOverrides(ui.PlatformDispatcher dispatcher) {
  var result = dispatcher;
  assert(() {
    result = _wrapperFor(dispatcher);
    return true;
  }());
  return result;
}

/// Returns the [ui.FlutterView] that applies the [debugViewMetricsOverrides]
/// entry registered for `view`'s id, when `view` itself does not apply it.
///
/// A view read straight from a [ui.PlatformDispatcher] that has been wrapped —
/// from [ui.PlatformDispatcher.views] on [ui.PlatformDispatcher.instance],
/// rather than from the dispatcher [BindingBase.platformDispatcher] returns —
/// reports the metrics the platform reports, while [debugViewMetricsOverrides]
/// has an entry for its id. Reading it through the wrapper instead keeps what a
/// view reports and what the registry says in agreement, which is what
/// [RenderView], [View] and [MediaQueryData.fromView] rely on: they read an
/// override only through the view, never from the registry.
///
/// Engine views are normalized even before the binding wraps their dispatcher,
/// because a [View] can be constructed before [runWidget] initializes it. A
/// view this library produced already applies its own override and is returned
/// unchanged, as is a view whose dispatcher has not been wrapped — a
/// [TestFlutterView], say, which is read through its own dispatcher — or that
/// reports no dispatcher at all.
///
/// Like the wrapper itself, the result does not depend on whether an override
/// is registered: a view that is wrapped while one exists would otherwise
/// change identity as tooling installs and removes overrides.
///
/// Returns `view` unchanged outside of debug mode (in profile or release mode).
ui.FlutterView debugViewWithMetricsOverrides(ui.FlutterView view) {
  var result = view;
  assert(() {
    if (view is _DebugViewMetricsFlutterView) {
      return true;
    }
    // Low-level rendering tests can provide a view without a dispatcher. Such a
    // view cannot take part in overrides; its existing contract is left intact.
    final ui.PlatformDispatcher? dispatcher = _debugDispatcherOf(view);
    if (dispatcher == null) {
      return true;
    }
    // The engine's dispatcher is wrapped on demand, so that a View constructed
    // before the binding is still ends up with the same view the binding will
    // vend later. Any other dispatcher has to have been wrapped already: a view
    // of a dispatcher nobody wrapped is one nobody asked to apply overrides.
    final _DebugViewMetricsPlatformDispatcher? wrapper =
        identical(dispatcher, ui.PlatformDispatcher.instance)
        ? _wrapperFor(dispatcher)
        : _wrappers[dispatcher];
    result = wrapper?._tryWrapView(view) ?? view;
    return true;
  }());
  return result;
}

/// Tells every [ui.PlatformDispatcher] that has been wrapped by
/// [debugApplyViewMetricsOverrides] that the metric groups named here changed,
/// by invoking the `dart:ui` callbacks that report them.
///
/// Which dispatchers are told is not assumed: it is usually
/// [ui.PlatformDispatcher.instance], but a binding that supplies its own, as
/// [BindingBase.platformDispatcher] documents, registers the framework's
/// callbacks on that one instead, and would never hear about an override if
/// only the singleton were told.
///
/// A dispatcher is told whichever view an override was registered for, and
/// whether or not it reports that view: what an override changes for a given
/// dispatcher is for that dispatcher's own metrics to say, and re-reading
/// metrics that did not change is what the platform's own notifications ask
/// for too.
///
/// This is called by [debugSetViewMetricsOverride] and
/// [debugClearViewMetricsOverrides], and is not exported from the foundation
/// library. Does nothing outside of debug mode (in profile or release mode),
/// where nothing is ever wrapped.
void debugReplayViewMetricsNotifications({
  required bool platformConfiguration,
  required bool textScaleFactor,
  required bool platformBrightness,
  required bool accessibilityFeatures,
  required bool viewMetrics,
}) {
  assert(() {
    // Pruned here rather than as dispatchers are wrapped, because this already
    // reads every target; wrapping n dispatchers would otherwise cost O(n²).
    _wrapped.removeWhere(
      (WeakReference<_DebugViewMetricsPlatformDispatcher> reference) => reference.target == null,
    );
    // Iterated over a copy: a callback is free to wrap another dispatcher.
    for (final WeakReference<_DebugViewMetricsPlatformDispatcher> reference in _wrapped.toList()) {
      reference.target?._replay(
        platformConfiguration: platformConfiguration,
        textScaleFactor: textScaleFactor,
        platformBrightness: platformBrightness,
        accessibilityFeatures: accessibilityFeatures,
        viewMetrics: viewMetrics,
      );
    }
    return true;
  }());
}

// Reads one member of a `dart:ui` object that an incomplete test double may not
// implement, and reports "not implemented" as null. The value comes back in a
// one-element record so that a member whose own type is nullable — such as
// [ui.PlatformDispatcher.implicitView] — can still be told apart from an absent
// one.
//
// A [ui.FlutterView] or [ui.PlatformDispatcher] written for a rendering-layer
// test can omit `viewId`, `platformDispatcher` or `implicitView` altogether:
// `Fake` answers every member it does not implement with an
// [UnimplementedError], and a double with a `noSuchMethod` of its own throws a
// [NoSuchMethodError]. Neither object can take part in overrides, so a missing
// member is treated as an absent value rather than as a failure.
//
// [read] must do nothing but read the single member being probed. These two
// errors are the only signal `dart:ui` gives that a member is missing, and they
// are indistinguishable from the same errors raised from inside a member that
// does exist, so anything else in [read] would have its own failures
// misattributed to a member that is missing.
(T,)? _ifImplemented<T>(T Function() read) {
  try {
    return (read(),);
  } on NoSuchMethodError {
    return null;
  } on UnimplementedError {
    return null;
  }
}

// The dispatcher [view] reports, or null if it does not implement one.
ui.PlatformDispatcher? _debugDispatcherOf(ui.FlutterView view) =>
    _ifImplemented(() => view.platformDispatcher)?.$1;

// The id [view] reports, or null if it does not implement one.
int? _debugViewIdOf(ui.FlutterView view) => _ifImplemented(() => view.viewId)?.$1;

// Keyed by the wrapped dispatcher so that the wrapper cannot outlive it.
final Expando<_DebugViewMetricsPlatformDispatcher> _wrappers =
    Expando<_DebugViewMetricsPlatformDispatcher>('debugViewMetricsOverrides');

// The wrappers that are notified when an override changes, in the order they
// were wrapped.
//
// An Expando cannot be enumerated, so the values of [_wrappers] are also kept
// here, weakly and pruned as they die. A wrapper is reachable only through the
// entry its own dispatcher keys, and holds that dispatcher strongly, so the two
// die together and remembering one for the sake of notifying it keeps neither
// alive.
final List<WeakReference<_DebugViewMetricsPlatformDispatcher>> _wrapped =
    <WeakReference<_DebugViewMetricsPlatformDispatcher>>[];

// The wrapper for `dispatcher`, built and cached if there is not one already,
// and `dispatcher` itself if it is already a wrapper.
//
// This is the only place a root wrapper is created, so a dispatcher cannot be
// wrapped for the framework to read without also becoming a dispatcher that
// [debugReplayViewMetricsNotifications] tells about override changes.
_DebugViewMetricsPlatformDispatcher _wrapperFor(ui.PlatformDispatcher dispatcher) {
  if (dispatcher is _DebugViewMetricsPlatformDispatcher) {
    return dispatcher;
  }
  _DebugViewMetricsPlatformDispatcher? wrapper = _wrappers[dispatcher];
  if (wrapper == null) {
    wrapper = _DebugViewMetricsPlatformDispatcher(dispatcher);
    _wrappers[dispatcher] = wrapper;
    _wrapped.add(WeakReference<_DebugViewMetricsPlatformDispatcher>(wrapper));
  }
  return wrapper;
}

/// A [ui.PlatformDispatcher] that reports the metrics of
/// [debugViewMetricsOverrides] in place of the ones the platform reports.
///
/// Members that do not carry an overridable metric forward to [_dispatcher]
/// unchanged.
///
/// There is one instance per wrapped dispatcher, plus one per view: the
/// per-view instances are what [ui.FlutterView.platformDispatcher] returns, and
/// they resolve the platform-wide metrics ([ui.PlatformDispatcher.textScaleFactor],
/// [ui.PlatformDispatcher.accessibilityFeatures] and friends) from the override
/// of the view they belong to. The instance that is not tied to a view resolves
/// them from the override of [ui.PlatformDispatcher.implicitView], because
/// consumers that read those metrics off the binding rather than off a view —
/// [SemanticsBinding.accessibilityFeatures], for one — have no view to resolve
/// against. Such a consumer is therefore process-wide however many views there
/// are; [DebugViewMetricsOverride.disableAnimations] describes what that means
/// for the one whose behavior an application is most likely to notice.
class _DebugViewMetricsPlatformDispatcher implements ui.PlatformDispatcher {
  _DebugViewMetricsPlatformDispatcher(this._dispatcher) : _viewId = null, _root = null;

  _DebugViewMetricsPlatformDispatcher._forView(_DebugViewMetricsPlatformDispatcher root, int viewId)
    : _root = root,
      _viewId = viewId,
      _dispatcher = root._dispatcher;

  /// The dispatcher whose metrics are being overridden.
  final ui.PlatformDispatcher _dispatcher;

  // The zone each notification callback was registered in.
  //
  // dart:ui records this in every callback setter and guarantees the callback
  // runs there rather than wherever the platform happened to deliver the event
  // from; a replayed notification has to do the same, or a callback registered
  // in one zone runs in whichever zone changed the override, losing that zone's
  // values and its error handling. The zone the wrapped dispatcher captured is
  // private to it, so the wrapper keeps its own, which is the one the framework
  // registered through.
  //
  // Kept on the root, because that is the wrapper that replays, and a per-view
  // one registers on the very same dispatcher: there is one callback slot, so
  // there is one zone to remember for it.
  (WeakReference<ui.VoidCallback>, Zone)? _onMetricsChangedRegistration;
  (WeakReference<ui.VoidCallback>, Zone)? _onTextScaleFactorChangedRegistration;
  (WeakReference<ui.VoidCallback>, Zone)? _onPlatformBrightnessChangedRegistration;
  (WeakReference<ui.VoidCallback>, Zone)? _onAccessibilityFeaturesChangedRegistration;
  (WeakReference<ui.VoidCallback>, Zone)? _onPlatformConfigurationChangedRegistration;

  /// The dispatcher that owns the view wrappers, or null if this is that
  /// dispatcher.
  final _DebugViewMetricsPlatformDispatcher? _root;

  /// The view whose override supplies the platform-wide metrics, or null to use
  /// [ui.PlatformDispatcher.implicitView].
  final int? _viewId;

  // This wrapper if it is a root, and the root that owns it if it is not.
  //
  // The zone fields above live there, and so does [_views]; a per-view wrapper
  // shares the dispatcher its root wraps, so what either of them is asked about
  // the whole dispatcher has one answer, kept in one place.
  _DebugViewMetricsPlatformDispatcher get _rootWrapper => _root ?? this;

  // Reports the metric groups named as changed, the way dart:ui reports them:
  // the platform configuration first, then the callback for the field that
  // changed, when that field has one of its own.
  //
  // Only a root wrapper replays, which is what makes reading the zone fields
  // off `this` right: a per-view wrapper records onto its root, so its own are
  // all null and every notification would fall back to the mutating zone.
  void _replay({
    required bool platformConfiguration,
    required bool textScaleFactor,
    required bool platformBrightness,
    required bool accessibilityFeatures,
    required bool viewMetrics,
  }) {
    assert(_root == null, 'Only a root wrapper holds the zones its views registered through.');
    if (platformConfiguration) {
      _notify(
        () => _dispatcher.onPlatformConfigurationChanged,
        _onPlatformConfigurationChangedRegistration,
      );
    }
    if (textScaleFactor) {
      _notify(() => _dispatcher.onTextScaleFactorChanged, _onTextScaleFactorChangedRegistration);
    }
    if (platformBrightness) {
      _notify(
        () => _dispatcher.onPlatformBrightnessChanged,
        _onPlatformBrightnessChangedRegistration,
      );
    }
    if (accessibilityFeatures) {
      _notify(
        () => _dispatcher.onAccessibilityFeaturesChanged,
        _onAccessibilityFeaturesChangedRegistration,
      );
    }
    if (viewMetrics) {
      _notify(() => _dispatcher.onMetricsChanged, _onMetricsChangedRegistration);
    }
  }

  // Delivers one notification, in the zone a wrapper of this dispatcher saw
  // the callback being registered in, and without letting a failure cancel the
  // notifications after it: a metric that changed and was not reported leaves
  // the framework reading a value nothing told it to re-read, which is the
  // state this whole replay exists to prevent.
  //
  // Like dart:ui's _invoke, cross-zone delivery uses runGuarded. Same-zone
  // delivery is guarded too: this replay must continue after a failure, so it
  // cannot rely on an exception unwinding to the platform entry point. A
  // callback installed directly on the wrapped dispatcher has an unknown zone
  // and is never paired with the zone of the callback it replaced; it, and a
  // callback that cannot even be read off an incomplete test double, are
  // reported through FlutterError.
  @pragma('vm:notify-debugger-on-exception')
  void _notify(
    ui.VoidCallback? Function() read,
    (WeakReference<ui.VoidCallback>, Zone)? registration,
  ) {
    try {
      final ui.VoidCallback? callback = read();
      if (callback == null) {
        return;
      }
      if (registration != null && identical(registration.$1.target, callback)) {
        registration.$2.runGuarded(callback);
      } else {
        callback();
      }
    } catch (exception, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'foundation library',
          context: ErrorDescription(
            'while telling a PlatformDispatcher that a debug view metrics override changed',
          ),
        ),
      );
    }
  }

  // Keyed by the wrapped view so that a wrapper cannot outlive the view it
  // wraps, and so that repeated reads of `views` return the same wrappers:
  // views are compared by identity and used as map keys (as GlobalKeys, by
  // RenderView and by the widgets layer), so their identity has to be stable.
  // Only the root dispatcher ever populates this; the per-view ones resolve
  // through [_root], so `late` keeps them from allocating an Expando each.
  late final Expando<_DebugViewMetricsFlutterView> _views = Expando<_DebugViewMetricsFlutterView>();

  // The entry whose platform-wide metrics this dispatcher reports.
  //
  // A per-view wrapper resolves the entry registered for its own view. The root
  // wrapper has no view of its own, so it resolves the implicit view's:
  // consumers that read a platform-wide metric off the binding rather than off
  // a view — [SemanticsBinding.accessibilityFeatures], for one — have no view
  // to resolve against. See [_DebugViewMetricsPlatformDispatcher].
  //
  // Without an implicit view either, nothing identifies which view the caller
  // meant, and no entry is resolved. Guessing — taking the only entry there
  // happens to be, or the first view the dispatcher reports — would apply an
  // entry registered for one view to a dispatcher that has nothing to do with
  // it, and would silently change which entry it picked as soon as a second one
  // was registered.
  DebugViewMetricsOverride? get _override {
    final int? viewId = _viewId ?? _ifImplemented(() => _dispatcher.implicitView?.viewId)?.$1;
    return viewId == null ? null : debugViewMetricsOverrides[viewId];
  }

  _DebugViewMetricsFlutterView _wrapView(ui.FlutterView view) {
    final _DebugViewMetricsPlatformDispatcher root = _rootWrapper;
    return root._views[view] ??= _DebugViewMetricsFlutterView(
      view,
      _DebugViewMetricsPlatformDispatcher._forView(root, view.viewId),
    );
  }

  // [_wrapView], for a view that may not implement [ui.FlutterView.viewId] and
  // so may not be wrappable at all. See [_ifImplemented].
  _DebugViewMetricsFlutterView? _tryWrapView(ui.FlutterView view) {
    final _DebugViewMetricsPlatformDispatcher root = _rootWrapper;
    final _DebugViewMetricsFlutterView? wrapped = root._views[view];
    if (wrapped != null) {
      return wrapped;
    }
    final int? viewId = _debugViewIdOf(view);
    if (viewId == null) {
      return null;
    }
    return root._views[view] = _DebugViewMetricsFlutterView(
      view,
      _DebugViewMetricsPlatformDispatcher._forView(root, viewId),
    );
  }

  // Overridden metrics.

  @override
  ui.AccessibilityFeatures get accessibilityFeatures {
    final ui.AccessibilityFeatures features = _dispatcher.accessibilityFeatures;
    final DebugViewMetricsOverride? override = _override;
    return override == null || !override.overridesAccessibilityFeatures
        ? features
        : _DebugAccessibilityFeatures(features, override);
  }

  @override
  bool get alwaysUse24HourFormat =>
      _override?.alwaysUse24HourFormat ?? _dispatcher.alwaysUse24HourFormat;

  @override
  ui.Brightness get platformBrightness =>
      _override?.platformBrightness ?? _dispatcher.platformBrightness;

  // The ratio of the first point of an overridden table, as
  // [DebugViewMetricsOverride.textScaling] documents. The table is validated
  // when it is registered, so the first point has a finite, positive unscaled
  // size to divide by.
  @override
  double get textScaleFactor {
    final List<ui.Offset>? textScaling = _override?.textScaling;
    if (textScaling == null) {
      return _dispatcher.textScaleFactor;
    }
    final ui.Offset first = textScaling.first;
    return first.dy / first.dx;
  }

  @override
  double scaleFontSize(double unscaledFontSize) {
    final List<ui.Offset>? textScaling = _override?.textScaling;
    if (textScaling == null) {
      return _dispatcher.scaleFontSize(unscaledFontSize);
    }
    return _scaleFontSizeWithTable(textScaling, unscaledFontSize);
  }

  // Applies [points] to [fontSize] the way
  // [DebugViewMetricsOverride.textScaling] documents: a size between two points
  // is interpolated linearly between them, and one outside the points is scaled
  // by the ratio of the nearest point.
  //
  // A negative, infinite or NaN font size is not rejected. Whatever `dart:ui`
  // does with one is what an application already sees, and installing an
  // override must not turn a value the platform tolerates into an assertion the
  // platform never raised; the nearest-point rule happens to apply to all of
  // them, which keeps the result as finite or as not as the input.
  static double _scaleFontSizeWithTable(List<ui.Offset> points, double fontSize) {
    final ui.Offset first = points.first;
    if (!(fontSize > first.dx)) {
      return fontSize * (first.dy / first.dx);
    }
    final ui.Offset last = points.last;
    if (fontSize >= last.dx) {
      return fontSize * (last.dy / last.dx);
    }
    for (var i = 1; i < points.length; i += 1) {
      final ui.Offset upper = points[i];
      if (fontSize <= upper.dx) {
        final ui.Offset lower = points[i - 1];
        final double t = (fontSize - lower.dx) / (upper.dx - lower.dx);
        return lower.dy + (upper.dy - lower.dy) * t;
      }
    }
    // Unreachable: the loop ends at the last point, which the test above
    // already handled.
    return fontSize * (last.dy / last.dx);
  }

  // Views, wrapped so that the metrics they report are overridden too.

  // Held rather than torn off per call: `views` is read once per frame per
  // view, and `map(_wrapView)` would otherwise allocate a fresh bound closure
  // alongside the iterable every time.
  late final ui.FlutterView Function(ui.FlutterView) _wrapViewTearOff = _wrapView;

  @override
  Iterable<ui.FlutterView> get views => _dispatcher.views.map(_wrapViewTearOff);

  @override
  ui.FlutterView? view({required int id}) {
    final ui.FlutterView? view = _dispatcher.view(id: id);
    return view == null ? null : _wrapView(view);
  }

  @override
  ui.FlutterView? get implicitView {
    final ui.FlutterView? view = _dispatcher.implicitView;
    return view == null ? null : _wrapView(view);
  }

  // Everything below carries no overridable view metric and is forwarded.

  @override
  String get defaultRouteName => _dispatcher.defaultRouteName;

  @override
  Iterable<ui.Display> get displays => _dispatcher.displays;

  @override
  int? get engineId => _dispatcher.engineId;

  @override
  ui.FrameData get frameData => _dispatcher.frameData;

  @override
  String get initialLifecycleState => _dispatcher.initialLifecycleState;

  // The text spacing preferences below are in logical pixels, like
  // [ui.DisplayFeature.bounds], but unlike display features they are
  // typographic offsets applied to logical font sizes rather than positions on
  // the screen, so an overridden device pixel ratio leaves them alone: the
  // user asked for "two more logical pixels between letters", and that is still
  // what they get in the overridden logical space.
  @override
  double? get letterSpacingOverride => _dispatcher.letterSpacingOverride;

  @override
  double? get lineHeightScaleFactorOverride => _dispatcher.lineHeightScaleFactorOverride;

  @override
  ui.Locale get locale => _dispatcher.locale;

  @override
  List<ui.Locale> get locales => _dispatcher.locales;

  @override
  bool get nativeSpellCheckServiceDefined => _dispatcher.nativeSpellCheckServiceDefined;

  @override
  bool get brieflyShowPassword => _dispatcher.brieflyShowPassword;

  @override
  double? get paragraphSpacingOverride => _dispatcher.paragraphSpacingOverride;

  @override
  bool get semanticsEnabled => _dispatcher.semanticsEnabled;

  @override
  bool get supportsShowingSystemContextMenu => _dispatcher.supportsShowingSystemContextMenu;

  @override
  String? get systemFontFamily => _dispatcher.systemFontFamily;

  @override
  double? get wordSpacingOverride => _dispatcher.wordSpacingOverride;

  @override
  ui.VoidCallback? get onAccessibilityFeaturesChanged => _dispatcher.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(ui.VoidCallback? callback) {
    _dispatcher.onAccessibilityFeaturesChanged = callback;
    _rootWrapper._onAccessibilityFeaturesChangedRegistration = callback == null
        ? null
        : (WeakReference<ui.VoidCallback>(callback), Zone.current);
  }

  @override
  ui.FrameCallback? get onBeginFrame => _dispatcher.onBeginFrame;
  @override
  set onBeginFrame(ui.FrameCallback? callback) {
    _dispatcher.onBeginFrame = callback;
  }

  @override
  ui.VoidCallback? get onDrawFrame => _dispatcher.onDrawFrame;
  @override
  set onDrawFrame(ui.VoidCallback? callback) {
    _dispatcher.onDrawFrame = callback;
  }

  @override
  ui.ErrorCallback? get onError => _dispatcher.onError;
  @override
  set onError(ui.ErrorCallback? callback) {
    _dispatcher.onError = callback;
  }

  @override
  ui.VoidCallback? get onFrameDataChanged => _dispatcher.onFrameDataChanged;
  @override
  set onFrameDataChanged(ui.VoidCallback? callback) {
    _dispatcher.onFrameDataChanged = callback;
  }

  @override
  ui.HitTestCallback? get onHitTest => _dispatcher.onHitTest;
  @override
  set onHitTest(ui.HitTestCallback? callback) {
    _dispatcher.onHitTest = callback;
  }

  @override
  ui.KeyDataCallback? get onKeyData => _dispatcher.onKeyData;
  @override
  set onKeyData(ui.KeyDataCallback? callback) {
    _dispatcher.onKeyData = callback;
  }

  @override
  ui.VoidCallback? get onLocaleChanged => _dispatcher.onLocaleChanged;
  @override
  set onLocaleChanged(ui.VoidCallback? callback) {
    _dispatcher.onLocaleChanged = callback;
  }

  @override
  ui.VoidCallback? get onMetricsChanged => _dispatcher.onMetricsChanged;
  @override
  set onMetricsChanged(ui.VoidCallback? callback) {
    _dispatcher.onMetricsChanged = callback;
    _rootWrapper._onMetricsChangedRegistration = callback == null
        ? null
        : (WeakReference<ui.VoidCallback>(callback), Zone.current);
  }

  @override
  ui.VoidCallback? get onPlatformBrightnessChanged => _dispatcher.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(ui.VoidCallback? callback) {
    _dispatcher.onPlatformBrightnessChanged = callback;
    _rootWrapper._onPlatformBrightnessChangedRegistration = callback == null
        ? null
        : (WeakReference<ui.VoidCallback>(callback), Zone.current);
  }

  @override
  ui.VoidCallback? get onPlatformConfigurationChanged => _dispatcher.onPlatformConfigurationChanged;
  @override
  set onPlatformConfigurationChanged(ui.VoidCallback? callback) {
    _dispatcher.onPlatformConfigurationChanged = callback;
    _rootWrapper._onPlatformConfigurationChangedRegistration = callback == null
        ? null
        : (WeakReference<ui.VoidCallback>(callback), Zone.current);
  }

  @override
  ui.PlatformMessageCallback? get onPlatformMessage => _dispatcher.onPlatformMessage;
  @override
  set onPlatformMessage(ui.PlatformMessageCallback? callback) {
    _dispatcher.onPlatformMessage = callback;
  }

  @override
  ui.PointerDataPacketCallback? get onPointerDataPacket => _dispatcher.onPointerDataPacket;
  @override
  set onPointerDataPacket(ui.PointerDataPacketCallback? callback) {
    _dispatcher.onPointerDataPacket = callback;
  }

  @override
  ui.TimingsCallback? get onReportTimings => _dispatcher.onReportTimings;
  @override
  set onReportTimings(ui.TimingsCallback? callback) {
    _dispatcher.onReportTimings = callback;
  }

  @override
  ui.SemanticsActionEventCallback? get onSemanticsActionEvent => _dispatcher.onSemanticsActionEvent;
  @override
  set onSemanticsActionEvent(ui.SemanticsActionEventCallback? callback) {
    _dispatcher.onSemanticsActionEvent = callback;
  }

  @override
  ui.VoidCallback? get onSemanticsEnabledChanged => _dispatcher.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(ui.VoidCallback? callback) {
    _dispatcher.onSemanticsEnabledChanged = callback;
  }

  @override
  ui.VoidCallback? get onSystemFontFamilyChanged => _dispatcher.onSystemFontFamilyChanged;
  @override
  set onSystemFontFamilyChanged(ui.VoidCallback? callback) {
    _dispatcher.onSystemFontFamilyChanged = callback;
  }

  @override
  ui.VoidCallback? get onTextScaleFactorChanged => _dispatcher.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(ui.VoidCallback? callback) {
    _dispatcher.onTextScaleFactorChanged = callback;
    _rootWrapper._onTextScaleFactorChangedRegistration = callback == null
        ? null
        : (WeakReference<ui.VoidCallback>(callback), Zone.current);
  }

  @override
  ui.ViewFocusChangeCallback? get onViewFocusChange => _dispatcher.onViewFocusChange;
  @override
  set onViewFocusChange(ui.ViewFocusChangeCallback? callback) {
    _dispatcher.onViewFocusChange = callback;
  }

  @override
  ui.Locale? computePlatformResolvedLocale(List<ui.Locale> supportedLocales) =>
      _dispatcher.computePlatformResolvedLocale(supportedLocales);

  @override
  ByteData? getPersistentIsolateData() => _dispatcher.getPersistentIsolateData();

  @override
  void registerBackgroundIsolate(ui.RootIsolateToken token) =>
      _dispatcher.registerBackgroundIsolate(token);

  @override
  void requestDartPerformanceMode(ui.DartPerformanceMode mode) =>
      _dispatcher.requestDartPerformanceMode(mode);

  @override
  void resetInternalState() => _dispatcher.resetInternalState();

  @override
  void requestViewFocusChange({
    required int viewId,
    required ui.ViewFocusState state,
    required ui.ViewFocusDirection direction,
  }) => _dispatcher.requestViewFocusChange(viewId: viewId, state: state, direction: direction);

  @override
  void scheduleFrame() => _dispatcher.scheduleFrame();

  @override
  void scheduleWarmUpFrame({
    required ui.VoidCallback beginFrame,
    required ui.VoidCallback drawFrame,
  }) => _dispatcher.scheduleWarmUpFrame(beginFrame: beginFrame, drawFrame: drawFrame);

  @override
  void sendPlatformMessage(
    String name,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) => _dispatcher.sendPlatformMessage(name, data, callback);

  @override
  void sendPortPlatformMessage(String name, ByteData? data, int identifier, Object port) {
    // `port` is declared as a `SendPort` by the VM's dart:ui and as an `Object`
    // by the web's, so this parameter is widened to `Object` to satisfy both.
    // Forwarding it therefore needs a downcast that only exists on the VM,
    // which is what going through `dynamic` expresses; `strict-casts` reports
    // that downcast, and there is nothing here to check it against on the web.
    final dynamic sendPort = port;
    // ignore: argument_type_not_assignable
    _dispatcher.sendPortPlatformMessage(name, data, identifier, sendPort);
  }

  @override
  void setApplicationLocale(ui.Locale locale) => _dispatcher.setApplicationLocale(locale);

  @override
  void setIsolateDebugName(String name) => _dispatcher.setIsolateDebugName(name);

  @override
  void setSemanticsTreeEnabled(bool enabled) => _dispatcher.setSemanticsTreeEnabled(enabled);

  @override
  void updateSemantics(ui.SemanticsUpdate update) => _dispatcher.updateSemantics(update);

  @override
  String toString() =>
      'DebugViewMetricsPlatformDispatcher(${_viewId == null ? 'implicit view' : 'view $_viewId'})';
}

/// A [ui.FlutterView] that reports the metrics its entry in
/// [debugViewMetricsOverrides] specifies in place of the ones the platform
/// reports.
///
/// Members that do not carry an overridable view metric forward to [_view]
/// unchanged. In particular [display] reports the real [ui.Display], because it
/// describes hardware rather than the view.
class _DebugViewMetricsFlutterView implements ui.FlutterView {
  _DebugViewMetricsFlutterView(this._view, this._platformDispatcher)
    : assert(
        _platformDispatcher._viewId == _view.viewId,
        'A view must report a dispatcher bound to its own id, or the override '
        'it resolves would not be the one registered for it.',
      );

  /// The view whose metrics are being overridden.
  final ui.FlutterView _view;

  /// The dispatcher that resolves this view's platform-wide metric overrides.
  ///
  /// This is not the dispatcher [debugApplyViewMetricsOverrides] returned; see
  /// [_DebugViewMetricsPlatformDispatcher] for why they differ. It is owned by
  /// this view so that it is collected along with it.
  @override
  ui.PlatformDispatcher get platformDispatcher => _platformDispatcher;
  final _DebugViewMetricsPlatformDispatcher _platformDispatcher;

  DebugViewMetricsOverride? get _override => debugViewMetricsOverrides[_view.viewId];

  // Overridden metrics.

  @override
  double get devicePixelRatio => _override?.devicePixelRatio ?? _view.devicePixelRatio;

  @override
  ui.Size get physicalSize => _override?.physicalSize ?? _view.physicalSize;

  @override
  ui.ViewConstraints get physicalConstraints {
    // Overriding the size of a view makes it a fixed-size view: a loose
    // constraint would let layout pick the real size back up and the override
    // would have no effect.
    final ui.Size? physicalSize = _override?.physicalSize;
    return physicalSize == null
        ? _view.physicalConstraints
        : ui.ViewConstraints.tight(physicalSize);
  }

  @override
  ui.ViewPadding get padding => _override?.padding ?? _view.padding;

  @override
  ui.ViewPadding get viewInsets => _override?.viewInsets ?? _view.viewInsets;

  @override
  ui.ViewPadding get viewPadding => _override?.viewPadding ?? _view.viewPadding;

  @override
  ui.ViewPadding get systemGestureInsets =>
      _override?.systemGestureInsets ?? _view.systemGestureInsets;

  @override
  List<ui.DisplayFeature> get displayFeatures {
    final double? devicePixelRatio = _override?.devicePixelRatio;
    final List<ui.DisplayFeature> displayFeatures = _view.displayFeatures;
    if (devicePixelRatio == null ||
        displayFeatures.isEmpty ||
        _view.devicePixelRatio == devicePixelRatio) {
      return displayFeatures;
    }
    // [ui.DisplayFeature.bounds] is the one metric [ui.FlutterView] reports in
    // logical rather than physical pixels: the engine divides it by the real
    // device pixel ratio when it decodes it. Overriding that ratio changes the
    // logical space every other metric is reported in, so these have to move
    // with it, or a hinge would be reported outside the window it is inside.
    final double scale = _view.devicePixelRatio / devicePixelRatio;
    return <ui.DisplayFeature>[
      for (final ui.DisplayFeature displayFeature in displayFeatures)
        ui.DisplayFeature(
          bounds: ui.Rect.fromLTRB(
            displayFeature.bounds.left * scale,
            displayFeature.bounds.top * scale,
            displayFeature.bounds.right * scale,
            displayFeature.bounds.bottom * scale,
          ),
          type: displayFeature.type,
          state: displayFeature.state,
        ),
    ];
  }

  // Everything below carries no overridable view metric and is forwarded.

  @override
  ui.Display get display => _view.display;

  /// The corner radii the platform reports, in physical pixels.
  ///
  /// Unlike [displayFeatures] these are physical, so an overridden device pixel
  /// ratio converts them at the point they are read, and nothing is needed
  /// here.
  @override
  ui.DisplayCornerRadii? get displayCornerRadii => _view.displayCornerRadii;

  @override
  ui.GestureSettings get gestureSettings => _view.gestureSettings;

  @override
  int get viewId => _view.viewId;

  // An omitted size means "this view's physical size", which for this view is
  // the overridden one. Left to the view underneath, the omission would resolve
  // to the size the platform reports, so a scene would be rendered at a size
  // this view says it does not have.
  //
  // Only an override supplies one, rather than [physicalSize] resolving it,
  // because an omitted size is not everywhere the same request as the size it
  // would resolve to: the web engine takes a size it is given as a resize, and
  // writes it to the DOM. Passing the size the platform already reports would
  // turn every such render into a reflow, which is not what this wrapper is
  // allowed to cost while nothing is overridden.
  @override
  void render(ui.Scene scene, {ui.Size? size}) =>
      _view.render(scene, size: size ?? _override?.physicalSize);

  @override
  void updateSemantics(ui.SemanticsUpdate update) => _view.updateSemantics(update);

  @override
  String toString() => 'DebugViewMetricsFlutterView(id: $viewId)';
}

/// The [ui.AccessibilityFeatures] of [_features], with the flags that
/// [_override] specifies replaced.
@immutable
class _DebugAccessibilityFeatures implements ui.AccessibilityFeatures {
  const _DebugAccessibilityFeatures(this._features, this._override);

  final ui.AccessibilityFeatures _features;
  final DebugViewMetricsOverride _override;

  @override
  bool get accessibleNavigation => _override.accessibleNavigation ?? _features.accessibleNavigation;

  @override
  bool get autoPlayAnimatedImages =>
      _override.autoPlayAnimatedImages ?? _features.autoPlayAnimatedImages;

  @override
  bool get autoPlayVideos => _override.autoPlayVideos ?? _features.autoPlayVideos;

  @override
  bool get boldText => _override.boldText ?? _features.boldText;

  @override
  bool get deterministicCursor => _override.deterministicCursor ?? _features.deterministicCursor;

  @override
  bool get disableAnimations => _override.disableAnimations ?? _features.disableAnimations;

  @override
  bool get highContrast => _override.highContrast ?? _features.highContrast;

  @override
  bool get invertColors => _override.invertColors ?? _features.invertColors;

  @override
  bool get onOffSwitchLabels => _override.onOffSwitchLabels ?? _features.onOffSwitchLabels;

  @override
  bool get reduceMotion => _override.reduceMotion ?? _features.reduceMotion;

  @override
  bool get supportsAnnounce => _override.supportsAnnounce ?? _features.supportsAnnounce;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    // ui.AccessibilityFeatures compares runtimeType before reaching for its
    // private bitfield, so it never sees this class as equal to itself; this
    // only has to handle other instances of this class.
    return other is _DebugAccessibilityFeatures &&
        other.accessibleNavigation == accessibleNavigation &&
        other.autoPlayAnimatedImages == autoPlayAnimatedImages &&
        other.autoPlayVideos == autoPlayVideos &&
        other.boldText == boldText &&
        other.deterministicCursor == deterministicCursor &&
        other.disableAnimations == disableAnimations &&
        other.highContrast == highContrast &&
        other.invertColors == invertColors &&
        other.onOffSwitchLabels == onOffSwitchLabels &&
        other.reduceMotion == reduceMotion &&
        other.supportsAnnounce == supportsAnnounce;
  }

  @override
  int get hashCode => Object.hash(
    accessibleNavigation,
    autoPlayAnimatedImages,
    autoPlayVideos,
    boldText,
    deterministicCursor,
    disableAnimations,
    highContrast,
    invertColors,
    onOffSwitchLabels,
    reduceMotion,
    supportsAnnounce,
  );

  @override
  String toString() {
    final features = <String>[
      if (accessibleNavigation) 'accessibleNavigation',
      if (invertColors) 'invertColors',
      if (disableAnimations) 'disableAnimations',
      if (boldText) 'boldText',
      if (reduceMotion) 'reduceMotion',
      if (highContrast) 'highContrast',
      if (onOffSwitchLabels) 'onOffSwitchLabels',
      if (supportsAnnounce) 'supportsAnnounce',
      if (autoPlayAnimatedImages) 'autoPlayAnimatedImages',
      if (autoPlayVideos) 'autoPlayVideos',
      if (deterministicCursor) 'deterministicCursor',
    ];
    return 'AccessibilityFeatures$features';
  }
}
