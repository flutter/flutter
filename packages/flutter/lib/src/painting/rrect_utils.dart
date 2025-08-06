import 'basic_types.dart';
import 'edge_insets.dart';

/// Utility methods for manipulating [RRect] objects.
abstract final class RRectUtils {
  /// Inflates an [RRect] by the given [EdgeInsets].
  static RRect inflateRRect(RRect rect, EdgeInsets insets) {
    return RRect.fromLTRBAndCorners(
      rect.left - insets.left,
      rect.top - insets.top,
      rect.right + insets.right,
      rect.bottom + insets.bottom,
      topLeft: (rect.tlRadius + Radius.elliptical(insets.left, insets.top)).clamp(
        minimum: Radius.zero,
      ),
      topRight: (rect.trRadius + Radius.elliptical(insets.right, insets.top)).clamp(
        minimum: Radius.zero,
      ),
      bottomRight: (rect.brRadius + Radius.elliptical(insets.right, insets.bottom)).clamp(
        minimum: Radius.zero,
      ),
      bottomLeft: (rect.blRadius + Radius.elliptical(insets.left, insets.bottom)).clamp(
        minimum: Radius.zero,
      ),
    );
  }

  /// Deflates an [RRect] by the given [EdgeInsets].
  static RRect deflateRRect(RRect rect, EdgeInsets insets) {
    return RRect.fromLTRBAndCorners(
      rect.left + insets.left,
      rect.top + insets.top,
      rect.right - insets.right,
      rect.bottom - insets.bottom,
      topLeft: (rect.tlRadius - Radius.elliptical(insets.left, insets.top)).clamp(
        minimum: Radius.zero,
      ),
      topRight: (rect.trRadius - Radius.elliptical(insets.right, insets.top)).clamp(
        minimum: Radius.zero,
      ),
      bottomRight: (rect.brRadius - Radius.elliptical(insets.right, insets.bottom)).clamp(
        minimum: Radius.zero,
      ),
      bottomLeft: (rect.blRadius - Radius.elliptical(insets.left, insets.bottom)).clamp(
        minimum: Radius.zero,
      ),
    );
  }
}
