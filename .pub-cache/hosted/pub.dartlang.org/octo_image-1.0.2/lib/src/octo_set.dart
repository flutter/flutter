import 'package:flutter/material.dart';

import '../octo_image.dart';

/// OctoSets are predefined combinations of a [OctoPlaceholderBuilder],
/// [OctoProgressIndicatorBuilder], [OctoImageBuilder] and/or [OctoErrorBuilder].
/// All sets have at least a placeholder or progress indicator and
/// an error builder.
///
/// For example:
///     OctoImage.fromSet(
///      image: NetworkImage('https://dummyimage.com/600x400/000/fff'),
///      octoSet: OctoSet.simple(),
///    );
class OctoSet {
  /// Optional builder to further customize the display of the image.
  final OctoImageBuilder? imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final OctoPlaceholderBuilder? placeholderBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final OctoProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final OctoErrorBuilder? errorBuilder;

  OctoSet._({
    this.imageBuilder,
    this.placeholderBuilder,
    this.progressIndicatorBuilder,
    this.errorBuilder,
  }) : assert(placeholderBuilder != null || progressIndicatorBuilder != null);

  /// Simple set to show [OctoPlaceholder.circularProgressIndicator] as
  /// placeholder and [OctoError.icon] as error.
  factory OctoSet.blurHash(
    String hash, {
    BoxFit? fit,
    Text? errorMessage,
  }) {
    return OctoSet._(
      placeholderBuilder: OctoPlaceholder.blurHash(hash, fit: fit),
      errorBuilder: OctoError.blurHash(hash, fit: fit),
    );
  }

  /// Simple set to show [OctoPlaceholder.circularProgressIndicator] as
  /// placeholder and [OctoError.icon] as error.
  factory OctoSet.circleAvatar({
    required Color backgroundColor,
    required Widget text,
  }) {
    return OctoSet._(
      placeholderBuilder: OctoPlaceholder.circleAvatar(
          backgroundColor: backgroundColor, text: text),
      imageBuilder: OctoImageTransformer.circleAvatar(),
      errorBuilder:
          OctoError.circleAvatar(backgroundColor: backgroundColor, text: text),
    );
  }

  /// Simple set to show [OctoPlaceholder.circularProgressIndicator] as
  /// placeholder and [OctoError.icon] as error.
  factory OctoSet.circularIndicatorAndIcon({bool showProgress = false}) {
    return OctoSet._(
      placeholderBuilder:
          showProgress ? null : OctoPlaceholder.circularProgressIndicator(),
      progressIndicatorBuilder: showProgress
          ? OctoProgressIndicator.circularProgressIndicator()
          : null,
      errorBuilder: OctoError.icon(),
    );
  }
}
