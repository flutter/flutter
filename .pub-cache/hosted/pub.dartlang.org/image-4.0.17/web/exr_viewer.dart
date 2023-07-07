import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Convert all .exr IMG elements on the page to PNG so that they can be viewed
/// by browsers.
void main() {
  final images = querySelectorAll('img');

  for (var e in images) {
    final imgElem = e as ImageElement;
    if (imgElem.src!.toLowerCase().endsWith('.exr')) {
      final req = HttpRequest()
        ..open('GET', imgElem.src!)
        ..overrideMimeType('text/plain; charset=x-user-defined');
      req.onLoadEnd.listen((e) {
        if (req.status == 200) {
          // Get the bytes from the image file
          final b = req.responseText!
              .split('')
              .map((e) => String.fromCharCode(e.codeUnitAt(0) & 0xff))
              .join()
              .codeUnits;
          final bytes = Uint8List.fromList(b);

          // Decode the EXR image
          final image = img.decodeExr(bytes);
          if (image != null) {
            // Adjust the exposure of the EXR image
            final ldr = img.hdrToLdr(image, exposure: 0.8);
            // Convert the adjusted EXR to a PNG
            final png = img.encodePng(ldr);
            // Replace the image element src with the converted image.
            final png64 = base64Encode(png);
            // ignore: unsafe_html
            imgElem.src = 'data:image/png;base64,$png64';
          }
        }
      });
      req.send('');
    }
  }
}
