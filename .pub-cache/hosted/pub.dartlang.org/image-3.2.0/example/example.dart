import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  final image = decodeImage(File('test.webp').readAsBytesSync())!;

  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  final thumbnail = copyResize(image, width: 120);

  // Save the thumbnail as a PNG.
  File('thumbnail.png').writeAsBytesSync(encodePng(thumbnail));
}
