import 'dart:io';
import 'package:image/image.dart';

void main(List<String> argv) {
  if (argv.isEmpty) {
    print('Usage: image_server <image_file>');
    return;
  }

  final filename = argv[0];

  final file = File(filename);
  if (!file.existsSync()) {
    print('File does not exist: $filename');
    return;
  }

  final fileBytes = file.readAsBytesSync();

  final decoder = findDecoderForData(fileBytes);
  if (decoder == null) {
    print('Could not find format decoder for: $filename');
    return;
  }

  final image = decoder.decodeImage(fileBytes)!;

  // ... do something with image ...

  // Save the image as a PNG
  final png = PngEncoder().encodeImage(image);
  // Write the PNG to disk
  File('$filename.png').writeAsBytesSync(png);
}
