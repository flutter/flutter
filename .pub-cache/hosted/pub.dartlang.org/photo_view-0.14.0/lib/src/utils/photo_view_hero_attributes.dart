import 'package:flutter/widgets.dart';

/// Data class that holds the attributes that are going to be passed to
/// [PhotoViewImageWrapper]'s [Hero].
class PhotoViewHeroAttributes {
  const PhotoViewHeroAttributes({
    required this.tag,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
  });

  /// Mirror to [Hero.tag]
  final Object tag;

  /// Mirror to [Hero.createRectTween]
  final CreateRectTween? createRectTween;

  /// Mirror to [Hero.flightShuttleBuilder]
  final HeroFlightShuttleBuilder? flightShuttleBuilder;

  /// Mirror to [Hero.placeholderBuilder]
  final HeroPlaceholderBuilder? placeholderBuilder;

  /// Mirror to [Hero.transitionOnUserGestures]
  final bool transitionOnUserGestures;
}
