import 'package:flutter/material.dart';

import '../octo_image.dart';

/// Predefined set of [OctoProgressIndicatorBuilder]s. For example:
///     OctoImage(
///      image: NetworkImage('https://dummyimage.com/600x400/000/fff'),
///      progressIndicatorBuilder:
///          OctoProgressIndicator.circularProgressIndicator(),
///    );
class OctoProgressIndicator {
  /// Default [CircularProgressIndicator] with progress if available.
  static OctoProgressIndicatorBuilder circularProgressIndicator() {
    return (context, progress) {
      double? value;
      if (progress != null && progress.expectedTotalBytes != null) {
        value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
      }
      return Center(child: CircularProgressIndicator(value: value));
    };
  }
}
