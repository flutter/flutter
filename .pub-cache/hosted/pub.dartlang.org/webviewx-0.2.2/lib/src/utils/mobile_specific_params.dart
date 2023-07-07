import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Parameters specific to the mobile version.
///
/// This may merge with [WebSpecificParams] in the future.
class MobileSpecificParams {
  /// A set of gesture recognizers.
  ///
  /// This is used in order to allow the users to scroll in situations where
  /// it would normally not be possible.
  ///
  /// What does that mean? Check this out(part 3): {@youtube 500 300 https://www.youtube.com/watch?v=RA-vLF_vnng}
  ///
  /// Example usage:
  ///
  /// ```dart
  /// mobileGestureRecognizers: Set()
  /// ..add(
  ///   Factory<VerticalDragGestureRecognizer>(
  ///     () => VerticalDragGestureRecognizer(),
  ///   ),
  /// )
  /// ..add(
  ///   Factory<TapGestureRecognizer>(
  ///     () => TapGestureRecognizer(),
  ///   ),
  /// )
  /// ..add(
  ///   Factory<LongPressGestureRecognizer>(
  ///     () => LongPressGestureRecognizer(),
  ///   ),
  /// ),
  /// ```
  final Set<Factory<OneSequenceGestureRecognizer>>? mobileGestureRecognizers;

  /// Same as the original one from webview_flutter.
  final bool debuggingEnabled;

  /// Same as the original one from webview_flutter.
  final bool gestureNavigationEnabled;

  /// Enable WebView hybrid composition
  final bool androidEnableHybridComposition;

  /// Constructor
  const MobileSpecificParams({
    this.mobileGestureRecognizers,
    this.gestureNavigationEnabled = false,
    this.debuggingEnabled = false,
    this.androidEnableHybridComposition = false,
  });
}
