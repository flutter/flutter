// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/animation.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/scheduler.dart' show TickerProvider;

// Examples can assume:
// late BuildContext context;

/// Enables or disables tickers (and thus animation controllers) in the widget
/// subtree.
///
/// This only works if [AnimationController] objects are created using
/// widget-aware ticker providers. For example, using a
/// [TickerProviderStateMixin] or a [SingleTickerProviderStateMixin].
class TickerMode extends StatefulWidget {
  /// Creates a widget that enables or disables tickers and optionally forces frames.
  const TickerMode({
    super.key,
    required this.enabled,
    required this.child,
    this.forceFrames = false,
  });

  /// The requested ticker mode for this subtree.
  ///
  /// The effective ticker mode of this subtree may differ from this value
  /// if there is an ancestor [TickerMode] with this field set to false.
  ///
  /// If true and all ancestor [TickerMode]s are also enabled, then tickers in
  /// this subtree will tick.
  ///
  /// If false, then tickers in this subtree will not tick regardless of any
  /// ancestor [TickerMode]s. Animations driven by such tickers are not paused,
  /// they just don't call their callbacks. Time still elapses.
  final bool enabled;

  /// If true, tickers in this subtree will force frames even if
  /// frames would normally not be scheduled (e.g. even if the
  /// device's screen is turned off).
  ///
  /// Use sparingly as this will cause significantly higher battery
  /// usage when the device should be idle.
  final bool forceFrames;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Whether tickers in the given subtree should be enabled or disabled.
  ///
  /// This is used automatically by [TickerProviderStateMixin] and
  /// [SingleTickerProviderStateMixin] to decide if their tickers should be
  /// enabled or disabled.
  ///
  /// In the absence of a [TickerMode] widget, this function defaults to true.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// // ignore: deprecated_member_use
  /// bool tickingEnabled = TickerMode.of(context);
  /// ```
  @Deprecated(
    'Use TickerMode.valuesOf to get both enabled and forceFrames. '
    'This feature was deprecated after v3.35.0-0.0.pre.',
  )
  static bool of(BuildContext context) {
    final _EffectiveTickerMode? widget = context
        .dependOnInheritedWidgetOfExactType<_EffectiveTickerMode>();
    return widget?.enabled ?? true;
  }

  /// Obtains a [ValueListenable] from the [TickerMode] surrounding the `context`,
  /// which indicates whether tickers are enabled in the given subtree.
  ///
  /// When that [TickerMode] enables or disables tickers, the listenable notifies
  /// its listeners.
  ///
  /// While the [ValueListenable] is stable for the lifetime of the surrounding
  /// [TickerMode], calling this method does not establish a dependency between
  /// the `context` and the [TickerMode] and the widget owning the `context`
  /// does not rebuild when the ticker mode changes from true to false or vice
  /// versa. This is preferable when the ticker mode does not impact what is
  /// currently rendered on screen, e.g. because it is only used to mute/unmute a
  /// [Ticker]. Since no dependency is established, the widget owning the
  /// `context` is also not informed when it is moved to a new location in the
  /// tree where it may have a different [TickerMode] ancestor. When this
  /// happens, the widget must manually unsubscribe from the old listenable,
  /// obtain a new one from the new ancestor [TickerMode] by calling this method
  /// again, and re-subscribe to it. [StatefulWidget]s can, for example, do this
  /// in [State.activate], which is called after the widget has been moved to
  /// a new location.
  ///
  /// Alternatively, [of] can be used instead of this method to create a
  /// dependency between the provided `context` and the ancestor [TickerMode].
  /// In this case, the widget automatically rebuilds when the ticker mode
  /// changes or when it is moved to a new [TickerMode] ancestor, which
  /// simplifies the management cost in the widget at the expense of some
  /// potential unnecessary rebuilds.
  ///
  /// In the absence of a [TickerMode] widget, this function returns a
  /// [ValueListenable], whose [ValueListenable.value] is always true.
  @Deprecated(
    'Use TickerMode.getValuesNotifier to get both enabled and forceFrames. '
    'This feature was deprecated after v3.35.0-0.0.pre.',
  )
  static ValueListenable<bool> getNotifier(BuildContext context) {
    final _EffectiveTickerMode? widget = context
        .getInheritedWidgetOfExactType<_EffectiveTickerMode>();
    return widget?.notifier ?? const _ConstantValueListenable<bool>(true);
  }

  /// Returns the requested ticker mode values for this subtree and establishes
  /// a dependency on the ancestor [TickerMode], if any.
  ///
  /// This is used automatically by [TickerProviderStateMixin] and
  /// [SingleTickerProviderStateMixin] to decide if their tickers should be
  /// enabled or disabled.
  ///
  /// In the absence of a [TickerMode] widget, this defaults to enabled
  /// tickers that don't force frames.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// bool tickingEnabled = TickerMode.valuesOf(context).enabled;
  /// ```
  static TickerModeData valuesOf(BuildContext context) {
    final _EffectiveTickerMode? widget = context
        .dependOnInheritedWidgetOfExactType<_EffectiveTickerMode>();
    return widget?.values ?? TickerModeData.fallback;
  }

  /// Obtains a [ValueListenable] from the [TickerMode] surrounding the `context`,
  /// which indicates whether tickers are enabled in the given subtree.
  ///
  /// When that [TickerMode] enabled or disabled tickers, the listenable notifies
  /// its listeners.
  ///
  /// While the [ValueListenable] is stable for the lifetime of the surrounding
  /// [TickerMode], calling this method does not establish a dependency between
  /// the `context` and the [TickerMode] and the widget owning the `context`
  /// does not rebuild when the ticker mode data changes. This is preferable
  /// when the ticker mode does not impact what is currently rendered on screen,
  /// e.g. because it is only used to mute/unmute a [Ticker]. Since no dependency
  /// is established, the widget owning the `context` is also not informed when
  /// it is moved to a new location in the tree where it may have a different
  /// [TickerMode] ancestor. When this happens, the widget must manually
  /// unsubscribe from the old listenable, obtain a new one from the new ancestor
  /// [TickerMode] by calling this method again, and re-subscribe to it.
  /// [StatefulWidget]s can, for example, do this in [State.activate],
  /// which is called after the widget has been moved to a new location.
  ///
  /// Alternatively, [of] can be used instead of this method to create a
  /// dependency between the provided `context` and the ancestor [TickerMode].
  /// In this case, the widget automatically rebuilds when the ticker mode
  /// changes or when it is moved to a new [TickerMode] ancestor, which
  /// simplifies the management cost in the widget at the expensive of some
  /// potential unnecessary rebuilds.
  ///
  /// In the absence of a [TickerMode] widget, this function returns a
  /// [ValueListenable], whose [ValueListenable.value] is
  /// [TickerModeData.fallback].
  static ValueListenable<TickerModeData> getValuesNotifier(BuildContext context) {
    final _EffectiveTickerMode? widget = context
        .getInheritedWidgetOfExactType<_EffectiveTickerMode>();
    return widget?.valuesNotifier ??
        const _ConstantTickerModeDataListenable(TickerModeData.fallback);
  }

  /// Creates a [TickerMode] that overrides the ambient ticker mode values.
  ///
  /// The given `enabled` and `forceFrames` override the ambient values when not null;
  /// otherwise the ambient values are preserved.
  static Widget merge({Key? key, bool? enabled, bool? forceFrames, required Widget child}) {
    return Builder(
      builder: (BuildContext context) {
        final _EffectiveTickerMode? parent = context
            .dependOnInheritedWidgetOfExactType<_EffectiveTickerMode>();
        final bool parentEnabled = parent?.enabled ?? TickerModeData.fallback.enabled;
        final bool parentForce = parent?.forceFrames ?? TickerModeData.fallback.forceFrames;
        return TickerMode(
          key: key,
          enabled: enabled ?? parentEnabled,
          forceFrames: forceFrames ?? parentForce,
          child: child,
        );
      },
    );
  }

  @override
  State<TickerMode> createState() => _TickerModeState();
}

class _TickerModeState extends State<TickerMode> {
  bool _ancestorTickerMode = TickerModeData.fallback.enabled;
  bool _ancestorForceFrames = TickerModeData.fallback.forceFrames;
  final ValueNotifier<bool> _effectiveMode = ValueNotifier<bool>(TickerModeData.fallback.enabled);
  final ValueNotifier<TickerModeData> _effectiveValues = ValueNotifier<TickerModeData>(
    TickerModeData.fallback,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _EffectiveTickerMode? parent = context
        .dependOnInheritedWidgetOfExactType<_EffectiveTickerMode>();
    _ancestorTickerMode = parent?.enabled ?? TickerModeData.fallback.enabled;
    _ancestorForceFrames = parent?.forceFrames ?? TickerModeData.fallback.forceFrames;
    _updateEffectiveMode();
  }

  @override
  void didUpdateWidget(TickerMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateEffectiveMode();
  }

  @override
  void dispose() {
    _effectiveMode.dispose();
    _effectiveValues.dispose();
    super.dispose();
  }

  void _updateEffectiveMode() {
    final bool enabled = _ancestorTickerMode && widget.enabled;
    final bool force = _ancestorForceFrames || widget.forceFrames;
    _effectiveMode.value = enabled;
    _effectiveValues.value = TickerModeData(enabled: enabled, forceFrames: force);
  }

  @override
  Widget build(BuildContext context) {
    return _EffectiveTickerMode(
      enabled: _effectiveMode.value,
      forceFrames: _effectiveValues.value.forceFrames,
      notifier: _effectiveMode,
      valuesNotifier: _effectiveValues,
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty(
        'requested mode',
        value: widget.enabled,
        ifTrue: 'enabled',
        ifFalse: 'disabled',
        showName: true,
      ),
    );
  }
}

class _EffectiveTickerMode extends InheritedWidget {
  const _EffectiveTickerMode({
    required this.enabled,
    required this.forceFrames,
    required this.notifier,
    required this.valuesNotifier,
    required super.child,
  });

  final bool enabled;
  final bool forceFrames;
  final ValueNotifier<bool> notifier;
  final ValueNotifier<TickerModeData> valuesNotifier;

  TickerModeData get values => valuesNotifier.value;

  @override
  bool updateShouldNotify(_EffectiveTickerMode oldWidget) =>
      enabled != oldWidget.enabled || forceFrames != oldWidget.forceFrames;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty(
        'effective mode',
        value: enabled,
        ifTrue: 'enabled',
        ifFalse: 'disabled',
        showName: true,
      ),
    );
  }
}

/// Provides a single [Ticker] that is configured to only tick while the current
/// tree is enabled, as defined by [TickerMode].
///
/// To create the [AnimationController] in a [State] that only uses a single
/// [AnimationController], mix in this class, then pass `vsync: this`
/// to the animation controller constructor.
///
/// This mixin only supports vending a single ticker. If you might have multiple
/// [AnimationController] objects over the lifetime of the [State], use a full
/// [TickerProviderStateMixin] instead.
@optionalTypeArgs
mixin SingleTickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          '$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.',
        ),
        ErrorDescription(
          'A SingleTickerProviderStateMixin can only be used as a TickerProvider once.',
        ),
        ErrorHint(
          'If a State is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.',
        ),
      ]);
    }());
    _ticker = Ticker(
      onTick,
      debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
    );
    _updateTickerModeNotifier();
    _updateTicker(); // Sets _ticker.mute correctly.
    return _ticker!;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription(
          '$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
          'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
          'be disposed before calling super.dispose().',
        ),
        ErrorHint(
          'Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.',
        ),
        _ticker!.describeForError('The offending ticker was'),
      ]);
    }());
    _tickerModeNotifier?.removeListener(_updateTicker);
    _tickerModeNotifier = null;
    super.dispose();
  }

  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @override
  void activate() {
    super.activate();
    // We may have a new TickerMode ancestor.
    _updateTickerModeNotifier();
    _updateTicker();
  }

  void _updateTicker() {
    final TickerModeData values = _tickerModeNotifier!.value;
    if (_ticker != null) {
      _ticker!.muted = !values.enabled;
      _ticker!.forceFrames = values.forceFrames;
    }
  }

  void _updateTickerModeNotifier() {
    final ValueListenable<TickerModeData> newNotifier = TickerMode.getValuesNotifier(context);
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTicker);
    newNotifier.addListener(_updateTicker);
    _tickerModeNotifier = newNotifier;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final String? tickerDescription = switch ((_ticker?.isActive, _ticker?.muted)) {
      (true, true) => 'active but muted',
      (true, _) => 'active',
      (false, true) => 'inactive and muted',
      (false, _) => 'inactive',
      (null, _) => null,
    };
    properties.add(
      DiagnosticsProperty<Ticker>(
        'ticker',
        _ticker,
        description: tickerDescription,
        showSeparator: false,
        defaultValue: null,
      ),
    );
  }
}

/// Provides [Ticker] objects that are configured to only tick while the current
/// tree is enabled, as defined by [TickerMode].
///
/// To create an [AnimationController] in a class that uses this mixin, pass
/// `vsync: this` to the animation controller constructor whenever you
/// create a new animation controller.
///
/// If you only have a single [Ticker] (for example only a single
/// [AnimationController]) for the lifetime of your [State], then using a
/// [SingleTickerProviderStateMixin] is more efficient. This is the common case.
///
/// When creating multiple [AnimationController]s, using a single state with
/// [TickerProviderStateMixin] as vsync for all [AnimationController]s is more
/// efficient than creating multiple states with
/// [SingleTickerProviderStateMixin].
@optionalTypeArgs
mixin TickerProviderStateMixin<T extends StatefulWidget> on State<T> implements TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    if (_tickerModeNotifier == null) {
      // Setup TickerMode notifier before we vend the first ticker.
      _updateTickerModeNotifier();
    }
    assert(_tickerModeNotifier != null);
    _tickers ??= <_WidgetTicker>{};
    final TickerModeData values = _tickerModeNotifier!.value;
    final result =
        _WidgetTicker(
            onTick,
            this,
            debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
          )
          ..muted = !values.enabled
          ..forceFrames = values.forceFrames;
    _tickers!.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers!.contains(ticker));
    _tickers!.remove(ticker);
  }

  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @override
  void activate() {
    super.activate();
    // We may have a new TickerMode ancestor, get its Notifier.
    _updateTickerModeNotifier();
    _updateTickers();
  }

  void _updateTickers() {
    if (_tickers != null) {
      final TickerModeData values = _tickerModeNotifier!.value;
      final bool muted = !values.enabled;
      for (final Ticker ticker in _tickers!) {
        ticker.muted = muted;
        ticker.forceFrames = values.forceFrames;
      }
    }
  }

  void _updateTickerModeNotifier() {
    final ValueListenable<TickerModeData> newNotifier = TickerMode.getValuesNotifier(context);
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTickers);
    newNotifier.addListener(_updateTickers);
    _tickerModeNotifier = newNotifier;
  }

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (final Ticker ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription(
                '$runtimeType created a Ticker via its TickerProviderStateMixin, but at the time '
                'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                'be disposed before calling super.dispose().',
              ),
              ErrorHint(
                'Tickers used by AnimationControllers '
                'should be disposed by calling dispose() on the AnimationController itself. '
                'Otherwise, the ticker will leak.',
              ),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());
    _tickerModeNotifier?.removeListener(_updateTickers);
    _tickerModeNotifier = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Set<Ticker>>(
        'tickers',
        _tickers,
        description: _tickers != null
            ? 'tracking ${_tickers!.length} ticker${_tickers!.length == 1 ? "" : "s"}'
            : null,
        defaultValue: null,
      ),
    );
  }
}

// This class should really be called _DisposingTicker or some such, but this
// class name leaks into stack traces and error messages and that name would be
// confusing. Instead we use the less precise but more anodyne "_WidgetTicker",
// which attracts less attention.
class _WidgetTicker extends Ticker {
  _WidgetTicker(super.onTick, this._creator, {super.debugLabel});

  final TickerProviderStateMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}

class _ConstantValueListenable<T> implements ValueListenable<T> {
  const _ConstantValueListenable(this.value);

  @override
  void addListener(VoidCallback listener) {
    // Intentionally left empty: Value cannot change, so we never have to
    // notify registered listeners.
  }

  @override
  void removeListener(VoidCallback listener) {
    // Intentionally left empty: Value cannot change, so we never have to
    // notify registered listeners.
  }

  @override
  final T value;
}

/// Immutable compound values that describe the effective ticker behavior
/// for a subtree.
///
/// Instances of this class are produced by [TickerMode.valuesOf] and
/// [TickerMode.getValuesNotifier] and reflect the values that apply at a given
/// location in the widget tree after taking ancestor [TickerMode] widgets into
/// account.
///
/// Semantics of the fields:
/// - [enabled]: A ticker is considered enabled only if all ancestor
///   [TickerMode.enabled] values and the local [TickerMode.enabled] are true
///   (logical AND). When false, tickers are muted (time still elapses but
///   callbacks are not invoked).
/// - [forceFrames]: When true, tickers in the subtree request frames using
///   [SchedulerBinding.scheduleForcedFrame] while active. This value is
///   combined across ancestors using logical OR, so any ancestor requesting
///   forced frames enables it for the subtree.
///
/// For most widgets, reading these values is unnecessary; mixins such as
/// [SingleTickerProviderStateMixin] and [TickerProviderStateMixin] apply them
/// automatically to the [Ticker]s they vend. Use this class when you need to
/// observe or react to ticker policy explicitly.
@immutable
class TickerModeData {
  /// Creates a [TickerModeData].
  const TickerModeData({required this.enabled, required this.forceFrames});

  /// Fallback values used when there is no ancestor [TickerMode].
  ///
  /// This corresponds to tickers being enabled and not forcing frames.
  static const TickerModeData fallback = TickerModeData(enabled: true, forceFrames: false);

  /// Whether tickers are enabled (not muted) for the subtree.
  ///
  /// Effective value is the logical AND of all ancestor and local
  /// [TickerMode.enabled] values.
  final bool enabled;

  /// Whether tickers should request forced frames while active.
  ///
  /// Effective value is the logical OR of all ancestor and local
  /// [TickerMode.forceFrames] values. Forcing frames may increase battery
  /// usage, so use sparingly.
  final bool forceFrames;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TickerModeData && other.enabled == enabled && other.forceFrames == forceFrames;
  }

  @override
  int get hashCode => Object.hash(enabled, forceFrames);
}

class _ConstantTickerModeDataListenable implements ValueListenable<TickerModeData> {
  const _ConstantTickerModeDataListenable(this.value);

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  final TickerModeData value;
}
