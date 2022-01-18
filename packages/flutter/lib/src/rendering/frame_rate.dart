// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A desired frame rate.
///
/// This class can represent a few common specific frame rates, as well as three
/// special values:
///
///  * [fastest], meaning that the operating system should use the maximum rate
///    available from the hardware to get the smoothest display possible.
///
///  * [fps120], [fps90], [fps60], [fps48], [fps30], [fps25], [fps24], [fps15],
///    [fps12], [fps10], the specific frame rates.
///
///  * [slow], meaning that the operating system should prefer conserving battery
///    rather than smooth animations.
///
///  * [normal], meaning that no particular frame rate is desired but that the
///    operating system default is sufficient.
///
/// Each frame, the requested frame rate with the highest value is given to the
/// operating system.
///
/// The [normal] frame rate is considered to have the lowest value. Thus,
/// specifying [slow] will override a simultaneous request for [normal].
///
/// To specify a frame rate when using an [AnimationController], set
/// [AnimationController.frameRate]. When using a [ProgressIndicator], such as
/// [CircularProgressIndicator], consider using
/// [ProgressIndicator.reduceFrameRate] to specify that the frame rate should be
/// reduced. In other situations, consider calling
/// [RendererBinding.requestFrameRate] directly each tick of the animation.
@immutable
class FrameRate {
  const FrameRate._(this.frequency) : assert(frequency >= _kNormal), assert(frequency <= _kMax);

  /// The frame rate in frames per second (Hz).
  ///
  /// The value -1 is used to represent the default frame rate (FrameRate.normal).
  ///
  /// The value 0 is used to represent an operating-system-specific "slow" frame
  /// rate suitable for low-impact animations like progress bars or spinners.
  ///
  /// The value 2147483647 (2^31-1) is used to represent the maximum available
  /// frame rate of the device.
  final int frequency;

  static const int _kNormal = -1; // indicates a lack of preference
  static const int _kMin = 0; // indicates a desire for an OS-recommended slow frame rate
  static const int _kMax = 2147483647; // 2^31-1, an arbitrarily large number that won't cause issues in JS

  /// The normal frame rate of the device.
  ///
  /// This is typically 60 frames per second ([fps60]), but can vary based on
  /// the configuration of the device, power management needs, and so forth.
  ///
  /// See also:
  ///
  ///  * [fastest], to specify the smoothest possible frame rate.
  ///  * [slow], to specify that a fast frame rate is not necessary.
  static const FrameRate normal = FrameRate._(_kNormal);

  /// The fastest frame rate achievable by the device.
  ///
  /// This value is appropriate when maximizing the response rate is more
  /// important than conserving battery, e.g. when updating the display in
  /// response to the user scrolling a list.
  ///
  /// The precise frame rate varies based on the hardware and operating system
  /// configuration.
  ///
  /// See also:
  ///
  ///  * [slow], to specify that a fast frame rate is not necessary.
  static const FrameRate fastest = FrameRate._(_kMax);

  /// A slow frame rate suitable for low-impact animations.
  ///
  /// This value is appropriate when displaying just a progress bar or progress
  /// meter, e.g. a [CircularProgressIndicator].
  ///
  /// The precise frame rate varies based on the hardware and operating system
  /// configuration.
  ///
  /// See also:
  ///
  ///  * [fastest], to specify the smoothest possible frame rate.
  static const FrameRate slow = FrameRate._(_kMin);

  /// 120 frames per second.
  ///
  /// Consider using [fastest] instead of [fps120] if the precise frame rate is
  /// not as important as being as smooth as possible.
  static const FrameRate fps120 = FrameRate._(120);

  /// 90 frames per second.
  ///
  /// Consider using [fastest] instead of [fps90] if the precise frame rate is
  /// not as important as being as smooth as possible.
  static const FrameRate fps90 = FrameRate._(90);

  /// 60 frames per second.
  ///
  /// This frame rate is suitable for normal animations. It provides a balance
  /// between power management and animation quality. On many devices, this
  /// represents the fastest possible frame rate.
  ///
  /// Consider using [normal] instead of [fps60] if the precise frame rate is
  /// not as important as matching the platform's normal look and feel.
  static const FrameRate fps60 = FrameRate._(60);

  /// 48 frames per second.
  ///
  /// This frame rate is used in the film industry for a more "life-like" look
  /// than the more common 24 frames per second ([fps24]).
  static const FrameRate fps48 = FrameRate._(48);

  /// 30 frames per second.
  ///
  /// Consider using [slow] instead of [fps30] if the precise frame rate is
  /// not as important as saving battery life in general.
  static const FrameRate fps30 = FrameRate._(30);

  /// 25 frames per second.
  ///
  /// This frame rate is occasionally used for compatibility with legacy
  /// equipment (e.g. DVD players and televisions) in regions that use the PAL
  /// format (and a 50Hz AC power supply).
  static const FrameRate fps25 = FrameRate._(25);

  /// 24 frames per second.
  ///
  /// This is the frame rate typically used for motion pictures.
  static const FrameRate fps24 = FrameRate._(24);

  /// 15 frames per second.
  ///
  /// Consider using [slow] instead of [fps15] if the precise frame rate is
  /// not as important as saving battery life in general.
  static const FrameRate fps15 = FrameRate._(15);

  /// 12 frames per second.
  ///
  /// This is the frame rate usually used for hand-drawn animation ("shooting on
  /// twos").
  static const FrameRate fps12 = FrameRate._(12);

  /// 10 frames per second.
  ///
  /// Consider using [slow] instead of [fps10] if the precise frame rate is
  /// not as important as saving battery life in general.
  static const FrameRate fps10 = FrameRate._(10);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is FrameRate
        && other.frequency == frequency;
  }

  /// Whether this frame rate is lower than the `other` frame rate.
  ///
  /// The frame rates compare as follows:
  ///
  /// [normal] < [slow] < all the fpsXX rates < [fastest]
  bool operator <(FrameRate other) => frequency < other.frequency;

  /// Whether this frame rate is lower than, or equal to, the `other` frame
  /// rate.
  ///
  /// The frame rates compare as follows:
  ///
  /// [normal] < [slow] < all the fpsXX rates < [fastest]
  bool operator <=(FrameRate other) => frequency <= other.frequency;

  /// Whether this frame rate is higher than the `other` frame rate.
  ///
  /// The frame rates compare as follows:
  ///
  /// [fastest] > all the fpsXX rates > [slow] > [normal]
  bool operator >(FrameRate other) => frequency > other.frequency;

  /// Whether this frame rate is higher than, or equal to, the `other` frame
  /// rate.
  ///
  /// The frame rates compare as follows:
  ///
  /// [fastest] > all the fpsXX rates > [slow] > [normal]
  bool operator >=(FrameRate other) => frequency >= other.frequency;

  @override
  int get hashCode => frequency.hashCode;

  @override
  String toString() {
    if (frequency == _kNormal)
      return 'FrameRate.normal';
    if (frequency == _kMin)
      return 'FrameRate.slow';
    if (frequency == _kMax)
      return 'FrameRate.fastest';
    return 'FrameRate.fps$frequency';
  }
}
