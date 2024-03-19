import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';

/// A builder function used by the [ToggleValue] widget that takes the current
/// value and returns a widget.
typedef ToggleValueBuilder<T> = Widget Function(BuildContext context, T value);

/// A widget that toggles between values.
///
/// This widget is used to toggle the state of a widget created by the builder.
///
/// If not given a [changeNotifier], will start at the [offValue] (or the
/// [initialValue], if given) and toggle to the [onValue] on the frame after the
/// widget is first built. It will only toggle once.
///
/// If given a [changeNotifier], will also alternate between [offValue] and
/// [onValue] whenever the [changeNotifier] notifies of a change.
///
/// Like all stateful widgets in Flutter, if this widget is recreated, it will
/// lose the toggle state. To prevent this, give it a [Key] to allow it to be
/// reused instead of recreated.
///
/// The [ToggleValue] widget can be used to avoid the need for creating a
/// stateful widget just to trigger a change in another widget on creation.
///
/// {@tool dartpad}
/// This example shows how to use the [ToggleValue] widget to
/// trigger a fade-in animation when a widget is shown for the first time.
///
/// ** See example in examples/api/widgets/toggle_value/toggle_value.0.dart **
/// {@end-tool}
class ToggleValue<T> extends StatefulWidget {
  /// Creates a [ToggleValue] widget.
  ///
  /// The [builder], [offValue], and [onValue] parameters are required.
  const ToggleValue({
    super.key,
    required this.builder,
    T? initialValue,
    required this.offValue,
    required this.onValue,
    this.changeNotifier,
  }) : initialValue = initialValue ?? offValue;

  // The builder function, which takes the current value and returns a widget.
  ///
  /// Required.
  final ToggleValueBuilder<T> builder;

  /// The optional value to use when the widget is first created.
  ///
  /// Defaults to [offValue].
  final T? initialValue;

  /// The value to use when the widget is in the "off" state.
  ///
  /// If [initialValue] is not specified, it defaults to this value.
  ///
  /// Required.
  final T offValue;

  /// The value to use when the widget is in the "on" state.
  ///
  /// Required.
  final T onValue;

  /// The optional [ChangeNotifier] to listen to.
  ///
  /// If specified, the widget will toggle between [offValue] and [onValue]
  /// whenever the [ChangeNotifier] notifies of a change.
  final ChangeNotifier? changeNotifier;

  @override
  State<ToggleValue<T>> createState() => _ToggleValueState<T>();
}

enum _ToggleValueStatus {
  initial,
  off,
  on,
}

class _ToggleValueState<T> extends State<ToggleValue<T>> {
  _ToggleValueStatus triggered = _ToggleValueStatus.initial;

  void _trigger() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        triggered = switch (triggered) {
          _ToggleValueStatus.off => _ToggleValueStatus.on,
          _ToggleValueStatus.on => _ToggleValueStatus.off,
          _ToggleValueStatus.initial => _ToggleValueStatus.on,
        };
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _trigger();
    widget.changeNotifier?.addListener(_trigger);
  }

  @override
  void dispose() {
    widget.changeNotifier?.removeListener(_trigger);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ToggleValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changeNotifier != widget.changeNotifier) {
      oldWidget.changeNotifier?.removeListener(_trigger);
      widget.changeNotifier?.addListener(_trigger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return widget.builder(
          context,
          switch (triggered) {
            _ToggleValueStatus.off => widget.offValue,
            _ToggleValueStatus.on => widget.onValue,
            _ToggleValueStatus.initial => widget.initialValue,
          } as T,
        );
      },
    );
  }
}
