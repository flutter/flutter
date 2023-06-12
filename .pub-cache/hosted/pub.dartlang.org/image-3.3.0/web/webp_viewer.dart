import 'dart:convert';
import 'dart:html';

import 'package:image/image.dart';

/// Convert all .webp IMG elements on the page to PNG so that they can be viewed
/// by browsers like FireFox and IE.
void main() {
  final images = querySelectorAll('img');

  for (var _img in images) {
    final img = _img as ImageElement;
    if (img.src!.toLowerCase().endsWith('.webp')) {
      final req = HttpRequest();
      req.open('GET', img.src!);
      req.overrideMimeType('text\/plain; charset=x-user-defined');
      req.onLoadEnd.listen((e) {
        if (req.status == 200) {
          final bytes = req.responseText!
              .split('')
              .map((e) => String.fromCharCode(e.codeUnitAt(0) & 0xff))
              .join()
              .codeUnits;

          final image = decodeWebP(bytes)!;
          final png = encodePng(image);

          final png64 = base64Encode(png);
          // ignore: unsafe_html
          img.src = 'data:image/png;base64,$png64';
        }
      });
      req.send('');
    }
  }
}
