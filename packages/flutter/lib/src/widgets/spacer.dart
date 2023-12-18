// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../rendering.dart';
import 'basic.dart';
import 'framework.dart';

/// Spacer creates an adjustable, empty spacer that can be used to tune the
/// spacing between widgets in a [Flex] container, like [Row] or [Column].
///
/// The [Spacer] widget will take space in a dynamic or fixed way, depending
/// on which constructor is used:
/// * The default unnamed constructor [Spacer] will take up any available
/// space, so setting the [Flex.mainAxisAlignment] on a flex container that
/// contains a [Spacer] to [MainAxisAlignment.spaceAround],
/// [MainAxisAlignment.spaceBetween], or [MainAxisAlignment.spaceEvenly] will
/// not have any visible effect: the [Spacer] has taken up all of the
/// additional space, therefore there is none left to redistribute.
/// * The [Spacer.fixed] constructor will take an absolute amount of space in
/// the main axis.
///
/// {@tool snippet}
///
/// ```dart
/// const Row(
///   children: <Widget>[
///     Text('Begin'),
///     Spacer(), // Defaults to a flex of one.
///     Text('Middle 1'),
///     // Gives twice the space between Middle and End than Begin and Middle.
///     Spacer(flex: 2),
///     Text('Middle 1'),
///     Spacer.fixed(length: 24.0), // A fixed space of 24.0 dp
///     Text('End'),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=7FJgd7QN1zI}
///
/// See also:
///
///  * [Row] and [Column], which are the most common containers to use a Spacer
///    in.
///  * [SizedBox], to create a box with a specific size and an optional child.
class Spacer extends StatelessWidget {
  /// Creates a flexible space to insert into a [Flexible] widget.
  ///
  /// The [flex] parameter may not be null or less than one.
  const Spacer({super.key, int this.flex = 1})
      : length = null, assert(flex > 0);

  /// Creates a space with fixed length to insert into a [Flexible] widget.
  ///
  /// The [length] parameter must be equal or greater than zero.
  const Spacer.fixed({super.key, double this.length = 0.0}) : flex = null, assert(length >= 0.0);

  /// The flex factor to use in determining how much space to take up.
  ///
  /// The amount of space the [Spacer] can occupy in the main axis is determined
  /// by dividing the free space proportionately, after placing the inflexible
  /// children, according to the flex factors of the flexible children.
  ///
  /// Defaults to one.
  final int? flex;

  /// The absolute fixed length in the main axis that will be taken.
  final double? length;

  @override
  Widget build(BuildContext context) {
    assert(
      (flex == null) ^ (length == null),
      'Either flex or length should be provided, but not both.',
    );

    if (flex case final int flex) {
      return Expanded(
        flex: flex,
        child: const SizedBox.shrink(),
      );
    } else if (length case final double length){
      return _RawFixedLengthSpacer(length);
    } else {
      throw StateError('Unreachable code.');
    }
  }
}

final class _RawFixedLengthSpacer extends LeafRenderObjectWidget {
  const _RawFixedLengthSpacer(this.length);

  final double length;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFixedLengthSpacer(length: length);
  }

  @override
  void updateRenderObject(BuildContext context, RenderFixedLengthSpacer renderObject) {
    renderObject.length = length;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('length', length));
  }
}
