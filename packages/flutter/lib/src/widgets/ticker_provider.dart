// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'framework.dart';

export 'package:flutter/scheduler.dart' show TickerProvider;

/// Enables or disables tickers (and thus animation controllers) in the widget
/// subtree.
///
/// This only works if [AnimationController] objects are created using
/// widget-aware ticker providers. For example, using a
/// [TickerProviderStateMixin] or a [SingleTickerProviderStateMixin].
class TickerMode extends StatelessWidget {
  /// Creates a widget that enables or disables tickers.
  ///
  /// The [enabled] argument must not be null.
  const TickerMode({
    Key? key,
    required this.enabled,
    required this.child,
  }) : assert(enabled != null),
       super(key: key);

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
  /// bool tickingEnabled = TickerMode.of(context);
  /// ```
  static bool of(BuildContext context) {
    final _EffectiveTickerMode? widget = context.dependOnInheritedWidgetOfExactType<_EffectiveTickerMode>();
    return widget?.enabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return _EffectiveTickerMode(
      enabled: enabled && TickerMode.of(context),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('requested mode', value: enabled, ifTrue: 'enabled', ifFalse: 'disabled', showName: true));
  }
}

class _EffectiveTickerMode extends InheritedWidget {
  const _EffectiveTickerMode({
    Key? key,
    required this.enabled,
    required Widget child,
  }) : assert(enabled != null),
        super(key: key, child: child);

  final bool enabled;

  @override
  bool updateShouldNotify(_EffectiveTickerMode oldWidget) => enabled != oldWidget.enabled;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('effective mode', value: enabled, ifTrue: 'enabled', ifFalse: 'disabled', showName: true));
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
mixin SingleTickerProviderStateMixin<T extends StatefulWidget> on State<T> implements TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null)
        return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.'),
        ErrorDescription('A SingleTickerProviderStateMixin can only be used as a TickerProvider once.'),
        ErrorHint(
          'If a State is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.',
        ),
      ]);
    }());
    _ticker = Ticker(onTick, debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null);
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.of(context) would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    return _ticker!;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive)
        return true;
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
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_ticker != null)
      _ticker!.muted = !TickerMode.of(context);
    super.didChangeDependencies();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    String? tickerDescription;
    if (_ticker != null) {
      if (_ticker!.isActive && _ticker!.muted)
        tickerDescription = 'active but muted';
      else if (_ticker!.isActive)
        tickerDescription = 'active';
      else if (_ticker!.muted)
        tickerDescription = 'inactive and muted';
      else
        tickerDescription = 'inactive';
    }
    properties.add(DiagnosticsProperty<Ticker>('ticker', _ticker, description: tickerDescription, showSeparator: false, defaultValue: null));
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
@optionalTypeArgs
mixin TickerProviderStateMixin<T extends StatefulWidget> on State<T> implements TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_WidgetTicker>{};
    final _WidgetTicker result = _WidgetTicker(onTick, this, debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null);
    _tickers!.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers!.contains(ticker));
    _tickers!.remove(ticker);
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
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    final bool muted = !TickerMode.of(context);
    if (_tickers != null) {
      for (final Ticker ticker in _tickers!) {
        ticker.muted = muted;
      }
    }
    super.didChangeDependencies();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Set<Ticker>>(
      'tickers',
      _tickers,
      description: _tickers != null ?
        'tracking ${_tickers!.length} ticker${_tickers!.length == 1 ? "" : "s"}' :
        null,
      defaultValue: null,
    ));
  }
}

// This class should really be called _DisposingTicker or some such, but this
// class name leaks into stack traces and error messages and that name would be
// confusing. Instead we use the less precise but more anodyne "_WidgetTicker",
// which attracts less attention.
class _WidgetTicker extends Ticker {
  _WidgetTicker(TickerCallback onTick, this._creator, { String? debugLabel }) : super(onTick, debugLabel: debugLabel);

  final TickerProviderStateMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}
