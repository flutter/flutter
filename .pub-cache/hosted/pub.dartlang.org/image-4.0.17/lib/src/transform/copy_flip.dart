import '../image/image.dart';
import 'flip.dart';

/// Returns a copy of the [src] image, flipped by the given [direction].
Image copyFlip(Image src, {required FlipDirection direction}) =>
    flip(src.clone(), direction: direction);
