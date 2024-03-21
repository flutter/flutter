import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';

/// A builder function used by the [ToggleValue] widget that takes the current
/// value and returns a widget.
typedef ToggleValueBuilder<T> = Widget Function(BuildContext context, T value);

/// A widget that toggles between values, using a builder to build with the new
/// value.
///
/// The [ToggleValue] widget can be used to avoid the need for creating a
/// stateful widget just to trigger a change in another widget on creation.
///
/// If not given a [valueNotifier], will start at the [initialValue] (or the
/// [initialValue], if given) and toggle to the [value] on the frame after the
/// widget is first built. It will only toggle once.
///
/// If given a [valueNotifier], will start at [initialValue] and
/// switch to the value of the [valueNotifier], and then continue to switch
/// to each new value as the [valueNotifier] changes.
///
/// Like all stateful widgets in Flutter, if this widget is recreated, it will
/// lose its current state. To prevent this, give it a [Key] to allow it to be
/// reused instead of recreated.
///
/// {@tool dartpad}
/// This example shows how to use the [ToggleValue] widget to trigger an
/// [AnimatedAlign] animation when a widget is shown for the first time. This is
/// done without needing to create a stateful widget.
///
/// ** See code in examples/api/lib/widgets/toggle_value/toggle_value.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to use the [ToggleValue] widget to trigger an
/// [AnimatedAlign] animation when a widget is shown for the first time, and
/// then change the value of the alignment and animate each time a button is
/// pressed. This is done without needing to create a stateful widget.
///
/// ** See code in examples/api/lib/widgets/toggle_value/toggle_value.1.dart **
/// {@end-tool}

class ToggleValue<T> extends StatefulWidget {
  /// Creates a [ToggleValue] widget.
  ///
  /// The [builder], [initialValue], and one of [value] or [valueNotifier] are
  /// required.
  const ToggleValue({
    super.key,
    required this.builder,
    required this.initialValue,
    this.value,
    this.valueNotifier,
  })  : assert(value != null || valueNotifier != null, 'One of value or valueNotifier must be set.'),
        assert(value == null || valueNotifier == null, 'Cannot set both value and valueNotifier.');

  /// A builder function which takes a [BuildContext], and the current [value]
  /// (or the value of the [valueNotifier]) and returns a widget.
  ///
  /// Required.
  final ToggleValueBuilder<T> builder;

  /// The value to pass to the [builder] when the widget is first built.
  ///
  /// Required.
  final T initialValue;

  /// The optional value to pass to the [builder] when the widget is built the
  /// second and subsequent times.
  ///
  /// Ignored if [valueNotifier] is set.
  ///
  /// If not specified, then the current value of [valueNotifier] is used. One
  /// of [value] or [valueNotifier] must be set.
  ///
  /// Only one of [valueNotifier] or [value] may be set at a time, but one of
  /// them must be set.
  final T? value;

  /// The optional [ValueNotifier] to listen to.
  ///
  /// If specified, instead toggling between [initialValue] and [value] only
  /// once, whenever the [ValueNotifier] notifies of a change, the widget will
  /// use the notifier's value as the next value to build the [builder] with.
  ///
  /// Only one of [valueNotifier] or [value] may be set at a time, but one of
  /// them must be set.
  final ValueNotifier<T>? valueNotifier;

  @override
  State<ToggleValue<T>> createState() => _ToggleValueState<T>();
}

enum _ToggleValueStatus {
  initial,
  off,
  on,
}

class _ToggleValueState<T> extends State<ToggleValue<T>> {
  _ToggleValueStatus _triggered = _ToggleValueStatus.initial;
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? widget.initialValue;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _value = widget.valueNotifier?.value ?? widget.value ?? _value;
        _triggered = switch (_triggered) {
          _ToggleValueStatus.off => _ToggleValueStatus.on,
          _ToggleValueStatus.on => _ToggleValueStatus.off,
          _ToggleValueStatus.initial => _ToggleValueStatus.on,
        };
      });
    });
    widget.valueNotifier?.addListener(_trigger);
  }

  @override
  void dispose() {
    widget.valueNotifier?.removeListener(_trigger);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ToggleValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueNotifier != widget.valueNotifier) {
      oldWidget.valueNotifier?.removeListener(_trigger);
      widget.valueNotifier?.addListener(_trigger);
      _value = widget.valueNotifier?.value ?? widget.value ?? _value;
    }
    if (oldWidget.value != widget.value) {
      final T? value = widget.value;
      if (value != null) {
        _value = value;
      }
    }
  }

  void _trigger() {
    setState(() {
      _value = widget.valueNotifier!.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      switch (_triggered) {
        _ToggleValueStatus.off => widget.value != null ? widget.initialValue : _value,
        _ToggleValueStatus.on => widget.value ?? _value,
        _ToggleValueStatus.initial => widget.initialValue,
      },
    );
  }
}
