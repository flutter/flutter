part of 'core.dart';

/// A [FortuneWidget] visualizes (random) selection processes by iterating over
/// a list of items before settling on a selected item.
///
/// See also:
///  * [FortuneWheel]
///  * [FortuneBar]
///  * [FortuneItem]
abstract class FortuneWidget implements Widget {
  /// The default value for [duration] (currently **5 seconds**).
  static const Duration kDefaultDuration = Duration(seconds: 5);

  /// The default value for [rotationCount] (currently **100**).
  static const int kDefaultRotationCount = 100;

  /// {@template flutter_fortune_wheel.FortuneWidget.items}
  /// A list of [FortuneItem]s to be shown within this [FortuneWidget].
  /// {@endtemplate}
  List<FortuneItem> get items;

  /// {@template flutter_fortune_wheel.FortuneWidget.selected}
  /// A stream notifying this widget that a new value within [items] was
  /// selected.Used by [FortuneWidget]s to align [indicators] on the selected
  /// item.
  /// {@endtemplate}
  Stream<int> get selected;

  /// {@template flutter_fortune_wheel.FortuneWidget.rotationCount}
  /// The number of times a [FortuneWidget] rotates around all
  /// [items] before it settles on the [selected] value.
  /// {@endtemplate}
  int get rotationCount;

  /// {@template flutter_fortune_wheel.FortuneWidget.duration}
  /// The animation duration used for [FortuneCurve.spin]
  /// within [FortuneWidget] instances.
  /// {@endtemplate}
  Duration get duration;

  /// {@template flutter_fortune_wheel.FortuneWidget.animationType}
  /// The type of curve to use for easing the animation when [selected] changes.
  ///
  /// See also:
  ///  * [FortuneCurve], which defines commonly used curves
  /// {@endtemplate}
  Curve get curve;

  /// {@template flutter_fortune_wheel.FortuneWidget.onAnimationStart}
  /// Called when this widget starts an animation.
  /// Useful for disabling other widgets during the animation.
  /// {@endtemplate}
  VoidCallback? get onAnimationStart;

  /// {@template flutter_fortune_wheel.FortuneWidget.onAnimationEnd}
  /// Called when this widget's animation ends.
  /// Useful for enabling other widgets after the animation ends.
  /// {@endtemplate}
  VoidCallback? get onAnimationEnd;

  /// {@template flutter_fortune_wheel.FortuneWidget.indicators}
  /// The list of [indicators] is rendered on top of the underlying
  /// [FortuneWidget]. These can be used to visualize the position of the
  /// [selected] item.
  /// {@endtemplate}
  List<FortuneIndicator> get indicators;

  /// {@template flutter_fortune_wheel.FortuneWidget.styleStrategy}
  /// The strategy to use for styling individual [items] when they have no
  /// dedicated [FortuneItem.style].
  /// {@endtemplate}
  StyleStrategy get styleStrategy;

  /// {@template flutter_fortune_wheel.FortuneWidget.animateFirst}
  /// Determines if this widget animates during its first build.
  ///
  /// The [onAnimationStart] and [onAnimationEnd] callbacks will not be called
  /// during the first build and no animation occurs, if this is set to false.
  ///
  /// Defaults to true.
  /// {@endtemplate}
  bool get animateFirst;

  /// {@template flutter_fortune_wheel.FortuneWidget.physics}
  /// The behavior used for handling pan events on this widget.
  ///
  /// See also:
  ///  * [PanPhysics] as the base class for implementing custom behavior
  ///  * [NoPanPhysics], which disables panning
  ///  * [DirectionalPanPhysics], which handles one directional panning
  ///  * [CircularPanPhysics], which handles panning on circular shapes
  /// {@endtemplate}
  PanPhysics get physics;

  /// {@template flutter_fortune_wheel.FortuneWidget.onFling}
  /// Called when a fling gesture is detected by the active [physics].
  /// {@endtemplate}
  VoidCallback? get onFling;
}
