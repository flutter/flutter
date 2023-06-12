import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import '../octo_image.dart';

/// OctoPlaceholders are predefined [OctoPlaceholderBuilder]s that can easily
/// be used for the [OctoImage]. For example:
///     OctoImage(
///      image: NetworkImage('https://dummyimage.com/600x400/000/fff'),
///      placeholderBuilder: OctoPlaceholder.circularProgressIndicator(),
///    );
class OctoPlaceholder {
  /// Use [BlurHash](https://pub.dev/packages/flutter_blurhash) as a placeholder.
  /// The hash should be made server side. See [blurha.sh](https://blurha.sh/) for more information.
  /// [fit] defaults to [BoxFit.cover].
  static OctoPlaceholderBuilder blurHash(String hash, {BoxFit? fit}) {
    return (context) => SizedBox.expand(
          child: Image(
            image: BlurHashImage(hash),
            fit: fit ?? BoxFit.cover,
          ),
        );
  }

  /// Displays a [CircleAvatar] as placeholder
  static OctoPlaceholderBuilder circleAvatar({
    required Color backgroundColor,
    required Widget text,
  }) {
    return (context) => SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CircleAvatar(
            child: text,
            backgroundColor: backgroundColor,
          ),
        );
  }

  /// Displays a simple [CircularProgressIndicator] with undetermined progress.
  static OctoPlaceholderBuilder circularProgressIndicator() {
    return (context) => const Center(
          child: CircularProgressIndicator(),
        );
  }

  /// Displays a frame as placeholer. From the framework [Placeholder] widget.
  static OctoPlaceholderBuilder frame() {
    return (context) => const SizedBox.expand(child: Placeholder());
  }
}
