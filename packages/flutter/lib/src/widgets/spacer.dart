// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

/// Spacer creates an adjustable, empty spacer that can be used to tune the
/// spacing between widgets in a [Flexible] container, like [Row] or [Column].
///
/// Spacer takes an optional parameter [flex] that is used as the
/// [Flexible.flex] value.
///
/// ## Sample code
///
/// ```dart
/// new Row(
///   children: <Widget>[
///     new Text('Begin'),
///     new Spacer(),
///     new Text('Middle'),
///     // Gives twice the space between Middle and End than Begin and Middle.
///     new Spacer(flex: 2),
///     new Text('End'),
///   ],
/// )
/// ```
///
/// See also:
///
///  * [Row] and [Column], which are the most common containers to use a Spacer
///    in.
///  * [SizedBox], to create a box with a specific size and an optional child.
class Spacer extends StatelessWidget {
  /// Creates a flexible space to insert into a [Flexible] widget.
  ///
  /// The [flex] parameter may not be negative, but may be null. A null [flex]
  /// is the same as a [flex] of zero.
  const Spacer({Key key, this.flex: 1})
      : assert(flex == null || flex >= 0),
        super(key: key);

  /// The flex factor to use in determining how much space to take up.
  ///
  /// If null or zero, the [Spacer] will take up no space. If set to a value
  /// greater than zero, the amount of space the [Spacer] can occupy in the main
  /// axis is determined by dividing the free space proportionately, after
  /// placing the inflexible children, according to the flex factors of the
  /// flexible children.
  ///
  /// Defaults to one.
  final int flex;

  @override
  Widget build(BuildContext context) {
    return new Flexible(
      flex: flex,
      child: new LimitedBox(
        maxWidth: 0.0,
        maxHeight: 0.0,
        child: new ConstrainedBox(
          constraints: const BoxConstraints.expand(),
        ),
      ),
    );
  }
}
