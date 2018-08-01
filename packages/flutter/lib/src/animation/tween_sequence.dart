import 'package:flutter/foundation.dart';

import 'animation.dart';
import 'curves.dart';
import 'tween.dart';

/// Enables creating an [Animation] whose value is defined by a
/// sequence of [Tween]s.
///
/// Each [TweenSequenceItem] has a weight that defines its percentage
/// of the animation's duration, and an optional curve that's applied
/// to the item's tween. Each tween defines the animation's value
/// during the interval indicated by its weight.
///
/// For example, to define an animation that uses an easing curve to
/// interpolate between 5.0 and 10.0 during the first 40% of the
/// animation, remain at 10.0 for the next 20%, and then return to
/// 10.0 for the final 40%:
///
/// ```
/// final Animation<double> = new TweenSequence(
///   <TweenSequenceItem<double>>[
///     new TweenSequenceItem<double>(
///       tween: new Tween<double>(begin: 5.0, end: 10.0),
///       curve: Curves.ease
///       weight: 40.0,
///     ),
///     new TweenSequenceItem<double>(
///       tween: new ConstantTween<double>(10.0),
///       weight: 20.0,
///     ),
///     new TweenSequenceItem<double>(
///       tween: new Tween<double>(begin: 10.0, end: 5.0),
///       curve: Curves.ease,
///       weight: 40.0,
///     ),
///   ],
/// ).animate(myAnimationController);
///```
class TweenSequence<T> extends Animatable<T> {
  /// Construct a TweenSequence.
  ///
  /// The [items] parameter must be a list of one or more
  /// [TweenSequenceItem]s.
  TweenSequence(List<TweenSequenceItem<T>> items) : assert(items != null && items.isNotEmpty) {
    _items.addAll(items);

    double totalWeight = 0.0;
    for (TweenSequenceItem<T> item in _items)
      totalWeight += item.weight;

    double start = 0.0;
    for (int i = 0; i < _items.length; i++) {
      final double end = start + _items[i].weight / totalWeight;
      _intervals.add(new _Interval(start, end));
      start = end;
    }
  }

  final List<TweenSequenceItem<T>> _items = <TweenSequenceItem<T>>[];
  final List<_Interval> _intervals = <_Interval>[];

  T _evaluateAt(double t, int index) {
    final TweenSequenceItem<T> element = _items[index];
    final double tInterval = _intervals[index].value(t);
    final double tCurve =  element.curve == null ? tInterval : element.curve.transform(tInterval);
    return element.tween.lerp(tCurve);
  }

  @override
  T evaluate(Animation<double> animation) {
    final double t = animation.value;
    assert(t >= 0.0 && t <= 1.0);
    if (t == 1.0)
      return _evaluateAt(t, _items.length - 1);
    for (int index = 0; index < _items.length; index++) {
      if (_intervals[index].contains(t))
        return _evaluateAt(t, index);
    }
    // Should be unreachable.
    throw new FlutterError('TweenSequence.evaluate() could not find a interval for $t');
  }
}

/// A simple holder for one element of a [TweenSequence].
class TweenSequenceItem<T> {
  /// Construct a TweenSequenceItem.
  ///
  /// The [tween] must not be null and [weight] must be greater than 0.0.
  const TweenSequenceItem({
    @required this.tween,
    @required this.weight,
    this.curve
  }) : assert(tween != null), assert(weight != null && weight > 0.0);

  /// Along with [curve], defines the value of the [TweenSequence] for
  /// the interval within the animation's duration indicated by [weight]
  /// and this item's position in the list of items.
  final Tween<T> tween;

  /// An abitrary value that indicates the relative percentage of a
  /// [TweenSequence] animation's duration when [tween] will be used.
  ///
  /// The percentage for an individual item is the item's weight divided
  /// by the sum of all of the items' weights.
  final double weight;

  /// If specified, [tween] is interpolated through a curve.
  ///
  /// In other words, instead of finding the tween's value with
  /// `tween.lerp(t)`, for 0.0 <= t <= 1.0, the tween's value is
  /// `tween.lerp(curve.transform(t))`.
  final Curve curve;
}

class _Interval {
  const _Interval(this.start, this.end) : assert(end > start);

  final double start;
  final double end;

  bool contains(double t) => t >= start && t < end;

  double value(double t) => (t - start) / (end - start);

  @override
  String toString() => '<$start, $end>';
}
