import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:image/image.dart';

/// Decode and display various image formats. This is used as a visual
/// unit-test to identify problems that may occur after the translation to
/// javascript.
void main() {
  // An img on the html page is used to establish the path to the images
  // directory. It's removed after we get the path since we'll be populating
  // the page with our own decoded images.
  final img = querySelectorAll('img')[0] as ImageElement;
  final path = img.src!.substring(0, img.src!.lastIndexOf('/'));
  img.remove();

  // The list of images we'll be decoding, representing a wide range
  // of formats and sub-formats.
  final images = [
    'penguins.jpg',
    'puppies.jpg',
    '1_webp_ll.webp',
    '1.webp',
    '3_webp_a.webp',
    'BladeRunner_lossy.webp',
    'cars.gif',
    'trees.png',
    'animated.png',
  ];

  for (var name in images) {
    // Use an http request to get the image file from disk.
    final req = HttpRequest();
    req.open('GET', '$path/$name');
    req.responseType = 'arraybuffer';
    req.onLoadEnd.listen((e) {
      if (req.status == 200) {
        // Convert the text to binary byte list.
        final List<int> bytes = Uint8List.view(req.response as ByteBuffer);

        final label = DivElement();
        document.body!.append(label);
        label.text = name;

        // Create a canvas to put our decoded image into.
        final c = CanvasElement();
        document.body!.append(c);

        // Find the best decoder for the image.
        final decoder = findDecoderForData(bytes);
        if (decoder == null) {
          return;
        }

        // Some of the files are animated, so always decode to animation.
        // Single image files will decode to a single framed animation.
        final anim = decoder.decodeAnimation(bytes);
        if (anim == null) {
          return;
        }

        // If it's a single image, dump the decoded image into the canvas.
        if (anim.length == 1) {
          final image = anim.frames[0];

          //Image newImage = copyResize(image, 2000, -1, CUBIC);
          final newImage = image;

          c.width = newImage.width;
          c.height = newImage.height;

          // Create a buffer that the canvas can draw.
          final d = c.context2D.createImageData(c.width, c.height);
          // Fill the buffer with our image data.
          d.data.setRange(0, d.data.length, newImage.getBytes());
          // Draw the buffer onto the canvas.
          c.context2D.putImageData(d, 0, 0);

          return;
        }

        // A multi-frame animation, use a timer to draw frames.
        // TODO this is currently not using the timing information in the
        // [Animation], and using a hard-coded delay instead.

        // Setup the canvas size to the size of the first image.
        c.width = anim.frames[0].width;
        c.height = anim.frames[0].height;
        // Create a buffer that the canvas can draw.
        final d = c.context2D.createImageData(c.width, c.height);

        var frame = 0;
        Timer.periodic(const Duration(milliseconds: 40), (t) {
          final image = anim.frames[frame++];
          if (frame >= anim.numFrames) {
            frame = 0;
          }

          // Fill the buffer with our image data.
          d.data.setRange(0, d.data.length, image.getBytes());
          // Draw the buffer onto the canvas.
          c.context2D.putImageData(d, 0, 0);
        });
      }
    });
    req.send('');
  }
}
