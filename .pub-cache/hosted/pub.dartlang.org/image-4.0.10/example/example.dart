import 'package:image/image.dart' as img;

void main() async {
  await (img.Command()
        // Read a WebP image from a file.
        ..decodeWebPFile('test.webp')
        // Resize the image so its width is 120 and height maintains aspect
        // ratio.
        ..copyResize(width: 120)
        // Save the image to a PNG file.
        ..writeToFile('thumbnail.png'))
      // Execute the image commands in an isolate thread
      .executeThread();
}
