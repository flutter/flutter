import 'package:flutter/material.dart';

import '../octo_image.dart';

/// Helper class with pre-made [OctoImageBuilder]s. These can be directly
/// used when creating an image.
/// For example:
///     OctoImage(
///      image: NetworkImage('https://dummyimage.com/600x400/000/fff'),
///      imageBuilder: OctoImageTransformer.circleAvatar(),
///    );
class OctoImageTransformer {
  /// Clips the image as a circle, like a [CircleAvatar]
  static OctoImageBuilder circleAvatar() {
    return (context, child) => Center(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: ClipOval(
              child: child,
            ),
          ),
        );
  }
}
