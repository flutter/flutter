import 'dart:html';
import 'dart:math';
import 'package:image/image.dart';

double logN(num x, num div) => log(x) / div;

/// Render the Mandelbrot Set into an Image and display it.
void main() {
  const width = 1024;
  const height = 1024;

  // Create a canvas to put our decoded image into.
  final c = CanvasElement(width: width, height: height);
  document.body!.append(c);

  const zoom = 1.0;
  const moveX = -0.5;
  const moveY = 0.0;
  const maxIterations = 255;
  const radius = 2.0;
  const radiusSquared = radius * radius;
  final log2 = log(2.0);
  final log2MaxIterations = logN(maxIterations, log2);
  const h_2 = height / 2.0;
  const w_2 = width / 2.0;
  const aspect = 0.5;

  // Canvas expects RGBA pixel data
  final image = Image(width: width, height: height, numChannels: 4);
  for (final p in image) {
    final x = p.x;
    final y = p.y;
    final pi = (y - h_2) / (0.5 * zoom * aspect * height) + moveY;
    final pr = 1.5 * (x - w_2) / (0.5 * zoom * width) + moveX;

    var newRe = 0.0;
    var newIm = 0.0;
    var i = 0;
    for (; i < maxIterations; i++) {
      final oldRe = newRe;
      final oldIm = newIm;

      newRe = oldRe * oldRe - oldIm * oldIm + pr;
      newIm = 2.0 * oldRe * oldIm + pi;

      if ((newRe * newRe + newIm * newIm) > radiusSquared) {
        break;
      }
    }

    if (i == maxIterations) {
      image.setPixelRgba(x, y, 0, 255, 0, 255);
    } else {
      final z = sqrt(newRe * newRe + newIm * newIm);
      final b = 256.0 *
          logN(1.75 + i - logN(logN(z, log2), log2), log2) /
          log2MaxIterations;
      final brightness = b.toInt();
      image.setPixelRgba(x, y, brightness, brightness, 255, 255);
    }
  }

  // Create a buffer that the canvas can draw.
  final d = c.context2D.createImageData(image.width, image.height);
  // Fill the buffer with our image data.
  d.data.setRange(0, d.data.length, image.toUint8List());
  // Draw the buffer onto the canvas.
  c.context2D.putImageData(d, 0, 0);
}
