import 'package:mime/mime.dart';

void main() {
  print(lookupMimeType('test.html'));
  // text/html

  print(lookupMimeType('test', headerBytes: [0xFF, 0xD8]));
  // image/jpeg

  print(lookupMimeType('test.html', headerBytes: [0xFF, 0xD8]));
  // image/jpeg
}
