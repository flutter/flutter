// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

/// [Level]s to control logging output. Logging can be enabled to include all
/// levels above certain [Level]. [Level]s are ordered using an integer
/// value [Level.value]. The predefined [Level] constants below are sorted as
/// follows (in descending order): [Level.SHOUT], [Level.SEVERE],
/// [Level.WARNING], [Level.INFO], [Level.CONFIG], [Level.FINE], [Level.FINER],
/// [Level.FINEST], and [Level.ALL].
///
/// We recommend using one of the predefined logging levels. If you define your
/// own level, make sure you use a value between those used in [Level.ALL] and
/// [Level.OFF].
class Level implements Comparable<Level> {
  final String name;

  /// Unique value for this level. Used to order levels, so filtering can
  /// exclude messages whose level is under certain value.
  final int value;

  const Level(this.name, this.value);

  /// Special key to turn on logging for all levels ([value] = 0).
  static const Level ALL = Level('ALL', 0);

  /// Special key to turn off all logging ([value] = 2000).
  static const Level OFF = Level('OFF', 2000);

  /// Key for highly detailed tracing ([value] = 300).
  static const Level FINEST = Level('FINEST', 300);

  /// Key for fairly detailed tracing ([value] = 400).
  static const Level FINER = Level('FINER', 400);

  /// Key for tracing information ([value] = 500).
  static const Level FINE = Level('FINE', 500);

  /// Key for static configuration messages ([value] = 700).
  static const Level CONFIG = Level('CONFIG', 700);

  /// Key for informational messages ([value] = 800).
  static const Level INFO = Level('INFO', 800);

  /// Key for potential problems ([value] = 900).
  static const Level WARNING = Level('WARNING', 900);

  /// Key for serious failures ([value] = 1000).
  static const Level SEVERE = Level('SEVERE', 1000);

  /// Key for extra debugging loudness ([value] = 1200).
  static const Level SHOUT = Level('SHOUT', 1200);

  static const List<Level> LEVELS = [
    ALL,
    FINEST,
    FINER,
    FINE,
    CONFIG,
    INFO,
    WARNING,
    SEVERE,
    SHOUT,
    OFF
  ];

  @override
  bool operator ==(Object other) => other is Level && value == other.value;

  bool operator <(Level other) => value < other.value;

  bool operator <=(Level other) => value <= other.value;

  bool operator >(Level other) => value > other.value;

  bool operator >=(Level other) => value >= other.value;

  @override
  int compareTo(Level other) => value - other.value;

  @override
  int get hashCode => value;

  @override
  String toString() => name;
}
